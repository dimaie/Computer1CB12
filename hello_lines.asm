; =========================================================================
; SAP-3 Test Program
; 1. Sets up Video Colors
; 2. Prints "HELLO WORLD" to the top right of the Text RAM
; 3. Draws a horizontal line across the Graphics RAM
; 4. Draws a vertical line down the Graphics RAM using Read-Modify-Write
; =========================================================================

; --- Hardware Addresses ---
VID_INK   EQU 0C001h
VID_BG    EQU 0C002h
TXT_RAM   EQU 0A000h
GFX_RAM   EQU 04000h

; =========================================================================
; 1. COLOR SETUP (Bright Green on Black)
; =========================================================================
    MVI A, 1Ch          ; Load Bright Green (1Ch)
    STA VID_INK         ; Store to Ink Color Register
    
    MVI A, 00h          ; Load Black (00h)
    STA VID_BG          ; Store to Background Color Register

; =========================================================================
; 2. PRINT STRING "HELLO WORLD"
; =========================================================================
    LXI D, String_Data  ; Pointer to String Data
    LXI H, 0A045h       ; Pointer to Top-Right of Text RAM (Row 0, Col 69)

Print_Loop:
    LDAX D              ; Load character into A
    CPI 00h             ; Check for Null terminator
    JZ Draw_HLine       ; If end of string, jump to graphics drawing
    
    MOV M, A            ; Store character into Video RAM
    INX D               ; Increment String pointer
    INX H               ; Increment Video RAM pointer
    JMP Print_Loop      ; Loop to next character

; =========================================================================
; 3. DRAW HORIZONTAL LINE (Y = 120)
; =========================================================================
Draw_HLine:
    LXI H, 052C0h       ; Start Address = GFX_RAM + (120 rows * 40 bytes)
    MVI B, 28h          ; 40 bytes to write (320 pixels total)
    MVI A, 0FFh         ; Solid 8-pixel block (11111111b)
    
HLine_Loop:
    MOV M, A            ; Write 8 pixels to memory
    INX H               ; Move to next byte
    DCR B               ; Decrement column counter
    JNZ HLine_Loop      ; Repeat for 40 bytes

; =========================================================================
; 4. DRAW VERTICAL LINE (X = 160) - WITH READ-MODIFY-WRITE
; =========================================================================
Draw_VLine:
    LXI H, 04014h       ; Start Address = GFX_RAM + 20 (byte offset for X=160)
    LXI D, 0028h        ; Row stride = 40 bytes per row
    MVI B, 0F0h         ; 240 rows to draw
    
VLine_Loop:
    MOV A, M            ; 1. READ existing pixels from Graphics RAM
    ORI 80h             ; 2. BITWISE OR the new pixel (10000000b)
    MOV M, A            ; 3. WRITE the blended byte back to memory
    
    DAD D               ; Move HL down by exactly one row (HL = HL + DE)
    DCR B               ; Decrement row counter
    JNZ VLine_Loop      ; Repeat for 240 rows

; =========================================================================
; 5. HALT
; =========================================================================
Halt:
    JMP Halt            ; Infinite loop to park processor safely

; =========================================================================
; 6. STRING DATA
; =========================================================================
String_Data:
    DB "HELLO WORLD", 00h