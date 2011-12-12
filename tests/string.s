INCLUDE	../params_labboard.s


	ADRL	SP, stack_p		;Set up stack


	ADR		r0, mystring	; Grab string address
	BL 		LCD_write_str	; Print out string

	END b .					;End

INCLUDE ../lib/LCD.s
INCLUDE ../lib/LED.s

mystring 	DEFB 	"Hello World!", 0		

		DEFS	100
stack_p

