; =========================================================================
; SAP-3 System Monitor - Iteration 4
; - Keyboard PS/2 Scan Code Decoding
; - Line Buffering
; - Echoing and Backspace Support
; - Command Parser: Dxxxx (Dump Memory)
; - Command Parser: Mxxxx (Modify Memory)
; - Command Parser: Gxxxx (Go / Execute)
; - Command Parser: X     (Examine Registers)
; =========================================================================

ORG 0x0000
JMP START

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

; ---------------------------------------------------------
; Main Program
; ---------------------------------------------------------
ORG 0x0010
START:
    LXI SP, 0x3FFF      ; Initialize Stack Pointer
    
    ; Initialize User SP in VAR_REGS to 0x3FFF
    LXI H, 0x3FFF
    SHLD VAR_REGS + 8
    
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
    
    LXI H, MAIN_LOOP
    PUSH H              ; Push monitor return address onto user's stack
    
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

; ---------------------------------------------------------
; Subroutine: READ_LINE
; Reads a line of text into VAR_INPUT_BUF, handles backspace/echo
; ---------------------------------------------------------
READ_LINE:
    ; Clear Input Buffer Length
    MVI A, 0
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
    
    ; Wrap X to 79, Decrement Y
    MVI A, 79
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
    LXI B, 2400         ; 80 columns * 30 rows = 2400 bytes
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
    CPI 80              ; Check if we hit the end of the line (80 cols)
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
    PUSH PSW
    
    ; X = 0
    MVI A, 0
    STA VAR_CURSOR_X
    
    ; Y = Y + 1
    LDA VAR_CURSOR_Y
    INR A
    CPI 30              ; Check if we hit the bottom of the screen
    JC NL_NO_WRAP
    MVI A, 0            ; For now, just wrap back to the top of the screen
NL_NO_WRAP:
    STA VAR_CURSOR_Y
    
    ; Calculate Memory Pointer: 0xA000 + (Y * 80)
    MOV L, A
    MVI H, 0
    DAD H               ; HL = Y * 2
    DAD H               ; HL = Y * 4
    DAD H               ; HL = Y * 8
    DAD H               ; HL = Y * 16
    MOV E, L
    MOV D, H            ; DE = Y * 16
    DAD H               ; HL = Y * 32
    DAD H               ; HL = Y * 64
    DAD D               ; HL = Y * 80
    LXI D, 0xA000
    DAD D               ; HL = 0xA000 + Y * 80
    SHLD VAR_CURSOR_PTR
    
    CALL SYNC_CURSOR
    
    POP PSW
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