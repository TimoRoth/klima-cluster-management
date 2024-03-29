#!/bin/sh
set -e

if [ $# != 1 ]; then
	echo "Usage: $0 username"
	exit 1
fi

NAME="$1"

ldapdelete -x -W -D "cn=admin,dc=cluster,dc=klima,dc=uni-bremen,dc=de" "cn=$NAME,ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de" "cn=$NAME,ou=Group,dc=cluster,dc=klima,dc=uni-bremen,dc=de"

echo DONE
