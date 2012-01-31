;------------------------------------------------------------------- 
;	IRQ handler - Included from os.s													;
;																	;
;	By Andrew Leeming - 2012										;
;------------------------------------------------------------------- 

irq
			push	{r3,r4,r5}

			mov		r4, #IO_space			; Grab the IRQ number
			ldrb	r3, [r4,#IRQ_SRC]		; 	

			TST		r3, #BTN_TOP			; Check for TopButton press
			BNE		irq_btn_top
			TST		r3, #BTN_BOTTOM			; Check for BottomButton press
			BNE		irq_btn_btm				
			TST		r3, #BTN_ST1_PRESSED	; Check for BottomButton press
			BNE		irq_btn_st1			
			TST		r3, #TIMER				; Check for timer tick
			BNE		irq_clk_tick

			BIC		r3, r3, #&FF			; Clear all IRQ vectors, since I dont
			STRB	r3, [r4, #IRQ_SRC]		; know what they are
			B		irq_end

irq_btn_top
			BIC		r3, r3, #BTN_TOP		; Clear bit so we know it has been serviced
			STRB	r3, [r4, #IRQ_SRC]
			PUSH	{r0}
			MOV		r0, #&54
			SVC		print_char
			POP		{r0}
			B		irq_end
irq_btn_btm
			BIC		r3, r3, #BTN_BOTTOM		; Clear bit so we know it has been serviced
			STRB	r3, [r4, #IRQ_SRC]
			PUSH	{r0}
			MOV		r0, #&42
			SVC		print_char
			POP		{r0}
			B		irq_end
irq_btn_st1
			BIC		r3, r3, #BTN_ST1_PRESSED		; Clear bit so we know it has been serviced
			STRB	r3, [r4, #IRQ_SRC]
			PUSH	{r0}
			MOV		r0, #&50
			SVC		print_char
			POP		{r0}
			B		irq_end
irq_clk_tick
			BIC		r3, r3, #TIMER		; Clear bit so we know it has been serviced
			STRB	r3, [r4, #IRQ_SRC]
			ldrb	r3, [r4,#TIMER_CMP]		; Load the timer compare
			add		r3, r3, #100			; Add an additional 100ms
			strb	r3, [r4,#TIMER_CMP]		; Store updated timer compare
			mov		r3, #0
			strb	r3, [r4,#IRQ_SRC]		; Reset IRQ flags

			add		r10, r10, #1			; Add a second (units)
			cmp		r10, #10
			movhs	r10, #0					; Add a second (tens)
			addhs	r9, r9, #1
			B		irq_end


irq_end
			pop		{r3,r4,r5}
			subs	pc, lr, #4


irq_print_time
			push	{r0}
			mov 	r0, #&30
			add		r0, r0, r9
			SVC 	clear_screen
			SVC		print_char

			pop		{r0}
			b		irq_end
 