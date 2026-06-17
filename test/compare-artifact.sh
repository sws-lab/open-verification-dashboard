#!/bin/bash

OUTDIR=dashboard-artifact-regression/test22-pretty-yojson

mkdir -p $OUTDIR

./run-dashboard-comparisons.py --mopsa dashboard-artifact-data/quickstart/tool-outputs/mopsa.*.files/SV-COMP26_no-overflow/ --goblint dashboard-artifact-data/quickstart/tool-outputs/goblint.*.files/SV-COMP26_no-overflow/ --dashboard $PWD/.. --analyze '/home/holterka/dashboard/dashboard-artifact-data/sv-benchmarks-nooverflow/c/**' --out $OUTDIR/quickstart --log-file $OUTDIR/quickstart.log --progress-every 1

./run-dashboard-comparisons.py --mopsa dashboard-artifact-data/RQ1/tool-outputs-before/mopsa.*.files/SV-COMP26_no-overflow/ --goblint dashboard-artifact-data/RQ1/tool-outputs-before/goblint.*.files/SV-COMP26_no-overflow/ --dashboard $PWD/.. --analyze '/home/holterka/sv-benchmarks/c/**' --out $OUTDIR/RQ1-before --log-file $OUTDIR/RQ1-before.log --progress-every 1000
./run-dashboard-comparisons.py --mopsa dashboard-artifact-data/RQ1/tool-outputs/mopsa.*.files/SV-COMP26_no-overflow/ --goblint dashboard-artifact-data/RQ1/tool-outputs/goblint.*.files/SV-COMP26_no-overflow/ --dashboard $PWD/.. --analyze '/home/holterka/sv-benchmarks/c/**' --out $OUTDIR/RQ1 --log-file $OUTDIR/RQ1.log --progress-every 1000

./run-dashboard-comparisons.py --mopsa dashboard-artifact-data/RQ2/tool-outputs/mopsa.*.files/SV-COMP26_no-overflow/ --goblint dashboard-artifact-data/RQ2/tool-outputs/goblint.*.files/SV-COMP26_no-overflow/ --dashboard $PWD/.. --analyze '/home/holterka/sv-benchmarks/c/**' --out $OUTDIR/RQ2 --log-file $OUTDIR/RQ2.log --progress-every 1


# dashboard-artifact-data/RQ1/dashboard-outputs vs dashboard-artifact-regression/test{1,2,3}*
# Valid/Unreach: 652 vs 646
# Reason: dirname-1.yml.comparison.json contains patched-dirname-1.i checks in artifact. All other Mopsa's patched checks are properly filtered out. Artifact probably accidentally had patched-dirname-1.i in sv-benchmarks due to some uncontainerized testing, so the file actually existed for project filtering. Does not exist in the final artifact.

# dashboard-artifact-regression/test3-rundef-dir* vs dashboard-artifact-regression/test{4,5}-*
# Goblint Unreach column: [146, 0, 646, 0] vs [654, 44, 1958, 0]
# Reason: Mopsa's busybox patched checks are now all included. Filtering by path globbing (patched files in sv-benchmarks) instead of existence checks.
# Unreach/Valid: 2126 vs 2136
# Reason: uname-1.yml.comparison.json (+5), uname-2.yml.comparison.json (+5): CompareProofObligations sorting bug (ignoring file names can split up overlapping regions of same file, which now happens). Also CheckSet compare bug causes some conflict checks to be swallowed but that doesn't affect the joint matrix.

# dashboard-artifact-regression/test5-no-project vs dashboard-artifact-regression/test6-empty
# Valid/Unreach: 1958 vs 1960
# Reason: afterrec-2.yml.comparison.json (+1), afterrec_2calls-2.yml.comparison.json (+1): Fixed bug comparison was not made if one of the checks files had none.
