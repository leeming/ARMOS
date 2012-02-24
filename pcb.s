PCB_STATE_NEW       EQU    0x00
PCB_STATE_READY     EQU    0x01
PCB_STATE_BLOCKED   EQU    0x02
PCB_STATE_RUNNING   EQU    0x03
PCB_STATE_FINISHED  EQU    0x04


; This defines all the PCB parts + offsets
PCB_record          RECORD
PCB_OFFSET_ID       WORD
PCB_OFFSET_STATE    WORD
PCB_OFFSET_PC       WORD
PCB_OFFSET_REG      WORD    14
PCB_OFFSET_SP       WORD
                    WORD    99
PCB_OFFSET_STACK    WORD   
PCB_OFFSET_BOTTOM   WORD


PCB_NEXT_PROC_ID     DEFW   0x01        ; Next new proc id
PCB_CURRENT_ID       DEFW   0x01        ; PCB currently active
PCB_MAX_TIMESLICE    EQU    0x05        ; Number of clock ticks per timeslice
PCB_MAX_NUM          EQU    0x04        ; Maximum number of PCBs

PCB_SIZE             EQU    (PCB_OFFSET_BOTTOM - PCB_record)
;PCB_SIZE             EQU    0x80        ; Size of each PCB block

e_full_queue
        DEFB    "Error: Push to full Queue", 0
        ALIGN


; Few PCB setup routines to run thru before adding processes
PCB_setup
                PUSH    {R0,R1}

                ADR     R0, PCB_READY_QUEUE_HEAD    ; Set ready queue head
                ADR     R1, PCB_ready_queue
                STR     R1, [R0]

                ADR     R0, PCB_READY_QUEUE_TAIL    ; Set ready queue tail
                STR     R1, [R0]

                MOV     R1, #0xff                   ; Set queue as empty
                STR     R1, PCB_ready_queue

                POP     {R0,R1}
                MOV     PC, LR


PCB_save_reg
                PUSH    {LR}                    ; Keep a copy of LR since we are going
                                                ; to use this as a tmp register
                PUSH    {R0-R2}

                ; Change to SYSTEM mode
                MRS     R0, CPSR                ; Get current CPSR
                BIC     R0, R0, #&0F            ; Clear low order bits
                ORR     R0, R0, #MODE_SYSTEM    ; Set SYSTEM mode bits
                MSR     CPSR_c, R0              ; Rewrite CPSR
                NOP                             ; Apparently some ARM have a bug
                                                ; and this NOP fixes it

                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID      
                MOV     R1, #PCB_SIZE
                ADR     R2, PCB_offset          ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     R14, R1, R2             ; R13svc is now the base address for the PCB
                                                ; R0 , R1 and R2  no long needed

                ADD     R14, R14, #PCB_OFFSET_REG ;Address to store to
                POP     {R0-R2}                 ; Recover user reg before storing
                STMIA   R14!, {R0-R13,PC}       ; Store all reg to R14 pointer

                POP     {LR}                    ; Recover the original LR
                MOV     PC, LR

PCB_load_reg
                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                ADR     R2, PCB_offset          ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     R3, R1, R2              ; R13svc is now the base address for the PCB
                                                ; R0 , R1 and R2  no long needed
                ADD     R3, R3, #PCB_OFFSET_REG ;Address to load from
                LDMIA   R3, {R0-R12}            ; Load all reg

                MOV     PC, LR

