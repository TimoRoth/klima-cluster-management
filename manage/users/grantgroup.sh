#!/bin/sh
set -e

if [ $# != 2 ]; then
	echo "Usage: $0 username groupname"
	exit 1
fi

NAME="$1"
DN="$(ldapsearch -x -LLL -b ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de uid="$NAME" dn | head -n1 | cut -d' ' -f2)"
GROUPNAME="$2"

if [ -z "$DN" ]; then
	echo "User not found"
	exit 1
fi

cat <<EOF | ldapmodify -x -W -D "cn=admin,dc=cluster,dc=klima,dc=uni-bremen,dc=de"
dn: cn=$GROUPNAME,ou=Group,dc=cluster,dc=klima,dc=uni-bremen,dc=de
changetype: modify
add: member
member: $DN
EOF

echo DONE
