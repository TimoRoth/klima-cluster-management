#!/bin/bash
set -e

if [ $# != 1 ]; then
	echo "Usage: $0 username"
	exit 1
fi

NAME="$1"
HIGHEST_UID="$(ldapsearch -LLL "(uidNumber=*)" uidNumber -S uidNumber | grep uidNumber | tail -n1 | cut -d' ' -f2)"
[ -z "$HIGHEST_UID" ] && HIGHEST_UID=9999
NEW_UID="$(( $HIGHEST_UID + 1 ))"
NEWHOME="/home/users/$NAME"
INITPW="$(tr -dc A-Za-z0-9 </dev/urandom | head -c14)"
PWBASE64="$(echo -n "$INITPW" | base64 -w0)"

if [ -e "$NEWHOME" ]; then
	echo "Username already has a homedir, aborting."
	exit 1
fi

cat <<EOF | ldapmodify -x -W -D "cn=admin,dc=cluster,dc=klima,dc=uni-bremen,dc=de"
dn: cn=$NAME,ou=People,dc=cluster,dc=klima,dc=uni-bremen,dc=de
changetype: add
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
objectClass: sambaSamAccount
objectClass: groupedPerson
cn: $NAME
uid: $NAME
uidNumber: $NEW_UID
gidNumber: $NEW_UID
sambaSID: S-1-5-21-946833786-2825050785-1849188623-$NEW_UID
homeDirectory: $NEWHOME
loginShell: /bin/bash
gecos: Account added via adduser.sh by $(whoami) on $(date +"%Y-%m-%d %H-%M-%S %Z")
userPassword:: $PWBASE64
shadowLastChange: 0
pwdReset: TRUE

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
chmod 700 "$NEWHOME"
su $NAME -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 && cp ~/.ssh/id_ed25519.pub  ~/.ssh/authorized_keys"

mkdir "/home/www/$NAME"
chown -R $NAME:$NAME "/home/www/$NAME"
chmod 755 "/home/www/$NAME"

# Apply default quota of 1TB for new users
clush -w 10.110.10.200 zfs set "userquota@${NAME}=1T" datapool/export/home

SMBPASSWORD="$(tr -dc A-Za-z0-9 </dev/urandom | head -c14)"
printf '%s\n%s\n' "$SMBPASSWORD" "$SMBPASSWORD" | smbpasswd -s "$NAME"

echo
echo "Initial password for new user: $INITPW"

echo "Samba-password for new user: $SMBPASSWORD"
echo "Your samba password: $SMBPASSWORD" > "$NEWHOME/samba_password.txt"
chown "$NAME:$NAME" "$NEWHOME/samba_password.txt"
chmod 600 "$NEWHOME/samba_password.txt"

echo DONE
