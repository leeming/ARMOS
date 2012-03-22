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


PCB_NEXT_PROC_ID    DEFW   0x01        ; Next new procces id
PCB_CURRENT_ID      DEFW   0x01        ; PCB currently active
PCB_MAX_NUM         EQU    0x05        ; Maximum number of PCBs

PCB_SIZE            EQU    (PCB_OFFSET_BOTTOM - PCB_record)  



PCB_total           EQU    PCB_SIZE*PCB_MAX_NUM
PCB_area            DEFS   PCB_total           ; TODO rename this
PCB_area_end        NOP
ALIGN


; Define the queues we will use for PCBs
PCB_SPARE_BLOCK_QUEUE   DEFS    QUEUE_record_size   ; List of free PCB blocks
ALIGN
PCB_READY_QUEUE         DEFS    QUEUE_record_size   ; FIFO queue of ready processes
ALIGN                                               ; waiting for scheduling


;----------------------------
; Few `PCB manager` setup routines to run
; thru before adding processes
;   Params: n/a
;----------------------------
PCB_setup
                PUSH    {R0,R1,LR}

                ; Set up spare blocks queue
                ADR     R0, PCB_SPARE_BLOCK_QUEUE
                BL      QUEUE_init
                MOV     R1, R0
                MOV     R0, #PCB_MAX_NUM
                SUB     R0, R0, #1

_setup_loop     BL      QUEUE_add                   ; Add in each PCB block
                SUB     R0, R0, #1                  ; to spare block queue
                CMP     R0, #0
                BGE     _setup_loop


                ; Set up ready queue
                ADR     R0, PCB_READY_QUEUE
                BL      QUEUE_init                  ; Init empty wait queue
                
                POP     {R0,R1,LR}
                MOV     PC, LR


;----------------------------
; Save user process R0-R12 to its
; PCB area in memory
;   Params: R0-R12
;----------------------------
PCB_save_reg
                PUSH    {R0-R2,LR}              ; Keep a copy of LR since we are going
                                                ; to use this as a tmp register

                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID      
                MOV     R1, #PCB_SIZE
                ADRL    R2, PCB_area            ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     LR, R1, R2              ; LR is now the base address for the PCB

                                                ; R0 , R1 and R2  no long needed
                POP     {R0-R2}                 ; Recover user reg before storing
                                           

                ADD     LR, LR, #PCB_OFFSET_REG ;Address to store to

                STMIA   LR!, {R0-R12}           ; Store all reg at LR pointer

                POP     {LR}                    ; Recover the original LR
                MOV     PC, LR


;----------------------------
; Loads user process R0-R12 from
; it's PCB area in memory
;   Returns: R0-R12
;----------------------------
PCB_load_reg
                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                ADRL     R2, PCB_area           ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     R3, R1, R2              ; R3 is now the base address for the PCB

                ADD     R3, R3, #PCB_OFFSET_REG ; Address to load from
                LDMIA   R3, {R0-R12}            ; Load all reg

                MOV     PC, LR

;----------------------------
; Saves the user's 'special' registers
; i.e. PC, SP, LR & CPSR
;   Params: n/a? usr_sp, usr_lr, SPSR
;----------------------------
PCB_save_special_reg
                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                ADRL    R2, PCB_area            ; Get offset address of PCB
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

;----------------------------
; Loads the user's 'special' registers
; i.e. PC, SP, LR & CPSR
;   Returns: Restored registers with PC
;        on top of usr_stack
;----------------------------
PCB_load_special_reg
                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                ADRL    R2, PCB_area            ; Get offset address of PCB
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


;----------------------------
; Creates a process starting at the
; given address (R0)
;   Params: R0 start address of program
;----------------------------
PCB_create_process
                PUSH    {R1-R3,LR}
                PUSH    {R0}                    ; Make sure these are top of the stack
                                                ; as they are params for this routine

