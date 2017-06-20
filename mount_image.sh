#!/bin/bash
mount -t proc /proc /srv/sysimage/proc
mount --rbind /sys /srv/sysimage/sys
mount --make-rslave /srv/sysimage/sys
mount --rbind /dev /srv/sysimage/dev
mount --make-rslave /srv/sysimage/dev
mount --rbind /usr/portage /srv/sysimage/usr/portage
mount --rbind /var/lib/layman/science /srv/sysimage/var/lib/layman/science
