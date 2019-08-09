HOME=/homes/markuze
perf=/homes/markuze/copy/tools/perf/perf
perf=/homes/borispi/stable-4.14.110-debug/tools/perf/perf
#perf=/tmp/perf

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
	sudo $perf report $CORE -i $file $VMLINUX --show-cpu-utilization --stdio		> $name.text
	pkts=`grep -i "total_tx_packets:" net_$name.txt|cut -d: -f2`
	echo "./breakdown.pl -f $name.txt -p $pkts"
	./breakdown.pl -f $name.txt -p $pkts > ./$name.br 2>/dev/null
done

for file in mem*data; do
	extension="${file##*.}"
	name="${file%.*}"
	echo "$file :$name"
	sudo $perf report $CORE -i $file $VMLINUX --show-cpu-utilization --no-child --stdio --mem-mode	> $name.txt
	sudo $perf report $CORE -i $file $VMLINUX --show-cpu-utilization --stdio --mem-mode	> $name.text
done

