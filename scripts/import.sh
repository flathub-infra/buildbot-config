#!/bin/bash

REPO=$1
REMOTE=$2
IMPORT_REFS=$3
GPG_HOMEDIR=$4
GPG_KEY=$5

set -x
set -e

declare -A MIRROR_REFS

REFS=$(ostree --repo=$REPO remote refs  $REMOTE | sed s/$REMOTE://)
for REF in $REFS; do
    [[ ${REF} != 'runtime/'* && ${REF} != 'app/'* ]] && continue
    IFS='/' read -ra PARTS <<< "$REF"
    for IMPORT_REF in $IMPORT_REFS; do
        IFS='/' read -ra IMPORT_PARTS <<< "$IMPORT_REF"
        [[ ${PARTS[1]} != ${IMPORT_PARTS[0]}* ]] && continue
        [[ ${PARTS[2]} != ${IMPORT_PARTS[1]}*  && ${IMPORT_PARTS[1]} != "" ]] && continue
        [[ ${PARTS[3]} != ${IMPORT_PARTS[2]}*  && ${IMPORT_PARTS[2]} != "" ]] && continue
        #echo Matched: $REF $IMPORT_REF
        COMMIT=$(ostree --repo=$REPO show $REF 2> /dev/null| grep commit)
        #echo COMMIT=$COMMIT
        MIRROR_REFS[$REF]=$COMMIT
        break
    done
done

echo pulling ${!MIRROR_REFS[@]}
ostree --repo=$REPO pull --mirror $REMOTE ${!MIRROR_REFS[@]}

for REF in ${!MIRROR_REFS[@]}; do
    OLD_COMMIT=${MIRROR_REFS[$REF]}
    NEW_COMMIT=$(ostree --repo=$REPO show $REF 2> /dev/null| grep commit)
    echo $REF: $OLD_COMMIT is now $NEW_COMMIT
    # We always sign because the pull overwrote our signature
    echo signing $REF
    ostree gpg-sign --repo=$REPO --gpg-homedir=$GPG_HOMEDIR $REF $GPG_KEY || true
done

flatpak build-update-repo --generate-static-deltas --gpg-homedir=$GPG_HOMEDIR --gpg-sign=$GPG_KEY $REPO
