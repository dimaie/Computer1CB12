module uart #(
    // Default parameter assumes a 25.175MHz clock and 115200 baud rate (25,175,000 / 115200)
    parameter CLOCKS_PER_BIT = 219
)(
    input  wire       clk,
    input  wire       rst,
    
    // Serial interface pins
    input  wire       rx,
    output reg        tx,
    
    // Processor Tx interface
    input  wire [7:0] tx_data,
    input  wire       tx_we,
    output reg        tx_busy,
    
    // Processor Rx interface
    output reg  [7:0] rx_data,
    output reg        rx_done
);

    // State machine constants
    localparam STATE_IDLE  = 2'b00;
    localparam STATE_START = 2'b01;
    localparam STATE_DATA  = 2'b10;
    localparam STATE_STOP  = 2'b11;

    // Transmitter (Tx) internal registers
    reg [1:0]  tx_state;
    reg [15:0] tx_clk_count;
    reg [2:0]  tx_bit_index;
    reg [7:0]  tx_data_reg;

    // Receiver (Rx) internal registers
    reg [1:0]  rx_state;
    reg [15:0] rx_clk_count;
    reg [2:0]  rx_bit_index;

    // -------------------------------------------------------------------------
    // Anti-Metastability Synchronizer for Rx
    // -------------------------------------------------------------------------
    reg rx_sync_1, rx_sync;
    always @(posedge clk) begin
        if (rst) begin
            rx_sync_1 <= 1'b1;
            rx_sync   <= 1'b1;
        end else begin
            rx_sync_1 <= rx;
            rx_sync   <= rx_sync_1;
        end
    end

    // -------------------------------------------------------------------------
    // UART Transmitter Logic
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            tx_state     <= STATE_IDLE;
            tx           <= 1'b1; // Idle state for UART Tx is high
            tx_busy      <= 1'b0;
            tx_clk_count <= 0;
            tx_bit_index <= 0;
            tx_data_reg  <= 8'h00;
        end else begin
            case (tx_state)
                STATE_IDLE: begin
                    tx           <= 1'b1;
                    tx_clk_count <= 0;
                    tx_bit_index <= 0;
                    
                    if (tx_we) begin
                        tx_data_reg <= tx_data;
                        tx_state    <= STATE_START;
                        tx_busy     <= 1'b1;
                    end else begin
                        tx_busy     <= 1'b0;
                    end
                end
                
                STATE_START: begin
                    tx <= 1'b0;
                    if (tx_clk_count < CLOCKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_state     <= STATE_DATA;
                    end
                end
                
                STATE_DATA: begin
                    tx <= tx_data_reg[tx_bit_index];
                    if (tx_clk_count < CLOCKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end else begin
                        tx_clk_count <= 0;
                        if (tx_bit_index < 7) begin
                            tx_bit_index <= tx_bit_index + 1'b1;
                        end else begin
                            tx_bit_index <= 0;
                            tx_state     <= STATE_STOP;
                        end
                    end
                end
                
                STATE_STOP: begin
                    tx <= 1'b1;
                    if (tx_clk_count < CLOCKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_state     <= STATE_IDLE;
                        tx_busy      <= 1'b0;
                    end
                end
                
                default: tx_state <= STATE_IDLE;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // UART Receiver Logic
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            rx_state     <= STATE_IDLE;
            rx_clk_count <= 0;
            rx_bit_index <= 0;
            rx_done      <= 1'b0;
            rx_data      <= 8'h00;
        end else begin
            // Ensure rx_done only pulses for a single clock cycle
            rx_done <= 1'b0;
            
            case (rx_state)
                STATE_IDLE: begin
                    rx_clk_count <= 0;
                    rx_bit_index <= 0;
                    // Falling edge detected on Rx line (Start bit)
                    if (rx_sync == 1'b0) begin
                        rx_state <= STATE_START;
                    end
                end
                
                STATE_START: begin
                    // Wait for the middle of the start bit to sample
                    if (rx_clk_count == (CLOCKS_PER_BIT / 2)) begin
                        if (rx_sync == 1'b0) begin
                            rx_clk_count <= 0;
                            rx_state     <= STATE_DATA;
                        end else begin
                            // False start bit detected, return to idle
                            rx_state     <= STATE_IDLE;
                        end
                    end else begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end
                end
                
                STATE_DATA: begin
                    if (rx_clk_count < CLOCKS_PER_BIT - 1) begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end else begin
                        rx_clk_count          <= 0;
                        rx_data[rx_bit_index] <= rx_sync;
                        
                        if (rx_bit_index < 7) begin
                            rx_bit_index <= rx_bit_index + 1'b1;
                        end else begin
                            rx_bit_index <= 0;
                            rx_state     <= STATE_STOP;
                        end
                    end
                end
                
                STATE_STOP: begin
                    // Wait for only HALF the stop bit duration.
                    // This provides maximum framing tolerance for back-to-back bursts!
                    if (rx_clk_count < (CLOCKS_PER_BIT / 2)) begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end else begin
                        rx_done      <= 1'b1;
                        rx_clk_count <= 0;
                        rx_state     <= STATE_IDLE;
                    end
                end
                
                default: rx_state <= STATE_IDLE;
            endcase
        end
    end

endmodule