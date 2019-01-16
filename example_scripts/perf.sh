HOME=/homes/markuze
perf=/homes/markuze/copy/tools/perf/perf
CORE=3
sudo $perf report -C $CORE -i $1 --show-cpu-utilization --stdio		> `uname -r`_all_core_$CORE.txt
sudo $perf report -C $CORE -i $1 --show-cpu-utilization --stdio --no-child	> `uname -r`_nochild_core_$CORE.txt

CORE=1
sudo $perf report -C $CORE -i $1 --show-cpu-utilization --stdio		> `uname -r`_all_core_$CORE.txt
sudo $perf report -C $CORE -i $1 --show-cpu-utilization --stdio --no-child	> `uname -r`_nochild_core_$CORE.txt
