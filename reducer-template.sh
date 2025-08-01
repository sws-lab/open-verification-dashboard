#!/bin/sh
FILE_NAME="$(pwd)/<file>"
DASHBOARD_PATH="<path_to_dashboard_executable>"
MIN_ERR_CODE=4

echo "Running analysis on $FILE_NAME" 1>&2

gcc -fsyntax-only -Werror=unused-value "$FILE_NAME" -std=c11
if [ $? -ne 0 ]; then
	echo "GCC syntax check failed"
	exit 1
fi

goblint --ana.arrayoob true --ana.int.interval_set true --ana.float.interval true --ana.float.evaluate_math_functions true --ana.base.arrays.domain trivial --ana.base.arrays.nullbytes true --ana.base.strings.domain disjoint --sem.malloc.fail true --set "ana.activated[+]" memOutOfBounds --set "ana.activated[+]"  useAfterFree --warn.quote-code true  --dbg.timing.enabled true --result dashboard  --ana.sv-comp.functions true  --warn.error false --warn.warning false --warn.info false \
 --outfile out1.json "$FILE_NAME"
if [ $? -ne 0 ]; then
	echo "Goblint analysis failed"
	cat out1.json
	exit 1
fi

mopsa-c -silent /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/stdlib.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/assert.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/unistd.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/libintl.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/stdio_ext.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/wctype.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/sys/stat.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/error.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/math.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/stdio.c /home/robotechnic/Documents/Annee_2025-2024/stage/_opam/share/mopsa/stubs/c/libc/stdlib.c\
 -output ./out2.json -format=json -show-safe-checks \
 "$FILE_NAME"
if [ $? -ne 0 ]; then
	echo "Mopsa analysis failed"
	cat out2.json
	exit 1
fi

echo "Running dashboard analysis on $FILE_NAME" 1>&2
$DASHBOARD_PATH \
	--analyze "$FILE_NAME" \
	"out1.json" \
	"out2.json"

result=$?

if [ $result -eq 1 ]; then
	echo "Dashboard analysis failed" 1>&2
	exit 1
fi

# We exit code to be 4 (i.e safety conflicts) or 5 (i.e error level conflicts)
if [ $result -ge $MIN_ERR_CODE ]; then
	exit 0
else
	echo "Expected result to be at least $MIN_ERR_CODE, but got $result" 1>&2
	exit 1
fi