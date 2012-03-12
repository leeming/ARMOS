;---------------------------------------------------;
; Simple program to print a counter on the LCD      ;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        28 Feb 2012                 ;
;                                                   ;
;---------------------------------------------------;  

flashyStart
                MOV     R0, #0      ; Red LED
                MOV     R1, #0      ; Left hand side

                MOV     R2, #0
flashyMain
                


                MOV     R3, #0x0F000
_flashy_subLoop SUB     R3, R3, #1
                CMP     R3, #0
                BNE _flashy_subLoop

                SVC     led_toggle

 B flashyMain

                CMP     R2, #0
                MOVEQ   R2, #1
                MOVNE   R2, #0
                SVCEQ   led_on
                SVCNE   led_off


                B flashyMain