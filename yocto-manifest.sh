#!/bin/bash

array=(
https://git.yoctoproject.org/git/intel-iot-refkit 
https://git.yoctoproject.org/git/meta-alexa-demo
https://git.yoctoproject.org/git/meta-anaconda
https://git.yoctoproject.org/git/meta-arm
https://git.yoctoproject.org/git/meta-axxia
https://git.yoctoproject.org/git/meta-cgl
https://git.yoctoproject.org/git/meta-cloud-services
https://git.yoctoproject.org/git/meta-dpdk
https://git.yoctoproject.org/git/meta-amd
https://git.yoctoproject.org/git/meta-intel-qat
https://git.yoctoproject.org/git/meta-intel-iot-middleware
https://git.yoctoproject.org/git/meta-intel-contrib
https://git.yoctoproject.org/git/meta-intel-clear-containers
https://git.yoctoproject.org/git/meta-intel
https://git.yoctoproject.org/git/meta-gplv2
https://git.yoctoproject.org/git/meta-freescale
https://git.yoctoproject.org/git/meta-external-toolchain
https://git.yoctoproject.org/git/meta-ivi
https://git.yoctoproject.org/git/meta-java
https://git.yoctoproject.org/git/meta-maker
https://git.yoctoproject.org/git/meta-mentor
https://git.yoctoproject.org/git/meta-mingw
https://git.yoctoproject.org/git/meta-mingw-contrib
https://git.yoctoproject.org/git/meta-mono
https://git.yoctoproject.org/git/meta-oic
https://git.yoctoproject.org/git/meta-openssl102
https://git.yoctoproject.org/git/meta-qcom
https://git.yoctoproject.org/git/meta-qt4
https://git.yoctoproject.org/git/meta-raspberrypi
https://git.yoctoproject.org/git/meta-realtime
https://git.yoctoproject.org/git/meta-renesas
https://git.yoctoproject.org/git/meta-rockchip
https://git.yoctoproject.org/git/meta-security
https://git.yoctoproject.org/git/meta-spdxscanner
https://git.yoctoproject.org/git/meta-swupd
https://git.yoctoproject.org/git/meta-systemdev
https://git.yoctoproject.org/git/meta-tensorflow
https://git.yoctoproject.org/git/meta-ti
https://git.yoctoproject.org/git/meta-tlk
https://git.yoctoproject.org/git/meta-virtualization
https://git.yoctoproject.org/git/meta-xilinx
https://git.yoctoproject.org/git/meta-yocto
https://git.yoctoproject.org/git/meta-zephyr
https://git.yoctoproject.org/git/auto-upgrade-helper
https://git.yoctoproject.org/git/mraa
https://git.yoctoproject.org/git/opkg
https://git.yoctoproject.org/git/opkg-utils
https://git.yoctoproject.org/git/pseudo
https://git.yoctoproject.org/git/psplash
https://git.yoctoproject.org/git/release-tools
https://git.yoctoproject.org/git/rmc
https://git.yoctoproject.org/git/update-rc.d
https://git.yoctoproject.org/git/yocto-autobuilder
https://git.yoctoproject.org/git/yocto-autobuilder2
https://git.yoctoproject.org/git/eclipse-yocto
https://git.yoctoproject.org/git/test-xvideo
https://git.yoctoproject.org/git/fstests
https://git.yoctoproject.org/git/machinesetuptool
https://git.yoctoproject.org/git/meta-translator
https://git.yoctoproject.org/git/meta-minnow
https://git.yoctoproject.org/git/meta-meson-bsp
https://git.yoctoproject.org/git/meta-meson
https://git.yoctoproject.org/git/meta-luv
https://git.yoctoproject.org/git/meta-intel-quark
https://git.yoctoproject.org/git/meta-intel-galileo
https://git.yoctoproject.org/git/meta-fsl-ppc
https://git.yoctoproject.org/git/meta-fsl-arm
https://git.yoctoproject.org/git/git-submodule-test
)

git config --global --unset https.proxy
git config --list

for repo in "${array[@]}"
do
    layer=$(echo $repo | cut -d '/' -f 5)
    echo $layer
    if [ ! -d $layer ]
    then
        git gc && git clone $repo 
    else
        git pull
    fi
done
