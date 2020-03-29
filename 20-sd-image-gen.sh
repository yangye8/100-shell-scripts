#!/bin/bash
# Create a SD card image to be used for flashing board
set -e


############################  SETUP PARAMETERS
debug_mode='0'

IMG="$(date +%F-%T).img"
ROOTFS="rootfs"
# Boot partition size [in KiB]
BOOT_SPACE="524288"
BOOT_DIM=512

trap "printf \"\n%s\n\" exit ;exit" INT

############################  BASIC SETUP TOOLS
msg() {
    printf '%b\n' "$1" >&2
}

success() {
    if [ "$ret" -eq '0' ]; then
        msg "\33[32m[✔]\33[0m ${1}${2}"
    fi
}

error() {
    msg "\33[31m[✘]\33[0m ${1}${2}"
    [ -e ${ROOTFS} ] && rm -rf ${ROOTFS}
    [ -e ${IMG} ] && rm -rf ${IMG}
    exit 1
}

debug() {
    if [ "$debug_mode" -eq '1' ] && [ "$ret" -gt '1' ]; then
        msg "An error occurred in function \"${FUNCNAME[$i+1]}\" on line ${BASH_LINENO[$i+1]}, we're sorry for that."
    fi
}

file_must_exists() {
    # throw error on non-zero return value
    if [ ! -e "$1" ]; then
        error "You must have '$1' file to continue."
    fi
}

############################ SETUP FUNCTIONS

lodetach () {
    DEVICE="${1}"
    ATTEMPT="${2:-1}"

    if [ "${ATTEMPT}" -gt 3 ]
    then
        echo "Failed to detach loop device '${DEVICE}'."
        exit 1
    fi

    # Changes to block devices result in uevents which trigger rules which in
    # turn access the loop device (ex. udisks-part-id, blkid) which can cause
    # a race condition. We call 'udevadm settle' to help avoid this.
    if [ -x "$(which udevadm 2>/dev/null)" ]
    then
        udevadm settle
    fi

    # Loop back devices aren't the most reliable when it comes to writes.
    # We sleep and sync for good measure - better than build failure.
    sync
    sleep 1

     losetup -d "${DEVICE}" || lodetach "${DEVICE}" "$(expr ${ATTEMPT} + 1)"
}

privs () {
	if [ "$(id -u)" != 0 ]; then
		echo "Sorry, $0 must be run as root."
		exit 1
	fi	
}

calc_space () {
    local tar_file="$1"

    mkdir ${ROOTFS} && tar -zxf "$tar_file" -C ${ROOTFS}

    DU_DIM="$( du -ms ${ROOTFS} | cut -f1)"
    REAL_DIM="$(echo $(expr ${DU_DIM} + ${DU_DIM} \* 10 / 100 + 1))"
    REAL_DIM="$(($REAL_DIM + $BOOT_DIM + 100))"

    dd if=/dev/zero of=$IMG bs=1024k count=0 seek=${REAL_DIM} >/dev/null 2>&1
}

mkpart_mkfs () {
    losetup $FREELO $IMG 0

    parted -s ${FREELO} mklabel msdos || true
    parted -a optimal -s ${FREELO} mkpart primary fat32 1 ${BOOT_DIM} || true
    parted -a optimal -s ${FREELO} mkpart primary ext4 ${BOOT_DIM} 100% || true
    parted -s "${FREELO}" set 1 boot on || true
    parted -s "${FREELO}" set 1 lba off || true

    mkfs.vfat -F 32 -n "BOOT" ${FREELO}p1 >/dev/null 2>&1
    mkfs.ext4 -L "ROOTFS" ${FREELO}p2 >/dev/null 2>&1

    ret="$?"
    success "Setting up partition"
    debug
}

boot_cp () {
        mkdir -p binary.tmp
        mount ${FREELO}p1 binary.tmp
        umount binary.tmp

        ret="$?"
        success "Copying $1 $2 $3 $4 to fat32 partition"
        debug
    }

rootfs_cp () {
     mount ${FREELO}p2 binary.tmp
     tar -xf $1 -C binary.tmp

    sync && sync && sleep 1

    umount binary.tmp
    rmdir binary.tmp

    lodetach ${FREELO}

    ret="$?"
    success "Copying ROOTFS contents to ext4 partition"
    debug
}

finalize () {

    zip -r $IMG.zip $IMG >/dev/null 2>&1

    ret="$?"
    success "Compressing SD image"
    debug

    clean_work_area
}

usage () 
{
    echo Usage:
    echo "    ./mk_image.sh BOARD_DIR"
    echo "                --BOARD_DIR    zcu102 or zcu104"
    echo "    BOARD_DIR must contain BOOT.BIN and xclbin"
}

############################ MAIN()

clean_work_area () {
    [ -d ${ROOTFS} ] && rm -rf ${ROOTFS}

    if mount | grep "binary.tmp" >/dev/null 2>&1;
    then
        umount ./binary.tmp >/dev/null 2>&1
    fi

    [ -d "binary.tmp" ] && rm -rf binary.tmp
    rm -rf *.img
}

