;-----------------
; Turn on an LED
;   R0 = Colour - Red(0) Amber(1) Green(2) Blue(3)
;   R1 = Side - Left(0) Right(1)
;-----------------
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

;-----------------
; Turn off an LED
;   R0 = Colour - Red(0) Amber(1) Green(2) Blue(3)
;   R1 = Side - Left(0) Right(1)
;-----------------
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

;-----------------
; Toggles on/off an LED
;   R0 = Colour - Red(0) Amber(1) Green(2) Blue(3)
;   R1 = Side - Left(0) Right(1)
;-----------------
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

;-----------------
; Clears all LEDs
;-----------------
LED_clear
            PUSH    {r2,r3}
            MOV     r2, #IO_space
            MOV     r3, #0
            STRB    r3, [r2]
            POP     {r2,r3}
            MOV     PC,LR

;-------
; Enable LEDs while recovering their state
;-------
LED_en
            PUSH    {R0-R2}
            ; Enable LED
            MOV     R0, #BIT4_SET
            MOV     R1, #IO_space
            LDRB    R2, [R1, #PIO_B]
            ORR     R0, R0, R2
            STR     R0, [R1, #PIO_B]

            ; Recover state
            LDRB    R0, LED_saved_state
            STRB    R0, [R1]

            POP     {R0-R2}
            MOV     PC, LR


;-------
; Enable LEDs while saving their state
;-------
LED_de
            PUSH    {R0-R2}
            ; disable LED
            MOV     R0, #BIT4_USET
            MOV     R1, #IO_space
            LDRB    R2, [R1, #PIO_B]
            AND     R0, R0, R2
            STR     R0, [R1, #PIO_B]

            ; Save state
            LDRB    R0, [R1, #PIO_A]
            STRB    R0, LED_saved_state

            POP     {R0-R2}
            MOV     PC, LR



LED_saved_state     DEFW    0