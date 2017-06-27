#!/bin/sh
set -e

if [ $# != 1 ]; then
	echo "Usage: $0 username"
	exit 1
fi

NAME="$1"
DN="$(ldapsearch -x -LLL -b ou=People,dc=klima-cluster,dc=uni-bremen,dc=de uid="$NAME" dn | head -n1 | cut -d' ' -f2)"
GROUPNAME="vpn"

if [ -z "$DN" ]; then
	echo "User not found"
	exit 1
fi


cat <<EOF | ldapmodify -x -W -D "cn=admin,dc=klima-cluster,dc=uni-bremen,dc=de"
dn: cn=$GROUPNAME,ou=Group,dc=klima-cluster,dc=uni-bremen,dc=de
changetype: modify
delete: member
member: $DN
EOF

echo DONE
