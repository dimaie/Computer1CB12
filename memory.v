/*
 * Unified Memory Module
 *
 * This module implements the memory subsystem for the SAP-3 processor,
 * combining the MAR, Program ROM, Program RAM, and Video Memory into 
 * a single unit with a consolidated memory map.
 */

module memory(
    input  wire        clk,
    input  wire        rst,
    
    // CPU Control Signals
    input  wire        mar_we,
    input  wire        ram_we,
    input  wire [15:0] bus,
    output reg  [7:0]  out,
    
    // VGA Controller Interface (Read-Only Dual Port)
    input  wire [13:0] vga_gfx_addr,
    output wire [7:0]  vga_gfx_data,
    
    input  wire [11:0] vga_txt_addr,
    output wire [7:0]  vga_txt_data,
    
    input  wire [10:0] vga_font_addr,
    output wire [7:0]  vga_font_data,
    
    // Video Control Registers
    output reg  [7:0]  ink_color,
    output reg  [7:0]  bg_color,
    output reg  [6:0]  cursor_x,
    output reg  [4:0]  cursor_y,
    output reg  [1:0]  cursor_style,
    output reg  [7:0]  gfx_ink_color
);

    // Memory Address Register (MAR)
    reg [15:0] mar;
    
    // Delayed MAR (tracks 1-cycle read latency for output multiplexing)
    reg [15:0] mar_d1;

    // Output wires from physical memory blocks
    wire [7:0] rom_out;
    wire [7:0] ram_out;
    wire [7:0] gfx_ram_out;
    wire [7:0] txt_ram_out;

    // Write enables for specific memory blocks
    wire we_ram  = ram_we && (mar >= 16'h2000 && mar <= 16'h3FFF); // 8KB Program RAM
    wire we_gfx  = ram_we && (mar >= 16'h4000 && mar <= 16'h657F); // Strictly 9600 bytes (320x240)
    wire we_txt  = ram_we && (mar >= 16'hA000 && mar <= 16'hA95F); // Strictly 2400 bytes (80x30)
    wire we_font = ram_we && (mar >= 16'hB000 && mar <= 16'hB7FF); // 2KB Font space

    // -------------------------------------------------------------------------
    // Instantiations of Generic Block RAM Modules
    // -------------------------------------------------------------------------
    block_rom #(.ADDR_WIDTH(12), .DEPTH(3072), .INIT_FILE("program.hex")) rom_inst (
        .clk(clk), .addr(mar[11:0]), .q(rom_out)
    );

    block_ram #(.ADDR_WIDTH(13), .DEPTH(8192)) ram_inst (
        .clk(clk), .we(we_ram), .addr(mar[12:0]), .d(bus[7:0]), .q(ram_out)
    );

    vga_shared_tdp_ram #(.ADDR_WIDTH(14), .DEPTH(9600), .INIT_FILE("")) gfx_ram_inst (
        .clk(clk), .we_a(we_gfx), .addr_a(mar[13:0]), .d_a(bus[7:0]), .q_a(gfx_ram_out),
        .addr_b(vga_gfx_addr[13:0]), .q_b(vga_gfx_data)
    );

    vga_shared_tdp_ram #(.ADDR_WIDTH(12), .DEPTH(2400), .INIT_FILE("")) txt_ram_inst (
        .clk(clk), .we_a(we_txt), .addr_a(mar[11:0]), .d_a(bus[7:0]), .q_a(txt_ram_out),
        .addr_b(vga_txt_addr), .q_b(vga_txt_data)
    );

    vga_shared_ram #(.ADDR_WIDTH(11), .INIT_FILE("font_rom.hex")) font_ram_inst (
        .clk(clk), .we_a(we_font), .addr_a(mar[10:0]), .d_a(bus[7:0]),
        .addr_b(vga_font_addr), .q_b(vga_font_data)
    );

    // MAR and Video Control Registers Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mar        <= 16'b0;
            mar_d1     <= 16'b0;
            ink_color  <= 8'hFF; // Default White
            bg_color   <= 8'h00; // Default Black
            cursor_x   <= 7'd0;  // Default Col 0
            cursor_y   <= 5'd0;  // Default Row 0
            cursor_style <= 2'd2;  // Default Full Cursor
            gfx_ink_color <= 8'hFF; // Default White
        end else begin
            if (mar_we) begin
                mar <= bus;
            end
            
            // Track MAR to align multiplexer with the 1-cycle block RAM latency
            mar_d1 <= mar;
            
            // Register Write Decoding
            if (ram_we && mar >= 16'hC001 && mar <= 16'hC006) begin
                case (mar[2:0])
                    3'b001: ink_color    <= bus[7:0]; // 0xC001
                    3'b010: bg_color     <= bus[7:0]; // 0xC002
                    3'b011: cursor_x     <= bus[6:0]; // 0xC003
                    3'b100: cursor_y     <= bus[4:0]; // 0xC004
                    3'b101: cursor_style <= bus[1:0]; // 0xC005
                    3'b110: gfx_ink_color <= bus[7:0]; // 0xC006
                endcase
            end
        end
    end

    // CPU Memory Read Logic (Combinational multiplexer based on delayed MAR)
    always @(*) begin
        if (mar_d1 < 16'h0C00)
            out = rom_out;
        else if (mar_d1 >= 16'h2000 && mar_d1 <= 16'h3FFF)
            out = ram_out;
        else if (mar_d1 >= 16'h4000 && mar_d1 <= 16'h657F)
            out = gfx_ram_out;
        else if (mar_d1 >= 16'hA000 && mar_d1 <= 16'hA95F)
            out = txt_ram_out;
        else if (mar_d1 == 16'hC001)
            out = ink_color;
        else if (mar_d1 == 16'hC002)
            out = bg_color;
        else if (mar_d1 == 16'hC003)
            out = {1'b0, cursor_x};
        else if (mar_d1 == 16'hC004)
            out = {3'b0, cursor_y};
        else if (mar_d1 == 16'hC005)
            out = {6'b0, cursor_style};
        else if (mar_d1 == 16'hC006)
            out = gfx_ink_color;
        else
            out = 8'h00; // Default out for unmapped or write-only video RAM regions
    end

endmodule

// True Dual-Port Video RAM (Port A = CPU Read/Write, Port B = VGA Read-Only)
module vga_shared_tdp_ram #(
    parameter ADDR_WIDTH = 13,
    parameter DEPTH = (1 << ADDR_WIDTH),
    parameter INIT_FILE = ""
)(
    input  wire                  clk,
    input  wire                  we_a,
    input  wire [ADDR_WIDTH-1:0] addr_a,
    input  wire [7:0]            d_a,
    output reg  [7:0]            q_a,
    input  wire [ADDR_WIDTH-1:0] addr_b,
    output reg  [7:0]            q_b
);
    (* ram_init_file = INIT_FILE, ramstyle = "no_rw_check" *)
    reg [7:0] ram [0:DEPTH-1];
    always @(posedge clk) begin
        if (we_a) ram[addr_a] <= d_a;
        q_a <= ram[addr_a];
    end
    always @(posedge clk) begin
        q_b <= ram[addr_b];
    end
endmodule

// -----------------------------------------------------------------------------
// Generic Altera M4K Block RAM Inference Modules
// -----------------------------------------------------------------------------

// Single-Port ROM
module block_rom #(
    parameter ADDR_WIDTH = 12,
    parameter DEPTH = 3072,
    parameter INIT_FILE = "program.hex"
)(
    input  wire                  clk,
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [7:0]            q
);
    reg [7:0] rom [0:DEPTH-1];
    initial begin
        if (INIT_FILE != "") $readmemh(INIT_FILE, rom);
    end
    always @(posedge clk) begin
        q <= rom[addr];
    end
endmodule

// Single-Port RAM
module block_ram #(
    parameter ADDR_WIDTH = 13,
    parameter DEPTH = (1 << ADDR_WIDTH)
)(
    input  wire                  clk,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [7:0]            d,
    output reg  [7:0]            q
);
    reg [7:0] ram [0:DEPTH-1];
    always @(posedge clk) begin
        if (we) ram[addr] <= d;
        q <= ram[addr];
    end
endmodule

// Shared Video RAM (Port A = CPU Write-Only, Port B = VGA Read-Only)
module vga_shared_ram #(
    parameter ADDR_WIDTH = 13,
    parameter DEPTH = (1 << ADDR_WIDTH),
    parameter INIT_FILE = ""
)(
    input  wire                  clk,
    input  wire                  we_a,
    input  wire [ADDR_WIDTH-1:0] addr_a,
    input  wire [7:0]            d_a,
    input  wire [ADDR_WIDTH-1:0] addr_b,
    output reg  [7:0]            q_b
);
    (* ram_init_file = INIT_FILE, ramstyle = "no_rw_check" *)
    reg [7:0] ram [0:DEPTH-1];
    always @(posedge clk) begin
        if (we_a) ram[addr_a] <= d_a;
    end
    always @(posedge clk) begin
        q_b <= ram[addr_b];
    end
endmodule
