; autogen

        extern _binary_forth_core_fs_start
        extern _binary_forth_core_fs_size
        defcode "@forth/core.fs",14,__forth_core_fs
        push _binary_forth_core_fs_start
        push _binary_forth_core_fs_size
        push qword [var_forth_core_fs_l]
        NEXT

        defvar "@forth/core.fs_l",15,forth_core_fs_l,0
