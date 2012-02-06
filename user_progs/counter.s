;---------------------------------------------------;
; Simple program to print a counter on the LCD      ;
;                                                   ;
;   By Andrew Leeming                               ;
;       Created:        2 Feb 2012                  ;
;       Last Updated:   6 Feb 2012                  ;
;                                                   ;
;---------------------------------------------------;  

counterStart    
                ;MOV R0, #1
                ;MOV R1, #0
                ;SVC set_lcd_cursor


;Spinlock to waste some time
                LDR r0, spinlockMax
_subLoop        SUB r0, r0, #1
                CMP r0, #0
                BNE _subLoop

                LDR r0, currentCounter
                ADD r0, r0, #1
                STR r0, currentCounter

                nop;check R0 before
                SWI clear_screen

                nop;check R0 after
                BL LCD_print_dec


                B counterStart


spinlockMax      DCD    0x0000FFFF
currentCounter   DCD    0