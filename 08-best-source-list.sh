#!/bin/bash

# how to assign a array via $()
# temp=( $(find $1 -maxdepth 1 -type f) ) 
# for i in "${temp[@]}" 
#a=(foo bar "foo 1" "bar two")  #create an array
#b=("${a[@]}")                  #copy the array in another one 

VERSION="buster"
TEST_NETCONNECT_HOST="www.baidu.com"
SOURCES_MIRRORS_FILE="sources_mirrors.list"    
MIRRORS_SPEED_FILE="mirrors_speed.list"

FLAVOR=$(grep '^ID=' /etc/os-release | awk -F= '{print $2}')
FLAVOR=$(echo "$FLAVOR" | tr -d '"')

DEBIAN_MIRRORS=(\
    http://mirrors.ustc.edu.cn/debianu/ \
    http://mirrors.tuna.tsinghua.edu.cn/debian/ \
    http://mirrors.163.com/debian/ \
    http://mirrors.aliyun.com/debian/ \
)

UBUNTU_MIRRORS=(\
    http://mirrors.163.com/ubuntu/ \
    http://mirrors.aliyun.com/ubuntu/ \
    http://mirrors.ustc.edu.cn/ubuntu/ \
    http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ \
    http://mirrors.aliyun.com/ubuntu/ \
)

function get_ping_speed()    #return average ping $1 time
{
    local speed
    speed=$(ping -W1 -c1 "$1" 2> /dev/null | grep "^rtt" |  cut -d '/' -f5)
    echo "$speed"
}

function test_default_mirror_speed()    #
{
    local mirror_host
    local speed
    rm $MIRRORS_SPEED_FILE 2> /dev/null; touch $MIRRORS_SPEED_FILE
    
    if [ "$FLAVOR" == "debian" ];then
        LIST=( ${DEBIAN_MIRRORS[@]} )
    elif [ "$FLAVOR" == "ubuntu" ];then
        LIST=( ${UBUNTU_MIRRORS[@]} ) 
    elif [ "$FLAVOR" == "centos" ];then
        LIST=( ${CENTOS_MIRRORS[@]} )
    else
        echo "unsupport OS, exit";
        exit 2
    fi

    for mirror in "${LIST[@]}"
    do
        if [ "$mirror" != "" ]; then
            echo -e "Ping $mirror"
            mirror_host=$(echo "$mirror" | cut -d '/' -f3)    #change mirror_url to host
    
            speed=$(get_ping_speed "$mirror_host")
    
            if [ "$speed" != "" ]; then
                echo "Time is $speed ms"
                echo "$mirror $speed" >> $MIRRORS_SPEED_FILE
            else
                echo "Connected failed."
            fi
        fi
    done
}

function test_mirror_speed()    #
{
    local mirror_host
    local speed
    rm $MIRRORS_SPEED_FILE 2> /dev/null; touch $MIRRORS_SPEED_FILE
    
     cat $SOURCES_MIRRORS_FILE | while read mirror
    do
        if [ "$mirror" != "" ]; then
            echo -e "Ping $mirror"
            mirror_host=$(echo "$mirror" | cut -d '/' -f3)    #change mirror_url to host
    
            speed=$(get_ping_speed "$mirror_host")
    
            if [ "$speed" != "" ]; then
                echo "Time is $speed ms"
                echo "$mirror $speed" >> $MIRRORS_SPEED_FILE
            else
                echo "Connected failed."
            fi
        fi
    done
}

function get_fast_mirror()
{
    sort -k 2 -n -o $MIRRORS_SPEED_FILE $MIRRORS_SPEED_FILE
    local fast_mirror=`head -n 1 $MIRRORS_SPEED_FILE | cut -d ' ' -f1`
    echo $fast_mirror
    rm $MIRRORS_SPEED_FILE 2> /dev/null;
}

function backup_sources()
{
    echo -e "Backup your sources.list"
    sudo mv /etc/apt/sources.list /etc/apt/sources.list.`date +%F-%R:%S`
}

function update_sources()
{
    local COMP="main contrib non-free"
    local mirror="$1"
    local tmp=$(mktemp)

    echo "deb $mirror $VERSION $COMP" >> $tmp
    echo "deb $mirror $VERSION-updates $COMP" >> $tmp

    echo "deb-src $mirror $VERSION $COMP" >> $tmp 
    echo "deb-src $mirror $VERSION-updates $COMP" >> $tmp 

    sudo mv "$tmp" /etc/apt/sources.list
    echo -e "Your sources has been updated, and maybe you want to run "sudo apt-get update" now.";
}

echo -e "Testing the network connection.Please wait..."

if [ "$(get_ping_speed $TEST_NETCONNECT_HOST)" == "" ]; then
    echo -e "Network is bad.Please check your network."; exit 1
else
    echo -e "Network is good"
    test -f $SOURCES_MIRRORS_FILE

    if [ "$?" != "0" ]; then  
        echo -e "$SOURCES_MIRRORS_FILE is not exist. Test default mirror speed";
        test_default_mirror_speed;
    else
        test_mirror_speed
    fi

    fast_mirror=$(get_fast_mirror)

    if [ "$fast_mirror" == "" ]; then
        echo -e "Can't find the fastest software sources. Please check your $SOURCES_MIRRORS_FILE"
        exit 0
    fi

    echo -e "$fast_mirror is the fastest software sources. Do you want to use it? [y/n]"
    read choice

    if [ "$choice" != "y" ]; then
        exit 0
    fi

    backup_sources
    update_sources $fast_mirror
fi

exit 0 
