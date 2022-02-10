#!/bin/bash
set -e

cd "$(dirname "$0")"

ping -q -c 4 -W 1 10.110.11.10 >/dev/null && PRI_UP=1 || PRI_UP=0
ping -q -c 4 -W 1 10.110.11.11 >/dev/null && SEC_UP=1 || SEC_UP=0

if [[ $PRI_UP == 1 && $SEC_UP == 0 ]]; then
	exec ./login_up.sh standby
elif [[ $PRI_UP == 0 && $SEC_UP == 1 ]]; then
	exec ./login_up.sh primary
elif [[ $PRI_UP == 0 && $SEC_UP == 0 ]]; then
	if [[ $(hostname -s) == login01 ]]; then
		exec ./login_up.sh primary
	else
		exec ./login_up.sh standby
	fi
elif [[ $PRI_UP == 1 && $SEC_UP == 1 ]]; then
	echo "Both up?"
	exit -1
fi
