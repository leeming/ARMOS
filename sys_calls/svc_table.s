; SVC Table
svc_table	DEFW	_exit					; 0 - Exits the program 
			DEFW	LCD_clear				; 1 - Clears the LCD display
			DEFW	LCD_write_char			; 2 - Print a character on the LCD
			DEFW	LCD_write_str			; 3 - Prints a string on the LCD
            DEFW    clock_read              ; 4 - Gets time (returned in R0)
            DEFW    LCD_print_dec           ; 5 - Prints a decimal number to LCD
            DEFW    LCD_set_cursor          ; 6 - Sets the LCD cursor
            DEFW    PCB_create_process
            DEFW    LED_on
            DEFW    LED_off
            DEFW    LED_toggle
svc_table_end

svc_unknown	ADRL	R0, svc_unknown_str		; Grab error to print out
			SVC		print_str

			B		end						; Run unknown svr routine

; Friendly text names for the sys calls
exit			EQU		0
clear_screen	EQU		1
print_char		EQU		2
print_str		EQU		3
read_clk        EQU     4
print_dec       EQU     5
set_lcd_cursor  EQU     6
new_process     EQU     7
led_on          EQU     8
led_off         EQU     9
led_toggle      EQU     10


;SVC_MAX		EQU		7						; Number of SVC routines
SVC_MAX			EQU	(svc_table_end-svc_table)


;Temp
end
_exit           MOV R0, #123
                MOV R1, #IO_space
                STR R0, [R1, #HALT]
                B .                             ; Shouldnt get here, but just incasE?