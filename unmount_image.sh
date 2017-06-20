#!/bin/bash
umount -R /srv/sysimage/usr/portage
umount -R /srv/sysimage/var/lib/layman/science
umount -R /srv/sysimage/proc
umount -l /srv/sysimage/dev{/shm,/pts,}
umount -R /srv/sysimage/sys
