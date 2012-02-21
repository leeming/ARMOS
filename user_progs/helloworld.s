;---------------------------------------------------;
; Simple program to print "Hello World!" on the LCD ;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        2 Feb 2012                  ;
;       Last Updated:   16 Feb 2012                 ;
;                                                   ;
;---------------------------------------------------; 

helloworldMain
        ADR r0, helloString
        SVC print_str

        B helloworldEnd



helloworldEnd   B .


helloString
        DEFB    "Hello World!", 0
        ALIGN