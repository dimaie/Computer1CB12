; =========================================================================
; SAP-3 System Monitor - Iteration 4
; - Keyboard PS/2 Scan Code Decoding
; - Line Buffering
; - Echoing and Backspace Support
; - Command Parser: Dxxxx (Dump Memory)
; - Command Parser: Mxxxx (Modify Memory)
; - Command Parser: Gxxxx (Go / Execute)
; - Command Parser: X     (Examine Registers)
; - Command Parser: R     (Receive UART Payload)
; - Command Parser: S     (Step Over)
; - Command Parser: Bxxxx (Breakpoint)
; =========================================================================

ORG 0x0000
JMP START

ORG 0x0008
JMP BP_HANDLER

; ---------------------------------------------------------
; Variables in Program RAM
; ---------------------------------------------------------
ORG 0x2000
VAR_CURSOR_X:   DS 1
VAR_CURSOR_Y:   DS 1
VAR_CURSOR_PTR: DS 2
VAR_KB_STATE:   DS 1
VAR_INPUT_LEN:  DS 1
VAR_INPUT_BUF:  DS 64
VAR_MODIFY_PTR: DS 2
VAR_REG_NAME_PTR: DS 2
VAR_REGS:       DS 12   ; AF, BC, DE, HL, SP, PC (16-bit pairs)
VAR_BP_ACTIVE:  DS 1
VAR_BP_ADDR:    DS 2
VAR_BP_BYTES:   DS 3
VAR_DISASM_PTR: DS 2

; ---------------------------------------------------------
; C-Compiler ROM API Jump Table (Fixed Addresses)
; ---------------------------------------------------------
ORG 0x0010
API_PRINT_CHAR:    JMP PRINT_CHAR_C
API_READ_KEY:      JMP READ_KEY_C
API_CLEAR_SCREEN:  JMP CLEAR_SCREEN_C
API_PRINT_CHAR_XY: JMP PRINT_CHAR_XY_C
API_READ_CHAR_XY:  JMP READ_CHAR_XY_C
API_READ_PIXEL_XY: JMP READ_PIXEL_XY_C
API_CHECK_KEY:     JMP CHECK_KEY_C

; ---------------------------------------------------------
; Main Program
; ---------------------------------------------------------
ORG 0x0028
START:
    LXI SP, 0x3FFF      ; Initialize Stack Pointer
    
    ; Seed the bottom of the User Stack with the Monitor's Return Address
    LXI H, MAIN_LOOP
    PUSH H
    
    ; Initialize User SP in VAR_REGS to the new bottom (0x3FFD)
    LXI H, 0
    DAD SP
    SHLD VAR_REGS + 8
    
    ; Clear active breakpoint
    XRA A
    STA VAR_BP_ACTIVE
    
    CALL CLEAR_SCREEN
    
    ; Set Hardware Cursor Style (2 = Full Block)
    MVI A, 2
    STA 0xC005
    CALL SYNC_CURSOR

    ; Reset Keyboard State
    MVI A, 0
    STA VAR_KB_STATE

MAIN_LOOP:
    ; Print Prompt "->"
    MVI A, '-'
    CALL PRINT_CHAR
    MVI A, '>'
    CALL PRINT_CHAR
    
    CALL READ_LINE
    
    LDA VAR_INPUT_LEN
    ORA A               ; Is length 0?
    JZ MAIN_LOOP        ; If empty, just print new prompt
    
    ; Read first character
    LXI H, VAR_INPUT_BUF
    MOV A, M
    CPI 'D'
    JZ CMD_DUMP
    CPI 'M'
    JZ CMD_MODIFY
    CPI 'G'
    JZ CMD_GO
    CPI 'X'
    JZ CMD_EXAMINE
    CPI 'R'
    JZ CMD_RECEIVE
    CPI 'U'
    JZ CMD_UNASSEMBLE
    CPI 'S'
    JZ CMD_STEP
    CPI 'B'
    JZ CMD_BREAKPOINT
    
CMD_ERROR:
    MVI A, '?'
    CALL PRINT_CHAR
    CALL NEW_LINE
    JMP MAIN_LOOP

CMD_DUMP:
    LXI H, VAR_INPUT_BUF + 1
    CALL SKIP_SPACES
    CALL PARSE_HEX_WORD
    JC CMD_ERROR        ; Invalid hex characters
    
    ; HL now contains the starting address. Dump 32 bytes (2x16 lines)
    MVI B, 2
DUMP_LINE_LOOP:
    MOV A, H
    CALL PRINT_HEX_BYTE
    MOV A, L
    CALL PRINT_HEX_BYTE
    MVI A, ':'
    CALL PRINT_CHAR
    CALL PRINT_SPACE
    
    MVI C, 16
DUMP_BYTE_LOOP:
    MOV A, M
    CALL PRINT_HEX_BYTE
    CALL PRINT_SPACE
    INX H
    DCR C
    JNZ DUMP_BYTE_LOOP
    
    CALL NEW_LINE
    DCR B
    JNZ DUMP_LINE_LOOP
    
    JMP MAIN_LOOP

CMD_MODIFY:
    LXI H, VAR_INPUT_BUF + 1
    CALL SKIP_SPACES
    CALL PARSE_HEX_WORD
    JC CMD_ERROR        ; Invalid hex characters
    
    SHLD VAR_MODIFY_PTR
    
MODIFY_PROMPT:
    LHLD VAR_MODIFY_PTR
    MOV A, H
    CALL PRINT_HEX_BYTE
    MOV A, L
    CALL PRINT_HEX_BYTE
    MVI A, ':'
    CALL PRINT_CHAR
    
    MOV A, M
    CALL PRINT_HEX_BYTE
    MVI A, ':'
    CALL PRINT_CHAR
    
    CALL READ_LINE
    
    LDA VAR_INPUT_LEN
    ORA A
    JZ MAIN_LOOP        ; Empty input, return to prompt
    
    LXI H, VAR_INPUT_BUF
    CALL SKIP_SPACES
    CALL PARSE_HEX_BYTE
    JC MAIN_LOOP        ; If invalid hex, return to prompt
    
    ; Valid byte in A. Write to memory
    MOV B, A
    LHLD VAR_MODIFY_PTR
    MOV M, B
    
    ; Increment pointer and repeat
    INX H
    SHLD VAR_MODIFY_PTR
    JMP MODIFY_PROMPT

CMD_GO:
    LDA VAR_INPUT_LEN
    CPI 1               ; Was it just "G" without address?
    JZ GO_EXECUTE
    
    LXI H, VAR_INPUT_BUF + 1
    CALL SKIP_SPACES
    CALL PARSE_HEX_WORD
    JC CMD_ERROR        ; Invalid hex characters
    
    ; Store parsed address into VAR_REGS PC
    SHLD VAR_REGS + 10
    
