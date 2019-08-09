#perf=perf
suffx=$1
HOME=/tmp
perf=/homes/borispi/stable-4.14.110-debug/tools/perf/perf
net='/homes/markuze/TestSuite/DataCollector/'

export time=15
cd $net
./collect_net_cpu.pl 2>/dev/null > net_cpu$suffx.txt
cd -
sudo taskset -c 8 $perf record -C 0 -g -o cpu${suffx}.data sleep $time
sleep 5
sudo taskset -c 8 $perf record -C 0 -g -d -W -e cpu/mem-loads/p,cpu/mem-stores/p -o mem${suffx}.data sleep $time

