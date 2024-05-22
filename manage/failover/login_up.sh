#!/bin/bash
set -xe

# Stop drbd'ed services
systemctl stop named kea-dhcp4-server kea-ctrl-agent slurmdbd
systemctl stop mariadb

# Bring down drbd
if mount | grep /usr/drbd/current > /dev/null; then
	umount /usr/drbd/current
fi
drbdadm secondary all
rm -f /usr/drbd/{primary,standby}

# Remove primary/secondary IPs
ip addr del 10.110.10.250/24 dev ibp1s0 2>/dev/null || true
ip addr del 10.110.10.249/24 dev ibp1s0 2>/dev/null || true
ip addr del 10.110.16.5/24 dev enp129s0f1 2>/dev/null || true
ip addr del 10.110.16.6/24 dev enp129s0f1 2>/dev/null || true
ip addr del 10.110.11.10/24 dev eno1np0 2>/dev/null || true
ip addr del 10.110.11.11/24 dev eno1np0 2>/dev/null || true

if [[ $1 == down ]]; then
	exit 0
elif [[ $1 == primary ]]; then
	# Assign primary IPs
	ip addr add 10.110.10.250/24 dev ibp1s0
	ip addr add 10.110.16.5/24 dev enp129s0f1
	ip addr add 10.110.11.10/24 dev eno1np0

	# Bring primary drbd up
	drbdadm primary r0
	mount -o noatime /dev/drbd0 /usr/drbd/current
	ln -s current /usr/drbd/primary

	# Start Primary-Only DRBD'ed services
	systemctl restart mariadb
elif [[ $1 == standby ]]; then
	# Assign secondary IPs
	ip addr add 10.110.10.249/24 dev ibp1s0
	ip addr add 10.110.16.6/24 dev enp129s0f1
	ip addr add 10.110.11.11/24 dev eno1np0

	# Bring secondary drbd up
	drbdadm primary r1
	mount -o noatime /dev/drbd1 /usr/drbd/current
	ln -s current /usr/drbd/standby
else
	echo "Unknown command"
	exit 1
fi

# Bring up DRBD'ed services
systemctl restart named kea-ctrl-agent kea-dhcp4-server

# Restart dependend services
systemctl restart slurmdbd

# Flush ARP Cache everywhere
clush -g all,allm ip neigh flush all || true
