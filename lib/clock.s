; Reads the clock and returns a 8bit value (~1/255th second)

CLOCK_TICK     DEFW   0         ; Number of ticks since start
CLOCK_TICK_LEN DEFW   100       ; Number of ms per tick



clock_tick
            BIC     R3, R3, #TIMER          ; Clear bit so we know it has been serviced
            STRB    R3, [R4, #IRQ_SRC]
            LDRB     R3, [R4,#TIMER_CMP]     ; Load the timer compare
            ADD     R3, R3, #CLOCK_TICK_LEN
            STRB     R3, [R4,#TIMER_CMP]     ; Store updated timer compare
            MOV     R3, #0
            STRB    R3, [R4,#IRQ_SRC]       ; Reset IRQ flags

        ; Add one to tick counter
        ADR     R2, CLOCK_TICK
        LDR     R3, [R2]
        ADD     R3, R3, #1
        STR     R3, [R2]

        ;Hacky way to scale timer
        ADD     R10, R10, #1
        CMP     R10, #0x1F
        BLT     irq_end

        MOV     R10, #0
        CMP     R11, #0

        MOVEQ   R11, #1
        MOVEQ   R0, #1
        BEQ     LED_blue_on

        MOVNE   R11, #0
        MOVNE   R0, #1
        BNE     LED_blue_on


        ; Should we do anything on this tick?
        ; TODO

        B       irq_end







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