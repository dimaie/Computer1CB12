; Generated i8080 assembly code
; Compiled from C source

	ORG 2100H

	; Entry point
	LXI SP, STACK_TOP	; Initialize stack pointer
	CALL main
	HLT


abs:
	LHLD __VAR_abs_x	; Shadow stack push
	PUSH H
	; Load parameter x from hardware stack
	LXI H, 4
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_abs_x
	LHLD __VAR_abs_x
	PUSH H
	LXI H, 0
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L2
	LXI H, 0
	JMP L3
L2:
	LXI H, 1
L3:
	MOV A, H
	ORA L
	JZ L0
	LHLD __VAR_abs_x
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_abs_x
	XCHG	; Restore return value
	RET
	JMP L1
L0:
L1:
	LHLD __VAR_abs_x
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_abs_x
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_abs_x
	XCHG
	RET

; Local variables for abs
__VAR_abs_x:	DS 2	; variable

divide:
	LHLD __VAR_divide_res	; Shadow stack push
	PUSH H
	LHLD __VAR_divide_sign	; Shadow stack push
	PUSH H
	LHLD __VAR_divide_b	; Shadow stack push
	PUSH H
	LHLD __VAR_divide_a	; Shadow stack push
	PUSH H
	; Load parameter a from hardware stack
	LXI H, 10
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_divide_a
	; Load parameter b from hardware stack
	LXI H, 12
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_divide_b
	LXI H, 0
	SHLD __VAR_divide_sign
	LHLD __VAR_divide_a
	PUSH H
	LXI H, 0
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L6
	LXI H, 0
	JMP L7
L6:
	LXI H, 1
L7:
	MOV A, H
	ORA L
	JZ L4
	LHLD __VAR_divide_a
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	SHLD __VAR_divide_a
	LHLD __VAR_divide_sign
	PUSH H
	LXI H, 1
	POP D
	MOV A, E
	XRA L
	MOV L, A
	MOV A, D
	XRA H
	MOV H, A
	SHLD __VAR_divide_sign
	JMP L5
L4:
L5:
	LHLD __VAR_divide_b
	PUSH H
	LXI H, 0
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L10
	LXI H, 0
	JMP L11
L10:
	LXI H, 1
L11:
	MOV A, H
	ORA L
	JZ L8
	LHLD __VAR_divide_b
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	SHLD __VAR_divide_b
	LHLD __VAR_divide_sign
	PUSH H
	LXI H, 1
	POP D
	MOV A, E
	XRA L
	MOV L, A
	MOV A, D
	XRA H
	MOV H, A
	SHLD __VAR_divide_sign
	JMP L9
L8:
L9:
	LHLD __VAR_divide_a
	PUSH H
	LHLD __VAR_divide_b
	POP D
	CALL __div
	SHLD __VAR_divide_res
	LHLD __VAR_divide_sign
	MOV A, H
	ORA L
	JZ L12
	LHLD __VAR_divide_res
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_divide_a
	POP H		; Shadow stack pop
	SHLD __VAR_divide_b
	POP H		; Shadow stack pop
	SHLD __VAR_divide_sign
	POP H		; Shadow stack pop
	SHLD __VAR_divide_res
	XCHG	; Restore return value
	RET
	JMP L13
L12:
L13:
	LHLD __VAR_divide_res
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_divide_a
	POP H		; Shadow stack pop
	SHLD __VAR_divide_b
	POP H		; Shadow stack pop
	SHLD __VAR_divide_sign
	POP H		; Shadow stack pop
	SHLD __VAR_divide_res
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_divide_a
	POP H		; Shadow stack pop
	SHLD __VAR_divide_b
	POP H		; Shadow stack pop
	SHLD __VAR_divide_sign
	POP H		; Shadow stack pop
	SHLD __VAR_divide_res
	XCHG
	RET

; Local variables for divide
__VAR_divide_res:	DS 2	; variable
__VAR_divide_sign:	DS 2	; variable
__VAR_divide_b:	DS 2	; variable
__VAR_divide_a:	DS 2	; variable

clear_gfx_ram:
	LHLD __VAR_clear_gfx_ram_i	; Shadow stack push
	PUSH H
	LHLD __VAR_clear_gfx_ram_vram	; Shadow stack push
	PUSH H
	LXI H, 16384
	SHLD __VAR_clear_gfx_ram_vram
	LXI H, 0
	SHLD __VAR_clear_gfx_ram_i
L14:
	LHLD __VAR_clear_gfx_ram_i
	PUSH H
	LXI H, 4800
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L17
	LXI H, 0
	JMP L18
L17:
	LXI H, 1
L18:
	MOV A, H
	ORA L
	JZ L15
	LXI H, 0
	PUSH H
	LHLD __VAR_clear_gfx_ram_vram
	POP D
	MOV M, E
	INX H
	MOV M, D
	XCHG
	LHLD __VAR_clear_gfx_ram_vram
	PUSH H
	LXI H, 2
	POP D
	DAD D
	SHLD __VAR_clear_gfx_ram_vram
L16:
	LHLD __VAR_clear_gfx_ram_i
	PUSH H
	LXI H, 1
	POP D
	DAD D
	SHLD __VAR_clear_gfx_ram_i
	JMP L14
L15:
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_clear_gfx_ram_vram
	POP H		; Shadow stack pop
	SHLD __VAR_clear_gfx_ram_i
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_clear_gfx_ram_vram
	POP H		; Shadow stack pop
	SHLD __VAR_clear_gfx_ram_i
	XCHG
	RET

; Local variables for clear_gfx_ram
__VAR_clear_gfx_ram_i:	DS 2	; variable
__VAR_clear_gfx_ram_vram:	DS 2	; pointer

put_pixel:
	LHLD __VAR_put_pixel_mask	; Shadow stack push
	PUSH H
	LHLD __VAR_put_pixel_rem	; Shadow stack push
	PUSH H
	LHLD __VAR_put_pixel_vram_addr	; Shadow stack push
	PUSH H
	LHLD __VAR_put_pixel_color	; Shadow stack push
	PUSH H
	LHLD __VAR_put_pixel_y	; Shadow stack push
	PUSH H
	LHLD __VAR_put_pixel_x	; Shadow stack push
	PUSH H
	; Load parameter x from hardware stack
	LXI H, 14
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_put_pixel_x
	; Load parameter y from hardware stack
	LXI H, 16
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_put_pixel_y
	; Load parameter color from hardware stack
	LXI H, 18
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_put_pixel_color
	LHLD __VAR_put_pixel_x
	PUSH H
	LXI H, 0
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L21
	LXI H, 0
	JMP L22
L21:
	LXI H, 1
L22:
	MOV A, H
	ORA L
	JZ L19
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_x
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_y
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_color
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_vram_addr
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_rem
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_mask
	XCHG	; Restore return value
	RET
	JMP L20
L19:
L20:
	LHLD __VAR_put_pixel_x
	PUSH H
	LXI H, 320
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L25
	LXI H, 1
	JMP L26
L25:
	LXI H, 0
L26:
	MOV A, H
	ORA L
	JZ L23
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_x
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_y
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_color
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_vram_addr
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_rem
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_mask
	XCHG	; Restore return value
	RET
	JMP L24
L23:
L24:
	LHLD __VAR_put_pixel_y
	PUSH H
	LXI H, 0
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L29
	LXI H, 0
	JMP L30
L29:
	LXI H, 1
L30:
	MOV A, H
	ORA L
	JZ L27
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_x
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_y
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_color
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_vram_addr
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_rem
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_mask
	XCHG	; Restore return value
	RET
	JMP L28
L27:
L28:
	LHLD __VAR_put_pixel_y
	PUSH H
	LXI H, 240
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L33
	LXI H, 1
	JMP L34
L33:
	LXI H, 0
L34:
	MOV A, H
	ORA L
	JZ L31
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_x
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_y
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_color
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_vram_addr
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_rem
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_mask
	XCHG	; Restore return value
	RET
	JMP L32
L31:
L32:
	LXI H, 16384
	PUSH H
	LHLD __VAR_put_pixel_y
	PUSH H
	LXI H, 5
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L36
L35:
	DAD H
	DCR E
	JNZ L35
L36:
	POP D
	DAD D
	PUSH H
	LHLD __VAR_put_pixel_y
	PUSH H
	LXI H, 3
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L38
L37:
	DAD H
	DCR E
	JNZ L37
