#!/bin/bash

check() {
	return 255
}

depends() {
	echo bash
	echo network
	echo rootfs-block
	echo dracut-systemd
}

install() {
	inst sgdisk
	inst partx
	inst mkfs.xfs
	inst xfs_repair
	inst xfs_growfs
	inst rsync
	inst grep
	inst mdadm
	inst dd
	inst mkswap
	inst swapon
	inst chmod

	inst_hook pre-trigger 30 "$moddir/disable-md.sh"
	inst_hook cmdline 90 "$moddir/parse-clusterroot.sh"
	inst "$moddir/clusterroot.sh" "/sbin/clusterroot"

	dracut_need_initqueue
}

