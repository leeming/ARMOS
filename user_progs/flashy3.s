;---------------------------------------------------;
; Simple program to print a counter on the LCD      ;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        6 March 2012                ;
;                                                   ;
;---------------------------------------------------;  

flashy3Start
                MOV     R0, #1      ; ?? LED
                MOV     R1, #1      ; Right hand side

                MOV     R2, #0
flashy3Main
                


                MOV     R3, #0x3C000
_flashy3_subLoop SUB     R3, R3, #1
                CMP     R3, #0
                BNE _flashy3_subLoop

                SVC     led_toggle

 B flashy3Main

                CMP     R2, #0
                MOVEQ   R2, #1
                MOVNE   R2, #0
                SVCEQ   led_on
                SVCNE   led_off


                B flashy3Main