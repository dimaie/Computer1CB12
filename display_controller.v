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
    output wire [12:0] vga_gfx_addr,
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

    // Raw Timing Signals (Active-Low Syncs)
    wire hsync_raw = ~(x_cnt >= (H_VISIBLE + H_FRONT) && x_cnt < (H_VISIBLE + H_FRONT + H_SYNC));
    wire vsync_raw = ~(y_cnt >= (V_VISIBLE + V_FRONT) && y_cnt < (V_VISIBLE + V_FRONT + V_SYNC));
    wire vis_raw   =  (x_cnt < H_VISIBLE) && (y_cnt < V_VISIBLE);

    // Stage 0 -> Address Calculation
    wire [11:0] txt_row = {7'b0, y_cnt[8:4]};
    assign vga_txt_addr = (txt_row << 6) + (txt_row << 4) + {5'b0, x_cnt[9:3]}; // Row * 80 + Col
    
    wire [9:0]  y_gfx = y_cnt - 10'd40; // Center graphics (480 - 400 = 80 -> 40 top padding)
    wire [12:0] gfx_row = {4'b0, y_gfx[9:1]};
    assign vga_gfx_addr = (gfx_row << 5) + (gfx_row << 3) + {3'b0, x_cnt[9:4]}; // Scaled_Row * 40 + Scaled_Col

    // Pipeline Delay Registers
    reg [9:0] x_d1, x_d2, x_d3, x_d4;
    reg [9:0] y_d1, y_d2, y_d3, y_d4;
    reg h_d1, h_d2, h_d3, h_d4, h_d5;
    reg v_d1, v_d2, v_d3, v_d4, v_d5;
    reg vis_d1, vis_d2, vis_d3, vis_d4, vis_d5;
    reg [7:0] gfx_data_d3, gfx_data_d4;

    // Stage 2 -> Combinational Font Address Calculation
    assign vga_font_addr = {vga_txt_data[6:0], y_d2[3:0]};

    // Stage Delays Shifter
    always @(posedge clk) begin
        x_d1 <= x_cnt; x_d2 <= x_d1; x_d3 <= x_d2; x_d4 <= x_d3;
        y_d1 <= y_cnt; y_d2 <= y_d1; y_d3 <= y_d2; y_d4 <= y_d3;
        
        h_d1 <= hsync_raw; h_d2 <= h_d1; h_d3 <= h_d2; h_d4 <= h_d3; h_d5 <= h_d4;
        v_d1 <= vsync_raw; v_d2 <= v_d1; v_d3 <= v_d2; v_d4 <= v_d3; v_d5 <= v_d4;
        vis_d1 <= vis_raw; vis_d2 <= vis_d1; vis_d3 <= vis_d2; vis_d4 <= vis_d3; vis_d5 <= vis_d4;
        
        gfx_data_d3 <= vga_gfx_data;
        gfx_data_d4 <= gfx_data_d3;
    end

    // Stage 4/5 -> Final Extraction and Video Mixer
    wire text_pixel    = vga_font_data[ 3'd7 - x_d4[2:0] ]; // MSB is drawn left-most
    wire gfx_pixel     = gfx_data_d4[ 3'd7 - x_d4[3:1] ];   // MSB is drawn left-most
    wire in_gfx_bounds = (y_d4 >= 40 && y_d4 < 440);

    // Layer [1] = Graphics, Layer [0] = Text
    wire draw_ink = (layer_enable[0] && text_pixel) || (layer_enable[1] && in_gfx_bounds && gfx_pixel);
    wire [7:0] active_color = draw_ink ? ink_color : bg_color;

    always @(posedge clk) begin
        vga_hsync <= h_d5;
        vga_vsync <= v_d5;
        
        if (!vis_d5) begin
            vga_r <= 6'b0; vga_g <= 6'b0; vga_b <= 6'b0;
        end else begin
            // Expand standard 8-bit RRRGGGBB color into 18-bit hardware DAC format
            vga_r <= {active_color[7:5], active_color[7:5]};
            vga_g <= {active_color[4:2], active_color[4:2]};
            vga_b <= {active_color[1:0], active_color[1:0], active_color[1:0]};
        end
    end

endmodule