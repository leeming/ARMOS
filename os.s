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
        INCLUDE lib/system.s

        INCLUDE error.s


; Implementations of Exception vectors are handled here
reset		
			ADRL	SP, svr_stack			; Set supervisor stack pointer

			BL		LCD_clear				; Start with clear LCD
            BL      PCB_setup               ; Set up PCB


BL  LED_de
NOP;FF stored?
BL  LED_en

			; Change to IRQ mode
            MOV     R0, #MODE_IRQ
            BL      change_mode
			ADRL	SP, irq_stack			; Set IRQ stack pointer up		


            ; Change to FIQ mode
            MOV     R0, #MODE_FIQ
            BL      change_mode
            ADRL    SP, fiq_stack           ; Set FIQ stack pointer up


            ; Change to Abort mode
            MOV     R0, #MODE_ABORT
            BL      change_mode
            ADRL    SP, abort_stack           ; Set ABORT stack pointer up

			; Enable interupts
			MOV		r8, #IO_space			;
			MOV		r0, #0xC1					; Timer + buttons
			STR 	r0, [r8, #IRQ_EN]		;



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
			PUSH	{R4,R5,LR}				; Remember to save arg (if any)
											; from the initial call
									
			LDR 	R4, [LR, #-4] 			; Read SVC instruction	
			BIC 	R4, R4, #&FF000000 		; Mask off opcode
											; R4 now has the SVC number

			CMP		R4, #SVC_MAX			; Check upper limit
			BHI		svc_unknown				; Branch on unknown SVC number
			
			ADRL	LR,	svc_end				; Set LR to point to exit routine of SVC
			ADRL    R5, svc_table			; Grab address of SVC table
			LDR		PC, [R5, R4, LSL #2]	; Grab routine address from jump table

			;B		end						; End program ? This code isnt reachable

svc_end
			POP		{R4,R5,LR}				; Recover registers prior to SVC
			MOVS	PC, LR					; Return back to user land
			
; code crashes and runs ?off the end? of the RAM
prefetch_abort
            B       prefetch_abort_handler
			;B		. ;end						; End program

; attempt to read or write an I/O port while in user mode
data_abort
            B       data_abort_handler
			B		. ;end						; End program

; irq
INCLUDE irq.s


fiq
			B		. ;end						; End program

;-------------------------------------------------------------------

; SVC Table
INCLUDE sys_calls/svc_table.s

;PCB
INCLUDE pcb.s

;-------------------------------------------------------------------			

INCLUDE user_progs/helloworld.s
INCLUDE user_progs/counter.s
INCLUDE user_progs/testPrintDigit.s
INCLUDE user_progs/flashy.s



;Start the user programs here
start
        B  helloworldStart
        ;B flashyStart


        ;Start the helloworld program first
        ADR     R0, helloworldMain

;idle loop to test irq
B .



        SVC		0						; Quit

svc_unknown_str 	DEFB 	"Unknown SVC #", 0	
			ALIGN
nop
on_time         DEFS     1
                ALIGN

;-------------------------------------------------------------------
; Stacks


;Setup usermode stack : No longer needed as PCBs have own stack?
			DEFS	100
usr_stack

;Setup supervisor stack
			DEFS	100
svr_stack

;Setup abort stack
            DEFS    100
abort_stack

;Setup interupt stack
            DEFS    100
irq_stack

;Setup fast interupt stack
			DEFS	100
fiq_stack