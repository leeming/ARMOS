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
			ORR 	r1, r1, #0b0000_0001     ; Set E=1
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
			AND 	r1, r1, #0b1111_1110     ; Set E=0
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

;---------------------------
; LCD_io_wait
; 	Waits for LCD to become ready, called
;	from LCD_write_char and LCD_read_char (?)
;
;	Params: N/A
;	Return: N/A
;
; Tested : No - ish
;---------------------------
LCD_io_wait
			PUSH	{r0-r3}
			MOV		r0, #IO_space
			LDR 	r2, [r0, #PIO_B]
    
			ORR 	r2, r2, #0b00000100     ; Set R/W=1
			AND 	r2, r2, #0b11111101     ; Set RS=0
			STR 	r2, [r0, #PIO_B]
        
_lcdiowait
			ORR 	r2, r2, #0b00000001     ; Set E=1
			STR 	r2, [r0, #PIO_B]
			
			;Read LCD status byte    
			LDR 	r1, [r0, #PIO_A]		; Load PortA addr
			
			AND 	r2, r2, #0b11111110     ; Set E=0
			STR 	r2, [r0, #PIO_A]
			           
			AND 	r3, r1, #0b10000000		; Check if LCD is ready
			CMP 	r3, #0                  
			BNE 	_lcdiowait               ; If LCD is not ready, try again	  

            ;LCD is ready if here
			POP		{r0-r3}
			MOV		PC, LR

;---------------------------
; LCD_write_char
; 	<desc>
;
;	Params: R0 - Char to print
;	Return: N/A
;
; Tested : No
;---------------------------
LCD_write_char
			PUSH 	{r1-r3,LR}                ; Make sure we preserve these reg
			;MOV r5, r0                  ; Make a copy of the arg
			
			BL		LCD_io_wait				; Do spinloop until ready

			MOV		r1, #IO_space
			LDR 	r3, [r0, #PIO_B]
			ORR 	r3, r3, #0b11111011     ; Set R/W=0        
			AND 	r3, r3, #0b00000010     ; Set RS=1 
			STR 	r3, [r1, #PIO_B]
			
			STR 	r0, [r1, #PIO_A]        ; Print the char given
			
			ORR 	r3, r3, #0b00000001     ; Set E=1
			STR 	r3, [r1, #PIO_B]        
			AND 	r3, r3, #0b11111110     ; Set E=0
			STR 	r3, [r1, #PIO_B]
			
			POP 	{r1-r3,LR}
			MOV 	PC, LR                 ; Return back to print_str


;---------------------------
; LCD_write_str
; 	Prints a string that is pointed to
;	by the address in R0. Strings are
;	null terminated.
;
;	Params: R0 - Address of string to print
;	Return: N/A
;
; Tested : Yes
;---------------------------
LCD_write_str
			PUSH 	{r0,r4,LR}			; Save Reg that are used

_fetch_char 
			LDRB 	r4, [r0], #1   		; Fetch character
            CMP  	r4, #0         		; Check for null char
            BEQ  	_print_str_end

			PUSH	{r0}
            MOV  	r0,r4          		; Put char to print into R0
            BL   	LCD_write_char  	; Do print_char
			POP		{r0}

            B   	_fetch_char			; Get next char
_print_str_end                
            POP 	{r0,r4,LR}
            MOV 	PC,LR

;---------------------------
; LCD_write_cmd
; 	Sends a command character to the LCD
;
;	Params: R0 - Command character #
;	Return: N/A
;
; Tested : No - Only clear
;---------------------------
LCD_write_cmd
			PUSH 	{r1,r2,LR}              ; Make sure we preserve these reg

			BL		LCD_io_wait				; Do spinloop until ready

			MOV		r1, #IO_space
			LDR 	r2, [r0, #PIO_B]
			AND		r2, r2, #0b11111001     ; Set R/W=0 & RS=0
			EOR 	r2, r2, #0b00000000     ;

			STR 	r2, [r1, #PIO_B]
			STR 	r0, [r1, #PIO_A]        ; Print the char given
			
			ORR 	r2, r2, #0b00000001     ; Set E=1
			STR 	r2, [r1, #PIO_B]
			AND 	r2, r2, #0b11111110     ; Set E=0
			STR 	r2, [r1, #PIO_B]
			
			POP 	{r1,r2,LR}
			MOV 	PC, LR                 ; Return back to print_str


;---------------------------
; LCD_clear
; 	Wrapper routine to clear the LCD
;
;	Params: N/A
;	Return: N/A
;
; Tested : No 
;---------------------------
LCD_clear
        PUSH    {R0, LR}
        MOV		r0, #01
        BL		LCD_write_cmd
        POP     {R0, LR}
        MOV     PC, LR

LCD_set_cursor
        ;Set row
        CMP     r0, #0      
        MOVEQ   r0, #&00       ; First row
        MOVNE   r0, #&40       ; Second row
        ;Set column
        ADD     r0, r0, r1      ; Set position to be row+col
        ORR     r0, r0, #&80  ; OR with set cursor command
        B   LCD_write_cmd


;------------------------------------------------------
;                       Unprivileged
;------------------------------------------------------


;---------------------------
; LCD_print_dec_digit
;   Prints a single digit on the LCD
;
;   Params: R0 - Single digit to print
;   Return: N/A
;---------------------------
LCD_print_dec_digit
        PUSH    {LR}
        ADD r0, r0, #ASCII_OFFSET_0
        SVC print_char
        POP     {LR}
        MOV PC,LR

;---------------------------
; LCD_print_dec
;   Prints the decimal value of R0 to the LCD
;
;   Params: R0 - Value to print
;   Return: N/A
;---------------------------
LCD_print_dec
        PUSH    {R0-R3,LR}          ; Save registers


        BL bcd_convert              ; Convert into BCD
        MOV R1, R0                  ; Make a copy of R0

        ;Find out the number of digits to print out
        CMP R0, #&0F00_0000
        MOVHI R2, #8
        BHI _print_digit_loop
        CMP R0, #&00F0_0000
        MOVHI R2, #7
        BHI _print_digit_loop
        CMP R0, #&00F_0000
        MOVHI R2, #6
        BHI _print_digit_loop
        CMP R0, #&0000_F000
        MOVHI R2, #5
        BHI _print_digit_loop
        CMP R0, #&0000_0F00
        MOVHI R2, #4
        BHI _print_digit_loop
        CMP R0, #&0000_00F0
        MOVHI R2, #3
        BHI _print_digit_loop
        CMP R0, #&0000_000F
        MOVHI R2, #2
        BHI _print_digit_loop
        MOVLE R2, #1

_print_digit_loop
        SUB R3, R2, #1
        MOV R3, R3 LSL #2
        MOV R0, R1 LSR R3              ; Get the highest digit (shift R2*4 bits right)
        BIC R0, R0, #&FFFF_FFF0     ; Grab RHS 4bits
        BL LCD_print_dec_digit      ; Print digit to LCD

        SUB R2, R2, #1              ; Decrement remaining digits to print
        CMP R2, #0                  ; Loop back if there is still more digits
        BNE _print_digit_loop       ; to print


        POP     {R0-R3,LR}          ; Recover registers
        MOV PC,LR                   ; and return