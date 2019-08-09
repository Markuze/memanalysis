HOME=/homes/markuze
perf=/homes/markuze/copy/tools/perf/perf

CORE=""
#"-C 0"
IRQ_CORE=8

[ -z "$CPU" ] && CPU='cpu.data'
[ -z "$MEM" ] && MEM='mem.data'

#VMLINUX="-k /homes/markuze/copy/vmlinux"

sudo $perf report $CORE -i $CPU $VMLINUX --show-cpu-utilization --stdio		> cpu.txt
sudo $perf report $CORE -i $MEM $VMLINUX --show-cpu-utilization --stdio --mem-mode > mem.txt

#sudo $perf report $CORE -i $CPU $VMLINUX --show-cpu-utilization --stdio	--no-child	> cpu_n.txt
#sudo $perf report -C $IRQ_CORE -i $CPU --show-cpu-utilization --stdio		> txt
#sudo $perf report -C $CORE -i $1 --show-cpu-utilization --stdio --no-child	> `uname -r`_nochild_core_$CORE.txt
#sudo $perf report -C $CORE -i $1 --show-cpu-utilization --stdio --no-child	> `uname -r`_nochild_core_$CORE.txt
