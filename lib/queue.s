QUEUE_record            RECORD
QUEUE_head              WORD
QUEUE_tail              WORD
QUEUE_area              WORD    10  ; Number of items allowed in queue (extend if needed?)
QUEUE_record_size       WORD

QUEUE_null              EQU    0xFF


; Init a queue
; R0 - Ptr to queue record
QUEUE_init
                PUSH    {R1,R2}

                ; Set head
                ADD     R1, R0, #QUEUE_area
                STR     R1, [R0, #QUEUE_head]

                ; Set tail (=head)
                STR     R1, [R0, #QUEUE_tail]

                ; Set first queue element as special null value
                MOV     R2, #QUEUE_null
                STR     R2, [R0, #QUEUE_area]

                POP     {R1,R2}
                MOV PC, LR


; R0: Value to put on queue
; R1: Queue to add to
QUEUE_add
                PUSH    {R1-R6}
                
                ; Get the offset addr for queue head & tail
                LDR     R3, [R1, #QUEUE_head]
                LDR     R4, [R1, #QUEUE_tail]

                CMP     R3, R4                  ; Check if queue is empty/1 element
                BEQ     _queue_add_same_ptr

_queue_wrap_check
                ADD     R5, R1, #QUEUE_record_size
                ADD     R6, R4, #4              ; R6 = Tail + 4
                CMP     R5, R6                  ; Wrap point == New tail?
                BEQ     _queue_wrap_top

                CMP     R6, R3                  ; Head == New tail?
                BEQ     _queue_full_exception


_queue_save_new_tail                            ; R6 must point to new tail
                STR     R0, [R6]                ; Store item at new tail
                ADD     R3, R1, #QUEUE_tail     ; Update ptr to tail
                STR     R6, [R3]

                POP     {R1-R6}
                MOV     PC, LR


_queue_add_same_ptr
                ;Check if value is empty or not
                LDR     R5, [R3]
                CMP     R5, #QUEUE_null

                BNE    _queue_wrap_check        ; 1 Item present already, continue
                                                ; to added to queue like normal

                MOV     R6, R3                  ; Else add first element at head (==tail)
                B       _queue_save_new_tail

_queue_wrap_top
                ADD     R6, R1, #QUEUE_area     ; Grab addr of queue_top
                CMP     R3, R6                  ; New tail == head?
                BEQ     _queue_full_exception
                B       _queue_save_new_tail    ; Else add element to queue_top
                                                ; and update tail ptr

; End PCB_add_ready_queue

; Returns item on R0
; R1: Queue to remove from
QUEUE_remove
                PUSH    {R2-R4}
                ;Check for empty queue
                LDR     R2, [R1, #QUEUE_head]
                LDR     R3, [R1, #QUEUE_tail]
                CMP     R2, R3

                BEQ    _queue_remove_same_ptr

                LDR     R0, [R2]                ; Grab the contents of the head
                ADD     R2, R2, #4
                ADD     R4, R1, #QUEUE_record_size; Check to see if the new ptr
                CMP     R2, R4                  ; overlaps the queue boundry
                BEQ     _queue_wrap_head
                                                ;else continue onto save
_queue_remove_save
                ADD     R3, R1, #QUEUE_head
                STR     R2, [R3]

                POP    {R2-R4}
                MOV     PC, LR


_queue_remove_same_ptr
                MOV     R4, #QUEUE_null
                LDR     R0, [R2]                ; Grab the head's value
                CMP     R0, R4                  ; Does head's value == null?

                BEQ     _queue_empty_exception
                STR     R4, [R2]                ; then replace with the null seq
                                                ; instead of changing the head ptr
                B       _queue_remove_save

_queue_wrap_head
                ADD     R2, R1, #QUEUE_area     ; Reset ptr to top of queue space
                ADD     R3, R1, #QUEUE_head     ; and save
                STR     R2, [R3]
                B       _queue_remove_save
; End QUEUE_remove



_queue_full_exception                           ; Print Exception & Hang (temp?)
                BL      LCD_clear
                ADRL    R0, e_full_queue
                BL      LCD_write_str
                B       end

_queue_empty_exception                          ; Print Exception & Hang (temp?)
                BL      LCD_clear
                ADRL    R0, e_empty_queue
                BL      LCD_write_str
                B       end