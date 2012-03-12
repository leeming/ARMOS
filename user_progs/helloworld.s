;---------------------------------------------------;
; Simple program to print "Hello World!" on the LCD ;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        2 Feb 2012                  ;
;       Last Updated:   16 Feb 2012                 ;
;                                                   ;
;---------------------------------------------------; 

helloString
        DEFB    "Context Switching (y)", 0
        ALIGN

helloworldStart

        ; Set user registers to known values
        MOV     R0, #&F0
        MOV     R1, #&F1
        MOV     R2, #&F2
        MOV     R3, #&F3
        MOV     R4, #&F4
        MOV     R5, #&F5
        MOV     R6, #&F6
        MOV     R7, #&F7
        MOV     R8, #&F8
        MOV     R9, #&F9
        MOV     R10, #&FA
        MOV     R11, #&FB
        MOV     R12, #&FC

        ; Tell scheduler to deschedule this process
        ; here we can check to see if the reg are saved
        SVC nice

        ; When we are back here, check to see if reg
        ; where restored correctly.
        

helloworldMain
        ADR r0, helloString
        SVC print_str



