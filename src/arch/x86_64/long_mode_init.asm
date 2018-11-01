global long_mode_start


extern exception_gate_00
extern exception_gate_01
extern exception_gate_02
extern exception_gate_03
extern exception_gate_04
extern exception_gate_05
extern exception_gate_06
extern exception_gate_07
extern exception_gate_08
extern exception_gate_09
extern exception_gate_10
extern exception_gate_11
extern exception_gate_12
extern exception_gate_13
extern exception_gate_14
extern exception_gate_15
extern exception_gate_16
extern exception_gate_17
extern exception_gate_18
extern exception_gate_19

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
        ;sti
        mov rdx, 12


        ; call do_test
        jmp start_forth

        int 49
        hlt

setup_interrupt_table:
        ; mov dword [0x00*16], 0x00000000
        ; mov dword [0x01*16], 0x00000000
        ; mov dword [0x02*16], 0x00000000
        ; mov dword [0x03*16], 0x00000000
        ; mov dword [0x04*16], 0x00000000
        ; mov dword [0x05*16], 0x00000000
        ; mov dword [0x06*16], 0x00000000
        ; mov dword [0x07*16], 0x00000000
        ; mov dword [0x08*16], 0x00000000
        ; mov dword [0x09*16], 0x00000000
        ; mov dword [0x0A*16], 0x00000000
        ; mov dword [0x0B*16], 0x00000000
        ; mov dword [0x0C*16], 0x00000000
        ; mov dword [0x0D*16], 0x00000000
        ; mov dword [0x0E*16], 0x00000000
        ; mov dword [0x0F*16], 0x00000000
        ; mov dword [0x10*16], 0x00000000
        ; mov dword [0x11*16], 0x00000000
        ; mov dword [0x12*16], 0x00000000
        ; mov dword [0x13*16], 0x00000000
        ; mov word [0x00*16], exception_gate_00
	; mov word [0x01*16], exception_gate_01
	; mov word [0x02*16], exception_gate_02
	; mov word [0x03*16], exception_gate_03
	; mov word [0x04*16], exception_gate_04
	; mov word [0x05*16], exception_gate_05
	; mov word [0x06*16], exception_gate_06
	; mov word [0x07*16], exception_gate_07
	; mov word [0x08*16], exception_gate_08
	; mov word [0x09*16], exception_gate_09
	; mov word [0x0A*16], exception_gate_10
	; mov word [0x0B*16], exception_gate_11
	; mov word [0x0C*16], exception_gate_12
	; mov word [0x0D*16], exception_gate_13
	; mov word [0x0E*16], exception_gate_14
	; mov word [0x0F*16], exception_gate_15
	; mov word [0x10*16], exception_gate_16
	; mov word [0x11*16], exception_gate_17
	; mov word [0x12*16], exception_gate_18
	; mov word [0x13*16], exception_gate_19
        lidt [idtr]
        ret





section .bss
global idt
idt:
        resb 50*16

section .data
idtr:
        dw 4095                 ; limit
        dq 0
        ; dq idt                  ; addr

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
