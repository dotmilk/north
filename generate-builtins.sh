OUTPUT=builtin-files.asm

echo "; autogen" > $OUTPUT
for file in $*; do
    # echo "-*-"
    # echo $file
    # echo "-*-"
    BN=`echo $file | sed 's/\//_/g' | sed 's/\./_/g'`
    NAME=@$file
    VAR_NAME="${BN}_l"
    VAR_SYM="${NAME}_l"
    NAME_SIZE=${#NAME}
    VAR_NAME_SIZE=${#VAR_NAME}
    SYMBOL_START="_binary_${BN}_start"
    SYMBOL_END="_binary_${BN}_end"
    SYMBOL_SIZE="_binary_${BN}_size"
    echo ""                                           >> $OUTPUT
    echo "        global $SYMBOL_START"               >> $OUTPUT
    echo "        global $SYMBOL_SIZE"                >> $OUTPUT
    echo "        defcode \"$NAME\",$NAME_SIZE,__$BN" >> $OUTPUT
    echo "        mov r9, ___${BN}_"                     >> $OUTPUT
    echo "        push r9"                     >> $OUTPUT
    echo "        NEXT"                               >> $OUTPUT
    echo "$SYMBOL_START:" >> $OUTPUT
    echo "incbin \"$file\" " >> $OUTPUT
    echo "$SYMBOL_END:" >> $OUTPUT
    echo "$SYMBOL_SIZE:" >> $OUTPUT
    echo "        dq $SYMBOL_END - $SYMBOL_START" >> $OUTPUT
    echo "___${BN}_:"                                 >> $OUTPUT
    echo "        dq $SYMBOL_START"                   >> $OUTPUT
    echo "        dq $SYMBOL_SIZE"                    >> $OUTPUT
    echo "        dq 0"                               >> $OUTPUT
    echo "        dq name___${BN}"                    >> $OUTPUT

done
