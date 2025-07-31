#!/bin/sh
FILE_NAME="$(pwd)/<path>"
DASHBOARD_PATH="<dashbard>"

echo "Running analysis on $FILE_NAME" 1>&2
ls -l . 1>&2
goblint --ana.arrayoob true --ana.int.interval_set true --ana.float.interval true --ana.float.evaluate_math_functions true --ana.base.arrays.domain trivial --ana.base.arrays.nullbytes true --ana.base.strings.domain disjoint --sem.malloc.fail true --set "ana.activated[+]" memOutOfBounds --set "ana.activated[+]"  useAfterFree --warn.quote-code true  --dbg.timing.enabled true --result dashboard  --ana.sv-comp.functions true --outfile out1.json "$FILE_NAME"
if [ $? -ne 0 ]; then
	echo "Goblint analysis failed"
	cat out1.json
	exit 1
fi

mopsa-c -silent /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/stdlib.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/assert.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/unistd.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/libintl.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/stdio_ext.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/wctype.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/sys/stat.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/error.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/math.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/stdio.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/stdlib.c\
 -output ./out2.json -format=json \
 "$FILE_NAME"
if [ $? -ne 0 ]; then
	echo "Mopsa analysis failed"
	cat out2.json
	exit 1
fi

$DASHBOARD_PATH \
	--analyze "$FILE_NAME" \
	"out1.json" \
	"out2.json"

result=$?

if [ $result -eq 1 ]; then
	echo "Dashboard analysis failed"
	exit 1
fi

# We exit code to be 4 (i.e safety conflicts)
if [ $result -eq 4 ]; then
	exit 0
else
	exit 1
fi