L38:
	POP D
	DAD D
	PUSH H
	LHLD __VAR_put_pixel_x
	PUSH H
	LXI H, 3
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L40
L39:
	MOV A, H
	RLC
	MOV A, H
	RAR
	MOV H, A
	MOV A, L
	RAR
	MOV L, A
	DCR E
	JNZ L39
L40:
	POP D
	DAD D
	SHLD __VAR_put_pixel_vram_addr
	LHLD __VAR_put_pixel_x
	PUSH H
	LXI H, 7
	POP D
	MOV A, E
	ANA L
	MOV L, A
	MOV A, D
	ANA H
	MOV H, A
	SHLD __VAR_put_pixel_rem
	LXI H, 128
	PUSH H
	LHLD __VAR_put_pixel_rem
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L42
L41:
	MOV A, H
	RLC
	MOV A, H
	RAR
	MOV H, A
	MOV A, L
	RAR
	MOV L, A
	DCR E
	JNZ L41
L42:
	SHLD __VAR_put_pixel_mask
	LHLD __VAR_put_pixel_color
	MOV A, H
	ORA L
	JZ L43
	LHLD __VAR_put_pixel_vram_addr
	MOV E, M
	INX H
	MOV D, M
	XCHG
	PUSH H
	LHLD __VAR_put_pixel_mask
	POP D
	MOV A, E
	ORA L
	MOV L, A
	MOV A, D
	ORA H
	MOV H, A
	PUSH H
	LHLD __VAR_put_pixel_vram_addr
	POP D
	MOV M, E
	INX H
	MOV M, D
	XCHG
	JMP L44
L43:
	LHLD __VAR_put_pixel_vram_addr
	MOV E, M
	INX H
	MOV D, M
	XCHG
	PUSH H
	LHLD __VAR_put_pixel_mask
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	POP D
	MOV A, E
	ANA L
	MOV L, A
	MOV A, D
	ANA H
	MOV H, A
	PUSH H
	LHLD __VAR_put_pixel_vram_addr
	POP D
	MOV M, E
	INX H
	MOV M, D
	XCHG
L44:
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_x
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_y
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_color
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_vram_addr
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_rem
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_mask
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_x
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_y
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_color
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_vram_addr
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_rem
	POP H		; Shadow stack pop
	SHLD __VAR_put_pixel_mask
	XCHG
	RET

; Local variables for put_pixel
__VAR_put_pixel_mask:	DS 2	; variable
__VAR_put_pixel_rem:	DS 2	; variable
__VAR_put_pixel_vram_addr:	DS 2	; pointer
__VAR_put_pixel_color:	DS 2	; variable
__VAR_put_pixel_y:	DS 2	; variable
__VAR_put_pixel_x:	DS 2	; variable

draw_line:
	LHLD __VAR_draw_line_done	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_e2	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_err	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_sy	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_sx	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_dy	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_dx	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_color	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_y1	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_x1	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_y0	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_line_x0	; Shadow stack push
	PUSH H
	; Load parameter x0 from hardware stack
	LXI H, 26
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_draw_line_x0
	; Load parameter y0 from hardware stack
	LXI H, 28
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_draw_line_y0
	; Load parameter x1 from hardware stack
	LXI H, 30
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_draw_line_x1
	; Load parameter y1 from hardware stack
	LXI H, 32
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_draw_line_y1
	; Load parameter color from hardware stack
	LXI H, 34
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_draw_line_color
	LHLD __VAR_draw_line_x1
	PUSH H
	LHLD __VAR_draw_line_x0
	POP D
	MOV A, E
	SUB L
	MOV L, A
	MOV A, D
	SBB H
	MOV H, A
	PUSH H
	CALL abs
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_line_dx
	LHLD __VAR_draw_line_y1
	PUSH H
	LHLD __VAR_draw_line_y0
	POP D
	MOV A, E
	SUB L
	MOV L, A
	MOV A, D
	SBB H
	MOV H, A
	PUSH H
	CALL abs
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_line_dy
	LXI H, 1
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	SHLD __VAR_draw_line_sx
	LXI H, 1
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	SHLD __VAR_draw_line_sy
	LXI H, 0
	SHLD __VAR_draw_line_done
	LHLD __VAR_draw_line_x0
	PUSH H
	LHLD __VAR_draw_line_x1
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L47
	LXI H, 0
	JMP L48
L47:
	LXI H, 1
L48:
	MOV A, H
	ORA L
	JZ L45
	LXI H, 1
	SHLD __VAR_draw_line_sx
	JMP L46
L45:
L46:
	LHLD __VAR_draw_line_y0
	PUSH H
	LHLD __VAR_draw_line_y1
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L51
	LXI H, 0
	JMP L52
L51:
	LXI H, 1
L52:
	MOV A, H
	ORA L
	JZ L49
	LXI H, 1
	SHLD __VAR_draw_line_sy
	JMP L50
L49:
L50:
	LHLD __VAR_draw_line_dx
	PUSH H
	LHLD __VAR_draw_line_dy
	POP D
	MOV A, E
	SUB L
	MOV L, A
	MOV A, D
	SBB H
	MOV H, A
	SHLD __VAR_draw_line_err
L53:
	LHLD __VAR_draw_line_done
	MOV A, H
	ORA L
	JNZ L55
	LXI H, 1
	JMP L56
L55:
	LXI H, 0
L56:
	MOV A, H
	ORA L
	JZ L54
	LHLD __VAR_draw_line_color
	PUSH H
	LHLD __VAR_draw_line_y0
	PUSH H
	LHLD __VAR_draw_line_x0
	PUSH H
	CALL put_pixel
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	LHLD __VAR_draw_line_x0
	PUSH H
	LHLD __VAR_draw_line_x1
	POP D
	MOV A, E
	CMP L
	JNZ L59
	MOV A, D
	CMP H
	JNZ L59
	LXI H, 1
	JMP L60
L59:
	LXI H, 0
L60:
	PUSH H
	LHLD __VAR_draw_line_y0
	PUSH H
	LHLD __VAR_draw_line_y1
	POP D
	MOV A, E
	CMP L
	JNZ L61
	MOV A, D
	CMP H
	JNZ L61
	LXI H, 1
	JMP L62
L61:
	LXI H, 0
L62:
	POP D
	MOV A, D
	ORA E
	JZ L63
	MOV A, H
	ORA L
	JZ L63
	LXI H, 1
	JMP L64
L63:
	LXI H, 0
L64:
	MOV A, H
	ORA L
	JZ L57
	LXI H, 1
	SHLD __VAR_draw_line_done
	JMP L58
L57:
L58:
	LHLD __VAR_draw_line_done
	MOV A, H
	ORA L
	JNZ L67
	LXI H, 1
	JMP L68
L67:
	LXI H, 0
L68:
	MOV A, H
	ORA L
	JZ L65
	LHLD __VAR_draw_line_err
	PUSH H
	LXI H, 1
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L70
L69:
	DAD H
	DCR E
	JNZ L69
L70:
	SHLD __VAR_draw_line_e2
	LHLD __VAR_draw_line_e2
	PUSH H
	LHLD __VAR_draw_line_dy
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	POP D
	MOV A, L
	SUB E
	MOV A, H
	SBB D
	JM L73
	LXI H, 0
	JMP L74
L73:
	LXI H, 1
L74:
	MOV A, H
	ORA L
	JZ L71
	LHLD __VAR_draw_line_err
	PUSH H
	LHLD __VAR_draw_line_dy
	POP D
	MOV A, E
	SUB L
	MOV L, A
	MOV A, D
	SBB H
	MOV H, A
	SHLD __VAR_draw_line_err
	LHLD __VAR_draw_line_x0
	PUSH H
	LHLD __VAR_draw_line_sx
	POP D
	DAD D
	SHLD __VAR_draw_line_x0
	JMP L72
L71:
L72:
	LHLD __VAR_draw_line_e2
	PUSH H
	LHLD __VAR_draw_line_dx
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L77
	LXI H, 0
	JMP L78
L77:
	LXI H, 1
L78:
	MOV A, H
	ORA L
	JZ L75
	LHLD __VAR_draw_line_err
	PUSH H
	LHLD __VAR_draw_line_dx
	POP D
	DAD D
	SHLD __VAR_draw_line_err
	LHLD __VAR_draw_line_y0
	PUSH H
	LHLD __VAR_draw_line_sy
	POP D
	DAD D
	SHLD __VAR_draw_line_y0
	JMP L76
