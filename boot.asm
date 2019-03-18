SETUP:
    bits 16
    ; BIOS jumps to 0x7C00 if the 511th/512th bytes contain the boot signature
    ; So we offset with 0x7C00:
    org 0x7c00

    .clear_registers:
        xor ax, ax

SET_VIDEO_MODE_AND_CLEAR_SCREEN:
    mov ax, 13h  ; https://en.wikipedia.org/wiki/Mode_13h - (320x200x256 colors)
    int 10h ; https://en.wikipedia.org/wiki/INT_10H

BOOT_SIGNATURE:
    times 510 - ($-$$) db 0 ; pad with zeroes up to 510th byte
    dw 0xaa55 ; write magic 0x55 and 0xAA at the 511th and 512th byte
