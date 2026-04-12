module clock(
	input hlt,            // Halt input (from either processor or manual halt)
	input step_pulse,     // Pulse to generate a single clock cycle
	input clk_in,         // Main clock input
	output reg clk_out    // Clock output
);

always @(*) begin
   if (step_pulse) begin
      clk_out = 1'b1;  // Generate a single clock pulse when step button is pressed
   end else if (hlt) begin
      clk_out = 1'b0;  // Halt the clock when hlt is active
   end else begin
      clk_out = clk_in;  // Normal clock operation when not halted or stepping
   end
end

endmodule