L75:
L76:
	JMP L66
L65:
L66:
	JMP L53
L54:
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_x0
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_y0
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_x1
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_y1
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_color
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_dx
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_dy
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_sx
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_sy
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_err
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_e2
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_done
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_x0
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_y0
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_x1
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_y1
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_color
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_dx
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_dy
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_sx
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_sy
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_err
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_e2
	POP H		; Shadow stack pop
	SHLD __VAR_draw_line_done
	XCHG
	RET

; Local variables for draw_line
__VAR_draw_line_done:	DS 2	; variable
__VAR_draw_line_e2:	DS 2	; variable
__VAR_draw_line_err:	DS 2	; variable
__VAR_draw_line_sy:	DS 2	; variable
__VAR_draw_line_sx:	DS 2	; variable
__VAR_draw_line_dy:	DS 2	; variable
__VAR_draw_line_dx:	DS 2	; variable
__VAR_draw_line_color:	DS 2	; variable
__VAR_draw_line_y1:	DS 2	; variable
__VAR_draw_line_x1:	DS 2	; variable
__VAR_draw_line_y0:	DS 2	; variable
__VAR_draw_line_x0:	DS 2	; variable

get_sin:
	LHLD __VAR_get_sin_res	; Shadow stack push
	PUSH H
	LHLD __VAR_get_sin_a	; Shadow stack push
	PUSH H
	; Load parameter a from hardware stack
	LXI H, 6
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_get_sin_a
L79:
	LHLD __VAR_get_sin_a
	PUSH H
	LXI H, 0
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L81
	LXI H, 0
	JMP L82
L81:
	LXI H, 1
L82:
	MOV A, H
	ORA L
	JZ L80
	LHLD __VAR_get_sin_a
	PUSH H
	LXI H, 32
	POP D
	DAD D
	SHLD __VAR_get_sin_a
	JMP L79
L80:
L83:
	LHLD __VAR_get_sin_a
	PUSH H
	LXI H, 32
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L85
	LXI H, 1
	JMP L86
L85:
	LXI H, 0
L86:
	MOV A, H
	ORA L
	JZ L84
	LHLD __VAR_get_sin_a
	PUSH H
	LXI H, 32
	POP D
	MOV A, E
	SUB L
	MOV L, A
	MOV A, D
	SBB H
	MOV H, A
	SHLD __VAR_get_sin_a
	JMP L83
L84:
	; Inline assembly


        JMP SKIP_SIN_TABLE

    SIN_TABLE:

        DB 0, 20, 38, 56, 71, 83, 92, 98, 100, 98, 92, 83, 71, 56, 38, 20

        DB 0, 236, 218, 200, 185, 173, 164, 158, 156, 158, 164, 173, 185, 200, 218, 236

    SKIP_SIN_TABLE:

        LHLD __VAR_get_sin_a      ; Load 'a' into HL (0-31)

        LXI D, SIN_TABLE  ; Load table base address

        DAD D             ; HL = SIN_TABLE + a

        MOV L, M          ; Load the byte at that address

        MVI H, 0          ; Assume positive

        MOV A, L

        ANI 80H           ; Check sign bit

        JZ SIN_POS

        MVI H, 255        ; Sign-extend negative values

    SIN_POS:

        SHLD __VAR_get_sin_res    ; Store to C variable

    
	LHLD __VAR_get_sin_res
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_get_sin_a
	POP H		; Shadow stack pop
	SHLD __VAR_get_sin_res
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_get_sin_a
	POP H		; Shadow stack pop
	SHLD __VAR_get_sin_res
	XCHG
	RET

; Local variables for get_sin
__VAR_get_sin_res:	DS 2	; variable
__VAR_get_sin_a:	DS 2	; variable

get_cos:
	LHLD __VAR_get_cos_a	; Shadow stack push
	PUSH H
	; Load parameter a from hardware stack
	LXI H, 4
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_get_cos_a
	LHLD __VAR_get_cos_a
	PUSH H
	LXI H, 8
	POP D
	DAD D
	PUSH H
	CALL get_sin
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_get_cos_a
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_get_cos_a
	XCHG
	RET

; Local variables for get_cos
__VAR_get_cos_a:	DS 2	; variable

get_key:
	LHLD __VAR_get_key_key	; Shadow stack push
	PUSH H
	LXI H, 0
	SHLD __VAR_get_key_key
	; Inline assembly


        IN 01H                  ; Read keyboard status (Port 01H)

        ANI 01H                 ; Check Data Ready bit (Bit 0)

        JZ NO_KEY               ; If 0, no key is ready to be read

        

        IN 00H                  ; Read keyboard data (Port 00H)

        STA __VAR_get_key_key           ; Store to local C variable (compiler auto-prefixes function name)

        

    NO_KEY:

    
	LHLD __VAR_get_key_key
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_get_key_key
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_get_key_key
	XCHG
	RET

; Local variables for get_key
__VAR_get_key_key:	DS 2	; variable

put_char_at:
	LHLD __VAR_put_char_at_vram_addr	; Shadow stack push
	PUSH H
	LHLD __VAR_put_char_at_c	; Shadow stack push
	PUSH H
	LHLD __VAR_put_char_at_y	; Shadow stack push
	PUSH H
	LHLD __VAR_put_char_at_x	; Shadow stack push
	PUSH H
	; Load parameter x from hardware stack
	LXI H, 10
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_put_char_at_x
	; Load parameter y from hardware stack
	LXI H, 12
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_put_char_at_y
	; Load parameter c from hardware stack
	LXI H, 14
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_put_char_at_c
	LXI H, 40960
	PUSH H
	LHLD __VAR_put_char_at_y
	PUSH H
	LXI H, 6
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L88
L87:
	DAD H
	DCR E
	JNZ L87
L88:
	POP D
	DAD D
	PUSH H
	LHLD __VAR_put_char_at_y
	PUSH H
	LXI H, 4
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L90
L89:
	DAD H
	DCR E
	JNZ L89
L90:
	POP D
	DAD D
	PUSH H
	LHLD __VAR_put_char_at_x
	POP D
	DAD D
	SHLD __VAR_put_char_at_vram_addr
	; Inline assembly


        LHLD __VAR_put_char_at_vram_addr  ; Load the calculated 16-bit address into HL

        LDA  __VAR_put_char_at_c          ; Load the low byte of the character into A

        MOV  M, A             ; Store character in Text RAM

    
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_put_char_at_x
	POP H		; Shadow stack pop
	SHLD __VAR_put_char_at_y
	POP H		; Shadow stack pop
	SHLD __VAR_put_char_at_c
	POP H		; Shadow stack pop
	SHLD __VAR_put_char_at_vram_addr
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_put_char_at_x
	POP H		; Shadow stack pop
	SHLD __VAR_put_char_at_y
	POP H		; Shadow stack pop
	SHLD __VAR_put_char_at_c
	POP H		; Shadow stack pop
	SHLD __VAR_put_char_at_vram_addr
	XCHG
	RET

; Local variables for put_char_at
__VAR_put_char_at_vram_addr:	DS 2	; variable
__VAR_put_char_at_c:	DS 2	; variable
__VAR_put_char_at_y:	DS 2	; variable
__VAR_put_char_at_x:	DS 2	; variable

puts_at:
	LHLD __VAR_puts_at_c	; Shadow stack push
	PUSH H
	LHLD __VAR_puts_at_str	; Shadow stack push
	PUSH H
	LHLD __VAR_puts_at_y	; Shadow stack push
	PUSH H
	LHLD __VAR_puts_at_x	; Shadow stack push
	PUSH H
	; Load parameter x from hardware stack
	LXI H, 10
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_puts_at_x
	; Load parameter y from hardware stack
	LXI H, 12
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_puts_at_y
	; Load parameter str from hardware stack
	LXI H, 14
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_puts_at_str
	LHLD __VAR_puts_at_str
	MOV E, M
	INX H
	MOV D, M
	XCHG
	PUSH H
	LXI H, 255
	POP D
	MOV A, E
	ANA L
	MOV L, A
	MOV A, D
	ANA H
	MOV H, A
	SHLD __VAR_puts_at_c
