#!/bin/bash

COMMAND=$1
FLATHUB_REPO=$2
REMOTE=$3
REMOTE_URL=$4
REMOTE_GPGKEY=$5
IMPORT_REFS=$6
GPG_HOMEDIR=$7
GPG_KEY=$8

set -e

# This needs to be on the same fs as the regular repo so that hardlinks work
IMPORT_REPO=$FLATHUB_REPO/tmp/import-repo

if [ $COMMAND == 'import' ]; then
    ostree --repo=${IMPORT_REPO} init --mode=archive-z2

    curl ${REMOTE_GPGKEY} -o gpg.key
    ostree --repo=${IMPORT_REPO} remote add --if-not-exists --gpg-import=gpg.key ${REMOTE} ${REMOTE_URL}

    echo "Calculating refs to mirror"
    MIRROR_REFS=
    REFS=$(ostree --repo=$FLATHUB_REPO remote refs  $REMOTE | sed s/$REMOTE://)
    for REF in $REFS; do
        [[ ${REF} != 'runtime/'* && ${REF} != 'app/'* ]] && continue
        IFS='/' read -ra PARTS <<< "$REF"
        # We match all subrefs too:
        for IMPORT_REF in $IMPORT_REFS; do
            IFS='/' read -ra IMPORT_PARTS <<< "$IMPORT_REF"
            [[ ${PARTS[1]} != ${IMPORT_PARTS[0]}* ]] && continue
            [[ ${PARTS[2]} != ${IMPORT_PARTS[1]}*  && ${IMPORT_PARTS[1]} != "" ]] && continue
            [[ ${PARTS[3]} != ${IMPORT_PARTS[2]}*  && ${IMPORT_PARTS[2]} != "" ]] && continue
            MIRROR_REFS="${MIRROR_REFS} $REF"
            break
        done
    done

    # Import the current refs so that we don't have to download them
    # This will just be a bunch of hardlinks, so its quick and cheap
    for R in ${MIRROR_REFS}; do
        # Don't fail if the ref doesn't exist locally already
        ostree --repo=${IMPORT_REPO} pull-local --disable-fsync $FLATHUB_REPO ${R} || true
    done

    echo "Mirroring refs from $REMOTE"
    # We pull one at a time, because there is a max limit of fetchs (_OSTREE_MAX_OUTSTANDING_FETCHER_REQUESTS)
    for R in ${MIRROR_REFS}; do
        echo "Mirroring $R"
        ostree --repo=${IMPORT_REPO} pull --disable-fsync --mirror $REMOTE ${R}
    done

    echo "${MIRROR_REFS}" > refs-to-merge
fi

if [ $COMMAND == 'merge' ]; then
    echo "Merging mirrored refs"

    MIRROR_REFS=`cat refs-to-merge`

    set -x

    flatpak build-commit-from -v --gpg-homedir=$GPG_HOMEDIR --gpg-sign=$GPG_KEY \
            --src-repo=${IMPORT_REPO} --no-update-summary $FLATHUB_REPO ${MIRROR_REFS}

    flatpak build-update-repo --gpg-homedir=$GPG_HOMEDIR --gpg-sign=$GPG_KEY $FLATHUB_REPO
    flatpak build-update-repo --generate-static-deltas --gpg-homedir=$GPG_HOMEDIR --gpg-sign=$GPG_KEY $FLATHUB_REPO

    # Only remove this on success, so that on failures we don't have to re-pull *everything*
    rm -rf ${IMPORT_REPO}
fi