d2
                ;Find next available PCB block
                ADRL     R1, PCB_SPARE_BLOCK_QUEUE
                BL      QUEUE_remove

                ;Calculate block offset
                MOV     R1,  #PCB_OFFSET_BOTTOM
                MUL     R1, R1, R0              ; Offset from 'PCB_area'

                ;Set process ID
                LDR     R2, PCB_NEXT_PROC_ID    ; Load next available ID
                ADRL    R3, PCB_area            ; Grab PCB offset and calculate
                ADD     R3, R3, R1              ; base address for this PCB

                STR     R2, [R3, #PCB_OFFSET_ID]; Store ID in PCB R0

                ADD     R2, R2, #1              ; Increment next available ID
                ADRL    R4, PCB_NEXT_PROC_ID    ; Grab address location
                STR     R2, [R4]                ; Store new inc

                ;Stick on ready queue
                ADRL     R1, PCB_READY_QUEUE
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
                AND     R0, R0, #IRQ_EN_BITMASK
                STR     R0, [R3, #PCB_OFFSET_CPSR]

                POP     {R1-R3,LR}
                MOV     PC, LR                  ;Return


;----------------------------
; Starts the scheduler running
;   Params: n/a
;----------------------------
PCB_run
                ; Pick queue head
                ADRL R1, PCB_READY_QUEUE
                BL  QUEUE_remove

                ADRL R2, PCB_CURRENT_ID
                STR R0, [R2]

                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID
                MOV     R1, #PCB_SIZE
                MUL     R1, R1, R0              ; Offset per PCB block
                ADRL    R0, PCB_area            ; Get offset address of PCB
                ADD     R1, R1, R0              ; R1 is now the base address for the PCB

                ; Get stack
                ;;ADD     R2, R1, #PCB_OFFSET_SP
                ;;LDR     SP, [R2]
                LDR     SP, [R1, #PCB_OFFSET_SP]

                ; Get user PC
                ADD     R2, R1, #PCB_OFFSET_PC  ; Address to load from
                LDR     R0, [R2]                ; User_PC now stored in R0

                
                PUSH    {R0}                    ; Push PC onto usr_stack

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

;----------------------------
; Interupt routine for doing the
; actual context switch
;   Params: n/a
;----------------------------
PCB_irq nop
                ; Add previous process to back of ready queue
                ;PUSH    {R0,R1}        ; These can be scraped
d5                ADRL    R1, PCB_CURRENT_ID
                LDR     R0, [R1]
                ADR     R1, PCB_READY_QUEUE
                BL      QUEUE_add
                ;POP     {R0,R1}

                ; Save off process' reg
                POP     {R2-R5}                 ; Do a bit of stack shuffling
                POP     {R0-R1}
                BL      PCB_save_reg
                BL      PCB_save_special_reg

                BL      PCB_swap_in

                PUSH    {R0-R1}                 ; irq_end expects to pop R0,R1
                B       irq_end

;----------------------------
; Terminates current running process
;   SYS_CALL
;   Params: 
;----------------------------
PCB_terminate
                ADRL    R1, PCB_CURRENT_ID
                LDR     R0, [R1]

                ; Place (now free) block onto PCB_SPARE_BLOCK_QUEUE
                ADR     R1, PCB_SPARE_BLOCK_QUEUE
                BL      QUEUE_add

                ; Reset timer irq
                BL      clock_tick_reset

                BL      PCB_swap_in

                ; Recover usr_pc and branch
                POP     {LR}
                MOVS    PC, LR 

;----------------------------
; Terminates current running process
;   SYS_CALL
;   Params:
;----------------------------
PCB_nice
                ; Add previous process to back of ready queue
                PUSH    {R0,R1}
                ADRL    R1, PCB_CURRENT_ID
                LDR     R0, [R1]
                ADR     R1, PCB_READY_QUEUE
                BL      QUEUE_add
                POP     {R0,R1}
                POP     {R4,R5}

                ; Save off process' reg
                BL      PCB_save_reg
                BL      PCB_save_special_reg

                ; Reset timer irq
                BL      clock_tick_reset
                BL      PCB_swap_in

                ; Recover usr_pc and branch
                POP     {LR}
                MOVS    PC, LR 

;----------------------------
; Schedules in a process to run, but doesn't
; save the currently running process. This
; should be done elsewhere.
;   Params:
;----------------------------
PCB_swap_in
                SUB     SP, SP, #4
                PUSH    {LR}
                

                ; Get next process to switch in & update CURRENT_ID flag
                ADR     R1, PCB_READY_QUEUE
                BL      QUEUE_remove

                ADD     SP, SP, #8
                ADRL    R1, PCB_CURRENT_ID
                STR     R0, [R1]

                ; Load in next process' reg
                BL      PCB_load_special_reg
                BL      PCB_load_reg

                SUB     SP, SP, #4
                POP     {LR}
                MOV     PC, LR
