/*
 * ALU (Arithmetic Logic Unit) Module
 *
 * This module implements the ALU for the SAP-3 processor. It performs various
 * arithmetic and logical operations on the accumulator (acc) and temporary register (tmp).
 * It also manages the processor flags based on the operation results.
 *
 * Inputs:
 * - clk: Clock signal
 * - rst: Reset signal
 * - cs: Chip select, enables ALU operations
 * - flags_we: Write enable for flags register
 * - a_we: Write enable for accumulator
 * - a_store: Store accumulator value to internal register
 * - a_restore: Restore accumulator from internal register
 * - tmp_we: Write enable for temporary register
 * - op: 5-bit operation code
 * - bus: 8-bit data bus input
 *
 * Outputs:
 * - flags: 8-bit flags register (Z, C, P, S flags)
 * - out: 8-bit accumulator output
 */

module alu(
	input clk,
	input rst,
	input cs,
	input flags_we,
	input a_we,
	input a_store,
	input a_restore,
	input tmp_we,
	input[4:0] op,
	input[7:0] bus,
	output[7:0] flags,
	output[7:0] out
);

reg carry;  // Carry flag internal register

wire flg_c;  // Carry flag wire
wire flg_z;  // Zero flag wire
wire flg_p;  // Parity flag wire
wire flg_s;  // Sign flag wire

reg[7:0] acc;  // Accumulator register
reg[7:0] flg;  // Flags register
reg[7:0] act;  // Internal accumulator backup
reg[7:0] tmp;  // Temporary register

// Flag bit positions
localparam FLG_Z = 0;  // Zero flag
localparam FLG_C = 1;  // Carry flag
localparam FLG_P = 2;  // Parity flag
localparam FLG_S = 3;  // Sign flag

// ALU operation codes
localparam OP_ADD = 5'b00000;  // Add
localparam OP_ADC = 5'b00001;  // Add with carry
localparam OP_SUB = 5'b00010;  // Subtract
localparam OP_SBB = 5'b00011;  // Subtract with borrow
localparam OP_ANA = 5'b00100;  // AND
localparam OP_XRA = 5'b00101;  // XOR
localparam OP_ORA = 5'b00110;  // OR
localparam OP_CMP = 5'b00111;  // Compare
localparam OP_RLC = 5'b01000;  // Rotate left
localparam OP_RRC = 5'b01001;  // Rotate right
localparam OP_RAL = 5'b01010;  // Rotate left through carry
localparam OP_RAR = 5'b01011;  // Rotate right through carry
localparam OP_DAA = 5'b01100;  // Decimal adjust accumulator (unsupported)
localparam OP_CMA = 5'b01101;  // Complement accumulator
localparam OP_STC = 5'b01110;  // Set carry
localparam OP_CMC = 5'b01111;  // Complement carry
localparam OP_INR = 5'b10000;  // Increment accumulator
localparam OP_DCR = 5'b10001;  // Decrement accumulator

// Flag calculations based on accumulator value
assign flg_c = (carry == 1'b1);  // Carry flag
assign flg_z = (acc[7:0] == 8'b0);  // Zero flag
assign flg_s = acc[7];  // Sign flag (MSB)
assign flg_p = ~^acc[7:0];  // Parity flag (even parity)

// Main ALU logic on positive clock edge
always @(posedge clk, posedge rst) begin
	if (rst) begin
		acc <= 8'b0;
		act <= 8'b0;
		tmp <= 8'b0;
		carry <= 1'b0;
	end else begin
		if (a_we) begin
			acc <= bus;
		end else if (a_restore) begin
			acc <= act;
		end else if (cs) begin
			case (op)
				// Arithmetic operations
				OP_ADD: begin
					{carry, acc} <= acc + tmp;
				end
				OP_ADC: begin
					{carry, acc} <= acc + tmp + flg[FLG_C];
				end
				OP_SUB:	begin
					{carry, acc} <= acc - tmp;
				end
				OP_SBB:	begin
					{carry, acc} <= acc - tmp - flg[FLG_C];
				end
				// Logical operations
				OP_ANA: begin
					{carry, acc} <= acc & tmp;
				end
				OP_XRA: begin
					{carry, acc} <= acc ^ tmp;
				end
				OP_ORA: begin
					{carry, acc} <= acc | tmp;
				end
				// Compare operation
				OP_CMP: begin
					act <= acc - tmp;
				end
				// Rotate operations
				OP_RLC: begin
					carry <= acc[7];
					acc <= {acc[6:0], acc[7]};
				end
				OP_RRC: begin
					carry <= acc[0];
					acc <= {acc[0], acc[7:1]};
				end
				OP_RAL: begin
					carry <= acc[7];
					acc <= (acc << 1 | {7'b0, flg[FLG_C]});
				end
				OP_RAR: begin
					carry <= acc[0];
					acc <= (acc >> 1 | {flg[FLG_C], 7'b0});
				end
				// Complement and carry operations
				OP_CMA: begin
					acc <= ~acc;
				end
				OP_STC: begin
					carry <= 1'b1;
				end
				OP_CMC: begin
					carry <= ~flg[FLG_C];
				end
				// Increment/Decrement operations
				OP_INR: begin
					acc <= acc + 1;
				end
				OP_DCR: begin
					acc <= acc - 1;
				end
			endcase
		end

		if (a_store)
			act <= acc;

		if (tmp_we)
			tmp <= bus;
	end
end

// Flag update logic on negative clock edge
always @(negedge clk, posedge rst) begin
	if (rst) begin
		flg <= 8'b0;
	end else if (flags_we) begin
		flg <= bus;
	end else begin
		if (cs) begin
			case (op)
				// Update all flags for arithmetic and logical operations
				OP_ADD, OP_ADC, OP_SUB, OP_SBB, OP_ANA, OP_XRA, OP_ORA: begin
					flg[FLG_C] <= flg_c;
					flg[FLG_Z] <= flg_z;
					flg[FLG_S] <= flg_s;
					flg[FLG_P] <= flg_p;
				end

				// Update zero flag for compare
				OP_CMP: begin
					flg[FLG_Z] <= (act == 8'b0);
				end

				// Update flags for increment/decrement (no carry)
				OP_INR, OP_DCR: begin
					flg[FLG_Z] <= flg_z;
					flg[FLG_S] <= flg_s;
					flg[FLG_P] <= flg_p;
				end

				// Update carry flag for rotate and carry operations
				OP_RLC, OP_RRC, OP_RAL, OP_RAR, OP_STC, OP_CMC: begin
					flg[FLG_C] <= flg_c;
				end
			endcase
		end
	end
end

assign flags = flg;  // Output flags register
assign out = acc;  // Output accumulator value

endmodule
