#!/bin/bash
set -xe

cd "$(dirname "$0")"
rm -f downloads.sha256

ssh 10.110.10.200 "cd /srv/export/home/data/download && rhash -p '%{sha-256} %s %p\n' -r \$(find . -type l -xtype d -exec printf '%s/\n' {} \;) \$(find . -type l -xtype f) ." > downloads.sha256

grep -v 'cluster.klima.uni-bremen.de/~oggm/cmip6_tutorials' downloads.sha256 |
  grep -v 'cluster.klima.uni-bremen.de/~oggm/geodetic_ref_mb_maps' |
  grep -v 'cluster.klima.uni-bremen.de/~oggm/velocities' |
  grep -v 'cluster.klima.uni-bremen.de/~oggm/gdirs/oggm_v1.6' > downloads.sha256.tmp
mv downloads.sha256.tmp downloads.sha256

xz -9 -e downloads.sha256
sha256sum downloads.sha256.xz > downloads.sha256.xz.sha256

#module purge
#module load python/3

./gen_hdf_hashes.py downloads.sha256.xz downloads.sha256.hdf
sha256sum downloads.sha256.hdf > downloads.sha256.hdf.sha256

mv downloads.sha256.xz /home/data/www/downloads.sha256.xz
mv downloads.sha256.xz.sha256 /home/data/www/downloads.sha256.xz.sha256
mv downloads.sha256.hdf /home/data/www/downloads.sha256.hdf
mv downloads.sha256.hdf.sha256 /home/data/www/downloads.sha256.hdf.sha256
