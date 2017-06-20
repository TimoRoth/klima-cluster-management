#!/bin/sh
set -e

if [ $# != 1 ]; then
	echo "Usage: $0 username"
	exit 1
fi

NAME="$1"
GROUPNAME="vpn"

cat <<EOF | ldapmodify -x -W -D "cn=admin,dc=klima-cluster,dc=uni-bremen,dc=de"
dn: cn=$GROUPNAME,ou=Group,dc=klima-cluster,dc=uni-bremen,dc=de
changetype: modify
delete: memberUid
memberUid: $NAME
EOF

echo DONE