GO_EXECUTE:
    ; Context Switch Trampoline
    LHLD VAR_REGS + 8   ; Load User's SP
    SPHL                ; SP = User's SP
    
    LHLD VAR_REGS + 10  ; PC
    PUSH H
    LHLD VAR_REGS + 0   ; AF
    PUSH H
    LHLD VAR_REGS + 2   ; BC
    PUSH H
    LHLD VAR_REGS + 4   ; DE
    PUSH H
    LHLD VAR_REGS + 6   ; HL
    PUSH H
    
    POP H
    POP D
    POP B
    POP PSW
    
    RET                 ; Pops PC and jumps to user program!

CMD_EXAMINE:
    LXI H, VAR_REGS
    SHLD VAR_MODIFY_PTR
    LXI H, REG_NAMES
    SHLD VAR_REG_NAME_PTR

EXAMINE_PROMPT:
    LHLD VAR_REG_NAME_PTR
    MOV A, M
    ORA A
    JZ MAIN_LOOP        ; Null terminator means end of list
    
    CALL PRINT_CHAR     ; First letter of pair
    INX H
    MOV A, M
    CALL PRINT_CHAR     ; Second letter of pair
    INX H
    SHLD VAR_REG_NAME_PTR
    
    MVI A, '='
    CALL PRINT_CHAR
    
    LHLD VAR_MODIFY_PTR
    MOV E, M            ; Low byte
    INX H
    MOV D, M            ; High byte
    INX H
    PUSH H              ; Save pointer to NEXT register pair
    
    MOV A, D
    CALL PRINT_HEX_BYTE ; Print High byte
    MOV A, E
    CALL PRINT_HEX_BYTE ; Print Low byte
    
    MVI A, ':'
    CALL PRINT_CHAR
    CALL PRINT_SPACE
    
    CALL READ_LINE
    
    LDA VAR_INPUT_LEN
    ORA A
    JZ EXAMINE_NEXT     ; Empty input, skip to next pair
    
    LXI H, VAR_INPUT_BUF
    CALL SKIP_SPACES
    CALL PARSE_HEX_WORD
    JC EXAMINE_ERR      ; If parse fails, output error
    
    ; Store new 16-bit value in memory (Little-Endian)
    XCHG                ; DE = parsed new value
    LHLD VAR_MODIFY_PTR
    MOV M, E            ; Store Low byte
    INX H
    MOV M, D            ; Store High byte
    JMP EXAMINE_NEXT

EXAMINE_ERR:
    POP H               ; Restore stack before throwing error
    JMP CMD_ERROR

EXAMINE_NEXT:
    POP H               ; Restore pointer to next register pair
    SHLD VAR_MODIFY_PTR
    JMP EXAMINE_PROMPT

CMD_RECEIVE:
    LDA VAR_INPUT_LEN
    CPI 1               ; Ensure command is exactly 'R'
    JNZ CMD_ERROR
    
    CALL NEW_LINE       ; Start on a fresh line for diagnostic output
    
FLUSH_RX:
    IN 0x03
    ANI 0x02
    JZ FLUSH_DONE       ; If RX_READY is 0, buffer is clean!
    IN 0x02             ; If not, read the garbage byte and discard it
    JMP FLUSH_RX
FLUSH_DONE:
    
    MVI A, 0x06         ; Send ACK to PC to start transmission
    CALL UART_SEND_BYTE
    
    MVI D, 0            ; D will hold our Rolling Checksum
    
    ; --- Read 4-Byte Header ---
    CALL UART_RECV_BYTE
    MOV E, A            ; E = Addr Low
    ADD D
    MOV D, A
    
    CALL UART_RECV_BYTE
    MOV H, A            ; H = Addr High
    ADD D
    MOV D, A
    MOV L, E            ; HL = Target Address
    
    CALL UART_RECV_BYTE
    MOV C, A            ; C = Length Low
    ADD D
    MOV D, A
    
    CALL UART_RECV_BYTE
    MOV B, A            ; B = Length High
    ADD D
    MOV D, A
    
    PUSH B              ; Save original Length for diagnostic summary
    PUSH H              ; Save original Target Address for diagnostic summary
    
    ; Check for 0-length payload
    MOV A, B
    ORA C
    JZ RECV_VERIFY
    
    ; --- Receive Payload ---
RECV_LOOP:
    CALL UART_RECV_BYTE
    MOV M, A            ; Store byte to memory
    ADD D               ; Add to checksum
    MOV D, A            ; Save checksum
    
    ; Diagnostic: Print a '.' every 256 bytes (when C wraps to 0)
    MOV A, C
    ORA A
    JNZ RECV_SKIP_DOT
    MVI A, '.'
    CALL PRINT_CHAR
RECV_SKIP_DOT:
    
    INX H               ; Next address
    DCX B               ; Decrement remaining length
    MOV A, B
    ORA C
    JNZ RECV_LOOP       ; Repeat until BC == 0
    
RECV_VERIFY:
    CALL UART_RECV_BYTE ; Read PC Checksum
    CMP D               ; Compare with our calculated checksum
    JNZ RECV_ERROR
    
    MVI A, 0x06         ; Send Success ACK
    CALL UART_SEND_BYTE
    
    ; --- Success Summary ---
    CALL NEW_LINE
    MVI A, 'O'
    CALL PRINT_CHAR
    MVI A, 'K'
    CALL PRINT_CHAR
    CALL PRINT_SPACE
    
    POP H               ; Restore Target Address
    MOV A, H
    CALL PRINT_HEX_BYTE
    MOV A, L
    CALL PRINT_HEX_BYTE
    CALL PRINT_SPACE
    
    POP B               ; Restore Length
    MOV A, B
    CALL PRINT_HEX_BYTE
    MOV A, C
    CALL PRINT_HEX_BYTE
    
    CALL NEW_LINE
    JMP MAIN_LOOP       ; Return quietly to prompt
    
RECV_ERROR:
    POP H               ; Clean up stack (Address)
    POP B               ; Clean up stack (Length)
    MVI A, 0x15         ; Send NAK
    CALL UART_SEND_BYTE
    JMP CMD_ERROR       ; Print '?' and return to prompt

; =========================================================================
; C-Compiler ROM API Implementations
; =========================================================================

; void print_char(int c) @ 0x0010
PRINT_CHAR_C:
    PUSH B
    PUSH D
    LXI H, 6
    DAD SP
    MOV A, M            ; Read low byte of 'c'
    CALL PRINT_CHAR     ; Call monitor native routine
    POP D
    POP B
    RET

; int read_key() @ 0x0013
READ_KEY_C:
    PUSH B
    PUSH D
    CALL GET_KEY        ; Blocks, returns ASCII in A
    MOV L, A
    MVI H, 0
    POP D
    POP B
    RET

; void clear_screen(int layer) @ 0x0016
CLEAR_SCREEN_C:
    PUSH B
    PUSH D
    LXI H, 6
    DAD SP
    MOV A, M            ; Read low byte of 'layer'
    CPI 2
    JZ _CS_GFX
    CPI 1
    JZ _CS_TXT
_CS_BOTH:
    CALL CLEAR_SCREEN   ; Clears Text RAM and resets cursor
    CALL _DO_CS_GFX
    JMP _CS_DONE
