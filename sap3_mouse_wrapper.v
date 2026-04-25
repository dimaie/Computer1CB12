module sap3_mouse_wrapper (
    input  wire        clk,         // SAP-3 system clock (21.477MHz)
    input  wire        usbclk,      // 12MHz clock for USB Host
    input  wire        rst,         // Active-high reset
    
    // USB physical pins (Route to FPGA pins 239 and 238)
    inout  wire        usb_dp,
    inout  wire        usb_dm,
    
    // Synchronized outputs for I/O Port Mux
    output wire [15:0] mouse_x,
    output wire [15:0] mouse_y,
    output wire [7:0]  mouse_btn
);

    wire [1:0] typ;
    wire report;
    wire [7:0] host_mouse_btn;
    wire signed [7:0] mouse_dx;
    wire signed [7:0] mouse_dy;
    
    // Instantiate the USB HID Host core
    usb_hid_host host (
        .usbclk(usbclk),
        .rst(rst),
        .usb_dp(usb_dp),
        .usb_dm(usb_dm),
        .typ(typ),
        .report(report),
        .conerr(),
        .mouse_btn(host_mouse_btn),
        .mouse_dx(mouse_dx),
        .mouse_dy(mouse_dy)
    );

    // Accumulate deltas in the USB clock domain to prevent missed updates
    reg [15:0] abs_x_usb;
    reg [15:0] abs_y_usb;
    reg [7:0]  buttons_usb;
    
    always @(posedge usbclk) begin
        if (rst) begin
            abs_x_usb   <= 16'd160;  // Center of 320x240 screen
            abs_y_usb   <= 16'd120;
            buttons_usb <= 8'd0;
        end else if (report && typ == 2) begin
            buttons_usb <= host_mouse_btn;
            
            // Accumulate X (bounded 0 to 319)
            if ($signed(abs_x_usb) + $signed(mouse_dx) < 0)
                abs_x_usb <= 16'd0;
            else if ($signed(abs_x_usb) + $signed(mouse_dx) > 319)
                abs_x_usb <= 16'd319;
            else
                abs_x_usb <= $signed(abs_x_usb) + $signed(mouse_dx);
                
            // Accumulate Y (bounded 0 to 239)
            if ($signed(abs_y_usb) + $signed(mouse_dy) < 0)
                abs_y_usb <= 16'd0;
            else if ($signed(abs_y_usb) + $signed(mouse_dy) > 239)
                abs_y_usb <= 16'd239;
            else
                abs_y_usb <= $signed(abs_y_usb) + $signed(mouse_dy);
        end
    end

    // Cross to SAP-3 clock domain safely using 2-stage synchronizers
    reg [15:0] abs_x_sync1, abs_x_sync2;
    reg [15:0] abs_y_sync1, abs_y_sync2;
    reg [7:0]  buttons_sync1, buttons_sync2;

    always @(posedge clk) begin
        abs_x_sync1 <= abs_x_usb;
        abs_x_sync2 <= abs_x_sync1;
        abs_y_sync1 <= abs_y_usb;
        abs_y_sync2 <= abs_y_sync1;
        buttons_sync1 <= buttons_usb;
        buttons_sync2 <= buttons_sync1;
    end

    // Expose the synchronized registers directly
    assign mouse_x = abs_x_sync2;
    assign mouse_y = abs_y_sync2;
    assign mouse_btn = buttons_sync2;

endmodule