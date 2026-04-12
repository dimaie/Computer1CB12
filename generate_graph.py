import os
import tkinter as tk

def generate_graph_ram():
    width = 320
    height = 240
    bytes_per_row = width // 8
    total_bytes = 9600
    
    memory = bytearray(total_bytes)
    
    for y in range(height):
        row_offset = y * bytes_per_row
        
        # Top and bottom borders (solid lines)
        if y == 0 or y == height - 1:
            for x in range(bytes_per_row):
                memory[row_offset + x] = 0xFF
            continue
            
        # Left and right borders
        memory[row_offset] |= 0x80                        # Left border (bit 7)
        memory[row_offset + bytes_per_row - 1] |= 0x01    # Right border (bit 0)
        
        # Diagonals
        x1 = int(round(y * (width - 1) / (height - 1)))
        x2 = (width - 1) - x1
        
        memory[row_offset + (x1 // 8)] |= (1 << (7 - (x1 % 8)))
        memory[row_offset + (x2 // 8)] |= (1 << (7 - (x2 % 8)))
        
    # Format into Intel HEX exactly matching the existing file
    output_path = os.path.join(os.path.dirname(__file__), "graph_ram.hex")
    with open(output_path, "w") as f:
        for i in range(total_bytes):
            addr_hi = (i >> 8) & 0xFF
            addr_lo = i & 0xFF
            data = memory[i]
            
            # Intel HEX Checksum calculation
            checksum = (256 - ((1 + addr_hi + addr_lo + 0 + data) % 256)) % 256
            f.write(f":01{addr_hi:02X}{addr_lo:02X}00{data:02X}{checksum:02X}\n")
        f.write(":00000001FF\n")
        print(f"Generated {output_path} successfully!")

def display_preview():
    width = 320
    height = 240
    output_path = os.path.join(os.path.dirname(__file__), "graph_ram.hex")
    
    # Read the hex file back into a bytearray
    memory = bytearray(16384) # Expand buffer to fit new graphics size
    try:
        with open(output_path, "r") as f:
            for line in f:
                line = line.strip()
                # Parse 1-byte data records: :01 <addr> 00 <data> <checksum>
                if line.startswith(":01") and line[7:9] == "00":
                    addr = int(line[3:7], 16)
                    data = int(line[9:11], 16)
                    if addr < len(memory):
                        memory[addr] = data
    except FileNotFoundError:
        print(f"Could not find {output_path} to display.")
        return
        
    root = tk.Tk()
    root.title("graph_ram.hex Preview (Scaled 2x)")
    
    scale = 2
    canvas = tk.Canvas(root, width=width*scale, height=height*scale, bg="black")
    canvas.pack()
    
    # Map the bits to pixels on the canvas (MSB is the leftmost pixel)
    for y in range(height):
        row_offset = y * (width // 8)
        for x in range(width):
            if memory[row_offset + (x // 8)] & (1 << (7 - (x % 8))):
                canvas.create_rectangle(x*scale, y*scale, x*scale+scale, y*scale+scale, fill="#00FF00", outline="")
                
    root.mainloop()

if __name__ == "__main__":
    generate_graph_ram()
    display_preview()