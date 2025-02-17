; autogen

        extern _binary_forth_core_fs_start
        extern _binary_forth_core_fs_size
        defcode "@forth/core.fs",14,__forth_core_fs
        mov r9, ___forth_core_fs_
        push r9
        NEXT
___forth_core_fs_:
        dq _binary_forth_core_fs_start
        dq _binary_forth_core_fs_size
        dq 0
        dq name___forth_core_fs

        extern _binary_forth_interpreter_fs_start
        extern _binary_forth_interpreter_fs_size
        defcode "@forth/interpreter.fs",21,__forth_interpreter_fs
        mov r9, ___forth_interpreter_fs_
        push r9
        NEXT
___forth_interpreter_fs_:
        dq _binary_forth_interpreter_fs_start
        dq _binary_forth_interpreter_fs_size
        dq 0
        dq name___forth_interpreter_fs

        extern _binary_forth_strings_fs_start
        extern _binary_forth_strings_fs_size
        defcode "@forth/strings.fs",17,__forth_strings_fs
        mov r9, ___forth_strings_fs_
        push r9
        NEXT
___forth_strings_fs_:
        dq _binary_forth_strings_fs_start
        dq _binary_forth_strings_fs_size
        dq 0
        dq name___forth_strings_fs

        extern _binary_forth_structures_fs_start
        extern _binary_forth_structures_fs_size
        defcode "@forth/structures.fs",20,__forth_structures_fs
        mov r9, ___forth_structures_fs_
        push r9
        NEXT
___forth_structures_fs_:
        dq _binary_forth_structures_fs_start
        dq _binary_forth_structures_fs_size
        dq 0
        dq name___forth_structures_fs

        extern _binary_forth_vocabulary_fs_start
        extern _binary_forth_vocabulary_fs_size
        defcode "@forth/vocabulary.fs",20,__forth_vocabulary_fs
        mov r9, ___forth_vocabulary_fs_
        push r9
        NEXT
___forth_vocabulary_fs_:
        dq _binary_forth_vocabulary_fs_start
        dq _binary_forth_vocabulary_fs_size
        dq 0
        dq name___forth_vocabulary_fs
