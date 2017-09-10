#!/bin/sh

set -e

echo Free space on build disk:
df -h .

for i in ../../build-*; do
    if test -d $i; then
         pushd $i
         echo Scanning `basename $i`
         du -csh *
         popd
    fi
done
