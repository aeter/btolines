;; Using call convention: cdecl
SETUP:
    bits 16
    ; BIOS jumps to 0x7C00 if the 511th/512th bytes contain the boot signature
    ; So we offset everything with 0x7C00:
    org 0x7c00


MACROS_BEGIN:
%macro _call_draw_pixel_ 3 ; 3 parameters
    ; save registers modified by draw_pixel
    push ax
    push bx
    push cx
    push dx

    ; setup params for draw_pixel
    push %3 ; draw_pixel => color
    push %2 ; draw_pixel => y
    push %1 ; draw_pixel => x
    call draw_pixel
    pop %1
    pop %2
    pop %3

    ; restore saved registers
    pop dx
    pop cx
    pop bx
    pop ax
%endmacro

%macro _call_set_video_mode_and_clear_screen_ 0 ; 0 parameters
    push ax
    call set_video_mode_and_clear_screen
    pop ax
%endmacro

%macro _call_draw_line_ 0 ; 0 parameters
    push bx
    push cx
    push dx
    call draw_line
    pop dx
    pop cx
    pop bx
%endmacro

; using "enter" and "leave" saves 2 bytes from the executable
%macro _start_function_ 0 ; 0 parameters
    enter 0, 0 ; => push bp; mov bp, sp
%endmacro

%macro _end_function_ 0 ; 0 parameters
    leave ; => mov sp, bp; pop bp
    ret
%endmacro
MACROS_END:


%define sleep hlt
%define max_line_length_in_pixels 100
%define max_number_lines 200


START:
    _call_set_video_mode_and_clear_screen_
    _call_draw_line_

    .sleep_forever: ; so that qemu doesn't use 100% CPU
        sleep
        jmp .sleep_forever


FUNCTIONS_BEGIN:

; set_video_mode_and_clear_screen()
set_video_mode_and_clear_screen:
    _start_function_
    mov ax, 13h ; https://en.wikipedia.org/wiki/Mode_13h - (320x200x256 colors)
    int 10h ; https://en.wikipedia.org/wiki/INT_10H
    _end_function_

; TODO - use "y = ax + b", send a,b (and color?) as params
; draw_line()
draw_line:
    _start_function_

    mov cx, 10 ; startx is always the same, 10px
    mov bl, 0x2 ; color stored in bx
    ; TODO - starty can be calculated from y = ax + b....

    .draw_pixels_loop:
        inc cx ; next pixel x
        inc dx ; next pixel y
        cmp cx, max_line_length_in_pixels
        je .return
        _call_draw_pixel_ cx, dx, bx ; draw_pixel(next_pixel_x, next_pixel_y, color)
        sleep
        jmp .draw_pixels_loop
    .return:
        _end_function_

; draw_pixel(x, y, color)
draw_pixel:
    _start_function_
    mov cx, [bp + 4] ; x
    mov dx, [bp + 6] ; y
    mov bx, [bp + 8] ; color

    ; write pixel: ah = 0Ch, al = color, bh = page number, cx = x, dx = y
    mov ah, 0Ch
    mov al, bl ; set color
    mov bh, 1 ; page number
    int 10h

    _end_function_

FUNCTIONS_END:


BOOT_SIGNATURE:
    times 510 - ($-$$) db 0 ; pad with zeroes up to 510th byte
    dw 0xaa55 ; write magic 0x55 and 0xAA at the 511th and 512th byte