tgz2ext4() {
    local OUT=$(echo $1 | cut -d '.' -f '1').ext4
    local MOUNT_POINT="mnt"
    local ROOTFS="rootfs"

    if [ ! -d $ROOTFS ];then
        mkdir $ROOTFS
        tar -zxf $1 -C $ROOTFS
    fi

    ROOTFS_SIZE=$(du -s $ROOTFS | cut -f '1')
    ROOTFS_SIZE=$(expr $ROOTFS_SIZE + 102400)

    dd if=/dev/zero of=$OUT bs=1024 count=$ROOTFS_SIZE >/dev/null 2>&1

    mkfs.ext4 -F -L "ROOTFS" $OUT >/dev/null 2>&1

    [ ! -d "$MOUNT_POINT" ] && mkdir $MOUNT_POINT

    sudo mount $OUT $MOUNT_POINT
    sudo tar -zxf $1 -C $MOUNT_POINT && sync && sync
    sudo umount $MOUNT_POINT

    rm -rf $ROOTFS
}

main4tgz () {

    FREELO="$( losetup -f)"
    calc_space       "rootfs.tar.gz"
    mkpart_mkfs
    boot_cp
    rootfs_cp        "rootfs.tar.gz"
    finalize
    clean_work_area
    msg             "\nSD-card image $IMG.zip done"
    msg             "© `date +%Y`"
}

main4ext4 () {
    # Set alignment to 4MB [in KiB]
    IMAGE_ROOTFS_ALIGNMENT="4096"

    # Align partitions
    BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ROOTFS_ALIGNMENT} - 1)
    BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - ${BOOT_SPACE_ALIGNED} % ${IMAGE_ROOTFS_ALIGNMENT})
    ROOTFS_SIZE=$(du -s $1 | cut -f '1')
    SDIMG_SIZE=$(expr ${IMAGE_ROOTFS_ALIGNMENT} + ${BOOT_SPACE_ALIGNED} + ${ROOTFS_SIZE} + ${IMAGE_ROOTFS_ALIGNMENT})

    # Initialize sdcard image file
    dd if=/dev/zero of=${IMG} bs=1 count=0 seek=$(expr 1024 \* ${SDIMG_SIZE}) >/dev/null 2>&1

    # Create partition table
    parted -s ${IMG} mklabel msdos
    # Create boot partition and mark it as bootable
    parted -s ${IMG} unit KiB mkpart primary fat32 ${IMAGE_ROOTFS_ALIGNMENT} \
        $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT})
    parted -s ${IMG} set 1 boot on
    parted -s ${IMG} set 1 lba  off
    # Create rootfs partition
    parted -s ${IMG} unit KiB mkpart primary ext4 $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT}) \
        $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT} \+ ${ROOTFS_SIZE})

	# Create boot partition image
	BOOT_BLOCKS=$(LC_ALL=C parted -s ${IMG} unit b print \
	                  | awk "/ 1 / { print substr(\$4, 1, length(\$4 -1)) / 1024 }")

	# mkdosfs will sometimes use FAT16 when it is not appropriate,
	# resulting in a boot failure from SYSLINUX. Use FAT32 for
	# images larger than 512MB, otherwise let mkdosfs decide.
	if [ $(expr $BOOT_BLOCKS / 1024) -gt 512 ]; then
		FATSIZE="-F 32"
	fi

    if [ -f boot.img ]; then
       rm -f boot.img
    fi
	mkfs.vfat -n "BOOT" -S 512 ${FATSIZE} -C boot.img $BOOT_BLOCKS >/dev/null

    # Add stamp file
    mcopy -i boot.img -v BOOT.BIN ::
    mcopy -i boot.img -v Image ::

    # Burn Partitions
    dd if=boot.img of=${IMG} conv=notrunc seek=1 bs=$(expr ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) >/dev/null 2>&1 && sync && sync 
    dd if=$1 of=${IMG} conv=notrunc seek=1 bs=$(expr 1024 \* ${BOOT_SPACE_ALIGNED} + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) >/dev/null 2>&1 && sync && sync
    parted ${IMG} print

    rm -rf boot.img 

    finalize
    msg             "\nSD-card image $IMG.zip done"
    msg             "© `date +%Y`"
}

main () {

    trap "echo; echo -n Removing work area...; clean_work_area; echo exit;exit" INT

    file_must_exists "BOOT.BIN"
    file_must_exists "dpu.xclbin"

    for f in ./*
    do
        if [ -f $f ];then
            case ${f%i,} in
                *.ext4)
                    file_must_exists "rootfs.ext4"
                    file_must_exists "Image"
                    main4ext4 $f 
                    return 0
                    ;;
                *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
                    privs
                    file_must_exists "image.ub"
                    file_must_exists "rootfs.tar.gz"
                    main4tgz $f
                    return 0
                    ;;
            esac
        fi
    done
}

main "$@"
