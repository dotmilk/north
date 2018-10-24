[BITS 32]

section .data
        MULTIBOOT_HEADER_MAGIC   equ   0x1BADB002 ; magic number, GRUB searches for it in the first 8k
        ; of the specified file in GRUB menu

        MULTIBOOT_HEADER_FLAGS   equ   0x00010004 ; FLAGS[16] say to GRUB we are not
        ; an ELF executable and the fields
        ; header adress, load adress, load end adress;
        ; bss end adress and entry adress will be
        ; available in Multiboot header
        ; FLAGS[2] say to GRUB we need info about the
        ; video mode and we want to set it.

        CHECKSUM            equ -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)


        LOADBASE            equ 0x00100000        ; Must be >= 1MB. TODO: really?
_start:
        jmp     start            ; if you want use you own bootloader

align  4                           ; Multiboot header must be 32
                                          ; bits aligned to avoid error 13
        db 'unique'
multiboot_header:

       dd   MULTIBOOT_HEADER_MAGIC        ; magic number
       dd   MULTIBOOT_HEADER_FLAGS        ; flags
       dd   CHECKSUM                      ; checksum
       dd   LOADBASE + multiboot_header   ; header adress
       dd   LOADBASE                      ; load adress
       dd   00                            ; load end adress : not necessary
       dd   00                            ; bss end adress : not necessary
       dd   LOADBASE + start   ; entry adress
       dd   01                            ; mode_type TEXT -- change to 00 for linear graphics mode
       dd   640                           ; width
       dd   480                           ; height
       dd   16                            ; depth
