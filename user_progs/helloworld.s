;---------------------------------------------------;
; Simple program to print "Hello World!" on the LCD ;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        2 Feb 2012                  ;
;       Last Updated:   16 Feb 2012                 ;
;                                                   ;
;---------------------------------------------------; 

helloString
        DEFB    "Hello World!", 0
        ALIGN

helloworldStart
        nop

helloworldMain
        ADR r0, helloString
        SVC print_str



