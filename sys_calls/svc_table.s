; SVC Table
svc_table	DEFW	_exit					; 0 - Exits the program 
			DEFW	LCD_clear				; 1 - Clears the LCD display
			DEFW	LCD_write_char			; 2 - Print a character on the LCD
			DEFW	LCD_write_str			; 3 - Prints a string on the LCD
            DEFW    clock_read              ; 4 - Gets time (returned in R0)
            DEFW    LCD_print_dec           ; 5 - Prints a decimal number to LCD
            DEFW    LCD_set_cursor          ; 6 - Sets the LCD cursor
            DEFW    clock_callback
svc_table_end

svc_unknown	ADR		R0, svc_unknown_str		; Grab error to print out
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

SVC_MAX		EQU		6						; Number of SVC routines
;SVC_MAX			EQU	(svc_table_end-svc_table)


;Temp
end
_exit		B .