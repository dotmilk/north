section .multiboot_header
header_start:
        dd 0xE85250D6          ; Magic number mb2
        dd 0                    ; protected i386
        dd header_end - header_start ; header length
        dd 0x100000000 - (0xE85250D6 + 0 + (header_end - header_start))

        dw 0                    ; type
        dw 0                    ; flags
        dd 8                    ; size
header_end:
