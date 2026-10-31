#!/bin/bash
set -e

if [ $# != 1 ]; then
	echo "Usage: $0 username"
	exit 1
fi

REALM="CLUSTER.KLIMA.UNI-BREMEN.DE"

NAME="$1"
HIGHEST_UID="$(ldapsearch -x -LLL "(uidNumber=*)" uidNumber -S uidNumber | grep uidNumber | tail -n1 | cut -d' ' -f2)"
[ -z "$HIGHEST_UID" ] && HIGHEST_UID=9999
NEW_UID="$(( $HIGHEST_UID + 1 ))"
NEWHOME="/home/users/$NAME"
INITPW="$(tr -dc A-Za-z0-9 </dev/urandom | head -c14)"

DN="cn=$NAME,ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de"

if [ -e "$NEWHOME" ]; then
	echo "Username already has a homedir, aborting."
	exit 1
fi

cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi://%2Frun%2Fopenldap%2Fslapd.sock
dn: $DN
changetype: add
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
objectClass: groupedPerson
cn: $NAME
uid: $NAME
uidNumber: $NEW_UID
gidNumber: $NEW_UID
homeDirectory: $NEWHOME
loginShell: /bin/bash
gecos: Account added via adduser.sh by $(whoami) on $(date +"%Y-%m-%d %H-%M-%S %Z")
userPassword: {SASL}$NAME@$REALM
shadowLastChange: 0
pwdReset: FALSE

dn: cn=$NAME,ou=Group,dc=cluster,dc=klima,dc=uni-bremen,dc=de
changetype: add
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: $NAME
gidNumber: $NEW_UID
member: cn=$NAME,ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de

dn: cn=clusterusers,ou=Group,dc=cluster,dc=klima,dc=uni-bremen,dc=de
changetype: modify
add: member
member: cn=$NAME,ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de

dn: cn=vpn,ou=Group,dc=cluster,dc=klima,dc=uni-bremen,dc=de
changetype: modify
add: member
member: cn=$NAME,ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de
EOF

cp -a /etc/skel "$NEWHOME"
chown -R $NAME:$NAME "$NEWHOME"
chmod 750 "$NEWHOME"
sudo -i -u "$NAME" bash -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 && cp ~/.ssh/id_ed25519.pub  ~/.ssh/authorized_keys"

mkdir "/home/www/$NAME"
chown -R $NAME:$NAME "/home/www/$NAME"
chmod 755 "/home/www/$NAME"

# Apply default quota of 1TB for new users
clush -w 10.110.10.200 zfs set "userquota@${NAME}=1T" datapool/export/home

echo "Kerberizing..."

kadmin.local -r "$REALM" add_principal -x dn="$DN" -pw "$INITPW" "$NAME"

echo "Registering user with slurm..."

sacctmgr -i add Account "$NAME"
sacctmgr -i add User Accounts="$NAME" "$NAME"

echo
echo "Initial password for new user: $INITPW"
echo

echo DONE
