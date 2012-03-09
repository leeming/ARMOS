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
PCB_OFFSET_REG      WORD    13
PCB_OFFSET_SP       WORD
PCB_OFFSET_LR       WORD
PCB_OFFSET_CPSR     WORD
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
                POP     {R2-R5}                 ; Do a bit of stack shuffling
                POP     {R0-R1}

                PUSH    {LR}                    ; Keep a copy of LR since we are going
                                                ; to use this as a tmp register

                PUSH    {R0-R2}                 ; Stick these on top of the stack



                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID      
                MOV     R1, #PCB_SIZE
                ADR     R2, PCB_offset          ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     LR, R1, R2              ; LR is now the base address for the PCB

                                                ; R0 , R1 and R2  no long needed
                POP     {R0-R2}                 ; Recover user reg before storing
                                           

                ADD     LR, LR, #PCB_OFFSET_REG ;Address to store to

                STMIA   LR!, {R0-R12}           ; Store all reg to LR pointer

                POP     {LR}                    ; Recover the original LR
                MOV     PC, LR

PCB_load_reg
                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                ADR     R2, PCB_offset          ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     R3, R1, R2              ; R3 is now the base address for the PCB

                ADD     R3, R3, #PCB_OFFSET_REG ; Address to load from
                LDMIA   R3, {R0-R12}            ; Load all reg

                MOV     PC, LR

PCB_save_special_reg
                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                ADR     R2, PCB_offset          ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     R3, R1, R2              ; R3 is now the base address for the PCB

                ; Save user_sp and user_lr
                ADD     R4, R3, #PCB_OFFSET_SP
                STMIA   R4, {SP,LR}^

                ; Save user_pc
                POP     {R5}
                STR     R5, [R3, #PCB_OFFSET_PC]

                ; Save user_cpsr(SPSR)
                MRS     R5, SPSR
                STR     R5, [R3, #PCB_OFFSET_CPSR]

                MOV     PC, LR


PCB_load_special_reg
                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                ADR     R2, PCB_offset          ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     R3, R1, R2              ; R3 is now the base address for the PCB

                ; Load user_sp and user_lr
                ADD     R4, R3, #PCB_OFFSET_SP
                LDMIA   R4, {SP,LR}^

                ; Load user_pc
                LDR     R5, [R3, #PCB_OFFSET_PC]
                PUSH    {R5}

                ; Save user_cpsr(SPSR)
                LDR     R5, [R3, #PCB_OFFSET_CPSR]
                MSR     SPSR, R5

                MOV     PC, LR

PCB_load_pc
                PUSH    {R0-R1}

                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                MUL     R1, R1, R0              ; Offset per PCB block
                ADR     R0, PCB_offset          ; Get offset address of PCB
                ADD     R1, R1, R0              ; R1 is now the base address for the PCB

                ADD     R1, R1, #PCB_OFFSET_PC  ; Address to load from
                LDR     LR, [R1]                ; User_PC now stored in SVC_LR

                POP     {R0-R1}                 ; Get our user reg back
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
                ADD     R0, R0, R3              ; Make sure SP actually points to abs addr
                STR     R0, [R3, #PCB_OFFSET_SP]

                ;Set initial PC
                POP     {R0}
                STR     R0, [R3, #PCB_OFFSET_PC]

                ;Set initial 
                MOV     R0, #MODE_USER
                STR     R0, [R3, #PCB_OFFSET_CPSR]

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
                ; Pick queue head
                ADR R1, PCB_READY_QUEUE
                BL  QUEUE_remove

                ADR R2, PCB_CURRENT_ID
                STR R0, [R2]

                ; Move into System mode
                ;;MRS     LR, CPSR                ; Get current CPSR
                ;;BIC     LR, LR, #MODE_BITMASK   ; Clear low order bits
                ;;ORR     LR, LR, #MODE_SYSTEM    ; Set mode bits
                ;;MSR     CPSR_c, LR              ; Rewrite CPSR
                ;;NOP

                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                MUL     R1, R1, R0              ; Offset per PCB block
                ADR     R0, PCB_offset          ; Get offset address of PCB
                ADD     R1, R1, R0              ; R1 is now the base address for the PCB

                ; Get stack
                ADD     R2, R1, #PCB_OFFSET_SP
                LDR     SP, [R2]
                ;;ADD     SP, SP, R1              ; SP is saved as an offset, so make abs

                ; Get user PC
                ADD     R2, R1, #PCB_OFFSET_PC  ; Address to load from
                LDR     R0, [R2]                ; User_PC now stored in R0

                LDR     SP, [R1, #PCB_OFFSET_SP]
                PUSH    {R0}                    ; Push PC onto usr_stack
                ;STMFD   R3!, {R0}

                ; Reset clock irq for context switch
                BL      en_irq



                ; Move into user mode (not using change_mode routine as we
                ; need to preserve regs)
                MRS     R0, CPSR                ; Get current CPSR
                BIC     R0, R0, #MODE_BITMASK   ; Clear low order bits
                ORR     R0, R0, #MODE_USER      ; Set mode bits
                MSR     CPSR_c, R0              ; Rewrite CPSR
                NOP

               
                ; Return to user code
                POP     {PC}

PCB_irq
                ; Add previous process to back of ready queue
                PUSH    {R0,R1}
                ADR     R1, PCB_CURRENT_ID
                LDR     R0, [R1]
                ADR     R1, PCB_READY_QUEUE
                BL      QUEUE_add
                POP     {R0,R1}

                ; Save off process' reg
                BL      PCB_save_reg
                BL      PCB_save_special_reg

                ; Get next process to switch in & update CURRENT_ID flag
                ADR     R1, PCB_READY_QUEUE
                BL      QUEUE_remove
                ADR     R1, PCB_CURRENT_ID
                STR     R0, [R1]

                ; Load in next process' reg
                BL      PCB_load_special_reg
                BL      PCB_load_reg

                PUSH    {R0-R1}                 ; just cos irq_end expects it
                B       irq_end


PCB_saved_sp    DEFW    1

PCB_total       EQU     PCB_SIZE*PCB_MAX_NUM
PCB_offset      DEFS    PCB_total
PCB_offset_end  NOP