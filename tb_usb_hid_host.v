`timescale 1ns / 1ps

module tb_usb_hid_host;

    reg clk;
    reg rst;
    
    wire usb_dp;
    wire usb_dm;
    
    wire [1:0] typ;
    wire report;
    wire conerr;
    wire [7:0] mouse_btn;
    wire signed [7:0] mouse_dx;
    wire signed [7:0] mouse_dy;
    wire [63:0] dbg_hid_report;

    // ----------------------------------------------------
    // Mock USB Physical Layer
    // ----------------------------------------------------
    // Low-speed USB devices (like mice) pull D- HIGH to indicate connection.
    // The device pull-up must overpower the host's weak pull-down.
    pullup             (usb_dm); // Simulates mouse plugged in (1.5k resistor)
    pulldown (weak0)   (usb_dp); // Host 15k pull-down
    pulldown (weak0)   (usb_dm); // Host 15k pull-down

    // Instantiate the Unit Under Test (UUT)
    usb_hid_host uut (
        .usbclk(clk),
        .rst(rst),
        .usb_dp(usb_dp),
        .usb_dm(usb_dm),
        .typ(typ),
        .report(report),
        .conerr(conerr),
        .mouse_btn(mouse_btn),
        .mouse_dx(mouse_dx),
        .mouse_dy(mouse_dy),
        .key_modifiers(),
        .key1(),
        .key2(),
        .key3(),
        .key4(),
        .game_l(),
        .game_r(),
        .game_u(),
        .game_d(),
        .game_a(),
        .game_b(),
        .game_x(),
        .game_y(),
        .game_sel(),
        .game_sta(),
        .dbg_hid_report(dbg_hid_report)
    );

    // 12MHz Clock Generation
    initial begin
        clk = 0;
        forever #41.667 clk = ~clk; 
    end

    // Simulation Speed-Up, ROM Check, & Timeout Watchdog
    initial begin
        #300;
        if (uut.ukp.ukprom.mem[0] === 4'bx) begin
            $display("\n[FATAL ERROR] ROM is uninitialized! ModelSim cannot find 'usb_hid_host_rom.hex'.");
            $display("Please ensure the hex file is copied into your ModelSim simulation directory.\n");
            $finish;
        end
        
        // The host normally waits 201ms to debounce the physical USB connection.
        // We intercept the loop counter (wk = 200) and force it to 2 to skip the wait!
        wait (uut.ukp.wk == 8'hC8);
        force uut.ukp.wk = 8'h02;
        #100 release uut.ukp.wk;
        
        // Absolute timeout to prevent infinite hangs (Increased to 100ms)
        // The USB specification requires the host to hold the Reset (SE0) for 10ms - 50ms!
        #100000000; // 100ms absolute timeout
        $display("\n[FAIL] Simulation timed out!\n");
        $finish;
    end

    // Test Sequence
    initial begin
        $dumpfile("usb_hid_host_tb.vcd");
        $dumpvars(0, tb_usb_hid_host);
        
        rst = 1;
        #200;
        rst = 0;
        
        $display("Waiting for host to initiate USB Reset (~2ms simulated via speed-up)...");
        // Wait for host to drive USB Reset (SE0: both D+ and D- forced LOW)
        // The host must overpower our weak pull-up on D-
        wait (usb_dp == 1'b0 && usb_dm == 1'b0);
        $display("[PASS] Host detected device and initiated USB Reset (SE0).");
        
        $display("Waiting for host to transmit first packet...");
        // Wait for the host to exit reset and start toggling the bus (SYNC field)
        wait (uut.ukp.usb_oe == 1'b1 && (usb_dp == 1'b1 || usb_dm == 1'b1));
        $display("[PASS] Host exited reset and started transmitting SETUP packet.");
        
        // We have successfully verified the host TX path and micro-sequencer!
        // We don't simulate the full enumeration as it requires a complex USB device model.
        #5000;
        $display("Simulation complete.");
        $finish;
    end

endmodule