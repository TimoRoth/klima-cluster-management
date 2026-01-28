#!/bin/bash
set -eo pipefail

if [ $# != 1 ]; then
        echo "Usage: $0 username"
        exit 1
fi

NAME="$1"
DN="$(ldapsearch -x -LLL -b ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de uid="$NAME" dn | head -n1 | cut -d' ' -f2)"
REALM="CLUSTER.KLIMA.UNI-BREMEN.DE"
PRINAME="${NAME}@${REALM}"

if [ -z "$DN" ]; then
	echo "User not found"
	exit 1
fi

INITPW="$(tr -dc A-Za-z0-9 </dev/urandom | head -c32 || true)"
if [[ -n "$FORCEPW" ]]; then
	INITPW="$FORCEPW"
fi

kadmin.local -r "$REALM" add_principal -x dn="$DN" -pw "$INITPW" "$NAME"

cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi://%2Frun%2Fopenldap%2Fslapd.sock
dn: $DN
changetype: modify
replace: userPassword
userPassword: {SASL}$PRINAME
-
replace: pwdReset
pwdReset: FALSE
EOF

echo "Kerberized $NAME with new password: $INITPW"


