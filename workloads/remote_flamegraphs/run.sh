#!/bin/bash


# will run perf record on 2 systems while running a workload, it will then generate 2 flamegraphs
if [ $# -lt 3 ]; then
	echo "USAGE: $0 <host1> <host2> <cmd to trace -run on host1->"
	exit 1
fi

host1=$1 ; shift
host2=$1; shift
cmd=$@

sshcmd="ssh -o BatchMode=yes"
git_flame="https://github.com/brendangregg/FlameGraph.git"
flame_path="~/data/flame_workdir"
perf_record_script="perf_flame_2_events.sh"

run_cmd() {
	# sorry must be root to access perf tracepoints and kallsyms
	$sshcmd root@$1 "${@:2}" > /dev/null
}


echo "checking for passwordless login (keybased)"
if ! run_cmd $host1 /bin/true; then
	echo "Keys not registered on root@$host1; consider ssh-copy-id  -i <key> root@$host1"
	exit 1
elif ! run_cmd $host2 /bin/true; then
	echo "Keys not registered on root@$host2; consider ssh-copy-id  -i <key> root@$host2"
	exit 1
fi

echo "checking deps"
for h in $host1 $host2; do
	if ! run_cmd $h "command -v perf"; then
		run_cmd $h "dnf -y install perf" || exit 1
	fi
	if ! run_cmd $h "ls $flame_path/FlameGraph"; then
		echo "FlameGraph not found on $h: Building dir and cloning $git_flame"
		run_cmd $h "mkdir -p $flame_path && cd $flame_path && git clone $git_flame" || exit 1
	fi
	# lets just copy the record script over every time :)
	#if ! run_cmd $h "ls $flame_path/$perf_record_script"; then
	#	echo "$perf_record_script not found on $h: copying over now.."
		scp -o BatchMode=yes $perf_record_script root@$h:$flame_path || exit 1
	#fi
done

echo "Starting workload"

# host2 is complicated because we just need to do nothing for awhile
run_cmd $host2 "cd $flame_path; mkdir -p output && rm -rf output/* && cd output && ../$perf_record_script ../FlameGraph" &
run_cmd $host1 "cd $flame_path; mkdir -p output && rm -rf output/* && cd output && ../$perf_record_script ../FlameGraph $cmd"
# now we can kill the recording process on host2 
run_cmd $host2 "ps aux | grep 'perf record' | grep -v grep | awk '{print \$2}' | xargs kill"
echo "Waiting for $host2 to wrap up"
while run_cmd $host2 "ps aux | grep \"$perf_record_script\" | grep -v grep"; do
	sleep 2;
done

echo "Workload done, fetching SVGs"
outdir=output/`basename ${cmd%% *}`_`echo ${cmd#* } | sed 's/[^a-zA-Z0-9._-]/_/g'`--`date +"%Y%m%dT%H%M"`
for h in $host1 $host2; do
	scp -o BatchMode=yes root@$h:$flame_path/output/perf.svg perf.svg || exit 1
	mkdir -p $outdir
	mv perf.svg $outdir/$h.svg
done
echo "Output is in $outdir"

