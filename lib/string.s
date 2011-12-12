;-------------------------------
; print_char: 
;   Prints a character to an LCD
;
;   R0 = Character ascii value   
;
;-------------------------------


PORT_A  EQU &10000000
PORT_B  EQU &10000004

_print_char
		;;;;;pop	{r0}
        push {r1-r5}                ; Make sure we preserve these reg
        mov r5, r0                  ; Make a copy of the arg
        
        mov r2, #PORT_B
        ldr r3, [r2]
    
        orr r3, r3, #0b00000100     ; Set R/W=1
        and r3, r3, #0b11111101     ; Set RS=0
        str r3, [r2]
        
_lcdiowait
	    orr r3, r3, #0b00000001     ; Set E=1
        str r3, [r2]
        
        ;Read LCD status byte
        mov r0, #PORT_A             ; Load PortA addr
        ldr r1, [r0]
        
        and r3, r3, #0b11111110     ; Set E=0
        str r3, [r2]
        
        mov r0, #PORT_A             ; Check if LCD is ready
        and r4, r1, #0b10000000
        cmp r4, #0                  
        bne _lcdiowait               ; If LCD is not ready, try again
        
        orr r3, r3, #0b11111011     ; Set R/W=0        
        and r3, r3, #0b00000010     ; Set RS=1 
        str r3, [r2]
        
        str r5, [r0]                ; Print the char given
        
        orr r3, r3, #0b00000001     ; Set E=1
        str r3, [r2]        
        and r3, r3, #0b11111110     ; Set E=0
        str r3, [r2]
        
        pop {r1-r5}
        movs pc, lr                 ; Return back to print_str
;------------------------------------------------------------------------

;-------------------------------
; print_str: 
;   Prints a string to an LCD. Stops when it reaches a value of 0
; 
;   R0 = Front of string   
;
;-------------------------------
_print_str
				;;;;;pop	{r0}
                push {r4}			; Save Reg that are used

_fetch_char      ldrb r4, [r0], #1   ; Fetch character
                cmp  r4, #0         ; Check for null char
                beq  _print_str_end
                
                
                
                
                push {r0,lr}   ; Save current regs
                MRS 	R0, SPSR	;Save old spsr
                push {r0}
                MRS		R0, CPSR	; set SPSR(new) as CPSR
                MSR		SPSR, R0
                
                mov  r0,r4          ; Put char to print into R0
                bl   _print_char     ; Do print_char
                
                pop {r0}			; Reload orginal SPSR
                MSR 	SPSR, R0
                
                pop  {r0,lr}   ; Recover registers   
                b   _fetch_char
_print_str_end                
                pop {r4}
                movs pc,lr
               
;------------------------------------------------------------------------       

