; FXF launcher helper routines

; launch an FXF binary from a menu item
; inputs:
; r3: Launcher menu item
; outputs:
; none, does not return (jumps to `entry` when task ends)
launch_fxf:
    mov r0, menu_items_launcher_list
    add r0, 3 ; point to the first launcher item string
    mul r3, 10
    add r0, r3 ; r0 now points to the name of the FXF file to load

    ; copy the name into the launch_fxf_name buffer
    mov r1, launch_fxf_name
    mov r2, 8
    call copy_memory_bytes

    ; disable the menu bar
    call disable_menu_bar

    ; open the file
    mov r0, launch_fxf_name
    mov r1, 0
    mov r2, launch_fxf_struct
    call ryfs_open

    ; allocate memory for the binary
    mov r0, launch_fxf_struct
    call ryfs_get_size
    call allocate_memory
    cmp r0, 0
    ifz jmp allocate_error
    mov [launch_fxf_binary_ptr], r0

    ; read the file into memory
    mov r0, launch_fxf_struct
    mov r1, [launch_fxf_binary_ptr]
    call ryfs_read_whole_file

    ; allocate a 64KiB stack
    mov r0, 65536
    call allocate_memory
    cmp r0, 0
    ifz jmp allocate_error
    mov [launch_fxf_stack_ptr], r0

    ; relocate the binary
    mov r0, [launch_fxf_binary_ptr]
    call parse_fxf_binary

    ; create a new task
    mov r1, r0
    call get_unused_task_id
    mov.8 [launch_fxf_task_id], r0
    mov r2, [launch_fxf_stack_ptr]
    add r2, 65536 ; point to the end of the stack (stack grows down!!)
    mov r3, [launch_fxf_binary_ptr]
    mov r4, [launch_fxf_stack_ptr]
    call new_task

    ; fall-through to launch_fxf_yield_loop

; loop until the launched task ends
launch_fxf_yield_loop:
    movz.8 r0, [launch_fxf_task_id]
    call is_task_id_used
    ifz jmp entry
    call yield_task
    rjmp launch_fxf_yield_loop

launch_fxf_name: data.str "        fxf"
launch_fxf_struct: data.32 0 data.32 0
launch_fxf_task_id: data.8 0
launch_fxf_binary_ptr: data.32 0
launch_fxf_stack_ptr: data.32 0