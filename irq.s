;------------------------------------------------------------------- 
;	IRQ handler - Included from os.s													;
;																	;
;	By Andrew Leeming - 2012										;
;------------------------------------------------------------------- 

irq
            SUB     LR, LR, #4
			PUSH	{R0-R1, LR}

			MOV     R0, #IO_space           ; Grab the IRQ number
			LDRB    R1, [R0,#IRQ_SRC]		;

			TST     R1, #BTN_TOP			; Check for TopButton press
			BNE		irq_btn_top

			TST     R1, #BTN_BOTTOM			; Check for BottomButton press
			BNE		irq_btn_btm

;			TST     R1, #BTN_ST1_PRESSED	; Check for STButton press
;			BNE		irq_btn_st1

			TST     R1, #BIT0_SET			; Check for timer tick
            BNE     clock_tick

			BIC	    R1, R1, #&FF            ; Clear all IRQ vectors, since I dont
			STRB    R1, [R0, #IRQ_SRC]		; know what they are
			B		irq_end

irq_btn_top
			BIC		R1, R1, #BTN_TOP        ; Clear bit so we know it has been serviced
			STRB    R1, [R0, #IRQ_SRC]
			PUSH    {R0}

            MOV     R0, #3
            MOV     R1, #0
            BL      LED_toggle
            BL      irq_btn_debounce
			POP		{R0}
			B		irq_end
irq_btn_btm
			BIC		R1, R1, #BTN_BOTTOM		; Clear bit so we know it has been serviced
			STRB	R3, [R0, #IRQ_SRC]

            PUSH	{R1, R2}
            MOV     R0, #3
            MOV     R1, #1
            BL      LED_toggle
            BL      irq_btn_debounce
            POP     {R1, R2}

			B		irq_end
irq_btn_st1
			BIC		R1, R1, #BTN_ST1_PRESSED; Clear bit so we know it has been serviced
			STRB	R1, [R0, #IRQ_SRC]

            PUSH    {R0}
			MOV		R0, #&50
			SVC		print_char
			POP		{R0}

            B		irq_end

irq_btn_debounce
            PUSH    {R0}
            MOV     R0, #&FF0
_debounce_loop
            SUB     R0, R0, #1
            CMP     R0, #0
            BNE     _debounce_loop

            POP     {R0}
            MOV     PC, LR

irq_end
			POP     {R0-R1,LR}
            MOVS    PC, LR
