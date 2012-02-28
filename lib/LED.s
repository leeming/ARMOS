;---------------------------
; LED_{blue,red,amber,green}_{on,off}
; 	Turns on/off the LED on the board
;
;	Blah @see LED_on
;
;	Params: R0 - 1 for Right, 0 for Left
;
; Tested : Yes
;---------------------------
LED_blue_on	
			PUSH	{r1,r2}
			MOV		r1, #IO_space
			LDRB	r2, [r1]
			CMP		r0, #1					; Check if its Left(0) 
											; or Right(1) blue LED

			ORRNE	r2,r2, #BIT3_SET		; If Left set bit3=1
			ORREQ	r2,r2, #BIT7_SET		; If Right set bit7=1

			STRB	r2, [r1]
			POP		{r1,r2}
			MOV		PC,LR

LED_blue_off
			PUSH	{r1,r2}
			MOV		r1, #IO_space
			LDRB	r2, [r1]
			CMP		r0, #1					; Check if its Left(0) 
											; or Right(1) blue LED

			ANDNE	r2,r2, #BIT3_USET		; If Left set bit3=0
			ANDEQ	r2,r2, #BIT7_USET		; If Right set bit7=0

			STRB	r2, [r1]
			POP		{r1,r2}
			MOV		PC,LR

; R0 = Colour
; R1 = Side
LED_on	
			PUSH	{r2,r3,r4}
			MOV		r2, #IO_space
			LDRB	r3, [r2]

			; Set the colour bit mask

			CMP		r0, #0					; RED
			MOVEQ	r4, #BIT2_SET
			CMP		r0, #1					; AMBER
			MOVEQ	r4, #BIT1_SET
			CMP		r0, #2					; GREEN
			MOVEQ	r4, #BIT0_SET
			CMP		r0, #3					; BLUE
			MOVEQ	r4, #BIT3_SET
		  
			;Set the bitmask for LED
			CMP		r1, #1
			ORREQ	r3, r3, r4 LSL #4		; RIGHT 
			ORRNE	r3, r3, r4				; LEFT

			STRB	r3, [r2]
			POP		{r2,r3,r4}
			MOV		PC,LR


LED_off
			PUSH	{r2,r3}
			MOV		r2, #IO_space
			LDRB	r3, [r2]

			; Set the colour bit mask

			CMP		r0, #0					; RED
			MOVEQ	r4, #BIT2_USET
			CMP		r0, #1					; AMBER
			MOVEQ	r4, #BIT1_USET
			CMP		r0, #2					; GREEN
			MOVEQ	r4, #BIT0_USET
			CMP		r0, #3					; BLUE
			MOVEQ	r4, #BIT3_USET
		  
			;Set the bitmask for LED
			CMP		r1, #1
			ANDEQ	r3, r3, r4 LSL #4		; RIGHT
			ANDNE	r3, r3, r4				; LEFT

			STRB	r3, [r2]
			POP		{r2,r3}
			MOV		PC,LR

LED_toggle
            PUSH    {r2,r3}
            MOV     r2, #IO_space
            LDRB    r3, [r2]

            ; Set the colour bit mask

            CMP     r0, #0                  ; RED
            MOVEQ   r4, #BIT2_SET
            CMP     r0, #1                  ; AMBER
            MOVEQ   r4, #BIT1_SET
            CMP     r0, #2                  ; GREEN
            MOVEQ   r4, #BIT0_SET
            CMP     r0, #3                  ; BLUE
            MOVEQ   r4, #BIT3_SET

            ;Set the bitmask for LED
            CMP     r1, #1
            EOREQ   r3, r3, r4 LSL #4       ; RIGHT
            EORNE   r3, r3, r4              ; LEFT

            STRB    r3, [r2]
            POP     {r2,r3}
            MOV     PC,LR