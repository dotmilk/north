; autogen

        extern _binary_forth_core_fs_start
        extern _binary_forth_core_fs_size
        defcode "@forth/core.fs",14,__forth_core_fs
        push ___forth_core_fs_
        NEXT
___forth_core_fs_:
        dq _binary_forth_core_fs_start
        dq _binary_forth_core_fs_size
        dq 0
        dq name___forth_core_fs

        extern _binary_forth_structures_fs_start
        extern _binary_forth_structures_fs_size
        defcode "@forth/structures.fs",20,__forth_structures_fs
        push ___forth_structures_fs_
        NEXT
___forth_structures_fs_:
        dq _binary_forth_structures_fs_start
        dq _binary_forth_structures_fs_size
        dq 0
        dq name___forth_structures_fs
