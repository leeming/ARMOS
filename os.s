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
        INCLUDE lib/math.s
        INCLUDE lib/bcd_convert.s


; Implementations of Exception vectors are handled here
reset		
			ADRL	SP, svr_stack			; Set supervisor stack pointer

			BL		LCD_clear				; Start with clear LCD

			; Change to IRQ mode
			MRS 	R0, CPSR 				; Get current CPSR
			BIC 	R0, R0, #&0F 			; Clear low order bits
			ORR		R0,	R0, #&12			; Set IRQ mode bits
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

nop     ; Reset reg0-9 to a known value
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
			
nop; code crashes and runs ?off the end? of the RAM
prefetch_abort
			B		. ;end						; End program

nop; attempt to read or write an I/O port while in user mode
data_abort
			B		. ;end						; End program
nop; irq
INCLUDE irq.s


fiq
			B		. ;end						; End program

;-------------------------------------------------------------------

nop; SVC Table
INCLUDE sys_calls/svc_table.s
			
;-------------------------------------------------------------------			
			
;Start the actual program here
start		
        ;INCLUDE user_progs/helloworld.s
        INCLUDE user_progs/counter.s
        ;INCLUDE user_progs/testPrintDigit.s


        SVC		0						; Quit

svc_unknown_str 	DEFB 	"Unknown SVC #", 0	
			ALIGN
nop
on_time         DEFS     1
                ALIGN

;-------------------------------------------------------------------
; Stacks


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
