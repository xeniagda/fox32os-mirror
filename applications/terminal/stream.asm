; stream IO routines

; write a character to the terminal
; inputs:
; r0: pointer to ASCII character
stream_write_to_terminal:
    movz.8 r0, [r0]
    jmp print_character_to_terminal

stream_get_input:
    mov r0, [read_buffer]
    mov [read_buffer_ack], 1
    ret

read_buffer: data.32 0
read_buffer_ack: data.32 0