L91:
	LHLD __VAR_puts_at_c
	MOV A, H
	ORA L
	JZ L92
	LHLD __VAR_puts_at_c
	PUSH H
	LHLD __VAR_puts_at_y
	PUSH H
	LHLD __VAR_puts_at_x
	PUSH H
	CALL put_char_at
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	LHLD __VAR_puts_at_x
	PUSH H
	LXI H, 1
	POP D
	DAD D
	SHLD __VAR_puts_at_x
	LHLD __VAR_puts_at_str
	PUSH H
	LXI H, 1
	POP D
	DAD D
	SHLD __VAR_puts_at_str
	LHLD __VAR_puts_at_str
	MOV E, M
	INX H
	MOV D, M
	XCHG
	PUSH H
	LXI H, 255
	POP D
	MOV A, E
	ANA L
	MOV L, A
	MOV A, D
	ANA H
	MOV H, A
	SHLD __VAR_puts_at_c
	JMP L91
L92:
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_puts_at_x
	POP H		; Shadow stack pop
	SHLD __VAR_puts_at_y
	POP H		; Shadow stack pop
	SHLD __VAR_puts_at_str
	POP H		; Shadow stack pop
	SHLD __VAR_puts_at_c
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_puts_at_x
	POP H		; Shadow stack pop
	SHLD __VAR_puts_at_y
	POP H		; Shadow stack pop
	SHLD __VAR_puts_at_str
	POP H		; Shadow stack pop
	SHLD __VAR_puts_at_c
	XCHG
	RET

; Local variables for puts_at
__VAR_puts_at_c:	DS 2	; variable
__VAR_puts_at_str:	DS 2	; pointer
__VAR_puts_at_y:	DS 2	; variable
__VAR_puts_at_x:	DS 2	; variable

update_dir_text:
	LHLD __VAR_update_dir_text_dir	; Shadow stack push
	PUSH H
	; Load parameter dir from hardware stack
	LXI H, 4
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_update_dir_text_dir
	LHLD __VAR_update_dir_text_dir
	PUSH H
	LXI H, 0
	POP D
	MOV A, E
	CMP L
	JNZ L95
	MOV A, D
	CMP H
	JNZ L95
	LXI H, 1
	JMP L96
L95:
	LXI H, 0
L96:
	MOV A, H
	ORA L
	JZ L93
	JMP L98
L97:
	DB 85,80,32,32,32,0
L98:
	LXI H, L97
	PUSH H
	LXI H, 1
	PUSH H
	LXI H, 6
	PUSH H
	CALL puts_at
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	JMP L94
L93:
L94:
	LHLD __VAR_update_dir_text_dir
	PUSH H
	LXI H, 1
	POP D
	MOV A, E
	CMP L
	JNZ L101
	MOV A, D
	CMP H
	JNZ L101
	LXI H, 1
	JMP L102
L101:
	LXI H, 0
L102:
	MOV A, H
	ORA L
	JZ L99
	JMP L104
L103:
	DB 68,79,87,78,32,0
L104:
	LXI H, L103
	PUSH H
	LXI H, 1
	PUSH H
	LXI H, 6
	PUSH H
	CALL puts_at
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	JMP L100
L99:
L100:
	LHLD __VAR_update_dir_text_dir
	PUSH H
	LXI H, 2
	POP D
	MOV A, E
	CMP L
	JNZ L107
	MOV A, D
	CMP H
	JNZ L107
	LXI H, 1
	JMP L108
L107:
	LXI H, 0
L108:
	MOV A, H
	ORA L
	JZ L105
	JMP L110
L109:
	DB 82,73,71,72,84,0
L110:
	LXI H, L109
	PUSH H
	LXI H, 1
	PUSH H
	LXI H, 6
	PUSH H
	CALL puts_at
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	JMP L106
L105:
L106:
	LHLD __VAR_update_dir_text_dir
	PUSH H
	LXI H, 3
	POP D
	MOV A, E
	CMP L
	JNZ L113
	MOV A, D
	CMP H
	JNZ L113
	LXI H, 1
	JMP L114
L113:
	LXI H, 0
L114:
	MOV A, H
	ORA L
	JZ L111
	JMP L116
L115:
	DB 76,69,70,84,32,0
L116:
	LXI H, L115
	PUSH H
	LXI H, 1
	PUSH H
	LXI H, 6
	PUSH H
	CALL puts_at
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	JMP L112
L111:
L112:
	LHLD __VAR_update_dir_text_dir
	PUSH H
	LXI H, 4
	POP D
	MOV A, E
	CMP L
	JNZ L119
	MOV A, D
	CMP H
	JNZ L119
	LXI H, 1
	JMP L120
L119:
	LXI H, 0
L120:
	MOV A, H
	ORA L
	JZ L117
	JMP L122
L121:
	DB 83,80,73,78,32,0
L122:
	LXI H, L121
	PUSH H
	LXI H, 1
	PUSH H
	LXI H, 6
	PUSH H
	CALL puts_at
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	JMP L118
L117:
L118:
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_update_dir_text_dir
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_update_dir_text_dir
	XCHG
	RET

; Local variables for update_dir_text
__VAR_update_dir_text_dir:	DS 2	; variable

get_p_base:
	LHLD __VAR_get_p_base_base	; Shadow stack push
	PUSH H
	; Inline assembly


        JMP SKIP_P_ARRAY

    P_ARRAY:

        DS 32

    SKIP_P_ARRAY:

        LXI H, P_ARRAY

        SHLD __VAR_get_p_base_base

    
	LHLD __VAR_get_p_base_base
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_get_p_base_base
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_get_p_base_base
	XCHG
	RET

; Local variables for get_p_base
__VAR_get_p_base_base:	DS 2	; variable

get_old_p_base:
	LHLD __VAR_get_old_p_base_base	; Shadow stack push
	PUSH H
	; Inline assembly


        JMP SKIP_OLD_P_ARRAY

    OLD_P_ARRAY:

        DS 32

    SKIP_OLD_P_ARRAY:

        LXI H, OLD_P_ARRAY

        SHLD __VAR_get_old_p_base_base

    
	LHLD __VAR_get_old_p_base_base
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_p_base_base
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_p_base_base
	XCHG
	RET

; Local variables for get_old_p_base
__VAR_get_old_p_base_base:	DS 2	; variable

set_p:
	LHLD __VAR_set_p_py	; Shadow stack push
	PUSH H
	LHLD __VAR_set_p_px	; Shadow stack push
	PUSH H
	LHLD __VAR_set_p_y	; Shadow stack push
	PUSH H
	LHLD __VAR_set_p_x	; Shadow stack push
	PUSH H
	LHLD __VAR_set_p_idx	; Shadow stack push
	PUSH H
	; Load parameter idx from hardware stack
	LXI H, 12
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_set_p_idx
	; Load parameter x from hardware stack
	LXI H, 14
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_set_p_x
	; Load parameter y from hardware stack
	LXI H, 16
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_set_p_y
	CALL get_p_base
	PUSH H
	LHLD __VAR_set_p_idx
	PUSH H
	LXI H, 2
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L124
L123:
	DAD H
	DCR E
	JNZ L123
L124:
	POP D
	DAD D
	SHLD __VAR_set_p_px
	CALL get_p_base
	PUSH H
	LHLD __VAR_set_p_idx
	PUSH H
	LXI H, 2
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L126
L125:
	DAD H
	DCR E
	JNZ L125
L126:
	POP D
	DAD D
	PUSH H
	LXI H, 2
	POP D
	DAD D
	SHLD __VAR_set_p_py
	LHLD __VAR_set_p_x
	PUSH H
	LHLD __VAR_set_p_px
	POP D
	MOV M, E
	INX H
	MOV M, D
	XCHG
	LHLD __VAR_set_p_y
	PUSH H
	LHLD __VAR_set_p_py
	POP D
	MOV M, E
	INX H
	MOV M, D
	XCHG
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_idx
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_x
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_y
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_px
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_py
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_idx
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_x
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_y
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_px
	POP H		; Shadow stack pop
	SHLD __VAR_set_p_py
	XCHG
	RET

; Local variables for set_p
__VAR_set_p_py:	DS 2	; pointer
__VAR_set_p_px:	DS 2	; pointer
__VAR_set_p_y:	DS 2	; variable
__VAR_set_p_x:	DS 2	; variable
__VAR_set_p_idx:	DS 2	; variable

