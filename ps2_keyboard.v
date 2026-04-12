module ps2_keyboard(
    input  wire       clk,
    input  wire       rst,
    
    // PS/2 interface pins
    input  wire       ps2_clk,
    input  wire       ps2_dat,
    
    // Processor interface
    output reg  [7:0] scan_code,
    output reg        scan_code_ready
);

    // Synchronize PS/2 clock to the system clock to prevent metastability
    reg [2:0] ps2_clk_sync;
    always @(posedge clk) begin
        if (rst) begin
            ps2_clk_sync <= 3'b111;
        end else begin
            ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
        end
    end

    // Detect the falling edge of the synchronized PS/2 clock
    wire falling_edge = (ps2_clk_sync[2:1] == 2'b10);

    reg [3:0]  bit_count;
    reg [10:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            bit_count       <= 4'd0;
            shift_reg       <= 11'd0;
            scan_code       <= 8'h00;
            scan_code_ready <= 1'b0;
        end else begin
            scan_code_ready <= 1'b0; // Default to 0, pulse high for one cycle when done
            
            if (falling_edge) begin
                // Shift in the new bit at the MSB, existing bits shift down
                shift_reg <= {ps2_dat, shift_reg[10:1]};
                
                if (bit_count == 10) begin
                    bit_count <= 4'd0;
                    // Validate start bit (0) and stop bit (1) before outputting
                    if (shift_reg[1] == 1'b0 && ps2_dat == 1'b1) begin
                        scan_code       <= shift_reg[9:2];
                        scan_code_ready <= 1'b1;
                    end
                end else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end

endmodule