_CS_TXT:
    CALL CLEAR_SCREEN
    JMP _CS_DONE
_CS_GFX:
    CALL _DO_CS_GFX
_CS_DONE:
    POP D
    POP B
    RET

_DO_CS_GFX:
    LXI H, 0x4000       ; Graphics RAM Base Address
    LXI B, 7680         ; 256x240 bits / 8
_CS_GFX_LOOP:
    MVI M, 0x00         ; Fill with 0 (empty pixels)
    INX H
    DCX B
    MOV A, B
    ORA C
    JNZ _CS_GFX_LOOP
    RET

; void print_char_xy(int c, int x, int y) @ 0x0019
PRINT_CHAR_XY_C:
    PUSH B
    PUSH D
    ; 1. Load 'y'
    LXI H, 10
    DAD SP
    MOV A, M
    MOV L, A
    MVI H, 0            ; HL = y
    ; 2. Fast calculation of: y * 64
    DAD H               ; y * 2
    DAD H               ; y * 4
    DAD H               ; y * 8
    DAD H               ; y * 16
    DAD H               ; y * 32
    DAD H               ; y * 64
    ; 3. Add 'x'
    XCHG                ; DE = y * 64
    LXI H, 8
    DAD SP
    MOV A, M            ; A = x
    ADD E
    MOV E, A
    MOV A, D
    ACI 0
    MOV D, A            ; DE = (y * 64) + x
    ; 4. Add Text RAM Base (0xA000)
    LXI H, 0xA000
    DAD D               ; HL = 0xA000 + (y * 64) + x
    ; 5. Load 'c' and write
    XCHG                ; DE points to the VRAM target
    LXI H, 6
    DAD SP
    MOV A, M            ; A = c
    STAX D              ; Write 'c' directly to VRAM target
    POP D
    POP B
    RET

; int read_char_xy(int x, int y) @ 0x001C
READ_CHAR_XY_C:
    PUSH B
    PUSH D
    ; 1. Load 'y'
    LXI H, 8
    DAD SP
    MOV L, M
    MVI H, 0            ; HL = y
    ; 2. Fast calculation of: y * 64
    DAD H               ; y * 2
    DAD H               ; y * 4
    DAD H               ; y * 8
    DAD H               ; y * 16
    DAD H               ; y * 32
    DAD H               ; y * 64
    ; 3. Add 'x'
    XCHG                ; DE = y * 64
    LXI H, 6
    DAD SP
    MOV A, M            ; A = x
    ADD E
    MOV E, A
    MOV A, D
    ACI 0
    MOV D, A            ; DE = (y * 64) + x
    ; 4. Add Text RAM Base (0xA000)
    LXI H, 0xA000
    DAD D               ; HL = 0xA000 + (y * 64) + x
    ; 5. Read character
    MOV L, M            ; Return value in L
    MVI H, 0            ; H = 0
    POP D
    POP B
    RET

; int read_pixel_xy(int x, int y) @ 0x001F
READ_PIXEL_XY_C:
    PUSH B
    PUSH D
    ; 1. Load 'y'
    LXI H, 8
    DAD SP
    MOV L, M
    MVI H, 0            ; HL = y
    ; 2. Fast calculation of: y * 32
    DAD H               ; y * 2
    DAD H               ; y * 4
    DAD H               ; y * 8
    DAD H               ; y * 16
    DAD H               ; y * 32
    PUSH H              ; Save (y * 32)
    ; 3. Load 'x' (16-bit, as it can be > 255)
    LXI H, 8            ; Offset is 8 because we just pushed H
    DAD SP
    MOV E, M            ; E = x low
    INX H
    MOV D, M            ; D = x high
    ; 4. Calculate x / 8 using 16-bit shifts
    MOV A, D ! ORA A ! RAR ! MOV D, A ! MOV A, E ! RAR ! MOV E, A ; x / 2
    MOV A, D ! ORA A ! RAR ! MOV D, A ! MOV A, E ! RAR ! MOV E, A ; x / 4
    MOV A, D ! ORA A ! RAR ! MOV D, A ! MOV A, E ! RAR ! MOV E, A ; DE = x / 8
    ; 5. Add to y * 32
    POP H               ; HL = y * 32
    DAD D               ; HL = (y * 32) + (x / 8)
    ; 6. Add Graphics RAM Base (0x4000)
    LXI D, 0x4000
    DAD D               ; HL = 0x4000 + (y * 32) + (x / 8)
    ; 7. Read VRAM byte
    MOV B, M            ; B = VRAM byte
    ; 8. Calculate x % 8 and get bitmask
    LXI H, 6            ; Restore SP offset for 'x'
    DAD SP
    MOV A, M            ; A = x low
    ANI 0x07            ; A = x % 8
    LXI D, _RP_MASKS
    ADD E ! MOV E, A ! MOV A, D ! ACI 0 ! MOV D, A ; DE = _RP_MASKS + (x % 8)
    LDAX D              ; A = Specific Bit Mask
    ; 9. Test pixel
    ANA B               ; AND mask with VRAM byte
    JZ _RP_ZERO
    MVI L, 1
    MVI H, 0
    JMP _RP_DONE
_RP_ZERO:
    MVI L, 0
    MVI H, 0
_RP_DONE:
    POP D
    POP B
    RET

_RP_MASKS:
    DB 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01

; int check_key() @ 0x0022
CHECK_KEY_C:
    IN 0x01
    ANI 0x01
    JZ _CK_EMPTY
    IN 0x00
    MOV L, A
    MVI H, 0
    RET
_CK_EMPTY:
    LXI H, 0
    RET

; ---------------------------------------------------------
; Commands: Step (S) and Breakpoint (B)
; ---------------------------------------------------------
CMD_STEP:
    ; Disassemble current instruction to find length
    LHLD VAR_REGS + 10
    MOV B, M            ; B = opcode
    PUSH H              ; Save User PC
    
    LXI H, DISASM_MAP
    MOV E, B
    MVI D, 0
    DAD D
    MOV A, M            ; A = Template ID
    CALL GET_TEMPLATE   ; HL = Template String
    
    MVI D, 1            ; Default Length = 1
S_LEN_LOOP:
    MOV A, M
    ORA A
    JZ S_LEN_DONE
    INX H
    CPI 0x86
    JNZ S_LEN_NOT_2
    MVI D, 2
    JMP S_LEN_LOOP
S_LEN_NOT_2:
    CPI 0x87
    JNZ S_LEN_LOOP
    MVI D, 3
    JMP S_LEN_LOOP
S_LEN_DONE:
    POP H               ; HL = User PC
    MOV E, D
    MVI D, 0
    DAD D               ; HL = Next PC
    
    JMP INJECT_BP

CMD_BREAKPOINT:
    LDA VAR_INPUT_LEN
    CPI 1
    JZ BP_CLEAR
    
    LXI H, VAR_INPUT_BUF + 1
    CALL SKIP_SPACES
    CALL PARSE_HEX_WORD
    JC CMD_ERROR
    
