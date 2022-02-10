#!/bin/bash
set -e
cd "$(dirname "$0")"

KVER="$(cd /usr/src/linux && make kernelversion)"

cp -L /usr/src/linux/arch/x86/boot/bzImage isoroot/kernel
dracut --force --conf /srv/httpboot/dracut/dracut.conf --xz isoroot/initrd "${KVER}"

grub-mkrescue --compress=xz -d /usr/lib/grub/x86_64-efi -o boot.iso isoroot

ssh store "rm -rf /srv/sysimage/nodes/lib/modules/* /srv/sysimage/nodes/usr/src/*"
rsync -avzHAX --delete --force "/lib/modules/${KVER}/." store:"/srv/sysimage/nodes/lib/modules/${KVER}"
rsync -azHAX --delete --force "/usr/src/linux" "/usr/src/linux-${KVER}" store:"/srv/sysimage/nodes/usr/src/."
