change_mode
            ; Change to IRQ mode
            MRS     R1, CPSR                ; Get current CPSR
            BIC     R1, R1, #&0F            ; Clear low order bits
            ORR     R1, R1, R0              ; Set mode bits
            MOV     R0, LR                  ; Save LR as its local to current mode
            MSR     CPSR_c, R1              ; Rewrite CPSR
            NOP                             ; Apparently some ARM have a bug
                                            ; and this NOP fixes it

            MOV     PC, R0
