#!/bin/bash

systemdutildir="$1"
netroot="$2"
NEWROOT="$3"

[ -e "$systemdutildir"/systemd-networkd-wait-online ] || exit 0

if ! "$systemdutildir"/systemd-networkd-wait-online --timeout=5; then
	initqueue --settled --onetime /sbin/try-clusterroot "${systemdutildir}" "${netroot}" "${NEWROOT}"
	exit 0
fi

exec /sbin/clusterroot unused "$netroot" "$NEWROOT"
