#!/bin/bash
set -e

if [ $# != 1 ]; then
    echo "Usage: $0 username"
    exit 1
fi

NAME="$1"
NEWHOME="$(eval echo "~$NAME")"

SMBPASSWORD="$(tr -dc A-Za-z0-9 </dev/urandom | head -c14)"
printf '%s\n%s\n' "$SMBPASSWORD" "$SMBPASSWORD" | smbpasswd -s "$NAME"

echo "Samba-password for new user: $SMBPASSWORD"
echo "Your samba password: $SMBPASSWORD" > "$NEWHOME/samba_password.txt"
chown "$NAME:$NAME" "$NEWHOME/samba_password.txt"
chmod 600 "$NEWHOME/samba_password.txt"
