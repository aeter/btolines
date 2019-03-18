%define sleep hlt

SETUP:
    bits 16
    ; BIOS jumps to 0x7C00 if the 511th/512th bytes contain the boot signature
    ; So we offset with 0x7C00:
    org 0x7c00

SET_VIDEO_MODE_AND_CLEAR_SCREEN:
    mov ax, 13h  ; https://en.wikipedia.org/wiki/Mode_13h - (320x200x256 colors)
    int 10h ; https://en.wikipedia.org/wiki/INT_10H

MAX_LINE_LENGTH_IN_PIXELS equ 100

START:
draw_line:
    inc dx ; y
    inc cx ; x

    cmp cx, MAX_LINE_LENGTH_IN_PIXELS
    je return

    ; setup cdecl stack frame for draw_pixel
    push dx
    push cx
    call draw_pixel
    pop cx
    pop dx

    sleep
    jmp draw_line

; $param1 = x, $param2 = y
draw_pixel:
    ; cdecl prologue
    push bp
    mov bp, sp
    mov cx, [bp + 4] ; $param1
    mov dx, [bp + 6] ; $param2

    ; call function write pixel: ah = 0Ch, al = color, bh = page number, cx = x, dx = y
    mov al, 0x2 ; green color
    mov ah, 0Ch
    mov bh, 1 ; page number
    int 10h

    ; cdecl epilogue
    pop bp
    ret

return: ret

BOOT_SIGNATURE:
    times 510 - ($-$$) db 0 ; pad with zeroes up to 510th byte
    dw 0xaa55 ; write magic 0x55 and 0xAA at the 511th and 512th byte
