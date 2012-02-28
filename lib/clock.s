; Reads the clock and returns a 8bit value (~1/255th second)

CLOCK_TICK     DEFW   0         ; Number of ticks since start
CLOCK_TICK_LEN DEFW   100       ; Number of ms per tick

CLOCK_BIG_TICK      DEFW    0
CLOCK_BIG_TICK_LEN  DEFW    100


clock_tick
        PUSH    {R3-R6}
        BIC     R3, R3, #TIMER          ; Clear bit so we know it has been serviced
        STRB    R3, [R4, #IRQ_SRC]
        LDRB    R3, [R4,#TIMER_CMP]     ; Load the timer compare
        ADD     R3, R3, #CLOCK_TICK_LEN
        STRB    R3, [R4,#TIMER_CMP]     ; Store updated timer compare
        MOV     R3, #0
        STRB    R3, [R4,#IRQ_SRC]       ; Reset IRQ flags

        ; Add one to tick counter
        ADR     R2, CLOCK_TICK
        LDR     R3, [R2]
        ADD     R3, R3, #1

        ADR     R4, CLOCK_BIG_TICK_LEN
        LDR     R5, [R4]

        CMP     R3, R5                  ; Check to see if big tick happens
        MOVEQ   R3, #0                  ; Yes, reset small tick
        STR     R3, [R2]

        PUSH    {LR}
        BLEQ    _do_big_tick
        POP     {LR}

        ; Should we do anything on this tick?
        ; TODO


        POP     {R3-R6}
        B       irq_end

_do_big_tick
        ADR     R4, CLOCK_BIG_TICK
        LDR     R5, [R4]
        ADD     R5, R5, #1
        STR     R5, [R4]

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