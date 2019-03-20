SETUP:
    bits 16
    ; BIOS jumps to 0x7C00 if the 511th/512th bytes contain the boot signature
    ; So we offset everything with 0x7C00:
    org 0x7c00

;;;;;;;;;;;;;;;
;; Macros :) ;;
;;;;;;;;;;;;;;;
%macro call_draw_pixel 3 ; 3 parameters
    ; save registers modified by draw_pixel
    push ax
    push bx
    push cx
    push dx

    ; setup params for draw_pixel
    ; hopefully per the cdecl call convention
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

%macro make_random_number 1 ; 1 params (for the upper limit of the number)
    push dx
    rdtsc      ; changes ax and dx
    mov bx, %1 
    div bx     ; divides ax by bx, ax holds the remainder
    pop dx
%endmacro

;;;;;;;;;;;;;;;
;; Defines :) ;
;;;;;;;;;;;;;;;
%define sleep hlt
%define max_line_length_in_pixels 20
%define max_colors 256
%define screen_height_in_pixels 200
%define screen_width_in_pixels 320

;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;
START:
    set_video_mode_and_clear_screen:
        mov ax, 13h ; https://en.wikipedia.org/wiki/Mode_13h - (320x200x256 colors)
        int 10h ; https://en.wikipedia.org/wiki/INT_10H

    .draw_lines_loop:
    call draw_line
    sleep ; so we don't use 100% CPU
    jmp .draw_lines_loop

;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Functions :) ;;;;
;;;;;;;;;;;;;;;;;;;;;;;

; draw_line()
draw_line:
    enter 0, 0

    .set_random_startx:
        make_random_number screen_width_in_pixels
        mov cx, ax
        
    .set_random_starty:
        make_random_number screen_height_in_pixels
        mov dx, ax

    .set_random_color:
        make_random_number max_colors
        mov bx, ax

    .set_line_length_counter:
        mov ax, 0

    .draw_pixels_loop:
        inc cx ; next pixel x
        inc dx ; next pixel y
        inc ax ; line_length_counter
        cmp ax, max_line_length_in_pixels
        je .return
        call_draw_pixel cx, dx, bx ; draw_pixel(next_pixel_x, next_pixel_y, color)
        jmp .draw_pixels_loop
    .return:
        leave
        ret

; draw_pixel(x, y, color)
draw_pixel:
    enter 0, 0
    mov cx, [bp + 4] ; x
    mov dx, [bp + 6] ; y
    mov bx, [bp + 8] ; color

    ; write pixel: ah = 0Ch, al = color, bh = page number, cx = x, dx = y
    mov ah, 0Ch
    mov al, bl ; set color
    mov bh, 1 ; page number
    int 10h

    leave
    ret


BOOT_SIGNATURE:
    times 510 - ($-$$) db 0 ; pad with zeroes up to 510th byte
    dw 0xaa55 ; write magic 0x55 and 0xAA at the 511th and 512th byte
