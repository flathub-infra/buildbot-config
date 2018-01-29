#!/bin/bash

set -e

echo Free space on build disk:
df -h .

for i in ../../build-*; do
    if test -d $i; then
         pushd $i
         echo Scanning `basename $i`
         find . -maxdepth 1 -type d -printf '%t %p\n'
         du -csh *
         popd
    fi
done
