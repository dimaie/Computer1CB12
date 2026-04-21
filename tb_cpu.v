`timescale 1ns / 1ps

module tb_cpu;
    // Inputs
    reg clk_21;
    reg rst_n;
    
    // Outputs
    wire uart_txd;
    wire vga_hsync;
    wire vga_vsync;
    wire [5:0] vga_r, vga_g, vga_b;
    wire [7:0] ledr;
    
    // Instantiate the Unit Under Test (UUT)
    Computer1CB121_Top uut (
        .CLOCK_21(clk_21),
        .RESET_N(rst_n),
        .PS2_CLK(1'b1),
        .PS2_DAT(1'b1),
        .UART_RXD(1'b1),
        .UART_TXD(uart_txd),
        .VGA_HSYNC(vga_hsync),
        .VGA_VSYNC(vga_vsync),
        .VGA_R(vga_r),
        .VGA_G(vga_g),
        .VGA_B(vga_b),
        .LEDR(ledr)
    );

    // 21.4772 MHz Clock Generation
    initial begin
        clk_21 = 0;
        forever #23.28 clk_21 = ~clk_21;
    end

    // =========================================================================
    // FLEXIBLE VERIFICATION FRAMEWORK
    // =========================================================================
    
    integer i;
    
    // Task: Reset CPU and clear memory
    task setup_test(input [80*8:1] test_name);
    begin
        $display("\n--------------------------------------------------");
        $display(" RUNNING TEST: %0s", test_name);
        $display("--------------------------------------------------");
        
        // Wipe ROM with HLT (0x76) so runaway code instantly stops
        for (i = 0; i < 2560; i = i + 1) uut.memory.rom_inst.rom[i] = 8'h76;
        
        // Wipe 8KB User RAM (0x2000 to 0x3FFF)
        for (i = 0; i < 8192; i = i + 1) uut.memory.ram_inst.ram[i] = 8'h00;
        
        rst_n = 0; // Hold Reset
        #100;
    end
    endtask

    // Task: Inject an opcode into Program ROM
    task write_op(input [15:0] addr, input [7:0] op);
    begin
        uut.memory.rom_inst.rom[addr[11:0]] = op;
    end
    endtask

    // Task: Run CPU until Halt or Timeout
    task execute_and_wait;
    begin
        rst_n = 1; // Release reset to start CPU execution
        
        begin : wait_block
            fork
                begin
                    wait(uut.hlt === 1'b1);
                    #50; // Let final hardware stages settle
                    disable wait_block;
                end
                begin
                    #100000;
                    $display("  [ERROR] Timeout! CPU infinite loop or missing HLT.");
                    disable wait_block;
                end
            join
        end
    end
    endtask

    // Task: Verify Value
    task assert_val(input [80*8:1] name, input [15:0] actual, input [15:0] expected);
    begin
        if (actual === expected) begin
            $display("  [PASS] %0s == %04X", name, expected);
        end else begin
            $display("  [FAIL] %0s: Expected %04X, Got %04X", name, expected, actual);
        end
    end
    endtask

    // =========================================================================
    // TEST DEFINITIONS
    // =========================================================================
    
    initial begin
        #100; // Wait for system PLL to stabilize
        
        $display("==================================================");
        $display(" SAP-3 ISA VERIFICATION SUITE STARTING");
        $display("==================================================");
        
        // ---------------------------------------------------------
        // TEST 1: Evaluate Register write-back for RLC
        // ---------------------------------------------------------
        setup_test("RLC (Rotate Left Circular)");
        write_op(16'h0000, 8'h3E); // MVI A, 01h
        write_op(16'h0001, 8'h01); 
        write_op(16'h0002, 8'h07); // RLC
        write_op(16'h0003, 8'h76); // HLT
        execute_and_wait();
        
        // Assert Conditions: Register A should have rotated 0x01 to 0x02
        assert_val("Register A", uut.alu.acc, 8'h02);
        
        // ---------------------------------------------------------
        // TEST 2: Evaluate ALU Math and Flags (ADD Immediate)
        // ---------------------------------------------------------
        setup_test("ADI (Add Immediate) & Flags");
        write_op(16'h0000, 8'h3E); // MVI A, 10 (0x0A)
        write_op(16'h0001, 8'h0A); 
        write_op(16'h0002, 8'hC6); // ADI 20 (0x14)
        write_op(16'h0003, 8'h14); 
        write_op(16'h0004, 8'h76); // HLT
        execute_and_wait();
        
        // Assert Conditions: A should be 30 (0x1E), Carry Flag (Bit 1) = 0
        assert_val("Register A", uut.alu.acc, 8'h1E);
        assert_val("ALU Carry Flag", uut.alu_flags[1], 1'b0);

        // ---------------------------------------------------------
        // TEST 3: Evaluate Memory Writes (STA)
        // ---------------------------------------------------------
        setup_test("STA (Store Accumulator to RAM)");
        write_op(16'h0000, 8'h3E); // MVI A, 55h
        write_op(16'h0001, 8'h55); 
        write_op(16'h0002, 8'h32); // STA 2005h
        write_op(16'h0003, 8'h05); // LSB
        write_op(16'h0004, 8'h20); // MSB
        write_op(16'h0005, 8'h76); // HLT
        execute_and_wait();
        
        // Assert Conditions: Memory array at offset 5 (0x2005) should equal 0x55
        assert_val("RAM[0x2005]", uut.memory.ram_inst.ram[5], 8'h55);
        
        // ---------------------------------------------------------
        // TEST 4: Evaluate SBB A (ALU op with Accumulator as source)
        // ---------------------------------------------------------
        setup_test("SBB A (Sign Extension Trick)");
        write_op(16'h0000, 8'h3E); // MVI A, 0x05
        write_op(16'h0001, 8'h05); 
        write_op(16'h0002, 8'h37); // STC (Set Carry = 1)
        write_op(16'h0003, 8'h9F); // SBB A
        write_op(16'h0004, 8'h76); // HLT
        execute_and_wait();
        
        // Assert Conditions: 5 - 5 - 1 = -1 (0xFF)
        assert_val("Register A after SBB A", uut.alu.acc, 8'hFF);

        // ---------------------------------------------------------
        // TEST 5: Evaluate ORA M
        // ---------------------------------------------------------
        setup_test("ORA M (Read-Modify-Write Accumulator)");
        write_op(16'h0000, 8'h21); // LXI H, 0x200A
        write_op(16'h0001, 8'h0A); 
        write_op(16'h0002, 8'h20); 
        write_op(16'h0003, 8'h36); // MVI M, 0x0F
        write_op(16'h0004, 8'h0F); 
        write_op(16'h0005, 8'h3E); // MVI A, 0xF0
        write_op(16'h0006, 8'hF0); 
        write_op(16'h0007, 8'hB6); // ORA M
        write_op(16'h0008, 8'h76); // HLT
        execute_and_wait();
        
        // Assert Conditions: 0xF0 | 0x0F = 0xFF
        assert_val("Register A after ORA M", uut.alu.acc, 8'hFF);

        // ---------------------------------------------------------
        // TEST 6: Evaluate ACI (Add with Carry Immediate)
        // ---------------------------------------------------------
        setup_test("ACI (Add with Carry Immediate)");
        write_op(16'h0000, 8'h3E); // MVI A, 0x12
        write_op(16'h0001, 8'h12); 
        write_op(16'h0002, 8'h37); // STC (Set Carry = 1)
        write_op(16'h0003, 8'hCE); // ACI 0x40
        write_op(16'h0004, 8'h40); 
        write_op(16'h0005, 8'h76); // HLT
        execute_and_wait();
        
        // Assert Conditions: 0x12 + 0x40 + 1 = 0x53
        assert_val("Register A after ACI", uut.alu.acc, 8'h53);

        // ---------------------------------------------------------
        // TEST 7: Evaluate ADD L
        // ---------------------------------------------------------
        setup_test("ADD L");
        write_op(16'h0000, 8'h3E); // MVI A, 0x0C
        write_op(16'h0001, 8'h0C); 
        write_op(16'h0002, 8'h2E); // MVI L, 0xC0
        write_op(16'h0003, 8'hC0); 
        write_op(16'h0004, 8'h85); // ADD L
        write_op(16'h0005, 8'h76); // HLT
        execute_and_wait();
        
        // Assert Conditions: 0x0C + 0xC0 = 0xCC
        assert_val("Register A after ADD L", uut.alu.acc, 8'hCC);

        // ---------------------------------------------------------
        // TEST 8: Evaluate ANI
        // ---------------------------------------------------------
        setup_test("ANI (AND Immediate)");
        write_op(16'h0000, 8'h3E); // MVI A, 0x8C
        write_op(16'h0001, 8'h8C); 
        write_op(16'h0002, 8'hE6); // ANI 0x1F
        write_op(16'h0003, 8'h1F); 
        write_op(16'h0004, 8'h76); // HLT
        execute_and_wait();
        
        // Assert Conditions: 0x8C & 0x1F = 0x0C
        assert_val("Register A after ANI", uut.alu.acc, 8'h0C);

        // ---------------------------------------------------------
        // TEST 9: DRAW_PIXEL Address Math Sequence
        // ---------------------------------------------------------
        setup_test("DRAW_PIXEL Address Math Sequence");
        write_op(16'h0000, 8'h26); // MVI H, 0x12
        write_op(16'h0001, 8'h12); 
        write_op(16'h0002, 8'h2E); // MVI L, 0xC0
        write_op(16'h0003, 8'hC0); 
        write_op(16'h0004, 8'h3E); // MVI A, 0x0C
        write_op(16'h0005, 8'h0C); 
        
        write_op(16'h0006, 8'h85); // ADD L     (A = A + L)
        write_op(16'h0007, 8'h6F); // MOV L, A  (L = A)
        write_op(16'h0008, 8'h7C); // MOV A, H  (A = H)
        write_op(16'h0009, 8'hCE); // ACI 0x40  (A = A + 0x40 + C)
        write_op(16'h000A, 8'h40); // <--- MISSING IMMEDIATE DATA BYTE
        write_op(16'h000B, 8'h67); // MOV H, A  (H = A)
        
        write_op(16'h000C, 8'h22); // SHLD 0x2000 (Stores L at 2000, H at 2001)
        write_op(16'h000D, 8'h00); 
        write_op(16'h000E, 8'h20); 
        write_op(16'h000F, 8'h76); // HLT
        execute_and_wait();
        
        // Assert Conditions: HL should be 0x52CC
        assert_val("RAM[0x2000] (Expected L = CC)", uut.memory.ram_inst.ram[0], 8'hCC);
        assert_val("RAM[0x2001] (Expected H = 52)", uut.memory.ram_inst.ram[1], 8'h52);

        $display("\n==================================================");
        $display(" ALL TESTS COMPLETED.");
        $display("==================================================");
        $stop;
    end
endmodule