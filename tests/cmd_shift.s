INCLUDE	../params_labboard.s


	ADRL	SP, stack_p		;Set up stack

	mov r0, #&42
	bl LCD_write_char
	mov r0, #&52
	bl LCD_write_char


	MOV		R0, #01	;Clear
	BL 		LCD_write_cmd

	END b .					;End

INCLUDE ../lib/LCD.s
INCLUDE ../lib/LED.s

mystring 	DEFB 	"Hello World!", 0		

		DEFS	100
stack_p

