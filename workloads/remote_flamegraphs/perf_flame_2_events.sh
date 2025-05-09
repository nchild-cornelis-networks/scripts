#!/bin/bash

# READ AND THANKS TO https://www.brendangregg.com/blog/2014-10-31/cpi-flame-graphs.html
FLAME=$1
shift 1
CMD="$@"
EVENT1="instructions"
#EVENT1="cycles:a"  # add :k for just kernel code, or :a for all
EVENT2="cycles"
PERF="perf record -a -e $EVENT1,$EVENT2 -g -o perf.data"
echo "RUNING $PERF $CMD" >&2
$PERF $CMD

# make perf.data human readable 
perf script -i perf.data > perf_script.data || exit 1
echo "running flame scripts" >&2

# now we need to seperate into 2 different files
$FLAME/stackcollapse-perf.pl --event-filter=$EVENT1 perf_script.data > folded_ev1 || exit 1
$FLAME/stackcollapse-perf.pl --event-filter=$EVENT2 perf_script.data > folded_ev2 || exit 1

# diffolded makes one line hold a stack entry and 2 values (instead of just one)
$FLAME/difffolded.pl folded_ev1 folded_ev2 > out.perf-folded || exit 1
# finally we can make the graph
$FLAME/flamegraph.pl --title "$EVENT2 during $CMD" --subtitle "RED: $EVENT2 &lt; $EVENT1" out.perf-folded > perf.svg || exit 1
echo "done" >&2

