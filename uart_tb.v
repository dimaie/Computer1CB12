`timescale 1ns / 1ps
`include "uart.v"

module uart_tb;

    // Simulation parameters
    localparam CLOCKS_PER_BIT = 10; // Reduced for faster simulation
    localparam CLK_PERIOD     = 20; // 50 MHz clock

    // Testbench signals
    reg        clk;
    reg        rst;
    reg        rx_drv;
    wire       tx;
    reg  [7:0] tx_data;
    reg        tx_we;
    wire       tx_busy;
    wire [7:0] rx_data;
    wire       rx_done;

    // Loopback control
    reg  loopback_en;
    wire rx;

    // Drive RX either from testbench task or loopback from TX
    assign rx = loopback_en ? tx : rx_drv;

    // Instantiate the UART module
    uart #(
        .CLOCKS_PER_BIT(CLOCKS_PER_BIT)
    ) uut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx(tx),
        .tx_data(tx_data),
        .tx_we(tx_we),
        .tx_busy(tx_busy),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize signals
        rst         = 1'b1;
        rx_drv      = 1'b1; // Idle state is high
        tx_data     = 8'h00;
        tx_we       = 1'b0;
        loopback_en = 1'b0;

        // Apply reset
        #(CLK_PERIOD * 5);
        rst = 1'b0;
        #(CLK_PERIOD * 5);

        // -----------------------------------------------------------------
        // Test 1: External RX Stimulus
        // -----------------------------------------------------------------
        $display("--- Test 1: External RX Stimulus (Sending 8'hA5) ---");
        
        // Run the stimulus and listen for the pulse concurrently
        fork
            send_rx_byte(8'hA5);
            @(posedge rx_done); // Wait for done pulse
        join
        
        if (rx_data === 8'hA5) begin
            $display("PASS: RX received 8'hA5 correctly.");
        end else begin
            $display("FAIL: RX received 8'h%02h, expected 8'hA5.", rx_data);
        end

        #(CLK_PERIOD * CLOCKS_PER_BIT * 2);

        // -----------------------------------------------------------------
        // Test 2: TX to RX Loopback
        // -----------------------------------------------------------------
        $display("--- Test 2: TX to RX Loopback (Sending 8'h3C) ---");
        loopback_en = 1'b1; // Route TX directly back to RX
        
        // Start transmission
        @(posedge clk);
        tx_data = 8'h3C;
        tx_we   = 1'b1;
        @(posedge clk);
        tx_we   = 1'b0;

        // Wait for RX to finish receiving the looped-back data
        @(posedge rx_done);
        if (rx_data === 8'h3C) begin
            $display("PASS: Loopback received 8'h3C correctly.");
        end else begin
            $display("FAIL: Loopback received 8'h%02h, expected 8'h3C.", rx_data);
        end
        
        // Wait for TX to completely finish (stop bit)
        wait(tx_busy == 1'b0);
        #(CLK_PERIOD * CLOCKS_PER_BIT * 2);

        $display("--- Simulation Complete ---");
        $finish;
    end

    // Task to simulate receiving a byte over the RX line
    task send_rx_byte(input [7:0] data);
        integer i;
        begin
            // Start bit
            rx_drv = 1'b0;
            #(CLK_PERIOD * CLOCKS_PER_BIT);
            
            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx_drv = data[i];
                #(CLK_PERIOD * CLOCKS_PER_BIT);
            end
            
            // Stop bit
            rx_drv = 1'b1;
            #(CLK_PERIOD * CLOCKS_PER_BIT);
        end
    endtask

endmodule