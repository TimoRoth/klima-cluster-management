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
PWBASE64="$(echo -n "$NAME$NAME$NAME" | base64 -w0)"

if [ -e "$NEWHOME" ]; then
	echo "Username already has a homedir, aborting."
	exit 1
fi

cat <<EOF | ldapadd -x -W -D "cn=admin,dc=klima-cluster,dc=uni-bremen,dc=de"
dn: cn=$NAME,ou=People,dc=klima-cluster,dc=uni-bremen,dc=de
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
objectClass: sambaSamAccount
cn: $NAME
uid: $NAME
uidNumber: $NEW_UID
gidNumber: $NEW_UID
sambaSID: S-1-5-21-946833786-2825050785-1849188622-$NEW_UID
homeDirectory: $NEWHOME
loginShell: /bin/bash
gecos: Account added via adduser.sh by $(whoami) on $(date)
userPassword:: $PWBASE64
pwdReset: TRUE
shadowLastChange: 0

dn: cn=$NAME,ou=Group,dc=klima-cluster,dc=uni-bremen,dc=de
objectClass: top
objectClass: groupOfNames
objectClass: posixGroup
cn: $NAME
gidNumber: $NEW_UID
member: cn=$NAME,ou=People,dc=klima-cluster,dc=uni-bremen,dc=de
EOF

cp -a /etc/skel "$NEWHOME"
chown -R $NAME:$NAME "$NEWHOME"
chmod 700 "$NEWHOME"
su $NAME -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 && cp ~/.ssh/id_ed25519.pub  ~/.ssh/authorized_keys"

mkdir "/home/www/$NAME"
chown -R $NAME:$NAME "/home/www/$NAME"
chmod 755 "/home/www/$NAME"

# Apply default quota of 1TB for new users
zfs set "userquota@${NAME}=1T" datapool/home

# Add to users group
gpasswd -a "${NAME}" users

# Workdir dynamically created by slurm prolog/epilog
#mkdir -p /srv/sysimage/work/$NAME
#chown -R $NAME:users /srv/sysimage/work/$NAME
#chmod 700 /srv/sysimage/work/$NAME
#clush -a mkdir -p /work/$NAME
#clush -a chown -R $NAME:users /work/$NAME
#clush -a chmod 700 /work/$NAME

SMBPASSWORD="$(tr -dc A-Za-z0-9 </dev/urandom | head -c14)"
printf '%s\n%s\n' "$SMBPASSWORD" "$SMBPASSWORD" | smbpasswd -s "$NAME"

echo "Samba-password for new user: $SMBPASSWORD"
echo "Your samba password: $SMBPASSWORD" > "$NEWHOME/samba_password.txt"
chown "$NAME:$NAME" "$NEWHOME/samba_password.txt"
chmod 600 "$NEWHOME/samba_password.txt"

echo DONE
