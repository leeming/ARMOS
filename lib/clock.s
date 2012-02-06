; Reads the clock and returns a 8bit value (~1/255th second)

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