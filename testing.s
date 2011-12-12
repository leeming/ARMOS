INCLUDE	params_labboard.s



ADRL	SP, stack_p


mov r0, #&42
bl LCD_write_char
mov r0, #&52
bl LCD_write_char
mov r0, #&62
bl LCD_write_char
mov r0, #&45
bl LCD_write_char



end b .

INCLUDE lib/LCD.s
INCLUDE lib/LED.s

mystring 	DEFB 	"Hello World!", 0		

		DEFS	100
stack_p

