#!/bin/bash
set -e

cd "$(dirname "$0")"
[ -d grub ] && rm -r grub
grub-mknetdir --compress=xz --net-directory=/srv/tftpboot --subdir=grub
echo "source /grub.cfg" > grub/grub.cfg
find grub -type f -exec chmod 644 {} \;
find grub -type d -exec chmod 755 {} \;

cp /boot/kernel-$(uname -r) kernel

test -f initrd && rm initrd
dracut --conf /srv/tftpboot/dracut/dracut.conf --xz initrd "$(uname -r)"

chmod 644 kernel initrd
