/*
 * Register File Module
 *
 * This module implements the register file for the SAP-3 processor.
 * It contains 12 8-bit registers that can be accessed individually
 * or as 16-bit register pairs. The registers include general-purpose
 * registers (B,C,D,E,H,L), temporary registers (W,Z), and special
 * registers (PC, SP).
 *
 * Register layout:
 * 8-bit registers (indices 0-11):
 *   0: B,  1: C,  2: D,  3: E,  4: H,  5: L
 *   6: W,  7: Z,  8: PC_high, 9: PC_low, 10: SP_high, 11: SP_low
 *
 * 16-bit register pairs:
 *   BC (00): {B,C}, DE (10): {D,E}, HL (20): {H,L}
 *   WZ (30): {W,Z}, PC (40): {PC_high,PC_low}, SP (50): {SP_high,SP_low}
 *
 * Inputs:
 * - clk: Clock signal
 * - rst: Reset signal
 * - rd_sel: 5-bit read select (bit 4: 16-bit mode, bits 3:0: register index)
 * - wr_sel: 5-bit write select (same format as rd_sel)
 * - ext: 2-bit extension operation (INC, DEC, INC2)
 * - we: Write enable
 * - data_in: 16-bit input data
 *
 * Outputs:
 * - data_out: 16-bit output data
 */

module reg_file(
	input clk,
	input rst,
	input[4:0] rd_sel,
	input[4:0] wr_sel,
	input[1:0] ext,
	input we,
	input[15:0] data_in,
	output reg [15:0] data_out
);

// Register array: 12 x 8-bit registers
reg[7:0] data[0:11];

// Extract control signals from select lines
wire wr_ext = wr_sel[4];     // Write in 16-bit mode
wire rd_ext = rd_sel[4];     // Read in 16-bit mode
wire[3:0] wr_dst = wr_sel[3:0];  // Write register index
wire[3:0] rd_src = rd_sel[3:0];  // Read register index

// Extension operation constants
localparam EXT_INC  = 2'b01;  // Increment by 1
localparam EXT_DEC  = 2'b10;  // Decrement by 1
localparam EXT_INC2 = 2'b11;  // Increment by 2

// Synchronous write logic
always @(posedge clk, posedge rst) begin
	if (rst) begin
		// Reset all registers to 0
		data[0] <= 8'b0; data[1] <= 8'b0; data[2] <= 8'b0; data[3] <= 8'b0; data[4] <= 8'b0;
		data[5] <= 8'b0; data[6] <= 8'b0; data[7] <= 8'b0; data[8] <= 8'b0; data[9] <= 8'b0;
		data[10] <= 8'b0; data[11] <= 8'b0;
	end else begin
		if (ext == EXT_INC) begin
			// Increment 16-bit register pair by 1
			{data[wr_dst], data[wr_dst+1]} <= {data[wr_dst], data[wr_dst+1]} + 1;
		end else if (ext == EXT_INC2) begin
			// Increment 16-bit register pair by 2
			{data[wr_dst], data[wr_dst+1]} <= {data[wr_dst], data[wr_dst+1]} + 2;
		end else if (ext == EXT_DEC) begin
			// Decrement 16-bit register pair by 1
			{data[wr_dst], data[wr_dst+1]} <= {data[wr_dst], data[wr_dst+1]} - 1;
		end else if (we) begin
			if (wr_ext) begin
				// Write 16-bit data to register pair
				{data[wr_dst], data[wr_dst+1]} <= data_in;
			end else begin
				// Write low 8 bits to single register
				data[wr_dst] <= data_in[7:0];
			end
		end
	end
end

// Combinatorial read logic
always @(*) begin
	if (rd_ext) begin
		// Read 16-bit register pair
		data_out = {data[rd_src], data[rd_src+1]};
	end else begin
		// Read 8-bit register (padded with zeros)
		data_out = {8'b0, data[rd_src]};
	end
end

endmodule

