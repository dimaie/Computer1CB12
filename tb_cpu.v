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
        for (i = 0; i < 2048; i = i + 1) uut.memory.rom_inst.rom[i] = 8'h76;
        
        // Wipe 8KB User RAM (0x2000 to 0x3FFF)
        for (i = 0; i < 8192; i = i + 1) uut.memory.ram_inst.ram[i] = 8'h00;
        
        rst_n = 0; // Hold Reset
        #100;
    end
    endtask

    // Task: Inject an opcode into Program ROM
    task write_op(input [15:0] addr, input [7:0] op);
    begin
        uut.memory.rom_inst.rom[addr[10:0]] = op;
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
        
        $display("\n==================================================");
        $display(" ALL TESTS COMPLETED.");
        $display("==================================================");
        $stop;
    end
endmodule