; R0 is the start address of the program
PCB_create_process
                PUSH    {R1-R3,LR}
                PUSH    {R0}                    ; Make sure these are top of the stack
                                                ; as they are params for this routine


                ;Find next available PCB block
                BL      _PCB_find_next_avil

                ;Calculate block offset
                ;MOV     R1, #PCB_SIZE
                ;MOV     R1,  #(PCB_OFFSET_BOTTOM - PCB_RECORD) / 4
                MUL     R1, R1, R0              ; Offset from 'PCB_offset'

                ;Set process ID
                LDR     R2, PCB_NEXT_PROC_ID    ; Load next available ID
                ADR     R3, PCB_offset          ; Grab PCB offset and calculate
                ADD     R3, R3, R1              ; base address for this PCB

                STR     R2, [R3, #PCB_OFFSET_ID]; Store ID in PCB R0

                ADD     R2, R2, #1              ; Increment next available ID
                ADR     R4, PCB_NEXT_PROC_ID    ; Grab address location
                STR     R2, [R4]                ; Store new inc

                ;Set state
                MOV     R0, #PCB_STATE_NEW      ; Set state to NEW
                STR     R0, [R3, #PCB_OFFSET_STATE]

                ;Set stack pointer
                MOV     R0, #PCB_OFFSET_STACK
                STR     R0, [R3, #PCB_OFFSET_SP]

                ;Set initial PC
                POP     {R0}
                STR     R0, [R3, #PCB_OFFSET_PC]

                POP     {R1-R3,LR}
                MOV     PC, LR                  ;Return




_PCB_find_next_avil

                ;If we haven't even got to the max PCB yet
                ; we can just use the next ID as an offset
                LDR     R0, PCB_NEXT_PROC_ID
                MOV     R1, #PCB_MAX_NUM
         
                CMP     R0, R1                  ; Actually need id-1 since id is from 1 not 0
                BLT     _pick_head_pcb

                ; Scan for any finished processes
                ;TODO
                
                MOV     PC, LR

_pick_head_pcb
                ;At this stage R0 already holds the next proc id so just -1 and return
                SUB     R0, R0, #1
                MOV     PC, LR



                


; Ready queue for all runnable PCBs
PCB_READY_QUEUE_HEAD DEFW   0x00
PCB_READY_QUEUE_TAIL DEFW   0x00
PCB_ready_queue      DEFS  PCB_MAX_NUM*4, 0    ;The actual queue area
ALIGN
PCB_ready_queue_wrap nop                    ; If head/tail hits this, rewrite to top of queue area


PCB_push_ready_queue
                ;PUSH    {}
                LDR     R1, PCB_READY_QUEUE_HEAD
                LDR     R2, PCB_READY_QUEUE_TAIL

                CMP     R1, R2                  ; Check if queue is empty/1 element
                BEQ     _queue_same_ptr

_queue_wrap_check
                ADR     R3, PCB_ready_queue_wrap
                ADD     R4, R2, #4              ; R4 = Tail + 4
                CMP     R3, R4                  ; Wrap point == New tail?
                BEQ     _queue_wrap_top

                CMP     R4, R1                  ; Head == New tail?
                BEQ     _queue_full_exception


_queue_save_new_tail                            ; R4 must point to new tail
                STR     R0, [R4]                ; Store item at new tail
                ADR     R1, PCB_READY_QUEUE_TAIL; Update ptr to tail
                STR     R4, [R1]

                ;POP     {}
                MOV     PC, LR


_queue_same_ptr
                ;Check if value is 0xFF (empty) or not
                LDR     R3, [R1]
                CMP     R3, #0xFF

                BNE    _queue_wrap_check        ; 1 Item present already, continue
                                                ; to added to queue like normal

                MOV     R4, R1                  ; Else add first element at head (==tail)
                B       _queue_save_new_tail  

_queue_wrap_top
                ADR     R4, PCB_ready_queue     ; Grab addr of queue_top
                CMP     R1, R4                  ; New tail == head?
                BEQ     _queue_full_exception
                B       _queue_save_new_tail    ; Else add element to queue_top
                                                ; and update tail ptr

_queue_full_exception                           ; Print Exception & Hang (temp?)
                ADR     R0, e_full_queue
                BL      LCD_write_str
                B       end


; old code below??????????????????????????????????????????????????????

                ; Queue was empty
                STREQ   R0, [R2]                ; Store item at tail
                BEQ     _item_added

                ; Queue had 1 entry already
                ADDNE   R2, R2, #4              ; move tail ptr down
                ADR     R3, PCB_ready_queue_wrap
                CMP     R2, R3                  ; Check if ptr falls off bottom
                BEQ     _queue_add_wrap

                STR     R0, [R2]                ; No wrap needed, save to new tail
                ADR     R1, PCB_READY_QUEUE_TAIL; Update ptr to tail
                STR     R2, [R1]


_item_added
                ;POP     {}
                MOV     PC, LR

_queue_add_wrap



;PCB_push_ready_queue
                PUSH    {R1,R5}
                ;Check for full queue
                LDR     R1, PCB_READY_QUEUE_HEAD
                LDR     R2, PCB_READY_QUEUE_TAIL

                CMP     R1, R2                  ; Check obvious first, is the queue empty?
                MOVEQ   R3, R1
                BEQ     _push_ok
                

                ADD     R3, R1, #4
                CMP     R3, R2                  ; Check if Tail = Head + 4

                MVNEQ   R0, #1                  ; Return -1 for full queue
                MOVEQ   PC, LR

                ADR     R4, PCB_ready_queue_wrap
                CMP     R3, R4                  ; Check head needs to wrap-around

                ADR     R5, PCB_ready_queue
                MOVEQ   R3, R5                  ; R3 is the new head ptr, therefore
                                                ; if wrap-around, set as top of queue

                CMPEQ   R2, R5                  ; Check if tail at top of queue
                                                ; if it is, queue is full

                MVNEQ   R0, #1                  ; Return -1 for full queue
                MOVEQ   PC, LR

                ; If here need we can place the item (R0) at the new head (R3)
_push_ok        STR     R0, [R3]

                POP     {R1,R5}
                MOV     PC, LR

PCB_pop_ready_queue
                ;Check for empty queue
                LDR     R0, PCB_READY_QUEUE_HEAD
                LDR     R1, PCB_READY_QUEUE_TAIL
                CMP     R0, R1

                MVNEQ   R0, #1                  ; Return -1 for empty queue
                MOVEQ   PC, LR

                LDR     R2, [R0], #-4           ; Get value at head of queue & move head ptr

                ADR     R3, PCB_ready_queue     ; Check to see if head ptr goes past the
                                                ; wrap around address
                CMP     R0, R3
                MOVGE   PC, LR                  ; Return if not wrap around

                ; If here need to correct the queue wrap around
                ADR     R4, PCB_ready_queue_wrap
                SUB     R4, R4, #4
                STR     R4, [R0]

PCB_total       EQU     PCB_SIZE*PCB_MAX_NUM
PCB_offset      DEFS    PCB_total