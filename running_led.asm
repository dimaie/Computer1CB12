; =========================================================================
; SAP-3 Running LED Pattern
; Outputs a rotating bit across the 8 LEDs on Port 0x00
; =========================================================================

    ORG 0000h
    LXI SP, 3FFFh       ; Initialize Stack Pointer
    
    MVI A, 01h          ; Start with LED 0 turned on
    
Main_Loop:
    OUT 00h             ; Output Accumulator to LEDs
    RLC                 ; Rotate Accumulator Left (Shift LED)
    CALL Delay          ; Wait so the human eye can see it
    JMP Main_Loop       ; Repeat forever

; =========================================================================
; Delay Subroutine
; =========================================================================
Delay:
    PUSH PSW            ; Save Accumulator (LED state) and Flags
    PUSH B              ; Save BC
    LXI B, 0FFFFh       ; Load 65535 into BC for a long countdown
Delay_Loop:
    DCX B               ; Decrement BC
    MOV A, B
    ORA C               ; Check if BC == 0
    JNZ Delay_Loop      ; If not 0, keep looping
    POP B               ; Restore BC
    POP PSW             ; Restore Accumulator and Flags
    RET