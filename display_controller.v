/*
 * VGA Display Controller
 *
 * Generates standard 640x480 @ 60Hz VGA timing using a 25.175 MHz pixel clock.
 * Implements a 5-stage dual-read pixel pipeline to seamlessly overlay 
 * 64x30 text mode on top of 256x240 graphics mode.
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
    input  wire [7:0]  gfx_ink_color,
    input  wire [7:0]  bg_color,
    input  wire [6:0]  cursor_x,
    input  wire [4:0]  cursor_y,
    input  wire [1:0]  cursor_style,
    
    // Physical VGA Pins
    output reg         vga_hsync,
    output reg         vga_vsync,
    output wire        vblank,
    output reg  [5:0]  vga_r,
    output reg  [5:0]  vga_g,
    output reg  [5:0]  vga_b
);

    // 720x480 @ 59.8Hz "Magic" Timing Profile (using 21.477 MHz pixel clock)
    // Matches the exact MSX VDP timing signature for perfect LCD scaling
    localparam H_VISIBLE = 576;
    localparam H_FRONT   = 36;
    localparam H_SYNC    = 40;
    localparam H_BACK    = 32;
    localparam H_TOTAL   = 684;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 9;
    localparam V_SYNC    = 6;
    localparam V_BACK    = 30;
    localparam V_TOTAL   = 525;

    // Screen Coordinate Counters
    reg [9:0] x_cnt;
    reg [9:0] y_cnt;
    reg [5:0] blink_cnt; // 64-frame counter for ~1Hz blink cycle

    always @(posedge clk) begin
        if (rst) begin
            x_cnt <= 0;
            y_cnt <= 0;
            blink_cnt <= 0;
        end else begin
            if (x_cnt == H_TOTAL - 1) begin
                x_cnt <= 0;
                if (y_cnt == V_TOTAL - 1) begin
                    y_cnt <= 0;
                    blink_cnt <= blink_cnt + 1'b1; // Increment once per frame
                end else begin
                    y_cnt <= y_cnt + 1'b1;
                end
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
    // Active area is 512 pixels wide, centered in 576. (32 pixels padding on each side)
    wire active_h_t = (h_next_t >= 32 && h_next_t < 544);
    wire active_h_g = (h_next_g >= 32 && h_next_g < 544);
    
    wire [9:0] safe_h_t  = active_h_t ? (h_next_t - 32) : 10'd0;
    wire [9:0] safe_y_t  = (y_fetch_t < V_VISIBLE) ? y_fetch_t : 10'd0;
    wire [11:0] txt_row  = {7'b0, safe_y_t[8:4]};
    assign vga_txt_addr  = (txt_row << 6) + {6'b0, safe_h_t[8:3]}; // Row * 64 + Col (Pure Power of 2!)
    
    // 256x240 scaling: exactly 2x2 VGA pixels.
    wire [9:0] safe_h_g  = active_h_g ? (h_next_g - 32) : 10'd0;
    wire [9:0] safe_y_g  = (y_fetch_g < V_VISIBLE) ? y_fetch_g : 10'd0;
    wire [13:0] gfx_row  = {6'b0, safe_y_g[8:1]};
    assign vga_gfx_addr  = (gfx_row << 5) + {9'b0, safe_h_g[8:4]}; // Scaled_Row * 32 + Scaled_Col

    // Stage 2 -> Combinational Font Address Calculation
    // Stretch the 8x8 font vertically by repeating each scanline twice
    assign vga_font_addr = {vga_txt_data[7:0], y_fetch_f[3:1]};

    // Stage 4/5 -> Final Extraction and Video Mixer
    wire [9:0] local_x = (x_cnt >= 32 && x_cnt < 544) ? (x_cnt - 32) : 10'd0;
    wire in_gfx_bounds = (x_cnt >= 32 && x_cnt < 544) && (y_cnt < V_VISIBLE);
    
    wire raw_text_pixel = vga_font_data[ 3'd7 - local_x[2:0] ]; // MSB is drawn left-most
    wire gfx_pixel     = vga_gfx_data[ 3'd7 - local_x[3:1] ];  // MSB is drawn left-most
    
    // Hardware Cursor Logic: XOR the text pixel if we are over the cursor cell (and blink timer is high, if applicable)
    wire in_cursor_cell = in_gfx_bounds && (local_x[9:3] == cursor_x) && (y_cnt[8:4] == cursor_y);
    wire cursor_shape_active = (cursor_style == 2'd3) || (cursor_style == 2'd2) || 
                               (cursor_style == 2'd1 && y_cnt[3] == 1'b1);
    wire show_cursor    = in_cursor_cell && cursor_shape_active && (blink_cnt[5] || cursor_style == 2'd3) && (cursor_style != 2'd0);
    wire text_pixel     = raw_text_pixel ^ show_cursor;

    // Layer [1] = Graphics, Layer [0] = Text
    wire draw_txt = (layer_enable[0] && text_pixel && in_gfx_bounds);
    wire draw_gfx = (layer_enable[1] && in_gfx_bounds && gfx_pixel);
    wire [7:0] active_color = draw_txt ? ink_color : (draw_gfx ? gfx_ink_color : bg_color);

    // VBLANK is high whenever the Y counter is outside the visible screen area
    assign vblank = (y_cnt >= V_VISIBLE);

    wire [5:0] target_r = {active_color[7:5], active_color[7:5]};
    wire [5:0] target_g = {active_color[4:2], active_color[4:2]};
    wire [5:0] target_b = {active_color[1:0], active_color[1:0], active_color[1:0]};

    always @(posedge clk) begin
        // Output syncs directly derived from current beam position
        vga_hsync <= ~(x_cnt >= (H_VISIBLE + H_FRONT) && x_cnt < (H_VISIBLE + H_FRONT + H_SYNC));
        vga_vsync <= ~(y_cnt >= (V_VISIBLE + V_FRONT) && y_cnt < (V_VISIBLE + V_FRONT + V_SYNC));
        
        if (x_cnt < H_VISIBLE && y_cnt < V_VISIBLE) begin
            // Direct color output without artificial blurring
            vga_r <= target_r;
            vga_g <= target_g;
            vga_b <= target_b;
        end else begin
            vga_r <= 6'b0; 
            vga_g <= 6'b0; 
            vga_b <= 6'b0;
        end
    end

endmodule