get_px:
	LHLD __VAR_get_px_px	; Shadow stack push
	PUSH H
	LHLD __VAR_get_px_idx	; Shadow stack push
	PUSH H
	; Load parameter idx from hardware stack
	LXI H, 6
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_get_px_idx
	CALL get_p_base
	PUSH H
	LHLD __VAR_get_px_idx
	PUSH H
	LXI H, 2
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L128
L127:
	DAD H
	DCR E
	JNZ L127
L128:
	POP D
	DAD D
	SHLD __VAR_get_px_px
	LHLD __VAR_get_px_px
	MOV E, M
	INX H
	MOV D, M
	XCHG
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_get_px_idx
	POP H		; Shadow stack pop
	SHLD __VAR_get_px_px
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_get_px_idx
	POP H		; Shadow stack pop
	SHLD __VAR_get_px_px
	XCHG
	RET

; Local variables for get_px
__VAR_get_px_px:	DS 2	; pointer
__VAR_get_px_idx:	DS 2	; variable

get_py:
	LHLD __VAR_get_py_py	; Shadow stack push
	PUSH H
	LHLD __VAR_get_py_idx	; Shadow stack push
	PUSH H
	; Load parameter idx from hardware stack
	LXI H, 6
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_get_py_idx
	CALL get_p_base
	PUSH H
	LHLD __VAR_get_py_idx
	PUSH H
	LXI H, 2
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L130
L129:
	DAD H
	DCR E
	JNZ L129
L130:
	POP D
	DAD D
	PUSH H
	LXI H, 2
	POP D
	DAD D
	SHLD __VAR_get_py_py
	LHLD __VAR_get_py_py
	MOV E, M
	INX H
	MOV D, M
	XCHG
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_get_py_idx
	POP H		; Shadow stack pop
	SHLD __VAR_get_py_py
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_get_py_idx
	POP H		; Shadow stack pop
	SHLD __VAR_get_py_py
	XCHG
	RET

; Local variables for get_py
__VAR_get_py_py:	DS 2	; pointer
__VAR_get_py_idx:	DS 2	; variable

set_old_p:
	LHLD __VAR_set_old_p_py	; Shadow stack push
	PUSH H
	LHLD __VAR_set_old_p_px	; Shadow stack push
	PUSH H
	LHLD __VAR_set_old_p_y	; Shadow stack push
	PUSH H
	LHLD __VAR_set_old_p_x	; Shadow stack push
	PUSH H
	LHLD __VAR_set_old_p_idx	; Shadow stack push
	PUSH H
	; Load parameter idx from hardware stack
	LXI H, 12
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_set_old_p_idx
	; Load parameter x from hardware stack
	LXI H, 14
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_set_old_p_x
	; Load parameter y from hardware stack
	LXI H, 16
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_set_old_p_y
	CALL get_old_p_base
	PUSH H
	LHLD __VAR_set_old_p_idx
	PUSH H
	LXI H, 2
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L132
L131:
	DAD H
	DCR E
	JNZ L131
L132:
	POP D
	DAD D
	SHLD __VAR_set_old_p_px
	CALL get_old_p_base
	PUSH H
	LHLD __VAR_set_old_p_idx
	PUSH H
	LXI H, 2
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L134
L133:
	DAD H
	DCR E
	JNZ L133
L134:
	POP D
	DAD D
	PUSH H
	LXI H, 2
	POP D
	DAD D
	SHLD __VAR_set_old_p_py
	LHLD __VAR_set_old_p_x
	PUSH H
	LHLD __VAR_set_old_p_px
	POP D
	MOV M, E
	INX H
	MOV M, D
	XCHG
	LHLD __VAR_set_old_p_y
	PUSH H
	LHLD __VAR_set_old_p_py
	POP D
	MOV M, E
	INX H
	MOV M, D
	XCHG
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_idx
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_x
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_y
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_px
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_py
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_idx
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_x
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_y
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_px
	POP H		; Shadow stack pop
	SHLD __VAR_set_old_p_py
	XCHG
	RET

; Local variables for set_old_p
__VAR_set_old_p_py:	DS 2	; pointer
__VAR_set_old_p_px:	DS 2	; pointer
__VAR_set_old_p_y:	DS 2	; variable
__VAR_set_old_p_x:	DS 2	; variable
__VAR_set_old_p_idx:	DS 2	; variable

get_old_px:
	LHLD __VAR_get_old_px_px	; Shadow stack push
	PUSH H
	LHLD __VAR_get_old_px_idx	; Shadow stack push
	PUSH H
	; Load parameter idx from hardware stack
	LXI H, 6
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_get_old_px_idx
	CALL get_old_p_base
	PUSH H
	LHLD __VAR_get_old_px_idx
	PUSH H
	LXI H, 2
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L136
L135:
	DAD H
	DCR E
	JNZ L135
L136:
	POP D
	DAD D
	SHLD __VAR_get_old_px_px
	LHLD __VAR_get_old_px_px
	MOV E, M
	INX H
	MOV D, M
	XCHG
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_px_idx
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_px_px
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_px_idx
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_px_px
	XCHG
	RET

; Local variables for get_old_px
__VAR_get_old_px_px:	DS 2	; pointer
__VAR_get_old_px_idx:	DS 2	; variable

get_old_py:
	LHLD __VAR_get_old_py_py	; Shadow stack push
	PUSH H
	LHLD __VAR_get_old_py_idx	; Shadow stack push
	PUSH H
	; Load parameter idx from hardware stack
	LXI H, 6
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_get_old_py_idx
	CALL get_old_p_base
	PUSH H
	LHLD __VAR_get_old_py_idx
	PUSH H
	LXI H, 2
	POP D
	XCHG
	MOV A, E
	ORA A
	JZ L138
L137:
	DAD H
	DCR E
	JNZ L137
L138:
	POP D
	DAD D
	PUSH H
	LXI H, 2
	POP D
	DAD D
	SHLD __VAR_get_old_py_py
	LHLD __VAR_get_old_py_py
	MOV E, M
	INX H
	MOV D, M
	XCHG
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_py_idx
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_py_py
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_py_idx
	POP H		; Shadow stack pop
	SHLD __VAR_get_old_py_py
	XCHG
	RET

; Local variables for get_old_py
__VAR_get_old_py_py:	DS 2	; pointer
__VAR_get_old_py_idx:	DS 2	; variable

save_old_coordinates:
	LHLD __VAR_save_old_coordinates_i	; Shadow stack push
	PUSH H
	LXI H, 0
	SHLD __VAR_save_old_coordinates_i
L139:
	LHLD __VAR_save_old_coordinates_i
	PUSH H
	LXI H, 8
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L142
	LXI H, 0
	JMP L143
L142:
	LXI H, 1
L143:
	MOV A, H
	ORA L
	JZ L140
	LHLD __VAR_save_old_coordinates_i
	PUSH H
	CALL get_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	PUSH H
	LHLD __VAR_save_old_coordinates_i
	PUSH H
	CALL get_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	PUSH H
	LHLD __VAR_save_old_coordinates_i
	PUSH H
	CALL set_old_p
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
L141:
	LHLD __VAR_save_old_coordinates_i
	PUSH H
	LXI H, 1
	POP D
	DAD D
	SHLD __VAR_save_old_coordinates_i
	JMP L139
L140:
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_save_old_coordinates_i
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_save_old_coordinates_i
	XCHG
	RET

; Local variables for save_old_coordinates
__VAR_save_old_coordinates_i:	DS 2	; variable

