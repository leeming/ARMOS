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
PCB_QUEUE_NULL       EQU    0xFF



PCB_SPARE_BLOCK_QUEUE   DEFS    QUEUE_record_size
ALIGN
PCB_READY_QUEUE         DEFS    QUEUE_record_size
ALIGN



; Few PCB manager setup routines to run thru before adding processes
PCB_setup
                PUSH    {R0,R1,LR}

                ; Set up spare blocks queue
                ADR     R0, PCB_SPARE_BLOCK_QUEUE
                BL      QUEUE_init
                MOV     R1, R0
                MOV     R0, #PCB_MAX_NUM
                SUB     R0, R0, #1

_setup_loop     BL      QUEUE_add
                SUB     R0, R0, #1
                CMP     R0, #0
                BGE     _setup_loop


                ; Set up ready queue
                ADR     R0, PCB_READY_QUEUE
                BL      QUEUE_init
                

                POP     {R0,R1,LR}
                MOV     PC, LR


PCB_save_reg
                PUSH    {LR}                    ; Keep a copy of LR since we are going
                                                ; to use this as a tmp register
                PUSH    {R0-R2}

                ; Change to SYSTEM mode
                MRS     R0, CPSR                ; Get current CPSR
                BIC     R0, R0, #MODE_BITMASK   ; Clear low order bits
                ORR     R0, R0, #MODE_SYSTEM    ; Set SYSTEM mode bits
                MSR     CPSR_c, R0              ; Rewrite CPSR
                NOP                             ; Apparently some ARM have a bug
                                                ; and this NOP fixes it

                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID      
                MOV     R1, #PCB_SIZE
                ADR     R2, PCB_offset          ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     R14, R1, R2             ; R14svc is now the base address for the PCB
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

                ;LDR     SP  [R3, #PCB_OFFSET_PC]; SP is now being used as a temp
                                                ; reg to hold the process PC

                ADD     R3, R3, #PCB_OFFSET_REG ;Address to load from
                LDMIA   R3, {R0-R12}            ; Load all reg

                MOV     PC, LR

; R0 is the start address of the program
PCB_create_process
                PUSH    {R1-R3,LR}
                PUSH    {R0}                    ; Make sure these are top of the stack
                                                ; as they are params for this routine


                ;Find next available PCB block
                ADR     R1, PCB_SPARE_BLOCK_QUEUE
                BL      QUEUE_remove
;                BL      _PCB_find_next_avil

                ;Calculate block offset
                ;MOV     R1, #PCB_SIZE
                MOV     R1,  #PCB_OFFSET_BOTTOM
                MUL     R1, R1, R0              ; Offset from 'PCB_offset'

                ;Set process ID
                LDR     R2, PCB_NEXT_PROC_ID    ; Load next available ID
                ADR     R3, PCB_offset          ; Grab PCB offset and calculate
                ADD     R3, R3, R1              ; base address for this PCB

                STR     R2, [R3, #PCB_OFFSET_ID]; Store ID in PCB R0

                ADD     R2, R2, #1              ; Increment next available ID
                ADR     R4, PCB_NEXT_PROC_ID    ; Grab address location
                STR     R2, [R4]                ; Store new inc

                ;Stick on ready queue
                ADR     R1, PCB_READY_QUEUE
                BL      QUEUE_add

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


PCB_run
                PUSH    {R1, LR}    ;Do i actually want this? since this is exited via IRQ [wrong stack]
                ; Pick queue head
                ADR R1, PCB_READY_QUEUE
                BL  QUEUE_remove

                ADR R2, PCB_CURRENT_ID
                STR R0, [R2]

                ; Save supervisor SP and use it as a temp reg to hold new PC
                ADR R1, PCB_saved_sp
                STR SP, [R1]

                ; Load PCB
                BL PCB_load_reg

                ; Move into user mode (not using change_mode routine as we
                ; need to preserve regs [use LR as temp reg])
                MRS     LR, CPSR                ; Get current CPSR
                BIC     LR, LR, #MODE_BITMASK   ; Clear low order bits
                ORR     LR, LR, #MODE_USER      ; Set mode bits
                MSR     CPSR_c, LR              ; Rewrite CPSR
                NOP



                ; Run code

                MOV     PC, LR

PCB_irq                


PCB_saved_sp    DEFW    1

PCB_total       EQU     PCB_SIZE*PCB_MAX_NUM
PCB_offset      DEFS    PCB_total
PCB_offset_end  NOP