    pop [terminalStreamPtr]
    pop [arg0Ptr]

    call Main
    call end_current_task

GetNextWindowEvent:
    push r8
    call get_next_window_event
    mov r8, eventArgs
    mov [r8], r0
    add r8, 4
    mov [r8], r1
    add r8, 4
    mov [r8], r2
    add r8, 4
    mov [r8], r3
    add r8, 4
    mov [r8], r4
    add r8, 4
    mov [r8], r5
    add r8, 4
    mov [r8], r6
    add r8, 4
    mov [r8], r7
    pop r8
    ret

brk:
    brk
    ret

eventArgs: data.fill 0, 32
terminalStreamPtr: data.32 0
arg0Ptr: data.32 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"