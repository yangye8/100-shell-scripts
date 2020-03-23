#!/bin/bash -e
partition=/dev/sdd2
t_size=10m;
partition_path=$(mount |grep "/dev/sda2" | awk '{print $3}') 

DEBUG() {
[ "$_DEBUG" == "on"  ] && $@ || :
}

cd $partition_path

echo "============================= unix dd ==========================================="
echo "Measuring single-threaded, sequential-write I/O Performance via dd (100MB)"
for i in {1 2 3 4}; do time sh -c "dd if=/dev/zero of=testfile bs=104857600 count=1 && sync";done
echo "Measuring sequential I/O Read Performance via dd (100MB)"
for i in {1 2 3 4}; do time sh -c "dd if=testfile of=/dev/null";done
rm -rf testfile

msg() {
    printf '%b\n' "\33[32m[$*]\33[0m" >&2 && $*
    printf '%b\n' "\33[31m[✔]\33[0m" >&2
}

echo "============================= linux dd ==========================================="
msg dumpe2fs $partition
msg tune2fs -l $partition
msg hdparm -I $partition

echo "Measuring single-threaded, sequential-write I/O Performance via dd "
msg sudo hdparm -W1 $partition
# direct (use direct I/O for data)
# dsync (use synchronized I/O for data)
# sync (likewise, but also for metadata)
# oflag=dsync (oflag=dsync) : Use synchronized I/O for data. Do not skip this option. This option get rid of caching and gives you good and accurate results
# conv=fdatasyn: Again, this tells dd to require a complete “sync” once, right before it exits. This option is equivalent to oflag=dsync.

echo "Throughput (Streaming I/O)"
msg sudo dd if=/dev/zero of=testfile bs=100M count=1 oflag=direct 2>&1 |grep -v records;
msg sudo dd if=/dev/zero of=testfile bs=100M count=1 oflag=dsync 2>&1|grep -v records;

echo ""
echo "Latency mode"
msg sudo dd if=/dev/zero of=testfile bs=512 count=1000 oflag=direct 2>&1|grep -v records;
msg sudo dd if=/dev/zero of=testfile bs=512 count=1000 oflag=dsync 2>&1|grep -v records;

echo ""
echo "Measuring sequential I/O Read Performance via dd "
msg hdparm -Tt $partition
msg sudo /sbin/sysctl -w vm.drop_caches=3
msg sudo echo 3 > /proc/sys/vm/drop_caches
msg dd if=testfile of=/dev/null bs=8k 2>&1 |grep -v records

msg rm -rf testfile

echo "============================= fio ==========================================="

msg fio --name TEST --eta-newline=5s --filename=fio-tempfile.dat --rw=read --size=$t_size --io_size=10g --blocksize=1024k --ioengine=libaio --fsync=10000 --iodepth=32 --direct=1 --numjobs=1 --runtime=60 --group_reporting
msg fio --name TEST --eta-newline=5s --filename=fio-tempfile.dat --rw=write --size=$t_size --io_size=10g --blocksize=1024k --ioengine=libaio --fsync=10000 --iodepth=32 --direct=1 --numjobs=1 --runtime=60 --group_reporting
msg fio --name TEST --eta-newline=5s --filename=fio-tempfile.dat --rw=randread --size=$t_size --io_size=10g --blocksize=4k --ioengine=libaio --fsync=1 --iodepth=1 --direct=1 --numjobs=1 --runtime=60 --group_reporting
msg fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=$t_size --readwrite=randread
msg fio --name TEST --eta-newline=5s --filename=fio-tempfile.dat --rw=randrw --size=$t_size --io_size=10g --blocksize=4k --ioengine=libaio --fsync=1 --iodepth=1 --direct=1 --numjobs=1 --runtime=60 --group_reporting
msg fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=$t_size --readwrite=randrw --rwmixread=75
msg fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=$t_size --readwrite=randwrite
msg rm -rf fio-tempfile.dat

echo "============================= iozone ==========================================="
msg iozone -a $partition

echo "============================= bonnie++ ==========================================="

