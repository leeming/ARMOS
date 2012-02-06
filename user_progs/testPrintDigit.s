;---------------------------------------------------;
; Simple program to print some numbers on the LCD   ;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        6 Feb 2012                  ;
;       Last Updated:   6 Feb 2012                  ;
;                                                   ;
;---------------------------------------------------;


;Single digits first
        MOV R0, #10
        SVC print_dec
        MOV R0, #227
        SVC print_dec

        LDR R0, number1
        SVC print_dec


        B testPrintDigitsEnd


number1 DEFW    76543210


testPrintDigitsEnd   nop