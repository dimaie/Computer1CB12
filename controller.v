/*
 * Controller Module
 *
 * This module implements the control unit for the SAP-3 processor. It generates
 * control signals for all other modules based on the current instruction opcode
 * and execution stage. The controller manages the instruction fetch cycle and
 * executes instructions through multiple micro-operations (stages).
 *
 * Inputs:
 * - clk: Clock signal
 * - rst: Reset signal
 * - opcode: 8-bit instruction opcode
 * - flags: 8-bit processor flags (Z, C, P, S)
 *
 * Outputs:
 * - out: 35-bit control word containing all control signals
 */

module controller(
	input clk,
	input rst,
	input[7:0] opcode,
	input[7:0] flags,
	output[34:0] out
);

// Control word bit positions
localparam IN_OE         = 34;  // Input Port Output Enable
localparam OAR_WE        = 33;  // Output Address Register Write Enable
localparam OUT_WE        = 32;  // Output Write Enable
localparam HLT           = 31;  // Halt signal
localparam ALU_CS        = 30;  // ALU Chip Select
localparam ALU_FLAGS_WE  = 29;  // ALU Flags Write Enable
localparam ALU_A_WE      = 28;  // ALU Accumulator Write Enable
localparam ALU_A_STORE   = 27;  // ALU Accumulator Store
localparam ALU_A_RESTORE = 26;  // ALU Accumulator Restore
localparam ALU_TMP_WE    = 25;  // ALU Temporary Register Write Enable
localparam ALU_OP4       = 24;  // ALU Operation bit 4
localparam ALU_OP0       = 20;  // ALU Operation bit 0
localparam ALU_OE        = 19;  // ALU Output Enable
localparam ALU_FLAGS_OE  = 18;  // ALU Flags Output Enable
localparam REG_RD_SEL4   = 17;  // Register Read Select bit 4
localparam REG_RD_SEL0   = 13;  // Register Read Select bit 0
localparam REG_WR_SEL4   = 12;  // Register Write Select bit 4
localparam REG_WR_SEL0   = 8;   // Register Write Select bit 0
localparam REG_EXT1      = 7;   // Register Extension bit 1
localparam REG_EXT0      = 6;   // Register Extension bit 0
localparam REG_OE        = 5;   // Register Output Enable
localparam REG_WE        = 4;   // Register Write Enable
localparam MEM_WE        = 3;   // Memory Write Enable
localparam MEM_MAR_WE    = 2;   // Memory Address Register Write Enable
localparam MEM_OE        = 1;   // Memory Output Enable
localparam IR_WE         = 0;   // Instruction Register Write Enable

// Register extension operations
localparam REG_INC   = 2'b01;  // Increment register pair
localparam REG_DEC   = 2'b10;  // Decrement register pair
localparam REG_INC2  = 2'b11;  // Increment register pair by 2

// Register pair selections
localparam REG_BC    = 5'b10000;  // BC register pair
localparam REG_BC_B  = 5'b00000;  // B register
localparam REG_BC_C  = 5'b00001;  // C register

localparam REG_DE    = 5'b10010;  // DE register pair
localparam REG_DE_D  = 5'b00010;  // D register
localparam REG_DE_E  = 5'b00011;  // E register

localparam REG_HL    = 5'b10100;  // HL register pair
localparam REG_HL_H  = 5'b00100;  // H register
localparam REG_HL_L  = 5'b00101;  // L register

localparam REG_WZ    = 5'b10110;  // WZ register pair (temporary)
localparam REG_WZ_W  = 5'b00110;  // W register
localparam REG_WZ_Z  = 5'b00111;  // Z register

localparam REG_PC    = 5'b11000;  // Program Counter pair
localparam REG_PC_P  = 5'b01000;  // PC high byte
localparam REG_PC_C  = 5'b01001;  // PC low byte

localparam REG_SP    = 5'b11010;  // Stack Pointer pair
localparam REG_SP_S  = 5'b01010;  // SP high byte
localparam REG_SP_P  = 5'b01011;  // SP low byte

parameter MEM_WAIT_CYCLES = 2; // Configurable wait states for memory operations

reg[34:0] ctrl_word;  // Control word register
reg[3:0] stage;       // Current execution stage
reg stage_rst;        // Stage reset signal

reg[3:0] wait_cnt;    // Counter for wait states
reg waited;           // Flag to ensure we only wait once per stage

assign out = ctrl_word;  // Output the control word

