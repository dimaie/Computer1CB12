; =========================================================================
; SAP-3 Mouse Drawing Program
; Draws pixels on the VGA Graphics Layer (320x240) using the mouse.
; =========================================================================

GFX_RAM   EQU 4000h
MOUSE_X_L EQU 04h
MOUSE_X_H EQU 05h
MOUSE_Y_L EQU 06h
MOUSE_Y_H EQU 07h
MOUSE_BTN EQU 08h
CUR_X     EQU 0C003h
CUR_Y     EQU 0C004h

    ORG 3000h
    LXI SP, 3FFFh

    ; 1. Clear Graphics RAM (4000h to 657Fh = 9600 bytes = 2580h)
    LXI H, GFX_RAM
    LXI D, 9600
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
    MOV C, A      ; BC = Mouse X (0-319)
    
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
    ANI 01h       ; Check Left Button (Bit 0)
    JZ Main_Loop  ; If not pressed, jump back to top

    ; --- Draw Pixel ---
    ; Calculate: HL = (Y * 40)
    MOV L, D
    MVI H, 0      ; HL = Y
    DAD H         ; Y * 2
    DAD H         ; Y * 4
    DAD H         ; Y * 8
    PUSH H        ; Save (Y * 8)
    DAD H         ; Y * 16
    DAD H         ; Y * 32
    POP D         ; DE = (Y * 8)
    DAD D         ; HL = (Y * 32) + (Y * 8) = Y * 40

    ; Calculate: BC = X / 8
    PUSH B        ; Save original X for the bitmask
    MOV A, B ! ORA A ! RAR ! MOV B, A ! MOV A, C ! RAR ! MOV C, A
    MOV A, B ! ORA A ! RAR ! MOV B, A ! MOV A, C ! RAR ! MOV C, A
    MOV A, B ! ORA A ! RAR ! MOV B, A ! MOV A, C ! RAR ! MOV C, A
    
    DAD B         ; HL = (Y * 40) + (X / 8)
    LXI D, GFX_RAM
    DAD D         ; HL now points to the exact byte in Video RAM!

    ; Calculate Bitmask
    POP B         ; Restore original X
    MOV A, C
    ANI 07h       ; A = X % 8
    LXI D, BitMasks
    ADD E ! MOV E, A ! MOV A, D ! ACI 00h ! MOV D, A ; DE = BitMasks + (X % 8)
    LDAX D        ; A = Specific Bit Mask

    ; Set the pixel
    ORA M         ; Read current byte from screen, OR with new bit
    MOV M, A      ; Write updated byte back to screen
    JMP Main_Loop

BitMasks:
    DB 80h, 40h, 20h, 10h, 08h, 04h, 02h, 01h