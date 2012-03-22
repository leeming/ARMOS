;------------------------------------------------------------------- 
;	IRQ handler - Included from os.s													;
;																	;
;	By Andrew Leeming - 2012										;
;------------------------------------------------------------------- 

;----------------------------
; This is the main Interupt Service
; Routine (ISR). 
;   Params: n/a
;----------------------------
irq nop
d4            SUB     LR, LR, #4
			PUSH	{R0-R1, LR}

			MOV     R0, #IO_space           ; Grab the IRQ number
			LDRB    R1, [R0,#IRQ_SRC]		;

			TST     R1, #BTN_TOP			; Check for TopButton press
			BNE		irq_btn_top

			TST     R1, #BTN_BOTTOM			; Check for BottomButton press
			BNE		irq_btn_btm

			TST     R1, #BIT0_SET			; Check for timer tick
            BNE     clock_tick

			BIC	    R1, R1, #&FF            ; Clear all IRQ vectors, since the
			STRB    R1, [R0, #IRQ_SRC]		; OS does not service them
			B		irq_end

;----------------------------
; Routine for (Top) button press
;   Params: n/a
;----------------------------
irq_btn_top
			BIC		R1, R1, #BTN_TOP        ; Clear bit so we know it has been serviced
			STRB    R1, [R0, #IRQ_SRC]
			PUSH    {R0}

            ; Toggle left blue led
            MOV     R0, #3
            MOV     R1, #0
            BL      LED_toggle
            BL      irq_btn_debounce
			POP		{R0}
			B		irq_end

;----------------------------
; Routine for (Bottom) button press
;   Params: n/a
;----------------------------
irq_btn_btm
			BIC		R1, R1, #BTN_BOTTOM		; Clear bit so we know it has been serviced
			STRB	R3, [R0, #IRQ_SRC]
            PUSH	{R1, R2}

            ; Toggle right blue led
            MOV     R0, #3
            MOV     R1, #1
            BL      LED_toggle
            BL      irq_btn_debounce
            POP     {R1, R2}

			B		irq_end

;----------------------------
; Basic debounce routine for button
; presses
;   Params: n/a
;----------------------------
irq_btn_debounce
            PUSH    {R0}
            MOV     R0, #&FF00
_debounce_loop
            SUB     R0, R0, #1
            CMP     R0, #0
            BNE     _debounce_loop

            POP     {R0}
            MOV     PC, LR

;----------------------------
; Final call to exit out of an IRQ
;   Params: n/a
;----------------------------
irq_end
		    ; Add previous proce
            POP     {R0-R1,LR}
            MOVS    PC, LR
