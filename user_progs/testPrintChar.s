;---------------------------------------------------;
; Simple program to print some characters on the LCD;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        6 Feb 2012                  ;
;       Last Updated:   6 Feb 2012                  ;
;                                                   ;
;---------------------------------------------------;


        MOV R0, #&30
        SVC print_char
        MOV R0, #&31
        SVC print_char
        MOV R0, #&32
        SVC print_char
        MOV R0, #&33
        SVC print_char
        MOV R0, #&34
        SVC print_char
        MOV R0, #&35
        SVC print_char
        MOV R0, #&36
        SVC print_char
        MOV R0, #&37
        SVC print_char
        MOV R0, #&38
        SVC print_char
        MOV R0, #&39
        SVC print_char

        B testPrintCharEnd



testPrintCharEnd   nop
