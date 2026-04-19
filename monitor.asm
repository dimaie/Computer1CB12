; =========================================================================
; SAP-3 System Monitor - Iteration 2
; - Keyboard PS/2 Scan Code Decoding
; - Line Buffering
; - Echoing and Backspace Support
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

; ---------------------------------------------------------
; Main Program
; ---------------------------------------------------------
ORG 0x0010
START:
    LXI SP, 0x3FFF      ; Initialize Stack Pointer
    
    CALL CLEAR_SCREEN
    
    ; Initialize Cursor Variables
    MVI A, 0
    STA VAR_CURSOR_X
    STA VAR_CURSOR_Y
    LXI H, 0xA000
    SHLD VAR_CURSOR_PTR
    
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
    
    ; Clear Input Buffer Length
    MVI A, 0
    STA VAR_INPUT_LEN

INPUT_LOOP:
    CALL GET_KEY        ; Wait for key, return ASCII in A
    
    CPI 0x0D            ; Is it Enter?
    JZ HANDLE_ENTER
    
    CPI 0x08            ; Is it Backspace?
    JZ HANDLE_BS
    
    CPI 0x20            ; Is it Printable? (< 0x20 are control chars)
    JC INPUT_LOOP
    CPI 0x7F            ; DEL or higher are non-printable
    JNC INPUT_LOOP
    
    ; --- Handle Printable Character ---
    MOV B, A            ; Save character
    
    ; Check if buffer is full (max 60 chars to leave margin)
    LDA VAR_INPUT_LEN
    CPI 60
    JNC INPUT_LOOP      ; If full, ignore
    
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
    JMP INPUT_LOOP

HANDLE_BS:
    LDA VAR_INPUT_LEN
    ORA A               ; Is length 0?
    JZ INPUT_LOOP       ; Yes, do nothing (protects the prompt from deletion)
    
    DCR A               ; Decrease length
    STA VAR_INPUT_LEN
    
    CALL BACKSPACE      ; Move cursor back and erase
    JMP INPUT_LOOP

HANDLE_ENTER:
    CALL NEW_LINE
    ; For now, just print "?" to simulate unknown command, then loop
    MVI A, '?'
    CALL PRINT_CHAR
    CALL NEW_LINE
    JMP MAIN_LOOP

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