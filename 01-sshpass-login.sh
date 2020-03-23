#!/bin/bash -e

ip=$1
username=$2
passwd=$3
TIMEOUT=30

OSDIST=$(lsb_release -i |awk -F: '{print tolower($2)}' | tr -d ' \t')
SSHPASS=sshpass

trap "printf \"\n%s\n\" exit ;exit" INT

if [ $# != 3 ]
then
    echo "Usage: $0 [ip] [username] [passwd]"
    if [ $# == 2 ]
    then
        passwd="$username"
        echo "Warning: using username as passwd"
    else
        exit 1
    fi
fi

if [[ $OSDIST == "centos" ]]; then
    if [[ ! -x "$(command -v $SSHPASS)" ]]; then
        sudo yum install $SSHPASS 
    fi
fi

if [[ $OSDIST == "ubuntu" ]]; then
    if [[ ! -x "$(command -v $SSHPASS)" ]]; then
        sudo apt install $SSHPASS 
    fi
fi

if [[ ! -x "$(command -v $SSHPASS)" ]]; then
    echo "$SSHPASS is not installed, please install it"
    exit 1
fi

counter() {
    count=0;
    tput sc  #tput sc 存储光标位置
    while :;
    do
        if [ $count -lt $TIMEOUT ];then
            if ! ping -c 1 -n -w 1 "$ip" &> /dev/null
            then
                tput rc # tput rc 恢复光标位置
                tput ed # tput ed 清除光标位置，到行尾的内容
            else
                break;
            fi
            printf "%s" $((++count))s;
        else
            echo -e "\ntried $TIMEOUT times, ping failed, exit" 
            exit 0
        fi
    done
}

printf "%s" "Waiting for $ip ... "
#timeout 0.5 ping -c 3 -n "$1"

counter
printf "\n%s\n" "$ip is online"

echo "do command \"$SSHPASS -p $passwd ssh -XY $2@$ip\""
$SSHPASS -p "$passwd" ssh -XY "$username"@"$ip" || exit
