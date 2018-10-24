; global long_mode_start

; STAGE3 equ 0x60000
; extern start_forth
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
        mov word [idt+0x00*16], exception_gate_00
	mov word [idt+0x01*16], exception_gate_01
	mov word [idt+0x02*16], exception_gate_02
	mov word [idt+0x03*16], exception_gate_03
	mov word [idt+0x04*16], exception_gate_04
	mov word [idt+0x05*16], exception_gate_05
	mov word [idt+0x06*16], exception_gate_06
	mov word [idt+0x07*16], exception_gate_07
	mov word [idt+0x08*16], exception_gate_08
	mov word [idt+0x09*16], exception_gate_09
	mov word [idt+0x0A*16], exception_gate_10
	mov word [idt+0x0B*16], exception_gate_11
	mov word [idt+0x0C*16], exception_gate_12
	mov word [idt+0x0D*16], exception_gate_13
	mov word [idt+0x0E*16], exception_gate_14
	mov word [idt+0x0F*16], exception_gate_15
	mov word [idt+0x10*16], exception_gate_16
	mov word [idt+0x11*16], exception_gate_17
	mov word [idt+0x12*16], exception_gate_18
	mov word [idt+0x13*16], exception_gate_19
        lidt [idtr]
        ret

; -----------------------------------------------------------------------------
; CPU Exception Gates
exception_gate_00:
	mov al, 0x00
	jmp exception_gate_main

exception_gate_01:
	mov al, 0x01
	jmp exception_gate_main

exception_gate_02:
	mov al, 0x02
	jmp exception_gate_main

exception_gate_03:
	mov al, 0x03
	jmp exception_gate_main

exception_gate_04:
	mov al, 0x04
	jmp exception_gate_main

exception_gate_05:
	mov al, 0x05
	jmp exception_gate_main

exception_gate_06:
	mov al, 0x06
	jmp exception_gate_main

exception_gate_07:
	mov al, 0x07
	jmp exception_gate_main

exception_gate_08:
	mov al, 0x08
	jmp exception_gate_main

exception_gate_09:
	mov al, 0x09
	jmp exception_gate_main

exception_gate_10:
	mov al, 0x0A
	jmp exception_gate_main

exception_gate_11:
	mov al, 0x0B
	jmp exception_gate_main

exception_gate_12:
	mov al, 0x0C
	jmp exception_gate_main

exception_gate_13:
	mov al, 0x0D
	jmp exception_gate_main

exception_gate_14:
	mov al, 0x0E
	jmp exception_gate_main

exception_gate_15:
	mov al, 0x0F
	jmp exception_gate_main

exception_gate_16:
	mov al, 0x10
	jmp exception_gate_main

exception_gate_17:
	mov al, 0x11
	jmp exception_gate_main

exception_gate_18:
	mov al, 0x12
	jmp exception_gate_main

exception_gate_19:
	mov al, 0x13
	jmp exception_gate_main

exception_gate_main:
exception_gate_main_hang:
	nop
	jmp exception_gate_main_hang


section .bss
global idt
idt:
        resb 50*16

section .data
idtr:
        dw 4095                 ; limit
        dq idt                  ; addr

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
