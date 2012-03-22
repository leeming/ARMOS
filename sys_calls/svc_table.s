; SVC Table
svc_table	DEFW	_exit					; 0 - Exits the program 
			DEFW	LCD_clear				; 1 - Clears the LCD display
			DEFW	LCD_write_char			; 2 - Print a character on the LCD
			DEFW	LCD_write_str			; 3 - Prints a string on the LCD
            DEFW    clock_read              ; 4 - Gets time (returned in R0)
            DEFW    LCD_print_dec           ; 5 - Prints a decimal number to LCD
            DEFW    LCD_set_cursor          ; 6 - Sets the LCD cursor
            DEFW    PCB_create_process      ; 7 - Creates a process with start addr at R0
            DEFW    LED_on                  ; 8 - Turns LED on where R0 is colour and R1 LHS/RHS
            DEFW    LED_off                 ; 9 - Turns LED off where R0 is colour and R1 LHS/RHS
            DEFW    LED_toggle              ; 10- Toggles LED on/off where R0 is colour and R1 LHS/RHS
            DEFW    PCB_nice                ; 11- Allows a process to deschedule itself
            DEFW    PCB_terminate           ; 12- Terminate a process 
svc_table_end

svc_unknown	ADRL	R0, svc_unknown_str		; Grab error to print out
			SVC		print_str

			B		end						; Run unknown svr routine

; Friendly text names for the sys calls
exit			    EQU		0
clear_screen	    EQU		1
print_char		    EQU		2
print_str		    EQU		3
read_clk            EQU     4
print_dec           EQU     5
set_lcd_cursor      EQU     6
new_process         EQU     7
led_on              EQU     8
led_off             EQU     9
led_toggle          EQU     10
nice                EQU     11
kill                EQU     12

SVC_MAX			    EQU	(svc_table_end-svc_table)   ; Number of SVC routines


end
_exit               MOV R0, #123
                    MOV R1, #IO_space
                    STR R0, [R1, #HALT]
                    B .                             ; Shouldnt execute this, but just incase