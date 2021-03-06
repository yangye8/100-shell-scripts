#!/usr/bin/env bash

dev=$1
mode=$2
ssid=$3
key=$4

cat << EOF
cat /proc/net/wireless

iwgetid

nmcli connection show
nmcli connection show TP-LINK_0E03EA
nmcli -f GENERAL,WIFI-PROPERTIES dev show wlp109s0
nmcli dev wifi

watch -n1 iwconfig
watch -n 1 "awk 'NR==3 {print \"WiFi Signal Strength = \" \$3 \"00 %\"}''' /proc/net/wireless"
alias wl="watch -n 1 cat /proc/net/wireless"

iwconfig wlp109s0 | grep -i --color quality
iwconfig wlp109s0 | grep -i --color signal

wavemon
EOF

if [[ $# -ne 4 ]];then
    echo "usage:$0 dev mode ssid key eg: $0 wlan0 WPA2 wifi 12345678 "
    exit
fi

if ! $(iwlist "$dev" scan |grep -w "$ssid");then
    echo "couldn't find $ssid,exit"
    exit
fi

if [[ "$mode" == "WEP" ]];then
    #WEP 加密
    iwconfig "$dev" txpower on
    iwconfig "$dev" essid "$ssid" key "$key"
    iwconfig "$dev"
    ifup "$dev"
    dhclient "$dev"
    
    ip link set "$dev" up
    iw dev "$dev" scan | less
    iw dev "$dev" connect "$ssid" key 0:"$key"
elif [[ "$mode" == "WPA" ]] || [[ "$mode" == "WPA2" ]];then
    #WPA 或 WPA2 协议
    echo "network={ssid="$ssid"    psk="$key"    priority=1}" > /etc/wpasupplicant/wpa_supplicant.conf 
    wpa_supplicant -i "$dev" -c /etc/wpa_supplicant/wpa_supplicant.conf
    dhclient "$dev"
else 
    echo "$mode doesn't support. only WEP/WPA/WPA2"
    exit
fi
