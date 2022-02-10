#!/bin/bash
#
# Expected format:
#	root=cluster:rsync://1.2.3.4/rootpath
#

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)

if [ -z "$netroot" ]; then
	for netroot in $(getargs netroot=); do
		[ "${netroot%%:*}" = "cluster" ] && break
	done
	[ "${netroot%%:*}" = "cluster" ] || unset netroot
fi

# Root takes precedence over netroot
if [ "${root%%:*}" = "cluster" ] ; then
	if [ -n "$netroot" ] ; then
		warn "root takes precedence over netroot. Ignoring netroot"
	fi
	netroot=$root
	unset root
fi

# If it's not cluster we don't continue
[ "${netroot%%:*}" = "cluster" ] || return

# Extract rsync root image url
cluster_rsync_url="${netroot#*:}"
warn "Cluster-Boot from $cluster_rsync_url"

# Done, all good!
rootok=1

if [ -z "$root" ]; then
	root=block:/dev/root
	wait_for_dev -n /dev/root
fi

