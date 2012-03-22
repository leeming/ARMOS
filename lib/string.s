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
        PUSH {r1-r5}                ; Make sure we preserve these reg
        MOV r5, r0                  ; Make a copy of the arg
        
        MOV r2, #PORT_B
        LDR r3, [r2]
    
        ORR r3, r3, #0b00000100     ; Set R/W=1
        AND r3, r3, #0b11111101     ; Set RS=0
        STR r3, [r2]
        
_lcdiowait
	    ORR R3, r3, #0b00000001     ; Set E=1
        STR r3, [r2]
        
        ;Read LCD status byte
        MOV r0, #PORT_A             ; Load PortA addr
        LDR r1, [r0]
        
        AND r3, r3, #0b11111110     ; Set E=0
        STR r3, [r2]
        
        MOV r0, #PORT_A             ; Check if LCD is ready
        AND r4, r1, #0b10000000
        CMP r4, #0
        BNE _lcdiowait               ; If LCD is not ready, try again
        
        ORR r3, r3, #0b11111011     ; Set R/W=0
        AND r3, r3, #0b00000010     ; Set RS=1
        STR r3, [r2]
        
        STR r5, [r0]                ; Print the char given
        
        ORR r3, r3, #0b00000001     ; Set E=1
        STR r3, [r2]
        AND r3, r3, #0b11111110     ; Set E=0
        STR r3, [r2]
        
        POP {r1-r5}
        MOVS pc, lr                 ; Return back to print_str
;------------------------------------------------------------------------

;-------------------------------
; print_str: 
;   Prints a string to an LCD. Stops when it reaches a value of 0
; 
;   R0 = Front of string   
;
;-------------------------------
_print_str
                PUSH {r4}			; Save Reg that are used

_fetch_char     LDRB r4, [r0], #1   ; Fetch character
                CMP  r4, #0         ; Check for null char
                BEQ  _print_str_end
                
                PUSH {r0,lr}   ; Save current regs
                MRS 	R0, SPSR	;Save old spsr
                PUSH {r0}
                MRS		R0, CPSR	; set SPSR(new) as CPSR
                MSR		SPSR, R0
                
                MOV  r0,r4          ; Put char to print into R0
                BL   _print_char     ; Do print_char
                
                POP {r0}			; Reload orginal SPSR
                MSR 	SPSR, R0
                
                POP  {r0,lr}   ; Recover registers
                B   _fetch_char
_print_str_end                
                POP {r4}
                MOVS pc,lr
               
;------------------------------------------------------------------------       