project_vertex:
	LHLD __VAR_project_vertex_py	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_px	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_z_dist	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_z2	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_y1	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_cos_x	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_sin_x	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_z1	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_x1	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_cos_y	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_sin_y	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_ay	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_ax	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_z	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_y	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_x	; Shadow stack push
	PUSH H
	LHLD __VAR_project_vertex_idx	; Shadow stack push
	PUSH H
	; Load parameter idx from hardware stack
	LXI H, 36
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_project_vertex_idx
	; Load parameter x from hardware stack
	LXI H, 38
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_project_vertex_x
	; Load parameter y from hardware stack
	LXI H, 40
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_project_vertex_y
	; Load parameter z from hardware stack
	LXI H, 42
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_project_vertex_z
	; Load parameter ax from hardware stack
	LXI H, 44
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_project_vertex_ax
	; Load parameter ay from hardware stack
	LXI H, 46
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_project_vertex_ay
	LHLD __VAR_project_vertex_ay
	PUSH H
	CALL get_sin
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_project_vertex_sin_y
	LHLD __VAR_project_vertex_ay
	PUSH H
	CALL get_cos
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_project_vertex_cos_y
	LXI H, 100
	PUSH H
	LHLD __VAR_project_vertex_x
	PUSH H
	LHLD __VAR_project_vertex_cos_y
	POP D
	CALL __mul
	PUSH H
	LHLD __VAR_project_vertex_z
	PUSH H
	LHLD __VAR_project_vertex_sin_y
	POP D
	CALL __mul
	POP D
	DAD D
	PUSH H
	CALL divide
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_project_vertex_x1
	LXI H, 100
	PUSH H
	LHLD __VAR_project_vertex_z
	PUSH H
	LHLD __VAR_project_vertex_cos_y
	POP D
	CALL __mul
	PUSH H
	LHLD __VAR_project_vertex_x
	PUSH H
	LHLD __VAR_project_vertex_sin_y
	POP D
	CALL __mul
	POP D
	MOV A, E
	SUB L
	MOV L, A
	MOV A, D
	SBB H
	MOV H, A
	PUSH H
	CALL divide
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_project_vertex_z1
	LHLD __VAR_project_vertex_ax
	PUSH H
	CALL get_sin
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_project_vertex_sin_x
	LHLD __VAR_project_vertex_ax
	PUSH H
	CALL get_cos
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_project_vertex_cos_x
	LXI H, 100
	PUSH H
	LHLD __VAR_project_vertex_y
	PUSH H
	LHLD __VAR_project_vertex_cos_x
	POP D
	CALL __mul
	PUSH H
	LHLD __VAR_project_vertex_z1
	PUSH H
	LHLD __VAR_project_vertex_sin_x
	POP D
	CALL __mul
	POP D
	MOV A, E
	SUB L
	MOV L, A
	MOV A, D
	SBB H
	MOV H, A
	PUSH H
	CALL divide
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_project_vertex_y1
	LXI H, 100
	PUSH H
	LHLD __VAR_project_vertex_z1
	PUSH H
	LHLD __VAR_project_vertex_cos_x
	POP D
	CALL __mul
	PUSH H
	LHLD __VAR_project_vertex_y
	PUSH H
	LHLD __VAR_project_vertex_sin_x
	POP D
	CALL __mul
	POP D
	DAD D
	PUSH H
	CALL divide
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_project_vertex_z2
	LHLD __VAR_project_vertex_z2
	PUSH H
	LXI H, 150
	POP D
	DAD D
	SHLD __VAR_project_vertex_z_dist
	LHLD __VAR_project_vertex_z_dist
	PUSH H
	LHLD __VAR_project_vertex_x1
	PUSH H
	LXI H, 128
	POP D
	CALL __mul
	PUSH H
	CALL divide
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	PUSH H
	LXI H, 160
	POP D
	DAD D
	SHLD __VAR_project_vertex_px
	LHLD __VAR_project_vertex_z_dist
	PUSH H
	LHLD __VAR_project_vertex_y1
	PUSH H
	LXI H, 128
	POP D
	CALL __mul
	PUSH H
	CALL divide
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	PUSH H
	LXI H, 120
	POP D
	DAD D
	SHLD __VAR_project_vertex_py
	LHLD __VAR_project_vertex_py
	PUSH H
	LHLD __VAR_project_vertex_px
	PUSH H
	LHLD __VAR_project_vertex_idx
	PUSH H
	CALL set_p
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_idx
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_x
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_y
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_z
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_ax
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_ay
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_sin_y
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_cos_y
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_x1
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_z1
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_sin_x
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_cos_x
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_y1
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_z2
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_z_dist
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_px
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_py
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_idx
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_x
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_y
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_z
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_ax
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_ay
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_sin_y
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_cos_y
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_x1
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_z1
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_sin_x
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_cos_x
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_y1
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_z2
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_z_dist
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_px
	POP H		; Shadow stack pop
	SHLD __VAR_project_vertex_py
	XCHG
	RET

; Local variables for project_vertex
__VAR_project_vertex_py:	DS 2	; variable
__VAR_project_vertex_px:	DS 2	; variable
__VAR_project_vertex_z_dist:	DS 2	; variable
__VAR_project_vertex_z2:	DS 2	; variable
__VAR_project_vertex_y1:	DS 2	; variable
__VAR_project_vertex_cos_x:	DS 2	; variable
__VAR_project_vertex_sin_x:	DS 2	; variable
__VAR_project_vertex_z1:	DS 2	; variable
__VAR_project_vertex_x1:	DS 2	; variable
__VAR_project_vertex_cos_y:	DS 2	; variable
__VAR_project_vertex_sin_y:	DS 2	; variable
__VAR_project_vertex_ay:	DS 2	; variable
__VAR_project_vertex_ax:	DS 2	; variable
__VAR_project_vertex_z:	DS 2	; variable
__VAR_project_vertex_y:	DS 2	; variable
__VAR_project_vertex_x:	DS 2	; variable
__VAR_project_vertex_idx:	DS 2	; variable

draw_cube_edges:
	LHLD __VAR_draw_cube_edges_p7y	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p7x	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p6y	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p6x	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p5y	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p5x	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p4y	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p4x	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p3y	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p3x	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p2y	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p2x	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p1y	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p1x	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p0y	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_p0x	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_use_old	; Shadow stack push
	PUSH H
	LHLD __VAR_draw_cube_edges_color	; Shadow stack push
	PUSH H
	; Load parameter color from hardware stack
	LXI H, 38
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_draw_cube_edges_color
	; Load parameter use_old from hardware stack
	LXI H, 40
	DAD SP
	MOV E, M
	INX H
	MOV D, M
	XCHG
	SHLD __VAR_draw_cube_edges_use_old
	LHLD __VAR_draw_cube_edges_use_old
	MOV A, H
	ORA L
	JZ L144
	LXI H, 0
	PUSH H
	CALL get_old_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p0x
	LXI H, 0
	PUSH H
	CALL get_old_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p0y
	LXI H, 1
	PUSH H
	CALL get_old_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p1x
	LXI H, 1
	PUSH H
	CALL get_old_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p1y
	LXI H, 2
	PUSH H
	CALL get_old_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p2x
	LXI H, 2
	PUSH H
	CALL get_old_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p2y
	LXI H, 3
	PUSH H
	CALL get_old_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p3x
	LXI H, 3
	PUSH H
	CALL get_old_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p3y
	LXI H, 4
	PUSH H
	CALL get_old_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p4x
	LXI H, 4
	PUSH H
	CALL get_old_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p4y
	LXI H, 5
	PUSH H
	CALL get_old_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p5x
	LXI H, 5
	PUSH H
	CALL get_old_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p5y
	LXI H, 6
	PUSH H
	CALL get_old_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p6x
	LXI H, 6
	PUSH H
	CALL get_old_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p6y
	LXI H, 7
	PUSH H
	CALL get_old_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p7x
	LXI H, 7
	PUSH H
	CALL get_old_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p7y
	JMP L145