INJECT_BP:
    ; HL contains the target address for the NEW breakpoint!
    ; Push it to save it while we clean up any old breakpoints
    PUSH H
    
    ; Clear any old BP first to prevent leaving a stranded CALL in memory
    LDA VAR_BP_ACTIVE
    ORA A
    JZ INJECT_NEW
    LHLD VAR_BP_ADDR
    XCHG
    LXI H, VAR_BP_BYTES
    MOV A, M
    STAX D
    INX H
    INX D
    MOV A, M
    STAX D
    INX H
    INX D
    MOV A, M
    STAX D
INJECT_NEW:
    POP H               ; HL = NEW Breakpoint target
    SHLD VAR_BP_ADDR
    
    ; Save 3 original bytes
    XCHG                ; DE = BP Addr
    LXI H, VAR_BP_BYTES
    LDAX D
    MOV M, A
    INX D
    INX H
    LDAX D
    MOV M, A
    INX D
    INX H
    LDAX D
    MOV M, A
    
    ; Inject CALL 0x0008 (CD 08 00)
    LHLD VAR_BP_ADDR
    MVI M, 0xCD
    INX H
    MVI M, 0x08
    INX H
    MVI M, 0x00
    
    MVI A, 1
    STA VAR_BP_ACTIVE
    
    ; If this was a Step command, execute immediately
    LDA VAR_INPUT_BUF
    CPI 'S'
    JZ GO_EXECUTE
    
    CALL NEW_LINE
    MVI A, 'B'
    CALL PRINT_CHAR
    MVI A, 'P'
    CALL PRINT_CHAR
    MVI A, '+'
    CALL PRINT_CHAR
    CALL NEW_LINE
    JMP MAIN_LOOP

BP_CLEAR:
    LDA VAR_BP_ACTIVE
    ORA A
    JZ MAIN_LOOP        ; Was not active
    LHLD VAR_BP_ADDR
    XCHG
    LXI H, VAR_BP_BYTES
    MOV A, M
    STAX D
    INX H
    INX D
    MOV A, M
    STAX D
    INX H
    INX D
    MOV A, M
    STAX D
    XRA A
    STA VAR_BP_ACTIVE
    CALL NEW_LINE
    MVI A, 'B'
    CALL PRINT_CHAR
    MVI A, 'P'
    CALL PRINT_CHAR
    MVI A, '-'
    CALL PRINT_CHAR
    CALL NEW_LINE
    JMP MAIN_LOOP

BP_HANDLER:
    SHLD VAR_REGS + 6   ; Save User HL
    POP H               ; Pop Return Address (BP_ADDR + 3)
    DCX H               ; -1
    DCX H               ; -2
    DCX H               ; -3 (Now points to BP_ADDR)
    SHLD VAR_REGS + 10  ; Save User PC
    
    LXI H, 0
    DAD SP
    SHLD VAR_REGS + 8   ; Save User SP
    
    PUSH PSW
    POP H
    SHLD VAR_REGS + 0   ; Save User AF
    MOV H, B
    MOV L, C
    SHLD VAR_REGS + 2   ; Save User BC
    MOV H, D
    MOV L, E
    SHLD VAR_REGS + 4   ; Save User DE
    
    LXI SP, 0x3FFF      ; Switch to Monitor Stack
    
    ; Restore original bytes implicitly (like BP_CLEAR)
    LDA VAR_BP_ACTIVE
    ORA A
    JZ BP_DONE
    LHLD VAR_BP_ADDR
    XCHG
    LXI H, VAR_BP_BYTES
    MOV A, M
    STAX D
    INX H
    INX D
    MOV A, M
    STAX D
    INX H
    INX D
    MOV A, M
    STAX D
    XRA A
    STA VAR_BP_ACTIVE
    
BP_DONE:
    CALL NEW_LINE
    MVI A, '['
    CALL PRINT_CHAR
    MVI A, 'B'
    CALL PRINT_CHAR
    MVI A, 'P'
    CALL PRINT_CHAR
    MVI A, ']'
    CALL PRINT_CHAR
    CALL PRINT_SPACE
    
    LXI H, REG_NAMES
    LXI D, VAR_REGS
BP_REG_LOOP:
    MOV A, M
    ORA A
    JZ BP_REG_DONE
    CALL PRINT_CHAR     ; Print first letter (e.g., 'A')
    INX H
    MOV A, M
    CALL PRINT_CHAR     ; Print second letter (e.g., 'F')
    INX H
    MVI A, '='
    CALL PRINT_CHAR
    LDAX D              ; Load Low Byte
    MOV C, A
    INX D
    LDAX D              ; Load High Byte
    MOV B, A
    INX D               ; Point to next register pair
    MOV A, B
    CALL PRINT_HEX_BYTE ; Print High Byte
    MOV A, C
    CALL PRINT_HEX_BYTE ; Print Low Byte
    CALL PRINT_SPACE
    JMP BP_REG_LOOP
    
BP_REG_DONE:
    MVI A, 'F'
    CALL PRINT_CHAR
    MVI A, ':'
    CALL PRINT_CHAR
    CALL PRINT_SPACE
    
    LDA VAR_REGS + 0  ; Load the F register (Low byte of AF)
    MOV B, A
    
    MVI C, 'S'
    MVI D, 0x08       ; Mask for Sign Flag (Bit 3)
    CALL PRINT_FLAG
    
    MVI C, 'Z'
    MVI D, 0x01       ; Mask for Zero Flag (Bit 0)
    CALL PRINT_FLAG
    
    MVI C, 'P'
    MVI D, 0x04       ; Mask for Parity Flag (Bit 2)
    CALL PRINT_FLAG
    
    MVI C, 'C'
    MVI D, 0x02       ; Mask for Carry Flag (Bit 1)
    CALL PRINT_FLAG
    
    CALL NEW_LINE
    
    ; -- Print "Going to Execute" (PC) --
    MVI A, '='
    CALL PRINT_CHAR
    MVI A, '>'
    CALL PRINT_CHAR
    CALL PRINT_SPACE
    LHLD VAR_REGS + 10
    CALL DISASM_PRINT_LINE
    
    JMP MAIN_LOOP

PRINT_FLAG:
    MOV A, C
    CALL PRINT_CHAR
    MVI A, '='
    CALL PRINT_CHAR
    MOV A, B
    ANA D
    MVI A, '0'
    JZ PF_ZERO
    MVI A, '1'
PF_ZERO:
    CALL PRINT_CHAR
    CALL PRINT_SPACE
    RET

; ---------------------------------------------------------
; Command: Unassemble (Disassembler)
; ---------------------------------------------------------
CMD_UNASSEMBLE:
    LDA VAR_INPUT_LEN
    CPI 1
    JZ U_PROMPT_LOOP    ; If just "U" was typed, continue from the last address
    
    LXI H, VAR_INPUT_BUF + 1
    CALL SKIP_SPACES
    CALL PARSE_HEX_WORD
    JC CMD_ERROR        ; Invalid hex characters
    SHLD VAR_MODIFY_PTR
    
