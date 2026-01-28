#!/bin/sh
set -e

if [ $# != 1 ]; then
	echo "Usage: $0 username"
	exit 1
fi

NAME="$1"

sacctmgr -i delete User "$NAME" || true
sacctmgr -i delete Account "$NAME" || true

ldapdelete -Y EXTERNAL -H ldapi://%2Frun%2Fopenldap%2Fslapd.sock "cn=$NAME,ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de" "cn=$NAME,ou=Group,dc=cluster,dc=klima,dc=uni-bremen,dc=de"

echo DONE
