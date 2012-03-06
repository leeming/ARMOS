CLOCK_TICK          DEFW   0            ; Number of ticks since start
CLOCK_TICK_LEN      DEFW   100          ; Number of ms per tick

CLOCK_BIG_TICK      DEFW    0
CLOCK_BIG_TICK_LEN  DEFW    1;40


;-------------------
; Increments the internal clock counter.
;   R0 is set to #IO_SPACE from irq
;-------------------
clock_tick
        PUSH    {R2-R5}
        BIC     R3, R3, #TIMER          ; Clear bit so we know it has been serviced
        STRB    R3, [R0, #IRQ_SRC]
        LDRB    R3, [R0,#TIMER_CMP]     ; Load the timer compare
        ADD     R3, R3, #CLOCK_TICK_LEN
        STRB    R3, [R0,#TIMER_CMP]     ; Store updated timer compare
        MOV     R3, #0
        STRB    R3, [R0,#IRQ_SRC]       ; Reset IRQ flags

        ; Add one to tick counter
        ADR     R2, CLOCK_TICK
        LDR     R3, [R2]
        ADD     R3, R3, #1

        ADR     R4, CLOCK_BIG_TICK_LEN
        LDR     R5, [R4]

        CMP     R3, R5                  ; Check to see if big tick happens
        MOVEQ   R3, #0                  ; Yes, reset small tick
        STR     R3, [R2]

        BEQ    _do_big_tick

        POP     {R2-R5}
        B       irq_end

_do_big_tick
        ADR     R4, CLOCK_BIG_TICK
        LDR     R5, [R4]
        ADD     R5, R5, #1
        STR     R5, [R4]

        B       PCB_irq

;-------------------
; Resets the big tick counter
; ** TODO ** Reset little tick counter too
;-------------------
clock_tick_reset
        PUSH    {R0,R1}
        ADR     R0, CLOCK_BIG_TICK
        MOV     R1, #0
        STR     R1, [R0]

        POP     {R0,R1}
        MOV     PC, LR        



; Old code below here??????
clock_read
			push	{r1}
			mov		r1, #IO_space
			ldrb	r0, [r1,#TIMER_CMP]		; Load the timer compare
			pop		{r1, pc}^

clock_set_cmp
			push	{r3,r4}
			
			mov     r4, #IO_space 
			ldrb    r3, [r4,#TIMER_CMP]     ; Load the timer compare
            add     r3, r3, R0              ; Add an additional [R0]ms
            strb    r3, [r4,#TIMER_CMP]     ; Store updated timer compare
			pop		{r3,r4,pc}^


print_time
            push    {r0}
            SVC     clear_screen

            MOV R0, R9
            BL LCD_print_dec

            pop     {r0}
            b       irq_end