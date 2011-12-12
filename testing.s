INCLUDE	params_labboard.s



ADRL	SP, stack_p


mov r0, #&42
bl LCD_write_char


end b .

INCLUDE lib/LCD.s
INCLUDE lib/LED.s



		DEFS	100
stack_p

