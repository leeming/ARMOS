;
; Collection of math related functions
;


; http://www.sciencezero.org/index.php?title=ARM:_Division_by_10
div_10
        ADD     r1,r0,r0,lsl #1
        ADD     r0,r0,r1,lsl #2
        ADD     r0,r0,r1,lsl #6
        ADD     r0,r0,r1,lsl #10
        MOV     r0,r0,lsr #15
        MOV     PC, LR

