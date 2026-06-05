#!/bin/bash

OUTDIR=dashboard-artifact-regression/test11-meta-status-cleanup

mkdir -p $OUTDIR

./run-dashboard-comparisons.py --mopsa dashboard-artifact-data/quickstart/tool-outputs/mopsa.*.files/SV-COMP26_no-overflow/ --goblint dashboard-artifact-data/quickstart/tool-outputs/goblint.*.files/SV-COMP26_no-overflow/ --dashboard $PWD/.. --analyze '/home/holterka/dashboard/dashboard-artifact-data/sv-benchmarks-nooverflow/c/**' --out $OUTDIR/quickstart --log-file $OUTDIR/quickstart.log --progress-every 1

./run-dashboard-comparisons.py --mopsa dashboard-artifact-data/RQ1/tool-outputs-before/mopsa.*.files/SV-COMP26_no-overflow/ --goblint dashboard-artifact-data/RQ1/tool-outputs-before/goblint.*.files/SV-COMP26_no-overflow/ --dashboard $PWD/.. --analyze '/home/holterka/sv-benchmarks/c/**' --out $OUTDIR/RQ1-before --log-file $OUTDIR/RQ1-before.log --progress-every 1000
./run-dashboard-comparisons.py --mopsa dashboard-artifact-data/RQ1/tool-outputs/mopsa.*.files/SV-COMP26_no-overflow/ --goblint dashboard-artifact-data/RQ1/tool-outputs/goblint.*.files/SV-COMP26_no-overflow/ --dashboard $PWD/.. --analyze '/home/holterka/sv-benchmarks/c/**' --out $OUTDIR/RQ1 --log-file $OUTDIR/RQ1.log --progress-every 1000

./run-dashboard-comparisons.py --mopsa dashboard-artifact-data/RQ2/tool-outputs/mopsa.*.files/SV-COMP26_no-overflow/ --goblint dashboard-artifact-data/RQ2/tool-outputs/goblint.*.files/SV-COMP26_no-overflow/ --dashboard $PWD/.. --analyze '/home/holterka/sv-benchmarks/c/**' --out $OUTDIR/RQ2 --log-file $OUTDIR/RQ2.log --progress-every 1
