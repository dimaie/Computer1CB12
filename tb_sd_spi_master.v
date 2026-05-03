`timescale 1ns / 1ps

module tb_sd_spi_master;

    // Inputs
    reg clk;
    reg rst;
    reg [7:0] tx_data;
    reg tx_start;
    reg fast_mode;
    reg spi_miso;

    // Outputs
    wire [7:0] rx_data;
    wire ready;
    wire spi_clk;
    wire spi_mosi;

    // Instantiate the Unit Under Test (UUT)
    sd_spi_master uut (
        .clk(clk), 
        .rst(rst), 
        .tx_data(tx_data), 
        .tx_start(tx_start), 
        .fast_mode(fast_mode), 
        .rx_data(rx_data), 
        .ready(ready), 
        .spi_clk(spi_clk), 
        .spi_mosi(spi_mosi), 
        .spi_miso(spi_miso)
    );

    // Clock generation (21.477 MHz = ~46.5ns period)
    always #23.28 clk = ~clk;

    // Task to perform and verify a single SPI byte transfer
    task spi_transfer_and_check(input [7:0] data_to_send, input [7:0] expected_response);
        reg [7:0] slave_shift_reg;
        begin
            $display("INFO: Starting transfer of 0x%02h, expecting 0x%02h back.", data_to_send, expected_response);

            slave_shift_reg = expected_response;

            // Concurrently, simulate the slave device's response on the MISO line.
            // The slave changes its output on the falling edge of the clock.
            fork
                begin
                    // SPI Mode 0: First bit must be ready before the first rising edge
                    spi_miso <= slave_shift_reg[7];
                    slave_shift_reg = slave_shift_reg << 1;
                    
                    // Shift the remaining 7 bits on the first 7 falling edges
                    repeat(7) begin
                        @(negedge spi_clk);
                        spi_miso <= slave_shift_reg[7];
                        slave_shift_reg = slave_shift_reg << 1;
                    end
                    // On the 8th and final falling edge, release the line
                    @(negedge spi_clk);
                    spi_miso <= 1'b1;
                end

                // Drive the master to start the transfer
                begin
                    @(posedge clk);
                    tx_data = data_to_send;
                    tx_start = 1;
                    @(posedge clk);
                    tx_start = 0;
                    // Block until the hardware SPI master signals it is finished
                    wait (ready === 1'b1);
                end
            join

            // Allow one tick for signals to settle before checking the result
            #1;

            // Assert the received data matches the expected response
            if (rx_data !== expected_response) begin
                $display("TEST FAILED: Expected 0x%02h, but received 0x%02h.", expected_response, rx_data);
                $stop;
            end

            $display("TEST PASSED: Received 0x%02h as expected.", rx_data);
        end
    endtask

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        fast_mode = 0; // Slow mode for initialization
        spi_miso = 1;  // Simulate internal pull-up resistor
        tx_data = 0;
        tx_start = 0;

        #100 rst = 0;
        wait (ready === 1'b1); // Wait for module to be ready after reset
        
        // Run test cases
        spi_transfer_and_check(8'h40, 8'hAA); // Send 0x40, expect 0xAA back
        #1000;
        spi_transfer_and_check(8'h55, 8'h3C); // Send 0x55, expect 0x3C back

        #1000;
        $display("All SPI Master assertions passed. Simulation completed successfully.");
        $stop;
    end
    
endmodule