// Stage counter: increments on negative clock edge, resets on stage_rst or rst
// Includes wait state injection for memory operations.
always @(negedge clk, posedge rst) begin
	if (rst) begin
		stage <= 0;
		wait_cnt <= 0;
		waited <= 0;
	end else begin
		if (wait_cnt > 0) begin
			wait_cnt <= wait_cnt - 1'b1;
		end else if ((ctrl_word[MEM_MAR_WE] || ctrl_word[MEM_WE] || ctrl_word[MEM_OE]) && !waited && MEM_WAIT_CYCLES > 0) begin
			wait_cnt <= MEM_WAIT_CYCLES - 1'b1;
			waited <= 1'b1;
		end else begin
			waited <= 1'b0;
			if (stage_rst) begin
				stage <= 0;
			end else begin
				stage <= stage + 1'b1;
			end
		end
	end
end

// Main control logic: combinatorial generation of control signals
always @(*) begin
	ctrl_word = 0;      // Default: all signals low
	stage_rst = 0;      // Default: continue to next stage

	// Instruction fetch cycle (stages 0-2)
	if (stage == 0) begin
		ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
		ctrl_word[REG_OE] = 1'b1;
		ctrl_word[MEM_MAR_WE] = 1'b1;
	end else if (stage == 1) begin
		ctrl_word[MEM_OE] = 1'b1;
		ctrl_word[IR_WE] = 1'b1;
	end else if (stage == 2) begin
		ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
		ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
	end else begin
		// Instruction execution based on opcode
		casez (opcode)
			// NOP - No Operation
			8'o000: begin
				stage_rst = 1'b1;
			end

			// HLT - Halt
			8'o166: begin
				if (stage == 3) begin
					ctrl_word[HLT] = 1'b1;
				end
			end

			// MOV Rd, M
			// opcode[5:3] - Rd
			8'o1?6: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_HL;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					if (opcode[5:3] == 3'b111) begin
						ctrl_word[ALU_A_WE] = 1'b1;
					end else begin
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = {2'b0, opcode[5:3]};
						ctrl_word[REG_WE] = 1'b1;
					end

					ctrl_word[MEM_OE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// MOV M, Rs
			// opcode[2:0] - Rs
			8'o16?: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_HL;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					if (opcode[2:0] == 3'b111) begin
						ctrl_word[ALU_OE] = 1'b1;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[2:0]};
						ctrl_word[REG_OE] = 1'b1;
					end

					ctrl_word[MEM_WE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// MOV Rd, Rs
			// opcode[5:3] - Rd
			// opcode[2:0] - Rs
			8'o1??: begin
				if (stage == 3) begin
					if (opcode[2:0] == 3'b111) begin
						ctrl_word[ALU_OE] = 1'b1;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[2:0]};
						ctrl_word[REG_OE] = 1'b1;
					end

					if (opcode[5:3] == 3'b111) begin
						ctrl_word[ALU_A_WE] = 1'b1;
					end else begin
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = {2'b0, opcode[5:3]};
						ctrl_word[REG_WE] = 1'b1;
					end

					stage_rst = 1'b1;
				end
			end

			// INX, DCX - Increment/Decrement register pair
			// opcode[5:4] - 16-bit Register pair (BC=00, DE=01, HL=10, SP=11)
			// opcode[3]   - Operation: 0=Increment (INX), 1=Decrement (DCX)
			8'o0?3: begin
				if (stage == 3) begin
					// Select the register pair to modify
					if (opcode[5:4] == 2'b11)
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					else
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = {2'b10, opcode[5:4], 1'b0};

					// Set increment/decrement operation
					ctrl_word[REG_EXT1:REG_EXT0] = {opcode[3], ~opcode[3]};
					stage_rst = 1'b1;
				end
			end

			// INR/DCR M - Increment/Decrement memory location pointed by HL
			// opcode[0] - Operation: 0=Increment (INR), 1=Decrement (DCR)
			8'o064: begin
				if (stage == 3) begin
					// Set memory address to HL register value
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_HL;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					// Read memory value and store in ALU accumulator
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[ALU_A_STORE] = 1'b1;
					ctrl_word[ALU_A_WE] = 1'b1;
				end else if (stage == 5) begin
					// Perform increment/decrement operation
					ctrl_word[ALU_CS] = 1'b1;
					ctrl_word[ALU_OP4:ALU_OP0] = {4'b1000, opcode[0]};
				end else if (stage == 6) begin
					// Write result back to memory
					ctrl_word[ALU_OE] = 1'b1;
					ctrl_word[ALU_A_RESTORE] = 1'b1;
					ctrl_word[MEM_WE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// INR/DCR Rs
			// opcode[5:3] - Rs
			// opcode[0]   - INR (0), DCR (1)
			8'o0?4, 8'o0?5: begin
				if (stage == 3) begin
					if (opcode[5:3] == 3'b111) begin
						ctrl_word[ALU_CS] = 1'b1;
						ctrl_word[ALU_OP4:ALU_OP0] = {4'b1000, opcode[0]};
						stage_rst = 1'b1;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[5:3]};
						ctrl_word[REG_OE] = 1'b1;
						ctrl_word[ALU_A_STORE] = 1'b1;
						ctrl_word[ALU_A_WE] = 1'b1;
					end
				end else if (stage == 4) begin
					ctrl_word[ALU_CS] = 1'b1;
					ctrl_word[ALU_OP4:ALU_OP0] = {4'b1000, opcode[0]};
				end else if (stage == 5) begin
					ctrl_word[ALU_OE] = 1'b1;
					ctrl_word[ALU_A_RESTORE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = {2'b0, opcode[5:3]};
					ctrl_word[REG_WE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// Arithmetic/Logic Set 0 (M) - ALU operation with memory operand
			// opcode[5:3] - ALU operation code (ADD=000, ADC=001, SUB=010, SBB=011, ANA=100, XRA=101, ORA=110, CMP=111)
			8'o2?6: begin
				if (stage == 3) begin
					// Set memory address to HL
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_HL;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					// Load memory value into ALU temp register
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[ALU_TMP_WE] = 1'b1;
				end else if (stage == 5) begin
					// Execute ALU operation
					ctrl_word[ALU_CS] = 1'b1;
					ctrl_word[ALU_OP4:ALU_OP0] = {2'b0, opcode[5:3]};
					stage_rst = 1'b1;
				end
			end

			// Arithmetic/Logic Set 0 - ALU operation with register operand
			// opcode[2:0] - Source register
			// opcode[5:3] - ALU operation code
			8'o2??: begin
				if (stage == 3) begin
					// Load source register into ALU temp
					if (opcode[2:0] == 3'b111) begin
						ctrl_word[ALU_OE] = 1'b1;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[2:0]};
						ctrl_word[REG_OE] = 1'b1;
					end

					ctrl_word[ALU_TMP_WE] = 1'b1;
				end else if (stage == 4) begin
					// Execute ALU operation
					ctrl_word[ALU_CS] = 1'b1;
					ctrl_word[ALU_OP4:ALU_OP0] = {2'b0, opcode[5:3]};
					stage_rst = 1'b1;
				end
			end

			// Arithmetic/Logic Set 1
			// opcode[5:3] - ALU Op
			8'o0?7: begin
				if (stage == 3) begin
					ctrl_word[ALU_CS] = 1'b1;
					ctrl_word[ALU_OP4:ALU_OP0] = {2'b01, opcode[5:3]};
					stage_rst = 1'b1;
				end
			end

			// Arithmetic/Logic Immediate
			// opcode[5:3] - ALU Op
			8'o3?6: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[ALU_TMP_WE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[ALU_CS] = 1'b1;
					ctrl_word[ALU_OP4:ALU_OP0] = {2'b0, opcode[5:3]};
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
					stage_rst = 1'b1;
				end
			end

			// MVI M, d8
			8'o066: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = {2'b0, REG_WZ_W};
					ctrl_word[REG_WE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_HL;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, REG_WZ_W};
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
					stage_rst = 1'b1;
				end
			end

			// MVI Rd, d8
			// opcode[5:3] - Rd
			8'o0?6: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					if (opcode[5:3] == 3'b111) begin
						ctrl_word[ALU_A_WE] = 1'b1;
					end else begin
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = {2'b0, opcode[5:3]};
						ctrl_word[REG_WE] = 1'b1;
					end

					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
					stage_rst = 1'b1;
				end
			end

			// LXI
			// opcode[5:4] - Extended Register
			8'o001, 8'o021, 8'o041, 8'o061: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
				end else if (stage == 8) begin
					if (opcode[5:4] == 2'b11)
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					else
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = {2'b10, opcode[5:4], 1'b0};

					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[REG_WE] = 1'b1;
				end else if (stage == 9) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
					stage_rst = 1'b1;
				end
			end

			// LDA/STA a16
			// opcode[3]: STA (0) / LDA (1)
			8'o062, 8'o072: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
				end else if (stage == 8) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 9) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 10) begin
					if (opcode[3] == 0) begin
						ctrl_word[ALU_OE] = 1'b1;
						ctrl_word[MEM_WE] = 1'b1;
					end else begin
						ctrl_word[ALU_A_WE] = 1'b1;
						ctrl_word[MEM_OE] = 1'b1;
					end

					stage_rst = 1'b1;
				end
			end

			// STAX/LDAX Rs
			// opcode[5:4] - Rs
			// opcode[3]   - STAX (0) / LDAX (1)
			8'o002, 8'o012, 8'o022, 8'o032: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[5:4], 1'b0};
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
					ctrl_word[REG_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[5:4], 1'b1};
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
					ctrl_word[REG_WE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					if (opcode[3] == 1'b0) begin
						ctrl_word[ALU_OE] = 1'b1;
						ctrl_word[MEM_WE] = 1'b1;
					end else begin
						ctrl_word[ALU_A_WE] = 1'b1;
						ctrl_word[MEM_OE] = 1'b1;
					end

					stage_rst = 1'b1;
				end
			end

			// SHLD, LHLD
			// opcode[3] - SHLD (0) / LHLD (1)
			8'o042, 8'o052: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
				end else if (stage == 8) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 9) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 10) begin
					if (opcode[3] == 1'b0) begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_HL_L;
						ctrl_word[REG_OE] = 1'b1;
						ctrl_word[MEM_WE] = 1'b1;
					end else begin
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_HL_L;
						ctrl_word[REG_WE] = 1'b1;
						ctrl_word[MEM_OE] = 1'b1;
					end
				end else if (stage == 11) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 12) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 13) begin
					if (opcode[3] == 1'b0) begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_HL_H;
						ctrl_word[REG_OE] = 1'b1;
						ctrl_word[MEM_WE] = 1'b1;
					end else begin
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_HL_H;
						ctrl_word[REG_WE] = 1'b1;
						ctrl_word[MEM_OE] = 1'b1;
					end

					stage_rst = 1'b1;
				end
			end

			// DAD
			// opcode[5:4] - Extended Register
			8'o011, 8'o031, 8'o051, 8'o071: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_HL_L;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[ALU_A_STORE] = 1'b1;
					ctrl_word[ALU_A_WE] = 1'b1;
				end else if (stage == 4) begin
					if (opcode[5:4] == 2'b11) begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP_P;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[5:4], 1'b1};
					end

					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[ALU_TMP_WE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[ALU_CS] = 1'b1;
					ctrl_word[ALU_OP4:ALU_OP0] = 5'b00000; // Add
				end else if (stage == 6) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[ALU_OE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_HL_H;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[ALU_A_WE] = 1'b1;
				end else if (stage == 8) begin
					if (opcode[5:4] == 2'b11) begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP_S;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[5:4], 1'b0};
					end

					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[ALU_TMP_WE] = 1'b1;
				end else if (stage == 9) begin
					ctrl_word[ALU_CS] = 1'b1;
					ctrl_word[ALU_OP4:ALU_OP0] = 5'b00001; // Add w/ Carry
				end else if (stage == 10) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[ALU_OE] = 1'b1;
					ctrl_word[ALU_A_RESTORE] = 1'b1;
				end else if (stage == 11) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_HL;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_OE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// JMP
			8'o303: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 8) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_OE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// Jump Conditional
			// opcode[5:4] - flag
			// opcode[3]   - set (1) / unset (0)
			8'o3?2: begin
				if (stage == 3) begin
					if (flags[opcode[5:4]] != opcode[3]) begin
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
						ctrl_word[REG_EXT1:REG_EXT0] = REG_INC2;
						stage_rst = 1'b1;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
						ctrl_word[REG_OE] = 1'b1;
						ctrl_word[MEM_MAR_WE] = 1'b1;
					end
				end else if (stage == 4) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 8) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_OE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// Call Conditional
			// opcode[5:4] - flag
			// opcode[3]   - set (1) / unset (0)
			8'o3?4: begin
				if (stage == 3) begin
					if (flags[opcode[5:4]] != opcode[3]) begin
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
						ctrl_word[REG_EXT1:REG_EXT0] = REG_INC2;
						stage_rst = 1'b1;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
						ctrl_word[REG_OE] = 1'b1;
						ctrl_word[MEM_MAR_WE] = 1'b1;
					end
				end else if (stage == 4) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 8) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 9) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_DEC;
				end else if (stage == 10) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 11) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC_C;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_WE] = 1'b1;
				end else if (stage == 12) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_DEC;
				end else if (stage == 13) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 14) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC_P;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_WE] = 1'b1;
				end else if (stage == 15) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_OE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// CALL
			8'o315: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 8) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 9) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_DEC;
				end else if (stage == 10) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 11) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC_C;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_WE] = 1'b1;
				end else if (stage == 12) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_DEC;
				end else if (stage == 13) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 14) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC_P;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_WE] = 1'b1;
				end else if (stage == 15) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_OE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// Return Conditional
			// opcode[5:4] - flag
			// opcode[3]   - set (1) / unset (0)
			8'o3?0: begin
				if (stage == 3) begin
					if (flags[opcode[5:4]] != opcode[3]) begin
						stage_rst = 1'b1;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
						ctrl_word[REG_OE] = 1'b1;
						ctrl_word[MEM_MAR_WE] = 1'b1;
					end
				end else if (stage == 4) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 8) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 9) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_OE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// RET
			8'o311: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_W;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_WZ_Z;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 8) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 9) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_WZ;
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_WE] = 1'b1;
					ctrl_word[REG_OE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// PUSH Rs
			// opcode[5:4] - Extended Register
			8'o3?5: begin
				if (stage == 3) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_DEC;
				end else if (stage == 4) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 5) begin
					if (opcode[5:4] == 2'b11) begin // PSW
						ctrl_word[ALU_OE] = 1'b1;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[5:4], 1'b0};
						ctrl_word[REG_OE] = 1'b1;
					end

					ctrl_word[MEM_WE] = 1'b1;
				end else if (stage == 6) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_DEC;
				end else if (stage == 7) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 8) begin
					if (opcode[5:4] == 2'b11) begin // PSW
						ctrl_word[ALU_FLAGS_OE] = 1'b1;
					end else begin
						ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = {2'b0, opcode[5:4], 1'b1};
						ctrl_word[REG_OE] = 1'b1;
					end

					ctrl_word[MEM_WE] = 1'b1;
					stage_rst = 1'b1;
				end
			end

			// POP Rs
			// opcode[5:4] - Extended Register
			8'o301, 8'o321, 8'o341, 8'o361: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					if (opcode[5:4] == 2'b11) begin // PSW
						ctrl_word[ALU_FLAGS_WE] = 1'b1;
					end else begin
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = {2'b0, opcode[5:4], 1'b1};
						ctrl_word[REG_WE] = 1'b1;
					end

					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
				end else if (stage == 6) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_SP;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 7) begin
					if (opcode[5:4] == 2'b11) begin // PSW
						ctrl_word[ALU_A_WE] = 1'b1;
					end else begin
						ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = {2'b0, opcode[5:4], 1'b0};
						ctrl_word[REG_WE] = 1'b1;
					end

					ctrl_word[MEM_OE] = 1'b1;
				end else if (stage == 8) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_SP;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
					stage_rst = 1'b1;
				end
			end

			// OUT - Output accumulator to I/O port
			8'o323: begin
				if (stage == 3) begin
					// Write to memory address register the value of program counter
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					// Read the output address from memory
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[OAR_WE] = 1'b1;
				end else if (stage == 5) begin
					// Read ALU output into the output decoder
					ctrl_word[ALU_OE] = 1'b1;
					ctrl_word[OUT_WE] = 1'b1;
				end else if (stage == 6) begin
					// Increment PC counter
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
					stage_rst = 1'b1;
				end
			end

			// IN - Input from I/O port to accumulator
			8'o333: begin
				if (stage == 3) begin
					ctrl_word[REG_RD_SEL4:REG_RD_SEL0] = REG_PC;
					ctrl_word[REG_OE] = 1'b1;
					ctrl_word[MEM_MAR_WE] = 1'b1;
				end else if (stage == 4) begin
					ctrl_word[MEM_OE] = 1'b1;
					ctrl_word[OAR_WE] = 1'b1;
				end else if (stage == 5) begin
					ctrl_word[IN_OE] = 1'b1;
					ctrl_word[ALU_A_WE] = 1'b1;
				end else if (stage == 6) begin
					ctrl_word[REG_WR_SEL4:REG_WR_SEL0] = REG_PC;
					ctrl_word[REG_EXT1:REG_EXT0] = REG_INC;
					stage_rst = 1'b1;
				end
			end
		endcase
	end
end

endmodule
