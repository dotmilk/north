global long_mode_start
extern forth_start
section .text
bits 64
long_mode_start:
        mov ax, 0
        mov ss, ax
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax

        ; call forth_start

        ; try okok first
        mov rax, 0x2F4B2F4F2F4B2F4F
        mov qword [0xB8000], rax
        hlt
