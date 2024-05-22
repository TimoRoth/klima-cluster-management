#!/bin/bash
set -e
cd "$(dirname "$0")"

if [[ $# != 1 ]]; then
	echo Missing argument
	exit -1
fi

KVER="$(cd /usr/src/linux && make kernelversion)"

ssh "$1" "rm -rf /lib/modules/* /usr/src/*"
rsync -avzHAX --delete --force "/lib/modules/${KVER}/." "$1":"/lib/modules/${KVER}"
if [ -d "/usr/src/ofa_kernel" ]; then
	rsync -azHAX --delete --force "/usr/src/linux" "/usr/src/linux-${KVER}" "/usr/src/ofa_kernel" "$1":"/usr/src/."
else
	rsync -azHAX --delete --force "/usr/src/linux" "/usr/src/linux-${KVER}" "$1":"/usr/src/."
fi
