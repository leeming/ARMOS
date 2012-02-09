b start

PCB_STATE_NEW       EQU    0x00
PCB_STATE_READY     EQU    0x01
PCB_STATE_BLOCKED   EQU    0x02
PCB_STATE_RUNNING   EQU    0x03
PCB_STATE_FINISHED  EQU    0x04


PCB_OFFSET_ID       EQU    0x00
PCB_OFFSET_STATE    EQU    0x04
PCB_OFFSET_REG      EQU    0x00



PCB_NEXT_PROC_ID    DEFW   0x01        ; Next new proc id
PCB_CURRENT_ID      DEFW   0x01        ; PCB currently active
PCB_MAX_TIMESLICE   EQU    0x05        ; Number of clock ticks per timeslice
PCB_MAX_NUM         EQU    0x04        ; Maximum number of PCBs
PCB_SIZE            EQU    0x40        ; Size of each PCB block


start
                ADR SP, stack
                BL PCB_create_process

                MOV R0, #99
                MOV R1, #98
                MOV R2, #97
                MOV R3, #96
                MOV R4, #95
                MOV R5, #94
                MOV R6, #93
                MOV R7, #92
                MOV R8, #91
                MOV R9, #90

                B PCB_save_reg

                BL PCB_create_process
                BL PCB_create_process
end b .


PCB_save_reg
                PUSH    {LR}                    ; Keep a copy of LR since we are going
                                                ; to use this as a tmp register
                PUSH    {R0-R2}

                ;Load base address of current active PCB
                LDR     R0, PCB_CURRENT_ID      
                MOV     R1, #PCB_SIZE
                ADR     R2, PCB_offset          ; Get offset address of PCB
                MUL     R1, R1, R0              ; Offset per PCB block
                ADD     R14, R1, R2             ; R13svc is now the base address for the PCB
                                                ; R0 , R1 and R2  no long needed
                ADD     R14, R14, #PCB_OFFSET_REG ;Address to store to
                POP     {R0-R2}                 ; Recover user reg before storing
                STMIA   R14!, {R0-R12}          ; Store all reg to R14 pointer

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



PCB_create_process
                PUSH    {R0-R3,LR}

                ;Find next available PCB block
                BL      _PCB_find_next_avil

                ;Calculate block offset
                MOV     R1, #PCB_SIZE
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

                ;

                POP     {R0-R3,LR}
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

PCB_offset          DEFS    100

                    DEFS    100
stack               nop