; =========================================================================
; SAP-3 Mouse Test Demo
; Polls Mouse ports and updates hardware cursor / button status
; =========================================================================

TXT_RAM   EQU 0A000h
KB_DATA   EQU 00h
KB_STATUS EQU 01h
UART_DATA   EQU 02h
UART_STATUS EQU 03h
MOUSE_X_L EQU 04h
MOUSE_X_H EQU 05h
MOUSE_Y_L EQU 06h
MOUSE_Y_H EQU 07h
MOUSE_BTN EQU 08h

CUR_X     EQU 0C003h
CUR_Y     EQU 0C004h
CUR_STYLE EQU 0C005h

    ORG 2000h
    LXI SP, 3FFFh
    
    ; Clear Text RAM
    LXI H, TXT_RAM
    LXI D, 2400
Clear_Txt:
    MVI M, 00h
    INX H
    DCX D
    MOV A, D
    ORA E
    JNZ Clear_Txt
    
    ; Set colors (Bright Green on Black)
    MVI A, 1Ch
    STA 0C001h
    MVI A, 00h
    STA 0C002h
    
    ; Enable hardware cursor (Full block style)
    MVI A, 02h
    STA CUR_STYLE
    
Poll_Loop:
    CALL Process_Mouse
    
    IN KB_STATUS
    ANI 01h
    JNZ Process_KB
    
    IN UART_STATUS
    ANI 02h         ; Check bit 1 (uart_ready)
    JNZ Process_UART
    
    JMP Poll_Loop
    
Process_Mouse:
    PUSH H
    PUSH B
    
    ; --- 1. Scale Mouse X (0-319) to Cursor X (0-79) ---
    IN MOUSE_X_H
    MOV B, A
    IN MOUSE_X_L
    MOV C, A
    
    ; Divide BC by 4 (Shift Right 2 times)
    MOV A, B ! ORA A ! RAR ! MOV B, A  ; Clear Carry, shift high byte
    MOV A, C ! RAR ! MOV C, A          ; Shift low byte bringing in carry
    MOV A, B ! ORA A ! RAR ! MOV B, A  ; Shift high byte again
    MOV A, C ! RAR ! MOV C, A          ; Shift low byte again
    
    MOV A, C
    STA CUR_X                          ; Update Hardware Cursor X
    
    ; --- 2. Scale Mouse Y (0-239) to Cursor Y (0-29) ---
    ; Y fits entirely within the lower 8 bits, so we can ignore the high byte
    IN MOUSE_Y_L
    
    ; Divide A by 8 (Shift Right 3 times)
    RRC ! RRC ! RRC
    ANI 1Fh                            ; Mask off the wrapped bits to 5 bits (max 31)
    STA CUR_Y                          ; Update Hardware Cursor Y
    
    ; --- 3. Display Mouse Button State ---
    IN MOUSE_BTN
    MOV B, A
    LXI H, TXT_RAM + 76                ; Point to top-right of the screen (Col 76)
    MVI M, 42h ! INX H                 ; Print 'B'
    MVI M, 3Ah ! INX H                 ; Print ':'
    MOV A, B ! ANI 07h ! CALL HexToChar ! MOV M, A ; Print Button Hex (0-7)
    
    POP B
    POP H
    RET

Process_KB:
    ; Discard keyboard data for this test to keep focus on mouse
    IN KB_DATA
    JMP Poll_Loop

Process_UART:
    ; Discard UART data for this test
    IN UART_DATA
    JMP Poll_Loop

HexToChar:
    CPI 0Ah
    JC IsDigit
    ADI 07h
IsDigit:
    ADI 30h
    RET