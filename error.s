e_full_queue
        DEFB    "ERR Add to full Queue", 0
        ALIGN
e_empty_queue
        DEFB    "ERR Remove empty Queue", 0
        ALIGN
e_prefetch_abort
        DEFB    "ERR Prefetch Abort", 0
        ALIGN
e_data_abort
        DEFB    "ERR Data Abort", 0
        ALIGN

 
prefetch_abort_handler
                ADRL    R0, e_prefetch_abort
                BL      LCD_write_str
                B       end

data_abort_handler
                ADRL    R0, e_data_abort
                BL      LCD_write_str
                B       end