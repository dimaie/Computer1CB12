/*
 * VGA Display Controller
 *
 * Generates standard 640x480 @ 60Hz VGA timing using a 25.175 MHz pixel clock.
 * Implements a 5-stage dual-read pixel pipeline to seamlessly overlay 
 * 80x30 text mode on top of 320x200 graphics mode.
 */

module display_controller(
    input  wire        clk,
    input  wire        rst,
    
    // Memory interface
    output wire [13:0] vga_gfx_addr,
    input  wire [7:0]  vga_gfx_data,
    
    output wire [11:0] vga_txt_addr,
    input  wire [7:0]  vga_txt_data,
    
    output wire [10:0] vga_font_addr,
    input  wire [7:0]  vga_font_data,
    
    // Control registers
    input  wire [1:0]  layer_enable,
    input  wire [7:0]  ink_color,
    input  wire [7:0]  bg_color,
    
    // Physical VGA Pins
    output reg         vga_hsync,
    output reg         vga_vsync,
    output reg  [5:0]  vga_r,
    output reg  [5:0]  vga_g,
    output reg  [5:0]  vga_b
);

    // 640x480 @ 60Hz timing constants
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    // Screen Coordinate Counters
    reg [9:0] x_cnt;
    reg [9:0] y_cnt;

    always @(posedge clk) begin
        if (rst) begin
            x_cnt <= 0;
            y_cnt <= 0;
        end else begin
            if (x_cnt == H_TOTAL - 1) begin
                x_cnt <= 0;
                if (y_cnt == V_TOTAL - 1)
                    y_cnt <= 0;
                else
                    y_cnt <= y_cnt + 1'b1;
            end else begin
                x_cnt <= x_cnt + 1'b1;
            end
        end
    end

    // Pipeline Look-Ahead Logic
    wire [9:0] h_next_t = (x_cnt + 10'd2 >= H_TOTAL) ? (x_cnt + 10'd2 - H_TOTAL) : (x_cnt + 10'd2);
    wire [9:0] h_next_g = (x_cnt + 10'd1 >= H_TOTAL) ? (x_cnt + 10'd1 - H_TOTAL) : (x_cnt + 10'd1);
    
    wire [9:0] y_next    = (y_cnt + 10'd1 >= V_TOTAL) ? 10'd0 : (y_cnt + 10'd1);
    wire [9:0] y_fetch_t = (x_cnt >= H_TOTAL - 10'd2) ? y_next : y_cnt;
    wire [9:0] y_fetch_g = (x_cnt >= H_TOTAL - 10'd1) ? y_next : y_cnt;
    wire [9:0] y_fetch_f = (x_cnt >= H_TOTAL - 10'd1) ? y_next : y_cnt;

    // Stage 0 -> Address Calculation
    wire [11:0] txt_row = {7'b0, y_fetch_t[8:4]};
    assign vga_txt_addr = (txt_row << 6) + (txt_row << 4) + {5'b0, h_next_t[9:3]}; // Row * 80 + Col
    
    // 320x240 scaling: exactly 2x2 VGA pixels.
    wire [13:0] gfx_row = {6'b0, y_fetch_g[8:1]};
    assign vga_gfx_addr = (gfx_row << 5) + (gfx_row << 3) + h_next_g[9:4]; // Scaled_Row * 40 + Scaled_Col

    // Stage 2 -> Combinational Font Address Calculation
    // Use [3:1] to stretch the 8x8 font vertically by repeating each scanline twice
    // Use [7:0] to map the full 256-character space of the font ROM
    assign vga_font_addr = {vga_txt_data[7:0], y_fetch_f[3:1]};

    // Stage 4/5 -> Final Extraction and Video Mixer
    wire text_pixel    = vga_font_data[ 3'd7 - x_cnt[2:0] ]; // MSB is drawn left-most
    wire gfx_pixel     = vga_gfx_data[ 3'd7 - x_cnt[3:1] ];  // MSB is drawn left-most
    wire in_gfx_bounds = 1'b1; // Now covers full screen

    // Layer [1] = Graphics, Layer [0] = Text
    wire draw_ink = (layer_enable[0] && text_pixel) || (layer_enable[1] && in_gfx_bounds && gfx_pixel);
    wire [7:0] active_color = draw_ink ? ink_color : bg_color;

    always @(posedge clk) begin
        // Output syncs directly derived from current beam position
        vga_hsync <= ~(x_cnt >= (H_VISIBLE + H_FRONT) && x_cnt < (H_VISIBLE + H_FRONT + H_SYNC));
        vga_vsync <= ~(y_cnt >= (V_VISIBLE + V_FRONT) && y_cnt < (V_VISIBLE + V_FRONT + V_SYNC));
        
        if (x_cnt < H_VISIBLE && y_cnt < V_VISIBLE) begin
            // Expand standard 8-bit RRRGGGBB color into 18-bit hardware DAC format
            vga_r <= {active_color[7:5], active_color[7:5]};
            vga_g <= {active_color[4:2], active_color[4:2]};
            vga_b <= {active_color[1:0], active_color[1:0], active_color[1:0]};
        end else begin
            vga_r <= 6'b0; 
            vga_g <= 6'b0; 
            vga_b <= 6'b0;
        end
    end

endmodule