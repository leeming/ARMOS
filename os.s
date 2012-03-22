f ;------------------------------------------------------------------- 
;	Attempt at making basic interupts & OS							;
;																	;
;	By Andrew Leeming - 2011										;
;------------------------------------------------------------------- 

INCLUDE params_labboard.s


            org	&0

; Set up the Exception vectors
            B       reset                   ; Reset
            B       undefinstr              ; Undefined Instruction
            B       svc_entry               ; Supervisor Call/ Software Interupt
            B       prefetch_abort          ; Prefetch abort
            B       data_abort              ; Data abort
            nop								; Unused
            B       irq                     ; Interupt

            ; Fast Interupt     
            BL      LCD_clear
            ADRL    R0, fiq_bye
            BL      LCD_write_str
            B       end


;-------------------------------------------------------------------            

; Include all libaries needed
            INCLUDE lib/LCD.s
            INCLUDE lib/LED.s
            INCLUDE lib/clock.s
            INCLUDE lib/math.s
            INCLUDE lib/bcd_convert.s
            INCLUDE lib/system.s
            INCLUDE lib/queue.s

            INCLUDE error.s


; Implementations of Exception vectors are handled here
reset		
			ADRL	SP, svr_stack			; Set supervisor stack pointer

			BL		LCD_clear				; Start with clear LCD
            BL      PCB_setup               ; Set up PCB

            BL      LED_en                  ; Enable LEDs
            BL      LED_clear               ; Clear all LEDs



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

            ; Change to System mode
            MOV     R0, #MODE_SYSTEM 
            BL      change_mode
            ADRL    SP, usr_stack   

            ; Enable interupts
            MOV     r8, #IO_space           ;
            MOV     r0, #0xC1               ; Timer + buttons
            STR     r0, [r8, #IRQ_EN]       ;

d1
            ; Start creating user processes
            ADRL    R0, helloworldStart
            BL      PCB_create_process

            ADRL    R0, flashyStart
            BL      PCB_create_process

            ADRL    R0, flashy3Start
            BL      PCB_create_process

            ADRL    R0, flashy2Start
            BL      PCB_create_process

   
            ADRL    R0, counterStart
            BL      PCB_create_process


d3
            ; Start the scheduler
            BL      PCB_run
            SVC     0                       ; Quit
			
undefinstr	
			B		.	;end
			

d6  nop
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


svc_end
			POP		{R4,R5,LR}				; Recover registers prior to SVC
			MOVS	PC, LR					; Return back to user land


; code crashes and runs ?off the end? of the RAM
prefetch_abort
            B       prefetch_abort_handler


; attempt to read or write an I/O port while in user mode
data_abort
            B       data_abort_handler

; irq
INCLUDE irq.s

;-------------------------------------------------------------------

; SVC Table
INCLUDE sys_calls/svc_table.s

;PCB
INCLUDE pcb.s

;-------------------------------------------------------------------			

INCLUDE user_progs/helloworld.s
        SVC     kill
INCLUDE user_progs/counter.s
        SVC     kill
INCLUDE user_progs/testPrintDigit.s
        SVC     kill
INCLUDE user_progs/flashy.s
        SVC     kill
INCLUDE user_progs/flashy2.s
        SVC     kill
INCLUDE user_progs/flashy3.s
        SVC     kill




svc_unknown_str DEFB    "Unknown SVC #", 0
                ALIGN
fiq_bye         DEFB    "Halting", 0
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