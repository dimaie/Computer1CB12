; Simple Horizontal Line Drawing for SAP-3 / Intel 8080
; Line from (100, 120) to (200, 120)

ORG 0x0000          ; Program ROM starts at 0x0000

JMP START

; Variable storage in Program RAM
ORG 0x2000
VAR_X:  DS 1

ORG 0x0010
START:
    LXI SP, 0x3FFF  ; Initialize Stack Pointer
    
    ; Initialize Video Colors
    MVI A, 0x1C     ; Ink color (Bright Green)
    STA 0xC001
    MVI A, 0x00     ; Background color (Black)
    STA 0xC002

    ; Setup loop for Horizontal Line (X from 100 to 200, Y = 120)
    MVI A, 100
    STA VAR_X

LOOP_START:
    ; Check if X > 200
    LDA VAR_X
    CPI 201
    JNC LOOP_END

    ; Prepare arguments for DRAW_PIXEL
    ; BC = X (16-bit)
    MOV C, A
    MVI B, 0
    ; E = Y (8-bit) = 120
    MVI E, 120
    
    CALL DRAW_PIXEL
    
    ; X++
    LDA VAR_X
    INR A
    STA VAR_X
    
    JMP LOOP_START

LOOP_END:
    HLT

; ---------------------------------------------------------
; DRAW_PIXEL - Draws a single pixel at (X, Y)
; Inputs: BC = X (16-bit), E = Y (8-bit)
; ---------------------------------------------------------
DRAW_PIXEL:
    PUSH H
    PUSH D
    PUSH B
    PUSH PSW
    
    ; Calculate Y * 40 using shifts and adds
    MOV L, E
    MVI H, 0
    DAD H           ; HL = Y * 2
    DAD H           ; HL = Y * 4
    DAD H           ; HL = Y * 8
    MOV D, H
    MOV E, L        ; DE = Y * 8
    DAD H           ; HL = Y * 16
    DAD H           ; HL = Y * 32
    DAD D           ; HL = Y * 40
    
    ; Calculate X / 8 (shifts BC right 3 times securely)
    MOV A, B
    RRC
    RRC
    RRC
    ANI 0xE0
    MOV D, A
    MOV A, C
    RRC
    RRC
    RRC
    ANI 0x1F
    ORA D
    
    ; Add to HL to formulate full byte offset
    ADD L
    MOV L, A
    MOV A, H
    ACI 0x40        ; Add VRAM Base address (0x4000)
    MOV H, A        ; HL now points directly to the VRAM byte
    
    ; Calculate bit mask: 7 - (X % 8)
    MOV A, C
    ANI 0x07        ; A = X % 8
    JZ MASK_DONE_FAST
    MOV D, A        ; Loop counter
    MVI A, 0x80
MASK_LOOP:
    RRC
    DCR D
    JNZ MASK_LOOP
    JMP APPLY_MASK
    
MASK_DONE_FAST:
    MVI A, 0x80
    
APPLY_MASK:
    ORA M           ; Read from VRAM, OR with bit mask
    MOV M, A        ; Write back to VRAM
    
    POP PSW
    POP B
    POP D
    POP H
    RET