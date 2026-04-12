/*
 * Step Button Controller
 *
 * This module controls manual stepping mode for the SAP-3 processor.
 * It detects button presses (rising edges on step_mode) and generates
 * single-clock pulses for stepping through instructions manually.
 * It also manages the manual halt state for step mode operation.
 *
 * Inputs:
 * - clk: System clock
 * - rst: Reset signal
 * - step_mode: Step mode enable/button input
 *
 * Outputs:
 * - hlt_m: Manual halt flag (active during step mode)
 * - step_clk_pulse: Single clock pulse generated on step button press
 */

module step_button(
	input clk,
	input rst,
	input step_mode,
	output hlt_m,
	output step_clk_pulse
);

// Register to store previous step_mode value for edge detection
reg step_mode_last;
always @(posedge clk) begin
   step_mode_last <= step_mode;
end

// Detect rising edge: step_mode is high and was low last cycle
wire step_mode_edge = step_mode & ~step_mode_last;

// Manual halt register: set on step button press
reg hlt_r;
always @(posedge clk, posedge rst) begin
   if (rst) begin
      hlt_r <= 0;  // Clear halt on reset
   end else if (step_mode_edge) begin  // Set halt when step button pressed
		hlt_r <= 1;
   end
end

// Step clock pulse generator: single cycle pulse on step button press
reg step_clk_pulse_r;
always @(posedge clk or posedge rst) begin
   if (rst) begin
      step_clk_pulse_r <= 0;  // Clear pulse on reset
   end else if (step_mode_edge) begin  // Start pulse when step button pressed
      step_clk_pulse_r <= 1'b1;
   end else if (step_clk_pulse_r) begin  // End pulse after one clock cycle
      step_clk_pulse_r <= 1'b0;
   end
end

// Output assignments
assign step_clk_pulse = step_clk_pulse_r;
assign hlt_m = hlt_r;

endmodule