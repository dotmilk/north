global long_mode_start

        ; STAGE3 equ 0x60000
extern start_forth
section .text
bits 64
long_mode_start:
        mov ax, 0
        mov ss, ax
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        ; gdt64

        ; call forth_start
        call setup_interrupt_table

        mov rdx, 12


        ; call do_test
        jmp start_forth

        int 49
        hlt

setup_interrupt_table:
        lidt [idtr]
        ret


section .bss
global idt
idt:
        resb 50*16

section .data
idtr:
        dw 4095
        dq idt

section .text
int_handler:
        mov rax, 0x2F4B2F4F2F4f2F4F
        mov qword [0xB8000], rax
        hlt

do_test:


        mov rax, int_handler
        mov [idt+49*16], ax
        mov word [idt+49*16+2], 0x08 ; replace 0x20 with your code section selector
        mov word [idt+49*16+4], 0x8e00
        shr rax, 16
        mov [idt+49*16+6], ax
        shr rax, 16
        mov [idt+49*16+8], rax
        ;sti
        ret
