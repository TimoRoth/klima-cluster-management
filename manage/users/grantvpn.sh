#!/bin/sh
set -e

if [ $# != 1 ]; then
	echo "Usage: $0 username"
	exit 1
fi

NAME="$1"
DN="$(ldapsearch -x -LLL -b ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de uid="$NAME" dn | head -n1 | cut -d' ' -f2)"
GROUPNAME="vpn"

if [ -z "$DN" ]; then
	echo "User not found"
	exit 1
fi

cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi://%2Frun%2Fopenldap%2Fslapd.sock
dn: cn=$GROUPNAME,ou=Group,dc=cluster,dc=klima,dc=uni-bremen,dc=de
changetype: modify
add: member
member: $DN
EOF

echo DONE
