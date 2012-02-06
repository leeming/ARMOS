;---------------------------------------------------;
; Simple program to print "Hello World!" on the LCD ;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        2 Feb 2012                  ;
;       Last Updated:   2 Feb 2012                  ;
;                                                   ;
;---------------------------------------------------; 


        ADR r0, helloString
        SVC print_str

        B helloworldEnd

helloString
        DEFB    "Hello World!", 0
        ALIGN

helloworldEnd   nop