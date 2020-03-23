#!/bin/bash

SECONDS=0
job=9
Nproc=3

echo "========================================================================"
echo "顺序执行: shell前台进程"
echo "========================================================================"
for ((i=0; i<job; i++)); do
{
   WAIT=$((RANDOM/10000))
   echo  "[$(date +%T)] progress $i is sleeping for $WAIT seconds zzz…"
   sleep $WAIT
}
done
echo -e "time-consuming: $SECONDS seconds"
echo ""


echo "========================================================================"
echo "并发执行: 后台执行, wait命令以循环中最慢的进程结束为结束（水桶效应）"
echo "========================================================================"
SECONDS=0
for ((i=0; i<job; i++)); do
   WAIT=$((RANDOM/10000))
   echo  "[$(date +%T)] progress $i is sleeping for $WAIT seconds zzz…"
   sleep $WAIT &
done
wait
echo -e "time-consuming: $SECONDS seconds"
echo ""

echo "========================================================================"
echo "用数组控制并发数目"
echo "========================================================================"
SECONDS=0
pid=()
function ChkArray {
    index=0
    for PID in ${pid[*]}; do
        if [[ ! -d /proc/$PID ]]; then
            pid=(${pid[@]:0:$index} ${pid[@]:$index+1})
            break
        fi
        ((index++))
    done
}

for ((i=1; i<=job; i++)); do
    echo "progress $i is sleeping for 3 seconds zzz…"
    sleep 3 &
    pid+=("$!")
    while [[ ${#pid[*]} -ge $Nproc ]]; do
          ChkArray
          sleep 0.1
    done
done
wait
echo -e "time-consuming: $SECONDS   seconds"
echo ""

REPO_LIST=(\
    git://github.com/yangye8/100-shell-scripts.git \
    git://github.com/Rolinh/dfc.git \
    git://git.kernel.org/pub/scm/utils/i2c-tools/i2c-tools.git \
    git://github.com/pengutronix/memtool.git \
    git://github.com/vamanea/mtd-utils.git \
    git://github.com/apenwarr/netselect.git \
    git://github.com/openssh/openssh-portable
    git://github.com/ridernator/stopwatch.git \
    git://github.com/gregkh/usbutils.git \
    git://github.com/Xilinx/XRT.git \
)

parallar() {
PIDARRAY=()
for repo in "${REPO_LIST[@]}"
do
    git clone "$repo" &
    PIDARRAY+=("$!")
done
wait "${PIDARRAY[@]}"
}
