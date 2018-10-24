global start
global code_select

; extern long_mode_start
section .text
bits 32
%include "multiboot_header.asm"
start:
        mov esp, s_t
        ;call check_multiboot
        call check_cpuid
        call check_long_mode

%include "init/housekeeping.asm"
%include "init/init_pic.asm"

        call set_up_page_tables
        call enable_paging

        ; load 64-bit GDT
        lgdt [pointer]

        jmp code_selector:long_mode_start
        ; print ok should never get here
        mov dword [0xb8000], 0x2F4B2F4F
        hlt

        ; Prints Err: and given code to scren then hangs
        ; param: error code (in ascii) in al
error:
        mov dword [0xb8000], 0x4f524f45
        mov dword [0xb8004], 0x4f3a4f52
        mov dword [0xb8008], 0x4f204f20
        mov byte  [0xb800a], al
        hlt

check_multiboot:
        cmp eax, 0x36D76289
        jne .no_multiboot
        ret

.no_multiboot:
        mov al, "0"
        jmp error

check_cpuid:
        ; Try and flip ID bit (bit 21)
        ; in the FLAGS register. If we can CPUID is available

        ; Copy FLAGS into EAX via stack
        pushfd
        pop eax

        ; Copy to EXC for later compare
        mov ecx, eax

        ; Flip it
        xor eax, 1 << 21

        ; Copy EAX to FLAGS via the stack
        push eax
        popfd

        ; Copy back with flipped bit if CPUID is supported
        pushfd
        pop eax

        ; Restore FLAGS (if we were able to flip it or not)
        push ecx
        popfd

        ; Compare EAX and ECX
        cmp eax, ecx
        je .no_cpuid
        ret

.no_cpuid:
        mov al, "1"
        jmp error

check_long_mode:
        ; is extended processor info available
        mov eax, 0x80000000     ; implicit argument for cpuid
        cpuid                   ; get highest supported arg
        cmp eax, 0x80000001     ; we need atleast 0x80000001
        jb .no_long_mode        ; if less CPU too old

        ; now test if we can long mode
        mov eax, 0x80000001     ; argument for extended processor info
        cpuid                   ; feature bits in ecx and edx
        test edx, 1 << 29       ; see if LM-bit is set in D-register
        jz .no_long_mode        ; nope :-( err
        ret

.no_long_mode:
        mov al, "2"
        jmp error

set_up_page_tables:
        ; map firt p4 entry to p3 table
        mov eax, p3_table
        or eax, 0b11            ; present + writable
        mov [p4_table], eax

        ; map first p3 entry to p2
        mov eax, p2_table
        or eax, 0b11            ; present + writable
        mov [p3_table], eax

        mov ecx, 0              ; counter variable

.map_p2_table:
        ; map ecx-th p2 to a huge page starting at address 2Mib*ecx
        mov eax, 0x200000       ; 2Mib
        mul ecx                 ;start address of ecx-th page
        or eax, 0b10000011      ; present + writeable + huge
        mov [p2_table + ecx * 8], eax ; map ecx-th entry

        inc ecx                 ; increase the counter
        cmp ecx, 512            ; if counter == 512, p2 table is mapped
        jne .map_p2_table       ; otherwise do it again

        ret

enable_paging:
;; load p4 to cr3 (cpu uses this to acces p4 table)
        mov eax, p4_table
        mov cr3, eax

;; enable PAE-flag in cr4 (Physical Address Extension)
        mov eax, cr4
        or eax, 1 << 5
        mov cr4, eax

;; set long mode bit in EFER MSR
        mov ecx, 0xC0000080
        rdmsr
        or eax, 1 << 8
        wrmsr

;; enable paging in cr0 register
        mov eax, cr0
        or eax, 1 << 31
        mov cr0, eax

        ret



struc gdt_entry
.limit_low:   resb 2
.base_low:    resb 2
.base_middle: resb 1
.access:      resb 1
.granularity: resb 1
.base_high:   resb 1
endstruc


section .rodata
gdt64:
        dq 0                    ; zero entry
code_selector: equ $ - gdt64    ; cs
istruc gdt_entry
at gdt_entry.limit_low, dw 0
at gdt_entry.base_low, dw 0
at gdt_entry.base_middle, db 0
at gdt_entry.access, db 154
at gdt_entry.granularity, db 175
at gdt_entry.base_high, db 0
iend
data_selector: equ $ - gdt64    ; ds
istruc gdt_entry
at gdt_entry.limit_low, dw 0
at gdt_entry.base_low, dw 0
at gdt_entry.base_middle, db 0
at gdt_entry.access, db 146
at gdt_entry.granularity, db 0
at gdt_entry.base_high, db 0
iend
        ; dq (1<<43) | (1<<44) | (1<<47) | (1<<53)
        ; code segment
pointer:
        dw $ - gdt64 - 1
        dq gdt64


section .bss
align 4096
p4_table:
        resb 4096
p3_table:
        resb 4096
p2_table:
        resb 4096
s_b:
        resb 64
s_t:


%include "long_mode_init.asm"
%include "forth.asm"
