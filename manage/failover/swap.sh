#!/bin/bash
set -e

if [[ $1 == primary ]]; then
	/srv/manage/failover/login_up.sh down
	clush -g other /srv/manage/failover/login_up.sh standby
	/srv/manage/failover/login_up.sh primary
elif [[ $1 == standby ]]; then
	/srv/manage/failover/login_up.sh down
	clush -g other /srv/manage/failover/login_up.sh primary
	/srv/manage/failover/login_up.sh standby
else
	echo "Invalid argument"
	exit 1
fi
