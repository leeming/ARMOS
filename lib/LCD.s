;---------------------------
; <<routine>>
; 	<<desc>>
;
;	Params: 
;	Return: 
;
; Tested : No
;---------------------------
LCD_en		
			PUSH	{r0,r1}
			MOV		r0, #IO_space
			LDR		r1, [r0, #PIO_A]
			ORR 	r1, r1, #0b00000001     ; Set E=1
			STR 	r1, [r0, #PIO_A]     
			POP		{r0,r1}
			MOV		PC, LR

;---------------------------
; <<routine>>
; 	<<desc>>
;
;	Params: 
;	Return: 
;
; Tested : No
;---------------------------
LCD_disable	
			PUSH	{r0,r1}
			MOV		r0, #IO_space
			LDR		r1, [r0, #PIO_A]
			AND 	r1, r1, #0b11111110     ; Set E=0
			STR 	r1, [r0, #PIO_A]     
			POP		{r0,r1}
			MOV		PC, LR

;---------------------------
; LCD_backlight_on
; 	Turns on the board backlight
;
;	Params: N/A
;	Return: N/A
;
; Tested : Yes
;---------------------------
LCD_backlight_on
			PUSH	{r0,r1}		
			MOV		r0, #IO_space	
			LDR		r1, [r0, #PIO_B]			; Load address of PIO_B (Port_B)
			ORR		r1, r1, #0b0010_0000		; Set backlight bit (5) to 1
			STR		r1, [r0, #PIO_B]			;
			POP		{r0,r1}						;
			MOV		PC, LR

;---------------------------
; LCD_backlight_off
; 	Turns off the board backlight
;
;	Params: N/A
;	Return: N/A
;
; Tested : Yes
;---------------------------
LCD_backlight_off
			PUSH	{r0-r4}
			MOV		r0, #IO_space
			LDR		r1, [r0, #PIO_B]
			AND		r1, r1, #0b1101_1111
			STR		r1, [r0, #PIO_B]
			POP		{r0,r1}
			MOV		PC, LR

LCD_io_wait
			MOV		r2, #IO_space
			LDR 	r3, [r2, #PIO_B]
    
			ORR 	r3, r3, #0b00000100     ; Set R/W=1
			AND 	r3, r3, #0b11111101     ; Set RS=0
			STR 	r3, [r2, #PIO_B]
        
_lcdiowait
			ORR 	r3, r3, #0b00000001     ; Set E=1
			STR 	r3, [r2, #PIO_B]
			
			;Read LCD status byte
			;MOV 	r0, #PIO_A             ; Load PortA addr
			LDR 	r1, [r2, #PIO_A]
			
			AND 	r3, r3, #0b11111110     ; Set E=0
			STR 	r3, [r2, #PIO_A]
			
			MOV 	r0, #PIO_A             ; Check if LCD is ready
			AND 	r4, r1, #0b10000000
			CMP 	r4, #0                  
			BNE 	_lcdiowait               ; If LCD is not ready, try again	  

            ;LCD is ready if here
			POP		{r0-r4}
			MOV		PC, LR

LCD_write_char
			PUSH {r1-r5}                ; Make sure we preserve these reg
			MOV r5, r0                  ; Make a copy of the arg
			
			BL	LCD_io_wait

			ORR r3, r3, #0b11111011     ; Set R/W=0        
			AND r3, r3, #0b00000010     ; Set RS=1 
			STR r3, [r2]
			
			STR r5, [r0]                ; Print the char given
			
			ORR r3, r3, #0b00000001     ; Set E=1
			STR r3, [r2]        
			AND r3, r3, #0b11111110     ; Set E=0
			STR r3, [r2]
			
			POP {r1-r5}
			MOV PC, LR                 ; Return back to print_str