U_PROMPT_LOOP:
    MVI C, 16           ; Disassemble 16 lines per command
    
U_LINE_LOOP:
    PUSH B              ; Save line counter (C)
    
    LHLD VAR_MODIFY_PTR
    CALL DISASM_PRINT_LINE
    SHLD VAR_MODIFY_PTR
    
    POP B               ; Restore line counter
    DCR C
    JNZ U_LINE_LOOP
    JMP MAIN_LOOP       ; Back to prompt

; ---------------------------------------------------------
; Subroutine: DISASM_PRINT_LINE
; Disassembles and prints one instruction at HL.
; Returns: HL points to the NEXT instruction.
; ---------------------------------------------------------
DISASM_PRINT_LINE:
    SHLD VAR_DISASM_PTR
    
    MOV A, H
    CALL PRINT_HEX_BYTE
    MOV A, L
    CALL PRINT_HEX_BYTE
    MVI A, ':'
    CALL PRINT_CHAR
    CALL PRINT_SPACE
    
    MOV B, M            ; B = opcode
    
    LXI H, DISASM_MAP
    MOV E, B
    MVI D, 0
    DAD D
    MOV A, M            ; A = Template ID
    CALL GET_TEMPLATE   ; HL = Template String
    
    PUSH H              ; Save Template String pointer
    
    ; Dry-run scan of the template to determine instruction length (1, 2, or 3 bytes)
    MVI D, 1            ; Default Length = 1
DPL_LEN_LOOP:
    MOV A, M
    ORA A
    JZ DPL_LEN_DONE
    INX H
    CPI 0x86            ; Token 0x86 means 8-bit operand (Length = 2)
    JNZ DPL_LEN_NOT_2
    MVI D, 2
    JMP DPL_LEN_LOOP
DPL_LEN_NOT_2:
    CPI 0x87            ; Token 0x87 means 16-bit operand (Length = 3)
    JNZ DPL_LEN_LOOP
    MVI D, 3
    JMP DPL_LEN_LOOP
DPL_LEN_DONE:
    
    ; Print the raw bytes padded to exact alignment (e.g. "C3 10 30   ")
    LHLD VAR_DISASM_PTR
    MOV E, D            ; E = length
    MVI A, 3            ; Max padding columns
    SUB E
    MOV B, A            ; B = padding required
DPL_RAW_LOOP:
    MOV A, M
    CALL PRINT_HEX_BYTE
    CALL PRINT_SPACE
    INX H
    DCR E
    JNZ DPL_RAW_LOOP
    
    MOV A, B
    ORA A
    JZ DPL_PAD_DONE
DPL_PAD_LOOP:
    CALL PRINT_SPACE
    CALL PRINT_SPACE
    CALL PRINT_SPACE
    DCR B
    JNZ DPL_PAD_LOOP
DPL_PAD_DONE:
    CALL PRINT_SPACE
    
    POP D               ; D = Template String
    LHLD VAR_DISASM_PTR
    MOV C, M            ; C = opcode (for extracting tokens)
    INX H               ; HL = next byte (for extracting d8/d16)
    
DPL_PARSE_LOOP:
    LDAX D
    ORA A
    JZ DPL_LINE_DONE
    INX D
    
    CPI 0x80
    JC DPL_PRINT_LITERAL
    
    ; Evaluate Formatting Tokens
    CPI 0x81
    JZ DPL_TOK_R1
    CPI 0x82
    JZ DPL_TOK_R2
    CPI 0x83
    JZ DPL_TOK_RP
    CPI 0x84
    JZ DPL_TOK_RP2
    CPI 0x85
    JZ DPL_TOK_CC
    CPI 0x86
    JZ DPL_TOK_D8
    CPI 0x87
    JZ DPL_TOK_D16
    CPI 0x88
    JZ DPL_TOK_RST
    
DPL_PRINT_LITERAL:
    CALL PRINT_CHAR
    JMP DPL_PARSE_LOOP
    
DPL_TOK_R1:
    MOV A, C
    RRC
    RRC
    RRC
    ANI 0x07
    CALL PRINT_REG_NAME
    JMP DPL_PARSE_LOOP
    
DPL_TOK_R2:
    MOV A, C
    ANI 0x07
    CALL PRINT_REG_NAME
    JMP DPL_PARSE_LOOP
    
DPL_TOK_RP:
    MOV A, C
    RRC
    RRC
    RRC
    RRC
    ANI 0x03
    CALL PRINT_RP_NAME
    JMP DPL_PARSE_LOOP
    
DPL_TOK_RP2:
    MOV A, C
    RRC
    RRC
    RRC
    RRC
    ANI 0x03
    CALL PRINT_RP2_NAME
    JMP DPL_PARSE_LOOP
    
DPL_TOK_CC:
    MOV A, C
    RRC
    RRC
    RRC
    ANI 0x07
    CALL PRINT_CC_NAME
    JMP DPL_PARSE_LOOP
    
DPL_TOK_D8:
    MOV A, M
    CALL PRINT_HEX_BYTE
    MVI A, 'H'
    CALL PRINT_CHAR
    INX H
    JMP DPL_PARSE_LOOP
    
DPL_TOK_D16:
    ; 8080 is Little-Endian. Print High Byte first, then Low Byte.
    INX H
    MOV A, M
    CALL PRINT_HEX_BYTE
    DCX H
    MOV A, M
    CALL PRINT_HEX_BYTE
    MVI A, 'H'
    CALL PRINT_CHAR
    INX H
    INX H
    JMP DPL_PARSE_LOOP
    
DPL_TOK_RST:
    MOV A, C
    RRC
    RRC
    RRC
    ANI 0x07
    ADI '0'
    CALL PRINT_CHAR
    JMP DPL_PARSE_LOOP
    
DPL_LINE_DONE:
    CALL NEW_LINE
    RET

; --- Disassembler Subroutines ---
GET_TEMPLATE:
    LXI H, TEMPLATES
    MOV B, A
    ORA A
    JZ GT_DONE
GT_LOOP:
    MOV A, M
    INX H
    ORA A
    JNZ GT_LOOP
    DCR B
    JNZ GT_LOOP
GT_DONE:
    RET

PRINT_REG_NAME:
    PUSH H
    PUSH D
    LXI H, DISASM_REG
    MOV E, A
    MVI D, 0
    DAD D
    MOV A, M
    CALL PRINT_CHAR
    POP D
    POP H
    RET
    
PRINT_RP_NAME:
    PUSH H
    PUSH D
    LXI H, DISASM_RP
    MOV E, A
    MVI D, 0
    DAD D
    MOV A, M
    CALL PRINT_CHAR
    CPI 'S'
    JNZ PRPN_DONE
    MVI A, 'P'
    CALL PRINT_CHAR
PRPN_DONE:
    POP D
    POP H
    RET
    
