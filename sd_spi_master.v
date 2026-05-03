/*
 * SD Card SPI Master
 * 
 * Handles basic SPI communication with an SD card in SPI Mode 0.
 * Provides a slow mode (~335 kHz) for SD initialization and a 
 * fast mode (~10.7 MHz) for standard data block transfers.
 */
module sd_spi_master(
    input wire clk,       // System clock (e.g., 21.477 MHz)
    input wire rst,       // Active-high reset
    
    input wire [7:0] tx_data,
    input wire tx_start,
    input wire fast_mode, // 0 = ~335 kHz, 1 = ~10.7 MHz
    
    output reg [7:0] rx_data,
    output reg ready,
    
    output reg spi_clk,
    output reg spi_mosi,
    input wire spi_miso
);

    reg [6:0] clk_div;
    wire [6:0] max_div = fast_mode ? 7'd0 : 7'd63; // 63 = ~167 kHz safe mode
    
    reg [2:0] bit_cnt;
    reg [1:0] state; // 0: Idle, 1: Setup/Falling Edge, 2: Sample/Rising Edge
    
    reg [7:0] shift_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ready <= 1'b1;
            spi_clk <= 1'b0;
            spi_mosi <= 1'b1;
            rx_data <= 8'hFF;
            state <= 2'b00;
            clk_div <= 7'd0;
            bit_cnt <= 3'd0;
            shift_reg <= 8'hFF;
        end else begin
            case (state)
                2'b00: begin // Idle
                    spi_clk <= 1'b0;
                    if (tx_start && ready) begin
                        ready <= 1'b0;
                        shift_reg <= tx_data;
                        spi_mosi <= tx_data[7];
                        bit_cnt <= 3'd7;
                        clk_div <= 7'd0;
                        state <= 2'b01;
                    end
                end
                
                2'b01: begin // Setup time, then RISING EDGE and Sample
                    if (clk_div == max_div) begin
                        clk_div <= 7'd0;
                        spi_clk <= 1'b1;
                        shift_reg <= {shift_reg[6:0], spi_miso};
                        state <= 2'b10;
                    end else begin
                        clk_div <= clk_div + 1'b1;
                    end
                end
                
                2'b10: begin // Hold time, FALLING EDGE and Setup next bit
                    if (clk_div == max_div) begin
                        clk_div <= 7'd0;
                        spi_clk <= 1'b0;
                        if (bit_cnt == 3'd0) begin
                            rx_data <= shift_reg;
                            ready <= 1'b1;
                            spi_mosi <= 1'b1;
                            state <= 2'b00;
                        end else begin
                            spi_mosi <= shift_reg[7]; // Shift out the next bit
                            bit_cnt <= bit_cnt - 1'b1;
                            state <= 2'b01;
                        end
                    end else begin
                        clk_div <= clk_div + 1'b1;
                    end
                end
                
                default: state <= 2'b00;
            endcase
        end
    end
endmodule