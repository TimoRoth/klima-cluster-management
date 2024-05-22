#!/bin/bash
set -e

if [ $# != 1 ]; then
	echo "Usage: $0 username"
	exit 1
fi

NAME="$1"
INITPW="$(tr -dc A-Za-z0-9 </dev/urandom | head -c14)"
PWBASE64="$(echo -n "$INITPW" | base64 -w0)"

cat <<EOF | ldapmodify -x -W -D "cn=admin,dc=cluster,dc=klima,dc=uni-bremen,dc=de"
dn: cn=$NAME,ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de
changetype: modify
replace: userPassword
userPassword:: $PWBASE64
-
replace: shadowLastChange
shadowLastChange: 0
-
replace: pwdReset
pwdReset: TRUE
EOF

echo "Reset password for $NAME user: $INITPW"