PRINT_RP2_NAME:
    PUSH H
    PUSH D
    LXI H, DISASM_RP2
    MOV E, A
    MVI D, 0
    DAD D
    MOV A, M
    CALL PRINT_CHAR
    CPI 'P'
    JNZ PRP2_DONE
    MVI A, 'S'
    CALL PRINT_CHAR
    MVI A, 'W'
    CALL PRINT_CHAR
PRP2_DONE:
    POP D
    POP H
    RET
    
PRINT_CC_NAME:
    PUSH H
    PUSH D
    LXI H, DISASM_CC
    ADD A          ; A = A * 2
    MOV E, A
    MVI D, 0
    DAD D
    MOV A, M
    CALL PRINT_CHAR
    INX H
    MOV A, M
    CPI ' '
    JZ PCCN_DONE
    CALL PRINT_CHAR
PCCN_DONE:
    POP D
    POP H
    RET

; ---------------------------------------------------------
; Subroutine: READ_LINE
; Reads a line of text into VAR_INPUT_BUF, handles backspace/echo
; ---------------------------------------------------------
READ_LINE:
    ; Flush any stale keystrokes (like Enter release from previous commands)
RL_FLUSH:
    IN 0x01
    ANI 0x01
    JZ RL_FLUSH_DONE
    IN 0x00
    JMP RL_FLUSH
RL_FLUSH_DONE:
    
    ; Reset Keyboard State
    XRA A
    STA VAR_KB_STATE
    
    ; Clear Input Buffer Length
    STA VAR_INPUT_LEN
RL_LOOP:
    CALL GET_KEY        ; Wait for key, return ASCII in A
    
    CPI 0x0D            ; Is it Enter?
    JZ RL_ENTER
    
    CPI 0x08            ; Is it Backspace?
    JZ RL_BS
    
    CPI 0x20            ; Is it Printable? (< 0x20 are control chars)
    JC RL_LOOP
    CPI 0x7F            ; DEL or higher are non-printable
    JNC RL_LOOP
    
    ; --- Handle Printable Character ---
    MOV B, A            ; Save character
    
    ; Check if buffer is full (max 60 chars to leave margin)
    LDA VAR_INPUT_LEN
    CPI 60
    JNC RL_LOOP         ; If full, ignore
    
    ; Store character in buffer
    MOV E, A            ; E = length
    MVI D, 0            ; DE = length
    LXI H, VAR_INPUT_BUF
    DAD D               ; HL = VAR_INPUT_BUF + length
    MOV M, B            ; Store char
    
    ; Increment length
    LDA VAR_INPUT_LEN
    INR A
    STA VAR_INPUT_LEN
    
    ; Echo to screen
    MOV A, B
    CALL PRINT_CHAR
    JMP RL_LOOP

RL_BS:
    LDA VAR_INPUT_LEN
    ORA A               ; Is length 0?
    JZ RL_LOOP          ; Yes, do nothing
    
    DCR A               ; Decrease length
    STA VAR_INPUT_LEN
    
    CALL BACKSPACE      ; Move cursor back and erase
    JMP RL_LOOP

RL_ENTER:
    ; Null-terminate the buffer
    LDA VAR_INPUT_LEN
    MOV E, A
    MVI D, 0
    LXI H, VAR_INPUT_BUF
    DAD D
    MVI M, 0
    CALL NEW_LINE
    RET

; ---------------------------------------------------------
; Subroutine: GET_KEY
; Blocks until a valid MAKE code is pressed. Returns ASCII in A.
; ---------------------------------------------------------
GET_KEY:
GK_WAIT:
    ; Check if Keyboard is Ready (Bit 0 of Port 0x01)
    IN 0x01
    ANI 0x01
    JZ GK_WAIT
    
    ; Read Scan Code from Port 0x00
    IN 0x00
    
    CPI 0xE0            ; Ignore extended prefix
    JZ GK_WAIT
    
    CPI 0xF0            ; Is it a Break code?
    JNZ GK_CHECK_STATE
    
    ; Mark state as "Break Sequence"
    MVI A, 1
    STA VAR_KB_STATE
    JMP GK_WAIT

GK_CHECK_STATE:
    MOV B, A            ; Save scan code
    LDA VAR_KB_STATE
    ORA A
    JZ GK_DECODE        ; If state is 0, normal MAKE code
    
    ; If state is 1, this is the trailing code of a Break sequence.
    ; Reset state to 0 and ignore.
    MVI A, 0
    STA VAR_KB_STATE
    JMP GK_WAIT

GK_DECODE:
    MOV A, B            ; Restore scan code
    CPI 0x80            ; Ensure it's < 128 to prevent table overflow
    JNC GK_WAIT
    
    ; Look up ASCII character
    LXI H, SCAN_TO_ASCII
    MOV E, A
    MVI D, 0
    DAD D               ; HL = SCAN_TO_ASCII + Scan Code
    MOV A, M            ; Load ASCII value
    
    ORA A               ; Is it mapped to 0 (unknown)?
    JZ GK_WAIT
    
    RET                 ; Valid ASCII in A!

; ---------------------------------------------------------
; Subroutines: UART Serial I/O
; TX_BUSY is Bit 0 of Port 0x03. RX_READY is Bit 1 of Port 0x03.
; ---------------------------------------------------------
UART_RECV_BYTE:
    IN 0x03
    ANI 0x02            ; Check if RX_READY (Bit 1) is high
    JZ UART_RECV_BYTE   ; Block until a byte arrives
    IN 0x02             ; Read byte (this automatically clears the ready flag in hardware)
    RET

UART_SEND_BYTE:
    PUSH PSW
USB_WAIT:
    IN 0x03
    ANI 0x01            ; Check if TX_BUSY (Bit 0) is high
    JNZ USB_WAIT        ; Block while UART is transmitting
    POP PSW
    OUT 0x02            ; Transmit byte
    RET

; ---------------------------------------------------------
; String and Hex Utility Subroutines
; ---------------------------------------------------------
PRINT_SPACE:
    PUSH PSW
    MVI A, ' '
    CALL PRINT_CHAR
    POP PSW
    RET

PRINT_HEX_BYTE:
    PUSH PSW
    RRC
    RRC
    RRC
    RRC
    CALL PRINT_HEX_NIBBLE
    POP PSW
    CALL PRINT_HEX_NIBBLE
    RET

PRINT_HEX_NIBBLE:
    PUSH PSW
    ANI 0x0F
    CPI 10
    JC PHN_DIGIT
    ADI 7           ; Offset for 'A'-'F'
PHN_DIGIT:
    ADI 0x30        ; ASCII '0'
    CALL PRINT_CHAR
    POP PSW
    RET

SKIP_SPACES:
    MOV A, M
    CPI ' '
    RNZ
    INX H
    JMP SKIP_SPACES

PARSE_HEX_BYTE:
    ; Reads 2 hex chars from [HL], returns byte in A. Sets Carry if invalid.
    MOV A, M
    CALL PARSE_HEX_NIBBLE
    JC PHB_ERROR
    RLC
    RLC
    RLC
    RLC
    MOV B, A
    INX H
    MOV A, M
    CALL PARSE_HEX_NIBBLE
    JC PHB_ERROR
    ORA B
    RET
