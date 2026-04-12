/*
 * Instruction Register (IR) Module
 *
 * This module stores the current instruction opcode fetched from memory.
 * It holds the 8-bit instruction code that the controller uses to generate
 * control signals for executing the instruction.
 *
 * Inputs:
 * - clk: Clock signal
 * - rst: Reset signal (clears the register)
 * - we: Write enable (loads instruction from bus)
 * - bus: 8-bit data bus input
 *
 * Outputs:
 * - out: 8-bit instruction register output
 */

module ir(
	input clk,
	input rst,
	input we,
	input[7:0] bus,
	output[7:0] out
);

reg[7:0] ir;  // 8-bit instruction register

// Synchronous logic: update on clock edge or reset
always @(posedge clk, posedge rst) begin
	if (rst) begin
		ir <= 8'b0;  // Clear register on reset
	end else if (we) begin
		ir <= bus;  // Load instruction from bus when write enabled
	end
end

assign out = ir;  // Continuously output the stored instruction

endmodule

