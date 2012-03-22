;-------------------------------------------------------------------------------
; This code was originaly sourced from '/opt/info/courses/COMP22712/Code_examples/bcd_convert.s'
;
;
; Convert unsigned binary value in R0 into BCD representation, returned in R0
; Any overflowing digits are generated, but not retained or returned in this
;  version.
; Corrupts registers R1-R6, inclusive; also R14
; Does not require a stack


bcd_convert
        mov	r6, lr			    ; Keep return address
                                ;  in case there is no stack
		adr	r4, dec_table		; Point at conversion table
		mov	r5, #0			    ; Zero accumulator

bcd_loop	ldr	r1, [r4], #4    ; Get next divisor, step pointer
		cmp	r1, #1			    ; Termination condition?
		beq	bcd_out			    ;  yes

		bl	divide			    ; R0 := R0/R1 (rem. R2)

		add	r5, r0, r5, lsl #4	; Accumulate result
		mov	r0, r2			    ; Recycle remainder
		b	bcd_loop		    ;

bcd_out		add	r0, r0, r5, lsl #4	; Accumulate result to output

		mov	pc, r6			; Return

dec_table	DCD	1000000000, 100000000, 10000000, 1000000
		DCD	100000, 10000, 1000, 100, 10, 1

;-------------------------------------------------------------------------------

; 32-bit unsigned integer division R0/R1
; Returns quotient in R0 and remainder in R2
; R3 is corrupted (will be zero)
; Returns quotient FFFFFFFF in case of division by zero
; Does not require a stack

divide		mov	r2, #0			; AccH
		mov	r3, #32			; Number of bits in division
		adds	r0, r0, r0		; Shift dividend

divide1		adc	r2, r2, r2		; Shift AccH, carry into LSB
		cmp	r2, r1			; Will it go?
		subhs	r2, r2, r1		; If so, subtract
		adcs	r0, r0, r0		; Shift dividend & Acc. result
		sub	r3, r3, #1		; Loop count
		tst	r3, r3			; Leaves carry alone
		bne	divide1			; Repeat as required

		mov	pc, lr			; Return

;-------------------------------------------------------------------------------