PHB_ERROR:
    STC
    RET

PARSE_HEX_WORD:
    ; Reads 4 hex chars from [HL], returns word in HL. Sets Carry if invalid.
    PUSH B
    PUSH D
    MVI D, 0
    MVI E, 0
    MVI B, 4        ; 4 digits
PHW_LOOP:
    MOV A, M
    CALL PARSE_HEX_NIBBLE
    JC PHW_ERROR
    
    PUSH H          ; Save pointer
    MOV H, D        ; Shift DE left by 4
    MOV L, E
    DAD H
    DAD H
    DAD H
    DAD H
    MOV D, H
    MOV E, L
    POP H           ; Restore pointer
    
    ORA E           ; Add new nibble to E
    MOV E, A
    
    INX H           ; Next char
    DCR B
    JNZ PHW_LOOP
    
    MOV H, D        ; Move result to HL
    MOV L, E
    ORA A           ; Clear carry (success)
    POP D
    POP B
    RET
PHW_ERROR:
    STC             ; Set carry (error)
    POP D
    POP B
    RET

PARSE_HEX_NIBBLE:
    CPI '0'
    JC PHN_ERR
    CPI '9' + 1
    JC PHN_NUM
    CPI 'A'
    JC PHN_ERR
    CPI 'F' + 1
    JNC PHN_ERR
    SUI 55          ; 'A' (65) - 55 = 10
    ORA A
    RET
PHN_NUM:
    SUI '0'
    ORA A
    RET
PHN_ERR:
    STC
    RET

; ---------------------------------------------------------
; Subroutine: BACKSPACE
; Destructively moves the cursor back one space
; ---------------------------------------------------------
BACKSPACE:
    ; First, check if X is 0 and Y is 0 (safeguard)
    LDA VAR_CURSOR_Y
    MOV B, A
    LDA VAR_CURSOR_X
    ORA B
    JZ BS_DONE
    
    ; Check if X == 0
    LDA VAR_CURSOR_X
    ORA A
    JNZ BS_DEC_X
    
    ; Wrap X to 63, Decrement Y
    MVI A, 63
    STA VAR_CURSOR_X
    LDA VAR_CURSOR_Y
    DCR A
    STA VAR_CURSOR_Y
    JMP BS_UPDATE_PTR
    
BS_DEC_X:
    DCR A
    STA VAR_CURSOR_X
    
BS_UPDATE_PTR:
    ; Move Video RAM Pointer Back
    LHLD VAR_CURSOR_PTR
    DCX H
    SHLD VAR_CURSOR_PTR
    
    ; Erase the character at the new position
    MVI M, 0x20
    CALL SYNC_CURSOR
    
BS_DONE:
    RET

; ---------------------------------------------------------
; Subroutine: CLEAR_SCREEN
; Fills the 80x30 Text RAM with spaces (0x20)
; ---------------------------------------------------------
CLEAR_SCREEN:
    LXI H, 0xA000
    LXI B, 1920         ; 64 columns * 30 rows = 1920 bytes
CS_LOOP:
    MVI M, 0x20         ; Space character
    INX H
    DCX B
    MOV A, B
    ORA C
    JNZ CS_LOOP
    
    ; Reset Cursor Variables to top-left (Home)
    MVI A, 0
    STA VAR_CURSOR_X
    STA VAR_CURSOR_Y
    LXI H, 0xA000
    SHLD VAR_CURSOR_PTR
    CALL SYNC_CURSOR
    RET

; ---------------------------------------------------------
; Subroutine: PRINT_CHAR
; Prints the character in Accumulator and advances cursor
; ---------------------------------------------------------
PRINT_CHAR:
    PUSH H
    PUSH PSW
    
    ; Write Character to Text RAM
    LHLD VAR_CURSOR_PTR
    MOV M, A
    
    ; Advance Pointer
    INX H
    SHLD VAR_CURSOR_PTR
    
    ; Advance X Coordinate
    LDA VAR_CURSOR_X
    INR A
    CPI 64              ; Check if we hit the end of the line (64 cols)
    JC PC_NO_WRAP
    
    ; Handle Line Wrap
    CALL NEW_LINE
    JMP PC_DONE
    
PC_NO_WRAP:
    STA VAR_CURSOR_X
    CALL SYNC_CURSOR
    
PC_DONE:
    POP PSW
    POP H
    RET

; ---------------------------------------------------------
; Subroutine: NEW_LINE
; Moves the cursor to the beginning of the next line
; ---------------------------------------------------------
NEW_LINE:
    PUSH H
    PUSH D
    PUSH B
    PUSH PSW
    
    ; X = 0
    MVI A, 0
    STA VAR_CURSOR_X
    
    ; Y = Y + 1
    LDA VAR_CURSOR_Y
    INR A
    CPI 30              ; Check if we hit the bottom of the screen
    JC NL_NO_WRAP
    
    ; --- Scroll Screen Up ---
    LXI H, 0xA040       ; Source (Row 1)
    LXI D, 0xA000       ; Destination (Row 0)
    LXI B, 1856         ; 64 * 29 = 1856 bytes
NL_SCROLL_LOOP:
    MOV A, M
    STAX D
    INX H
    INX D
    DCX B
    MOV A, B
    ORA C
    JNZ NL_SCROLL_LOOP
    
    ; --- Clear Bottom Row ---
    ; DE now points to 0xA740 (Start of Row 29)
    LXI B, 64           ; 64 columns
NL_CLEAR_LOOP:
    MVI A, 0x20         ; Space character
    STAX D
    INX D
    DCX B
    MOV A, B
    ORA C
    JNZ NL_CLEAR_LOOP
    
    MVI A, 29           ; Keep cursor on row 29
NL_NO_WRAP:
    STA VAR_CURSOR_Y
    
    ; Calculate Memory Pointer: 0xA000 + (Y * 64)
    MOV L, A
    MVI H, 0
    DAD H               ; HL = Y * 2
    DAD H               ; HL = Y * 4
    DAD H               ; HL = Y * 8
    DAD H               ; HL = Y * 16
    DAD H               ; HL = Y * 32
    DAD H               ; HL = Y * 64
    LXI D, 0xA000
    DAD D               ; HL = 0xA000 + Y * 64
    SHLD VAR_CURSOR_PTR
    
    CALL SYNC_CURSOR
    
    POP PSW
    POP B
    POP D
    POP H
    RET

; ---------------------------------------------------------
; Subroutine: SYNC_CURSOR
; Writes X and Y variables to the Hardware VGA Registers
; ---------------------------------------------------------
SYNC_CURSOR:
    PUSH PSW
    LDA VAR_CURSOR_X
    STA 0xC003          ; Cursor X Register
    LDA VAR_CURSOR_Y
    STA 0xC004          ; Cursor Y Register
    POP PSW
    RET

