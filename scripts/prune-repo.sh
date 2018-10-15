#!/bin/bash

shopt -s extglob

ARG=$1
REPO=$2

N_BACKUPS=4

if [ $ARG = prepare ]; then
    set -x
    # This is slow, so we do it outside the lock in the prepare pahse
    ionice -c idle rm -rf "${REPO}-backup.$(($N_BACKUPS+1))"
else # main
    for i in $(seq $N_BACKUPS -1 1); do
        next_i=$(($i+1))
        mv "${REPO}-backup.${i}" "${REPO}-backup.${next_i}" || true
    done

    set -x

    mkdir ${REPO}-backup.1
    cp -aRln ${REPO}/!(deltas) "${REPO}-backup.1/"
    ostree prune --repo="${REPO}" --refs-only --depth=3
fi