L144:
	LXI H, 0
	PUSH H
	CALL get_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p0x
	LXI H, 0
	PUSH H
	CALL get_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p0y
	LXI H, 1
	PUSH H
	CALL get_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p1x
	LXI H, 1
	PUSH H
	CALL get_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p1y
	LXI H, 2
	PUSH H
	CALL get_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p2x
	LXI H, 2
	PUSH H
	CALL get_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p2y
	LXI H, 3
	PUSH H
	CALL get_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p3x
	LXI H, 3
	PUSH H
	CALL get_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p3y
	LXI H, 4
	PUSH H
	CALL get_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p4x
	LXI H, 4
	PUSH H
	CALL get_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p4y
	LXI H, 5
	PUSH H
	CALL get_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p5x
	LXI H, 5
	PUSH H
	CALL get_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p5y
	LXI H, 6
	PUSH H
	CALL get_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p6x
	LXI H, 6
	PUSH H
	CALL get_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p6y
	LXI H, 7
	PUSH H
	CALL get_px
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p7x
	LXI H, 7
	PUSH H
	CALL get_py
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	SHLD __VAR_draw_cube_edges_p7y
L145:
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p1y
	PUSH H
	LHLD __VAR_draw_cube_edges_p1x
	PUSH H
	LHLD __VAR_draw_cube_edges_p0y
	PUSH H
	LHLD __VAR_draw_cube_edges_p0x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p2y
	PUSH H
	LHLD __VAR_draw_cube_edges_p2x
	PUSH H
	LHLD __VAR_draw_cube_edges_p1y
	PUSH H
	LHLD __VAR_draw_cube_edges_p1x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p3y
	PUSH H
	LHLD __VAR_draw_cube_edges_p3x
	PUSH H
	LHLD __VAR_draw_cube_edges_p2y
	PUSH H
	LHLD __VAR_draw_cube_edges_p2x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p0y
	PUSH H
	LHLD __VAR_draw_cube_edges_p0x
	PUSH H
	LHLD __VAR_draw_cube_edges_p3y
	PUSH H
	LHLD __VAR_draw_cube_edges_p3x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p5y
	PUSH H
	LHLD __VAR_draw_cube_edges_p5x
	PUSH H
	LHLD __VAR_draw_cube_edges_p4y
	PUSH H
	LHLD __VAR_draw_cube_edges_p4x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p6y
	PUSH H
	LHLD __VAR_draw_cube_edges_p6x
	PUSH H
	LHLD __VAR_draw_cube_edges_p5y
	PUSH H
	LHLD __VAR_draw_cube_edges_p5x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p7y
	PUSH H
	LHLD __VAR_draw_cube_edges_p7x
	PUSH H
	LHLD __VAR_draw_cube_edges_p6y
	PUSH H
	LHLD __VAR_draw_cube_edges_p6x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p4y
	PUSH H
	LHLD __VAR_draw_cube_edges_p4x
	PUSH H
	LHLD __VAR_draw_cube_edges_p7y
	PUSH H
	LHLD __VAR_draw_cube_edges_p7x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p4y
	PUSH H
	LHLD __VAR_draw_cube_edges_p4x
	PUSH H
	LHLD __VAR_draw_cube_edges_p0y
	PUSH H
	LHLD __VAR_draw_cube_edges_p0x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p5y
	PUSH H
	LHLD __VAR_draw_cube_edges_p5x
	PUSH H
	LHLD __VAR_draw_cube_edges_p1y
	PUSH H
	LHLD __VAR_draw_cube_edges_p1x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p6y
	PUSH H
	LHLD __VAR_draw_cube_edges_p6x
	PUSH H
	LHLD __VAR_draw_cube_edges_p2y
	PUSH H
	LHLD __VAR_draw_cube_edges_p2x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_draw_cube_edges_color
	PUSH H
	LHLD __VAR_draw_cube_edges_p7y
	PUSH H
	LHLD __VAR_draw_cube_edges_p7x
	PUSH H
	LHLD __VAR_draw_cube_edges_p3y
	PUSH H
	LHLD __VAR_draw_cube_edges_p3x
	PUSH H
	CALL draw_line
	XCHG	; Save Return Value
	LXI H, 10
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_color
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_use_old
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p0x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p0y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p1x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p1y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p2x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p2y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p3x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p3y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p4x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p4y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p5x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p5y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p6x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p6y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p7x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p7y
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_color
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_use_old
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p0x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p0y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p1x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p1y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p2x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p2y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p3x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p3y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p4x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p4y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p5x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p5y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p6x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p6y
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p7x
	POP H		; Shadow stack pop
	SHLD __VAR_draw_cube_edges_p7y
	XCHG
	RET

; Local variables for draw_cube_edges
__VAR_draw_cube_edges_p7y:	DS 2	; variable
__VAR_draw_cube_edges_p7x:	DS 2	; variable
__VAR_draw_cube_edges_p6y:	DS 2	; variable
__VAR_draw_cube_edges_p6x:	DS 2	; variable
__VAR_draw_cube_edges_p5y:	DS 2	; variable
__VAR_draw_cube_edges_p5x:	DS 2	; variable
__VAR_draw_cube_edges_p4y:	DS 2	; variable
__VAR_draw_cube_edges_p4x:	DS 2	; variable
__VAR_draw_cube_edges_p3y:	DS 2	; variable
__VAR_draw_cube_edges_p3x:	DS 2	; variable
__VAR_draw_cube_edges_p2y:	DS 2	; variable
__VAR_draw_cube_edges_p2x:	DS 2	; variable
__VAR_draw_cube_edges_p1y:	DS 2	; variable
__VAR_draw_cube_edges_p1x:	DS 2	; variable
__VAR_draw_cube_edges_p0y:	DS 2	; variable
__VAR_draw_cube_edges_p0x:	DS 2	; variable
__VAR_draw_cube_edges_use_old:	DS 2	; variable
__VAR_draw_cube_edges_color:	DS 2	; variable

main:
	LHLD __VAR_main_key	; Shadow stack push
	PUSH H
	LHLD __VAR_main_i	; Shadow stack push
	PUSH H
	LHLD __VAR_main_last_dir	; Shadow stack push
	PUSH H
	LHLD __VAR_main_dir	; Shadow stack push
	PUSH H
	LHLD __VAR_main_ay_step	; Shadow stack push
	PUSH H
	LHLD __VAR_main_ax_step	; Shadow stack push
	PUSH H
	LHLD __VAR_main_ay	; Shadow stack push
	PUSH H
	LHLD __VAR_main_ax	; Shadow stack push
	PUSH H
	LXI H, 0
	SHLD __VAR_main_ax
	LXI H, 0
	SHLD __VAR_main_ay
	LXI H, 1
	SHLD __VAR_main_ax_step
	LXI H, 2
	SHLD __VAR_main_ay_step
	LXI H, 4
	SHLD __VAR_main_dir
	LXI H, 1
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	SHLD __VAR_main_last_dir
	CALL clear_gfx_ram
	JMP L147
L146:
	DB 68,73,82,58,32,0
L147:
	LXI H, L146
	PUSH H
	LXI H, 1
	PUSH H
	LXI H, 1
	PUSH H
	CALL puts_at
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	LXI H, 0
	SHLD __VAR_main_i
L148:
	LHLD __VAR_main_i
	PUSH H
	LXI H, 8
	POP D
	MOV A, E
	SUB L
	MOV A, D
	SBB H
	JM L151
	LXI H, 0
	JMP L152
L151:
	LXI H, 1
L152:
	MOV A, H
	ORA L
	JZ L149
	LXI H, 0
	PUSH H
	LXI H, 0
	PUSH H
	LHLD __VAR_main_i
	PUSH H
	CALL set_old_p
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
L150:
	LHLD __VAR_main_i
	PUSH H
	LXI H, 1
	POP D
	DAD D
	SHLD __VAR_main_i
	JMP L148
L149:
L153:
	LXI H, 1
	MOV A, H
	ORA L
	JZ L154
	CALL get_key
	SHLD __VAR_main_key
	LHLD __VAR_main_key
	PUSH H
	LXI H, 29
	POP D
	MOV A, E
	CMP L
	JNZ L157
	MOV A, D
	CMP H
	JNZ L157
	LXI H, 1
	JMP L158
L157:
	LXI H, 0
L158:
	PUSH H
	LHLD __VAR_main_key
	PUSH H
	LXI H, 117
	POP D
	MOV A, E
	CMP L
	JNZ L159
	MOV A, D
	CMP H
	JNZ L159
	LXI H, 1
	JMP L160
L159:
	LXI H, 0
L160:
	POP D
	MOV A, D
	ORA E
	JNZ L161
	MOV A, H
	ORA L
	JNZ L161
	LXI H, 0
	JMP L162
L161:
	LXI H, 1
L162:
	MOV A, H
	ORA L
	JZ L155
	LXI H, 2
	SHLD __VAR_main_ax_step
	LXI H, 0
	SHLD __VAR_main_ay_step
	LXI H, 0
	SHLD __VAR_main_dir
	JMP L156
L155:
L156:
	LHLD __VAR_main_key
	PUSH H
	LXI H, 27
	POP D
	MOV A, E
	CMP L
	JNZ L165
	MOV A, D
	CMP H
	JNZ L165
	LXI H, 1
	JMP L166
L165:
	LXI H, 0
L166:
	PUSH H
	LHLD __VAR_main_key
	PUSH H
	LXI H, 114
	POP D
	MOV A, E
	CMP L
	JNZ L167
	MOV A, D
	CMP H
	JNZ L167
	LXI H, 1
	JMP L168
L167:
	LXI H, 0
L168:
	POP D
	MOV A, D
	ORA E
	JNZ L169
	MOV A, H
	ORA L
	JNZ L169
	LXI H, 0
	JMP L170