; ---------------------------------------------------------
; PS/2 Scan Code to ASCII Lookup Table (Set 2)
; Maps 0x00 - 0x7F (Uppercase standard)
; ---------------------------------------------------------
SCAN_TO_ASCII:
    DB  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x60, 0x00 ; 00-0F
    DB  0x00, 0x00, 0x00, 0x00, 0x00, 0x51, 0x31, 0x00, 0x00, 0x00, 0x5A, 0x53, 0x41, 0x57, 0x32, 0x00 ; 10-1F
    DB  0x00, 0x43, 0x58, 0x44, 0x45, 0x34, 0x33, 0x00, 0x00, 0x20, 0x56, 0x46, 0x54, 0x52, 0x35, 0x00 ; 20-2F
    DB  0x00, 0x4E, 0x42, 0x48, 0x47, 0x59, 0x36, 0x00, 0x00, 0x00, 0x4D, 0x4A, 0x55, 0x37, 0x38, 0x00 ; 30-3F
    DB  0x00, 0x2C, 0x4B, 0x49, 0x4F, 0x30, 0x39, 0x00, 0x00, 0x2E, 0x2F, 0x4C, 0x3B, 0x50, 0x2D, 0x00 ; 40-4F
    DB  0x00, 0x00, 0x27, 0x00, 0x5B, 0x3D, 0x00, 0x00, 0x00, 0x00, 0x0D, 0x5D, 0x00, 0x5C, 0x00, 0x00 ; 50-5F
    DB  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; 60-6F
    DB  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; 70-7F

; ---------------------------------------------------------
; Text Constants
; ---------------------------------------------------------
REG_NAMES:
    DB "AFBCDEHLSPPC", 0

; ---------------------------------------------------------
; Disassembler Constants and Tables
; ---------------------------------------------------------
DISASM_REG: DB "BCDEHLMA"
DISASM_RP:  DB "BDHS"
DISASM_RP2: DB "BDHP"
DISASM_CC:  DB "NZZ NCCCPOPEP M "

DISASM_MAP:
    DB 0x00, 0x03, 0x05, 0x06, 0x09, 0x0A, 0x02, 0x1B, 0x39, 0x08, 0x04, 0x07, 0x09, 0x0A, 0x02, 0x1C
    DB 0x39, 0x03, 0x05, 0x06, 0x09, 0x0A, 0x02, 0x1D, 0x39, 0x08, 0x04, 0x07, 0x09, 0x0A, 0x02, 0x1E
    DB 0x39, 0x03, 0x2D, 0x06, 0x09, 0x0A, 0x02, 0x1F, 0x39, 0x08, 0x2E, 0x07, 0x09, 0x0A, 0x02, 0x20
    DB 0x39, 0x03, 0x2F, 0x06, 0x09, 0x0A, 0x02, 0x21, 0x39, 0x08, 0x30, 0x07, 0x09, 0x0A, 0x02, 0x22
    DB 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
    DB 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
    DB 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
    DB 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x23, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
    DB 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0B, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C
    DB 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0D, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E, 0x0E
    DB 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
    DB 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12, 0x12
    DB 0x29, 0x2C, 0x25, 0x24, 0x27, 0x2B, 0x13, 0x2A, 0x29, 0x28, 0x25, 0x39, 0x27, 0x26, 0x14, 0x2A
    DB 0x29, 0x2C, 0x25, 0x32, 0x27, 0x2B, 0x15, 0x2A, 0x29, 0x39, 0x25, 0x31, 0x27, 0x39, 0x16, 0x2A
    DB 0x29, 0x2C, 0x25, 0x34, 0x27, 0x2B, 0x17, 0x2A, 0x29, 0x36, 0x25, 0x33, 0x27, 0x39, 0x18, 0x2A
    DB 0x29, 0x2C, 0x25, 0x37, 0x27, 0x2B, 0x19, 0x2A, 0x29, 0x35, 0x25, 0x38, 0x27, 0x39, 0x1A, 0x2A
    
TEMPLATES:
    DB "NOP",0                          ; 00
    DB "MOV ", 0x81, ",", 0x82, 0       ; 01
    DB "MVI ", 0x81, ",", 0x86, 0       ; 02
    DB "LXI ", 0x83, ",", 0x87, 0       ; 03
    DB "LDAX ", 0x83, 0                 ; 04
    DB "STAX ", 0x83, 0                 ; 05
    DB "INX ", 0x83, 0                  ; 06
    DB "DCX ", 0x83, 0                  ; 07
    DB "DAD ", 0x83, 0                  ; 08
    DB "INR ", 0x81, 0                  ; 09
    DB "DCR ", 0x81, 0                  ; 0A
    DB "ADD ", 0x82, 0                  ; 0B
    DB "ADC ", 0x82, 0                  ; 0C
    DB "SUB ", 0x82, 0                  ; 0D
    DB "SBB ", 0x82, 0                  ; 0E
    DB "ANA ", 0x82, 0                  ; 0F
    DB "XRA ", 0x82, 0                  ; 10
    DB "ORA ", 0x82, 0                  ; 11
    DB "CMP ", 0x82, 0                  ; 12
    DB "ADI ", 0x86, 0                  ; 13
    DB "ACI ", 0x86, 0                  ; 14
    DB "SUI ", 0x86, 0                  ; 15
    DB "SBI ", 0x86, 0                  ; 16
    DB "ANI ", 0x86, 0                  ; 17
    DB "XRI ", 0x86, 0                  ; 18
    DB "ORI ", 0x86, 0                  ; 19
    DB "CPI ", 0x86, 0                  ; 1A
    DB "RLC", 0                         ; 1B
    DB "RRC", 0                         ; 1C
    DB "RAL", 0                         ; 1D
    DB "RAR", 0                         ; 1E
    DB "DAA", 0                         ; 1F
    DB "CMA", 0                         ; 20
    DB "STC", 0                         ; 21
    DB "CMC", 0                         ; 22
    DB "HLT", 0                         ; 23
    DB "JMP ", 0x87, 0                  ; 24
    DB "J", 0x85, " ", 0x87, 0          ; 25
    DB "CALL ", 0x87, 0                 ; 26
    DB "C", 0x85, " ", 0x87, 0          ; 27
    DB "RET", 0                         ; 28
    DB "R", 0x85, 0                     ; 29
    DB "RST ", 0x88, 0                  ; 2A
    DB "PUSH ", 0x84, 0                 ; 2B
    DB "POP ", 0x84, 0                  ; 2C
    DB "SHLD ", 0x87, 0                 ; 2D
    DB "LHLD ", 0x87, 0                 ; 2E
    DB "STA ", 0x87, 0                  ; 2F
    DB "LDA ", 0x87, 0                  ; 30
    DB "IN ", 0x86, 0                   ; 31
    DB "OUT ", 0x86, 0                  ; 32
    DB "XCHG", 0                        ; 33
    DB "XTHL", 0                        ; 34
    DB "SPHL", 0                        ; 35
    DB "PCHL", 0                        ; 36
    DB "DI", 0                          ; 37
    DB "EI", 0                          ; 38
    DB "???", 0                         ; 39