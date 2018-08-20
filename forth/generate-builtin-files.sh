echo "OK"
OUTPUT=builtin-files.asm

echo "; generated automatically don't fuck with this" > $OUTPUT
for file in $*; do
    echo `$file | sed 's/\//_/g' | sed 's/\./_/g'`
done