L169:
	LXI H, 1
L170:
	MOV A, H
	ORA L
	JZ L163
	LXI H, 2
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	SHLD __VAR_main_ax_step
	LXI H, 0
	SHLD __VAR_main_ay_step
	LXI H, 1
	SHLD __VAR_main_dir
	JMP L164
L163:
L164:
	LHLD __VAR_main_key
	PUSH H
	LXI H, 35
	POP D
	MOV A, E
	CMP L
	JNZ L173
	MOV A, D
	CMP H
	JNZ L173
	LXI H, 1
	JMP L174
L173:
	LXI H, 0
L174:
	PUSH H
	LHLD __VAR_main_key
	PUSH H
	LXI H, 116
	POP D
	MOV A, E
	CMP L
	JNZ L175
	MOV A, D
	CMP H
	JNZ L175
	LXI H, 1
	JMP L176
L175:
	LXI H, 0
L176:
	POP D
	MOV A, D
	ORA E
	JNZ L177
	MOV A, H
	ORA L
	JNZ L177
	LXI H, 0
	JMP L178
L177:
	LXI H, 1
L178:
	MOV A, H
	ORA L
	JZ L171
	LXI H, 0
	SHLD __VAR_main_ax_step
	LXI H, 2
	SHLD __VAR_main_ay_step
	LXI H, 2
	SHLD __VAR_main_dir
	JMP L172
L171:
L172:
	LHLD __VAR_main_key
	PUSH H
	LXI H, 28
	POP D
	MOV A, E
	CMP L
	JNZ L181
	MOV A, D
	CMP H
	JNZ L181
	LXI H, 1
	JMP L182
L181:
	LXI H, 0
L182:
	PUSH H
	LHLD __VAR_main_key
	PUSH H
	LXI H, 107
	POP D
	MOV A, E
	CMP L
	JNZ L183
	MOV A, D
	CMP H
	JNZ L183
	LXI H, 1
	JMP L184
L183:
	LXI H, 0
L184:
	POP D
	MOV A, D
	ORA E
	JNZ L185
	MOV A, H
	ORA L
	JNZ L185
	LXI H, 0
	JMP L186
L185:
	LXI H, 1
L186:
	MOV A, H
	ORA L
	JZ L179
	LXI H, 0
	SHLD __VAR_main_ax_step
	LXI H, 2
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	SHLD __VAR_main_ay_step
	LXI H, 3
	SHLD __VAR_main_dir
	JMP L180
L179:
L180:
	LHLD __VAR_main_dir
	PUSH H
	LHLD __VAR_main_last_dir
	POP D
	MOV A, E
	CMP L
	JNZ L189
	MOV A, D
	CMP H
	JZ L190
L189:
	LXI H, 1
	JMP L191
L190:
	LXI H, 0
L191:
	MOV A, H
	ORA L
	JZ L187
	LHLD __VAR_main_dir
	PUSH H
	CALL update_dir_text
	XCHG	; Save Return Value
	POP H	; Discard argument
	XCHG	; Restore Return Value
	LHLD __VAR_main_dir
	SHLD __VAR_main_last_dir
	JMP L188
L187:
L188:
	LHLD __VAR_main_ay
	PUSH H
	LHLD __VAR_main_ax
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 0
	PUSH H
	CALL project_vertex
	XCHG	; Save Return Value
	LXI H, 12
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_main_ay
	PUSH H
	LHLD __VAR_main_ax
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 1
	PUSH H
	CALL project_vertex
	XCHG	; Save Return Value
	LXI H, 12
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_main_ay
	PUSH H
	LHLD __VAR_main_ax
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 2
	PUSH H
	CALL project_vertex
	XCHG	; Save Return Value
	LXI H, 12
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_main_ay
	PUSH H
	LHLD __VAR_main_ax
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 3
	PUSH H
	CALL project_vertex
	XCHG	; Save Return Value
	LXI H, 12
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_main_ay
	PUSH H
	LHLD __VAR_main_ax
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 4
	PUSH H
	CALL project_vertex
	XCHG	; Save Return Value
	LXI H, 12
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_main_ay
	PUSH H
	LHLD __VAR_main_ax
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 5
	PUSH H
	CALL project_vertex
	XCHG	; Save Return Value
	LXI H, 12
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_main_ay
	PUSH H
	LHLD __VAR_main_ax
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 6
	PUSH H
	CALL project_vertex
	XCHG	; Save Return Value
	LXI H, 12
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LHLD __VAR_main_ay
	PUSH H
	LHLD __VAR_main_ax
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 30
	PUSH H
	LXI H, 30
	MOV A, H
	CMA
	MOV H, A
	MOV A, L
	CMA
	MOV L, A
	INX H
	PUSH H
	LXI H, 7
	PUSH H
	CALL project_vertex
	XCHG	; Save Return Value
	LXI H, 12
	DAD SP
	SPHL
	XCHG	; Restore Return Value
	LXI H, 1
	PUSH H
	LXI H, 0
	PUSH H
	CALL draw_cube_edges
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	LXI H, 0
	PUSH H
	LXI H, 1
	PUSH H
	CALL draw_cube_edges
	XCHG	; Save Return Value
	POP H	; Discard argument
	POP H	; Discard argument
	XCHG	; Restore Return Value
	CALL save_old_coordinates
	LHLD __VAR_main_ax
	PUSH H
	LHLD __VAR_main_ax_step
	POP D
	DAD D
	SHLD __VAR_main_ax
	LHLD __VAR_main_ay
	PUSH H
	LHLD __VAR_main_ay_step
	POP D
	DAD D
	SHLD __VAR_main_ay
	JMP L153
L154:
	LXI H, 0
	XCHG	; Save return value
	POP H		; Shadow stack pop
	SHLD __VAR_main_ax
	POP H		; Shadow stack pop
	SHLD __VAR_main_ay
	POP H		; Shadow stack pop
	SHLD __VAR_main_ax_step
	POP H		; Shadow stack pop
	SHLD __VAR_main_ay_step
	POP H		; Shadow stack pop
	SHLD __VAR_main_dir
	POP H		; Shadow stack pop
	SHLD __VAR_main_last_dir
	POP H		; Shadow stack pop
	SHLD __VAR_main_i
	POP H		; Shadow stack pop
	SHLD __VAR_main_key
	XCHG	; Restore return value
	RET
	; Fallback epilogue
	LXI H, 0
	XCHG
	POP H		; Shadow stack pop
	SHLD __VAR_main_ax
	POP H		; Shadow stack pop
	SHLD __VAR_main_ay
	POP H		; Shadow stack pop
	SHLD __VAR_main_ax_step
	POP H		; Shadow stack pop
	SHLD __VAR_main_ay_step
	POP H		; Shadow stack pop
	SHLD __VAR_main_dir
	POP H		; Shadow stack pop
	SHLD __VAR_main_last_dir
	POP H		; Shadow stack pop
	SHLD __VAR_main_i
	POP H		; Shadow stack pop
	SHLD __VAR_main_key
	XCHG
	RET

; Local variables for main
__VAR_main_key:	DS 2	; variable
__VAR_main_i:	DS 2	; variable
__VAR_main_last_dir:	DS 2	; variable
__VAR_main_dir:	DS 2	; variable
__VAR_main_ay_step:	DS 2	; variable
__VAR_main_ax_step:	DS 2	; variable
__VAR_main_ay:	DS 2	; variable
__VAR_main_ax:	DS 2	; variable

; Runtime support functions
__mul:
	; Multiply DE * HL, result in HL (16-bit)
	MOV B, H
	MOV C, L
	LXI H, 0
	MVI A, 16
__mul_loop:
	DAD H
	PUSH PSW
	MOV A, C
	RAL
	MOV C, A
	MOV A, B
	RAL
	MOV B, A
	JNC __mul_skip
	DAD D
__mul_skip:
	POP PSW
	DCR A
	JNZ __mul_loop
	RET

__div:
	; Divide DE / HL, result in HL (16-bit)
	MOV B, H
	MOV C, L
	LXI H, 0
__div_loop:
	MOV A, E
	SUB C
	MOV E, A
	MOV A, D
	SBB B
	MOV D, A
	JC __div_end
	INX H
	JMP __div_loop
__div_end:
	RET

; Runtime variables
; Stack space (still needed for CALL/RET and temporary values)
	ORG 3FFFH
STACK_TOP:
