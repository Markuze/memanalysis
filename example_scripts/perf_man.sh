HOME=/homes/markuze
perf=/homes/markuze/copy/tools/perf/perf
#DAT=4.14.0-damn-ne_v1_2.data
#DAT=/homes/markuze/copy/perf.data.old
DAT=4.14.0_2.data
CORE=1
#VMLINUX="-k /homes/markuze/copy/vmlinux"

sudo $perf report -C $CORE -i $DAT --show-cpu-utilization --mem-mode $VMLINUX

