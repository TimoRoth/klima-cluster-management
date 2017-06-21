#!/bin/sh
set -e

if [ $# != 1 ]; then
	echo "Usage: $0 username"
	exit 1
fi

NAME="$1"
HIGHEST_UID="$(ldapsearch -LLL "(uidNumber=*)" uidNumber -S uidNumber | grep uidNumber | tail -n1 | cut -d' ' -f2)"
[ -z "$HIGHEST_UID" ] && HIGHEST_UID=9999
NEW_UID="$(( $HIGHEST_UID + 1 ))"
PASS="$(slappasswd -n -s "$NAME$NAME$NAME")"

if [ -e /home/$NAME ]; then
	echo "Username already has a homedir, aborting."
	exit 1
fi

cat <<EOF | ldapadd -x -W -D "cn=admin,dc=klima-cluster,dc=uni-bremen,dc=de"
dn: cn=$NAME,ou=People,dc=klima-cluster,dc=uni-bremen,dc=de
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
cn: $NAME
uid: $NAME
uidNumber: $NEW_UID
gidNumber: 100
homeDirectory: /home/$NAME
loginShell: /bin/bash
gecos: $NAME
userPassword: $PASS
shadowLastChange: 0
shadowMax: 0
shadowWarning: 0
EOF

cp -a /etc/skel /home/$NAME
chown -R $NAME:users /home/$NAME
chmod 700 /home/$NAME
su $NAME -c "ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 && cp ~/.ssh/id_ed25519.pub  ~/.ssh/authorized_keys"

mkdir -p /srv/sysimage/work/$NAME
chown -R $NAME:users /srv/sysimage/work/$NAME
chmod 700 /srv/sysimage/work/$NAME

clush -a mkdir -p /work/$NAME
clush -a chown -R $NAME:users /work/$NAME
clush -a chmod 700 /work/$NAME

echo DONE
