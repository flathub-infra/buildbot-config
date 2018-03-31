#!/bin/bash

set -e

echo Free space on build disk:
df -h .

for i in ../../build-*; do
    if test -d $i; then
         pushd $i
         echo Scanning `basename $i`
         ls -lat
         du -c --max-depth=1 | sort -n
         umount -v */.flatpak-builder/rofiles/rofiles-* || true
         find -maxdepth 1 -type d -mtime +2 -print0 | xargs -0t rm -rf
         popd
    fi
done

echo Free space on build disk:
df -h .
