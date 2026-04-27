; =========================================================================
; SAP-3 Mouse Drawing Program
; Draws pixels on the VGA Graphics Layer (256x240) using the mouse.
; =========================================================================

GFX_RAM   EQU 4000h
MOUSE_X_L EQU 04h
MOUSE_X_H EQU 05h
MOUSE_Y_L EQU 06h
MOUSE_Y_H EQU 07h
MOUSE_BTN EQU 08h
CUR_X     EQU 0C003h
CUR_Y     EQU 0C004h
CUR_STYLE EQU 0C005h

    ORG 3000h
    LXI SP, 3FFFh

    ; Set Cursor Style to Full Block Solid (Non-Blinking)
    MVI A, 03h
    STA CUR_STYLE

    ; 1. Clear Graphics RAM (4000h to 5DFFh = 7680 bytes = 1E00h)
    LXI H, GFX_RAM
    LXI D, 7680
Clear_Gfx:
    MVI M, 00h
    INX H
    DCX D
    MOV A, D
    ORA E
    JNZ Clear_Gfx

Main_Loop:
    ; Read Mouse
    IN MOUSE_X_H
    MOV B, A
    IN MOUSE_X_L
    MOV C, A      ; BC = Mouse X (0-255)
    
    IN MOUSE_Y_L
    MOV D, A      ; D = Mouse Y (0-239)

    ; --- Update Hardware Text Cursor ---
    ; Cursor X = X / 4
    PUSH B
    MOV A, B ! ORA A ! RAR ! MOV B, A
    MOV A, C ! RAR ! MOV C, A
    MOV A, B ! ORA A ! RAR ! MOV B, A
    MOV A, C ! RAR ! MOV C, A
    MOV A, C
    STA CUR_X
    POP B

    ; Cursor Y = Y / 8
    MOV A, D
    RRC ! RRC ! RRC
    ANI 1Fh
    STA CUR_Y

    ; --- Check Mouse Button ---
    IN MOUSE_BTN
    ANI 03h       ; Check Left (Bit 0) and Right (Bit 1) Buttons
    JZ Main_Loop  ; If neither pressed, jump back to top
    PUSH PSW      ; Save button state to the stack

    ; --- Draw Pixel ---
    ; Calculate: HL = (Y * 32)
    MOV L, D
    MVI H, 0      ; HL = Y
    DAD H         ; Y * 2
    DAD H         ; Y * 4
    DAD H         ; Y * 8
    DAD H         ; Y * 16
    DAD H         ; Y * 32

    ; Calculate: BC = X / 8
    PUSH B        ; Save original X for the bitmask
    MOV A, B ! ORA A ! RAR ! MOV B, A ! MOV A, C ! RAR ! MOV C, A
    MOV A, B ! ORA A ! RAR ! MOV B, A ! MOV A, C ! RAR ! MOV C, A
    MOV A, B ! ORA A ! RAR ! MOV B, A ! MOV A, C ! RAR ! MOV C, A
    
    DAD B         ; HL = (Y * 32) + (X / 8)
    LXI D, GFX_RAM
    DAD D         ; HL now points to the exact byte in Video RAM!

    ; Calculate Bitmask
    POP B         ; Restore original X
    MOV A, C
    ANI 07h       ; A = X % 8
    LXI D, BitMasks
    ADD E ! MOV E, A ! MOV A, D ! ACI 00h ! MOV D, A ; DE = BitMasks + (X % 8)
    LDAX D        ; A = Specific Bit Mask

    ; Set or Clear the pixel
    MOV B, A      ; Save Mask in B
    POP PSW       ; Restore button state
    ANI 02h       ; Check Right Button (Bit 1)
    MOV A, B      ; Restore Mask to A
    JNZ Erase_Pixel

Draw_Pixel:
    ORA M         ; Read current byte from screen, OR with new bit
    MOV M, A      ; Write updated byte back to screen
    JMP Main_Loop

Erase_Pixel:
    CMA           ; Invert mask (e.g., 01000000b -> 10111111b)
    ANA M         ; AND with current byte to clear the bit
    MOV M, A      ; Write updated byte back to screen
    JMP Main_Loop

BitMasks:
    DB 80h, 40h, 20h, 10h, 08h, 04h, 02h, 01h