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
         find -maxdepth 1 -type d -mtime +90 -print0 | xargs rm -rfv
         popd
    fi
done

echo Free space on build disk:
df -h .
