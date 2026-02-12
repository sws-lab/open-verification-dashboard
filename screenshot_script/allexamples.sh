#!/bin/bash

# This script run mopsa and goblint on all the simple examples files separately and merge the results in a single file.
# It also produces the archive needed for the dashboard
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

rm -rf "$parent_path/results"
mkdir "$parent_path/results"

cd "$parent_path/../examples"
rm -rf *-mopsa.json *-goblint.json 

for f in simples/*.c; do
	echo "Running analysis on $f"
	mopsa-c -config=c/cell-itv-excluded-powerset.json \
		    -c-init-memset-threshold=33 \
			-loop-unrolling=0 \
			-hook=c-precision-suggestions \
			-format=json \
			-show-safe-checks \
			-c-check-overflows-with-relational \
			-c-check-unsigned-arithmetic-overflow=true \
			-output "$(basename $f .c)-mopsa.json" \
			$f
	
	goblint --ana.arrayoob true --ana.int.interval true --ana.float.interval true --ana.float.evaluate_math_functions true --ana.base.arrays.domain trivial --ana.base.arrays.nullbytes true --ana.base.strings.domain disjoint --sem.malloc.fail true --set "ana.activated[+]" memOutOfBounds --set "ana.activated[+]"  useAfterFree \
			--result dashboard --outfile "$(basename $f .c)-goblint.json" $f
done

rm ./simples/*.c.json
tar -czvf "$parent_path/results/simples.tar.gz" simples
mopsa_json=$(ls *-mopsa.json)
goblint_json=$(ls *-goblint.json)
python "$parent_path/merger.py" $mopsa_json "$parent_path/results/mopsa.json"
python "$parent_path/merger.py" $goblint_json "$parent_path/results/goblint.json"
rm -rf *-mopsa.json *-goblint.json
