;------------------------------------------------------------------- 
;	Attempt at making basic interupts & OS							;
;																	;
;	By Andrew Leeming - 2011										;
;------------------------------------------------------------------- 

INCLUDE params_labboard.s

			org	&0

; Set up the Exception vectors
            B   reset                       ; Reset
            B   undefinstr                  ; Undefined Instruction
            B   svc_entry                   ; Supervisor Call/ Software Interupt
            B   prefetch_abort              ; Prefetch abort
            B   data_abort                  ; Data abort
            nop								; Unused
            B   irq                         ; Interupt
            B   fiq                         ; Fast Interupt
;-------------------------------------------------------------------            

; Include all libaries needed
			INCLUDE lib/LCD.s
			INCLUDE lib/LED.s
			INCLUDE lib/clock.s


; Implementations of Exception vectors are handled here
reset		
			ADRL	SP, svr_stack			; Set supervisor stack pointer

			BL		LCD_clear				; Start with clear LCD

			; Change to IRQ mode
			MRS 	R0, CPSR 				; Get current CPSR
			BIC 	R0, R0, #&0F 			; Clear low order bits
			ORR		R0,	R0, #&12			; Set FIQ mode bits
			MSR 	CPSR_c, R0 				; Rewrite CPSR
			NOP								; Apparently some ARM have a bug
											; and this NOP fixes it

			ADRL	SP, irq_stack			; Set IRQ stack pointer up		


			; Change to FIQ mode
			MRS 	R0, CPSR 				; Get current CPSR
			BIC 	R0, R0, #&0F 			; Clear low order bits
			ORR		R0,	R0, #&11			; Set FIQ mode bits
			MSR 	CPSR_c, R0 				; Rewrite CPSR
			NOP								; Apparently some ARM have a bug
											; and this NOP fixes it

			ADRL	SP, fiq_stack			; Set FIQ stack pointer up

			; Enable interupts
			MOV		r8, #IO_space			;
			MOV		r0, #1					;
			STRB	r0, [r8, #IRQ_EN]		;

			; Change to user mode
			MRS 	R0, CPSR 				; Get current CPSR
			BIC 	R0, R0, #&8F 			; Clear low order bits + set IRQ&FIQ
			MSR 	CPSR_c, R0 				; Rewrite CPSR
			NOP								; Apparently some ARM have a bug
											; and this NOP fixes it
			
			ADRL	SP, usr_stack			; Set user stack pointer up

			; Reset reg0-9 to a known value
			MOV		R0, #0
			MOV		R1, #0
			MOV		R2, #0
			MOV		R3, #0
			MOV		R4, #0
			MOV		R5, #0
			MOV		R6, #0
			MOV		R7, #0
			MOV		R8, #0
			MOV		R9, #0

			B		start					; Start the program
			
			
			
undefinstr	
			B		.	;end
			
			
svc_entry	
			STR		LR, [SP, #-4]! 			; Push scratch register
			PUSH	{R4,R5,LR}				; Remember to save arg (if any)
											; from the initial call
									
			LDR 	R4, [LR, #-4] 			; Read SVC instruction	
			BIC 	R4, R4, #&FF000000 		; Mask off opcode
											; R4 now has the SVC number

			CMP		R4, #SVC_MAX			; Check upper limit
			BHI		svc_unknown				; Branch on unknown SVC number
			
			ADR		LR,	svc_end				; Set LR to point to exit routine of SVC
			ADR		R5, svc_table			; Grab address of SVC table
			LDR		PC, [R5, R4, LSL #2]	; Grab routine address from jump table

			;B		end						; End program ? This code isnt reachable

svc_end
			POP		{R4,R5,LR}				; Recover registers prior to SVC
			MOVS	PC, LR					; Return back to user land
			
; code crashes and runs ?off the end? of the RAM
prefetch_abort
			B		. ;end						; End program

; attempt to read or write an I/O port while in user mode
data_abort
			B		. ;end						; End program
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


fiq
			B		. ;end						; End program
;-------------------------------------------------------------------

; SVC Table
INCLUDE sys_calls/svc_table.s
			
;-------------------------------------------------------------------			
			
;Start the actual program here
start		
			B		start
			;MOV		R1, #0

 			SVC		read_clk					; Read clock
			
			CMP		R0, #255
			BNE		start

			ADD		R1,R1,#1
			
			CMP		R1,#255
			BNE		start

			Add		R2,R2,#1
			MOV		R1,#0

			B		start

			SVC		0						; Quit

; Stop running the program (moved to 'exit' system call)
;end         B .


mystring 	DEFB 	"Yes", 0	
			ALIGN
svc_unknown_str 	DEFB 	"Unknown SVC #", 0	
			ALIGN


			ALIGN
;-------------------------------------------------------------------
; Define Macros used
;			MACRO
;$label_svc 	SVC_EXIT						; Macro name
;$label_svc	MOVS	PC, LR
;			MEND


;-------------------------------------------------------------------




;Setup usermode stack
			DEFS	100
usr_stack

;Setup supervisor stack
			DEFS	100
svr_stack

;Setup interupt stack
			DEFS	100
irq_stack

;Setup fast interupt stack
			DEFS	100
fiq_stack


; Switch to IRQ mode
;			MRS 	R0, CPSR 				; Read current status
;			BIC 	R0, R0, #&1F 			; Clear mode field
;			ORR 	R0, R0, #&12 			; Append IRQ mode
;			MSR 	CPSR_c, R0 				; Update CPSR

; Switch from supervisor -> user mode
;			MRS 	R0, CPSR 				; Get current CPSR
;			BIC 	R0, R0, #&0F 			; Clear low order bits
;			MSR 	CPSR_c, R0 				; Rewrite CPSR
;			NOP 							; Bug fix on some ARMs
