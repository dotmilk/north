ENTRY(start)
SECTIONS {
    . = 1M ;
    .boot :
    {
        /* ensure multiboot header is at the beginning */
        *(.multiboot_header)
    }

    .text :
    {
        *(.text .text.*)
    }

    /* .rodata : */
    /* { */
    /*     *(.rodata .rodata.*) */
    /* } */

    /* .data.rel.ro : */
    /* { */
    /*     *(.data.rel.ro .data.rel.ro.*) */
    /* } */

    /* .data : */
    /* { */
    /*     *(.data .data.*) */
    /* } */

    /* kernel_stack_bottom = .; */
    /* .    += kernel_stack_size; */
    /* . = ALIGN(16); */
    /* kernel_stack_top = .; */

}
