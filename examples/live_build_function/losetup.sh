#!/bin/bash

#HDD_SIZE="auto"
HDD_SIZE=4GB

Lodetach ()
{
	DEVICE="${1}"
	ATTEMPT="${2:-1}"

	if [ "${ATTEMPT}" -gt 3 ]
	then
		Echo_error "Failed to detach loop device '${DEVICE}'."
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

	losetup -d "${DEVICE}" || Lodetach "${DEVICE}" "$(expr ${ATTEMPT} + 1)"
}

Losetup ()
{
	DEVICE="${1}"
	FILE="${2}"
	PARTITION="${3:-1}"

	losetup --read-only "${DEVICE}" "${FILE}"
	FDISK_OUT="$(fdisk -l -u ${DEVICE} 2>&1)"
	Lodetach "${DEVICE}"

	LOOPDEVICE="$(echo ${DEVICE}p${PARTITION})"

	if [ "${PARTITION}" = "0" ]
	then
		Echo_message "Mounting %s with offset 0" "${DEVICE}"

		losetup "${DEVICE}" "${FILE}"
	else
		SECTORS="$(echo "$FDISK_OUT" | sed -ne "s|^$LOOPDEVICE[ *]*\([0-9]*\).*|\1|p")"
		OFFSET="$(expr ${SECTORS} '*' 512)"

		Echo_message "Mounting %s with offset %s" "${DEVICE}" "${OFFSET}"

		losetup -o "${OFFSET}" "${DEVICE}" "${FILE}"
	fi
}

Calculate_partition_size ()
{
	ORIGINAL_SIZE="${1}"
	FILESYSTEM="${2}"

	case "${FILESYSTEM}" in
		ext2|ext3|ext4)
			PERCENT="10"
			;;
		*)
			PERCENT="3"
			;;
	esac

	echo $(expr ${ORIGINAL_SIZE} + ${ORIGINAL_SIZE} \* ${PERCENT} / 100 + 1)
}

ISO_Create ()
{
	BOOT_DIM="${3}"
	OF=${1}/binary.img
	
	if [ "$HDD_SIZE" = "auto" ];
	then
		DU_DIM="$(du -ms ${2} | cut -f1)"
		REAL_DIM="$(Calculate_partition_size ${DU_DIM} ext4)"
		REAL_DIM="$(($REAL_DIM + $BOOT_DIM + 100))"
	else
		REAL_DIM=4096
	fi
	
	dd if=/dev/zero of=$OF bs=1024k count=0 seek=${REAL_DIM} >/dev/null 2>&1
	
	FREELO="$(losetup -f)"
	Losetup $FREELO $OF 0
	
	parted -s ${FREELO} mklabel msdos || true
	parted -a optimal -s ${FREELO} mkpart primary fat32 1 ${BOOT_DIM} || true
	parted -a optimal -s ${FREELO} mkpart primary ext4 ${BOOT_DIM} 100% || true
	parted -s "${FREELO}" set 1 boot on || true
	parted -s "${FREELO}" set 1 lba off || true
	
	mkfs.vfat -F 32 -n "BOOT" ${FREELO}p1 >/dev/null
	mkfs.ext4 -L "ROOTFS" ${FREELO}p2 >/dev/null
	Echo_message "Copying binary contents into image..."
	
	mkdir -p binary.tmp
	mount ${FREELO}p1 binary.tmp
	cp -rf img/* binary.tmp
	umount binary.tmp
	
	mount ${FREELO}p2 binary.tmp
	cp -a ${2}/* binary.tmp
	sync && sync
	sleep 1
	umount binary.tmp
	
	rmdir binary.tmp
	Lodetach ${FREELO}
}
