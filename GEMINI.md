# SAP-3 Processor Project Context

## Overview
This project is an FPGA implementation of the SAP-3 (Simple As Possible 3) processor, which is an educational implementation of the Intel 8080 Instruction Set Architecture. 
The design uses a shared 16-bit internal data bus with multiplexed component access.
The hardware is based on the OneChipBook laptop. `OneChipBook12-TechRef.pdf` is available for all hardware-related questions.

## Verilog Coding Standards
- **Standard:** Use standard Verilog-2001 syntax. Do not use SystemVerilog specific features unless explicitly requested.
- **Sequential Logic:** Always use non-blocking assignments (`<=`) inside `always @(posedge clk)` blocks.
- **Combinational Logic:** Always use blocking assignments (`=`) inside `always @(*)` blocks. Default all outputs to a known state (e.g., `0`) at the top of combinational blocks to prevent latch inference.
- **Constants:** Use `localparam` for state definitions, opcodes, and bit-positions. Name them using `UPPER_CASE`.

## Naming Conventions
- `*_we`: Write Enable signals (active high).
- `*_oe`: Output Enable signals (active high, used for driving the shared bus).
- `*_sel`: Select signals for multiplexers.
- `clk`: System clock.
- `rst`: Internal reset (active-high).

## Memory Map
- `0x0000` - `0x07FF`: 2KB Program ROM
- `0x2000` - `0x3FFF`: 8KB Program RAM
- `0x8000` - `0x9FFF`: 8KB Video Graphics RAM (320x200 monochrome)
- `0xA000` - `0xAFFF`: 4KB Video Text RAM (80x30 text mode)
- `0xB000` - `0xB7FF`: 2KB Video Font RAM (16x8 character fonts, 128 chars)
- `0xC001`: Video Ink Color Register
- `0xC002`: Video Background Color Register

## Architecture Notes
- The external board reset (`RESET_N`) is active-low, but it is inverted to an active-high `rst` signal at the top level (`Computer1CB12-1_Top.v`). All sub-modules should assume `rst` is active-high.
- Memory is initialized from a `program.hex` hex file.
- The ALU evaluates arithmetic/logic operations on the positive clock edge but updates processor flags (Z, C, P, S) on the negative clock edge.
- Video Mixer Logic: The VGA display pipeline reads both Text and Graphics RAM simultaneously. Text pixels are overlaid transparently on top of graphics pixels, eliminating the need for a dedicated video mode register.
