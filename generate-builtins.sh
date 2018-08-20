OUTPUT=builtin-files.asm

echo "; autogen" > $OUTPUT
for file in $*; do
    # echo $file
    BN=`echo $file | sed 's/\//_/g' | sed 's/\./_/g'`
    NAME=@$file
    VAR_NAME="${BN}_l"
    VAR_SYM="${NAME}_l"
    NAME_SIZE=${#NAME}
    VAR_NAME_SIZE=${#VAR_NAME}
    SYMBOL_START="_binary_${BN}_start"
    SYMBOL_SIZE="_binary_${BN}_size"
    # echo $BN
    # echo $NAME
    # echo $NAME_SIZE
    echo ""                                                       >> $OUTPUT
    echo "        extern $SYMBOL_START"                           >> $OUTPUT
    echo "        extern $SYMBOL_SIZE"                            >> $OUTPUT
    echo "        defcode \"$NAME\",$NAME_SIZE,__$BN"             >> $OUTPUT
    echo "        push $SYMBOL_START"                             >> $OUTPUT
    echo "        push $SYMBOL_SIZE"                              >> $OUTPUT
    echo "        push qword [var_${BN}_l]"                       >> $OUTPUT
    echo "        NEXT"                                           >> $OUTPUT
    echo ""                                                       >> $OUTPUT
    echo "        defvar \"$VAR_SYM\",$VAR_NAME_SIZE,$VAR_NAME,0" >> $OUTPUT

done
