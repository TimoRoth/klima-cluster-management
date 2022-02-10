#!/bin/bash

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

warn "Cluster-Boot Test with Args: $*"

# Huh? Empty $2?
[ -z "$2" ] && exit 1

# Huh? Empty $3?
[ -z "$3" ] && exit 1

# root is in the form root=cluster:rsync://rsync_server/sysimage_root/
#netif="$1"
nroot="$2"
NEWROOT="$3"

# If it's not cluster boot we don't continue
[ "${nroot%%:*}" = "cluster" ] || return

rsyncserver="${nroot#cluster:}"
fsopts="noatime"

info "Doing Cluster-Boot from $rsyncserver"

force_create="$(getargbool 0 rd.force_reformat && echo 1 || echo 0)"

echo "Cluster: Will Force-Create? -> $force_create" 1>&2

# NVMe init can take a while, wait for our devices
udevsettle

# Check if nvme0n1 and nvme1n1 exist and have exactly two partitions
if [ $force_create = 0 ] && [ "/dev/nvme0n1p1 /dev/nvme0n1p2" = "$(echo /dev/nvme0n1p*)" ] && [ "/dev/nvme1n1p1 /dev/nvme1n1p2" = "$(echo /dev/nvme1n1p*)" ]; then
	info "nvme0n1 and nvme1n1 found as expected, continuing"
else
	warn "Empty or unknown disk layout detected, repartitioning"
	for p in /dev/nvme{0,1}n1; do
		sgdisk -o "$p" 1>&2 || die "sgdisk create failed"
		sgdisk --new=1:0:+4G "$p" 1>&2 || die "sgdisk uefi failed"
		sgdisk --largest-new=2 "$p" 1>&2 || die "sgdisk largest failed"
		sgdisk --typecode=1:fd00 "$p" 1>&2 || die "sgdisk typecode UEFI failed"
		sgdisk --typecode=2:fd00 "$p" 1>&2 || die "sgdisk typecode MD failed"
		sgdisk -p "$p" 1>&2 || die "sgdisk print failed"
		partx "$p" 1>&2 || die "partx failed"
	done
	force_create=1
fi

# Wait for partition to settle
udevsettle

# Try to assemble the mdadm array
for p in 1 2; do
	if [ $force_create = 0 ] && mdadm --assemble /dev/md$p /dev/nvme0n1p$p /dev/nvme1n1p$p; then
		info "Assembled mdadm array, continuing"
	else
		warn "Could not assemble mdadm array, creating a new one"
		mdadm --create /dev/md$p --level=0 --raid-devices=2 --run /dev/nvme{0,1}n1p$p || die "mdadm --create failed"
		force_create=1
	fi
done

# Wait for md's
udevsettle

# Attempt to mount once to potentially replay journal
mount -t xfs -o "$fsopts" /dev/md2 "$NEWROOT" >/dev/null 2>&1 && umount "$NEWROOT" >/dev/null 2>&1 || true

# Repair XFS to verify its existence (and to repair it, I guess)
if [ $force_create = 0 ] && xfs_repair /dev/md2; then
	info "Found valid XFS, continuing"
else
	warn "No valid XFS found, reformating"
	mkswap /dev/md1 || die "mkswap failed"
	mkfs.xfs -m bigtime=1 -f /dev/md2 || die "mkfs.xfs failed"
fi

if mount -t xfs -o "$fsopts" /dev/md2 "$NEWROOT"; then
	info "rootfs mounted, continuing"
else
	die "Could not mount xfs for cluster boot"
fi

warn "Copying rootfs via rsync. This could take a while"
rsync --stats -aHAX --delete --force --timeout=300 --exclude "swapfile" "$rsyncserver" "$NEWROOT" || die "rsync failed"
warn "rsync done"

warn "Activating swap"
swapon /dev/md1 || die "swapon failed"

warn "Updating hostname"
hn="$(cat /proc/sys/kernel/hostname)"
hns="${hn%%.*}"
echo "$hns" > /proc/sys/kernel/hostname || die "Setting static hostname failed"
grep -v "$hns" "$NEWROOT/etc/hosts" | sed "s/nodeself/${hns}/g" > "$NEWROOT/etc/hosts_new" || die "/etc/hosts update failed"
mv "$NEWROOT/etc/hosts_new" "$NEWROOT/etc/hosts" || die "hosts move failed"
echo "$hns" > "$NEWROOT/etc/hostname" || die "Setting /etc/hostname failed"

warn "Generating static networkd config"
myif="$(ip -o route get to 8.8.8.8 | sed -n 's/.*dev \([a-zA-Z0-9]\+\).*/\1/p')"
myip="$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')"
mygw="$(ip -o route get to 8.8.8.8 | sed -n 's/.*via \([0-9.]\+\).*/\1/p')"
mkdir -p "$NEWROOT/etc/systemd/network/" || die "mkdir networkd dir failed"
echo -e "[Match]\nName=${myif}\n\n[Network]\nAddress=${myip}/24\nGateway=${mygw}" > "$NEWROOT/etc/systemd/network/50-node.network" || die "echo networkd failed"

[ -e /dev/root ] || ln -s md2 /dev/root

# inject new exit_if_exists
echo 'settle_exit_if_exists="--exit-if-exists=/dev/root"; rm -f -- "$job"' > $hookdir/initqueue/cluster.sh
# force udevsettle to break
: > $hookdir/initqueue/work
