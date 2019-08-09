HOME=/homes/markuze
perf=/homes/markuze/copy/tools/perf/perf
perf=/homes/borispi/stable-4.14.110-debug/tools/perf/perf

CORE=""
CORE="-C 0"
IRQ_CORE="-C 2"

[ -z "$CPU" ] && CPU='cpu_local.data'
[ -z "$CPU2" ] && CPU2='cpu_remote.data'
[ -z "$MEM" ] && MEM='mem.data'

#VMLINUX="-k /homes/markuze/copy/vmlinux"

for file in cpu*data; do
	extension="${file##*.}"
	name="${file%.*}"
	echo "$file :$name"
	sudo $perf report $CORE -i $file $VMLINUX --show-cpu-utilization --no-child --stdio		> $name.txt
done

for file in mem*data; do
	extension="${file##*.}"
	name="${file%.*}"
	echo "$file :$name"
	sudo $perf report $CORE -i $file $VMLINUX --show-cpu-utilization --no-child --stdio --mem-mode	> $name.txt
done
#sudo $perf report $CORE -i $CPU $VMLINUX --show-cpu-utilization --stdio	--no-child	> cpu_n.txt
#sudo $perf report -C $IRQ_CORE -i $CPU --show-cpu-utilization --stdio		> txt
#sudo $perf report -C $CORE -i $1 --show-cpu-utilization --stdio --no-child	> `uname -r`_nochild_core_$CORE.txt
#sudo $perf report -C $CORE -i $1 --show-cpu-utilization --stdio --no-child	> `uname -r`_nochild_core_$CORE.txt
