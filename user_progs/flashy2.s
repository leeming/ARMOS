;---------------------------------------------------;
; Simple program to print a counter on the LCD      ;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        28 Feb 2012                 ;
;                                                   ;
;---------------------------------------------------;  

flashy2Start
                MOV     R0, #0      ; Red LED
                MOV     R1, #1      ; Right hand side

                MOV     R2, #0
flashy2Main
                


                MOV     R3, #0x1F000
_flashy2_subLoop SUB     R3, R3, #1
                CMP     R3, #0
                BNE _flashy2_subLoop

                SVC     led_toggle

 B flashy2Main

                CMP     R2, #0
                MOVEQ   R2, #1
                MOVNE   R2, #0
                SVCEQ   led_on
                SVCNE   led_off


                B flashy2Main