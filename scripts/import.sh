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
PULL_REPO=pull-repo

if [ $COMMAND == 'import' ]; then
    curl ${REMOTE_GPGKEY} -o gpg.key
    ostree --repo=${FLATHUB_REPO} remote add --if-not-exists --gpg-import=gpg.key ${REMOTE} ${REMOTE_URL}

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
            [[ ${PARTS[2]} != ${IMPORT_PARTS[1]} && ${IMPORT_PARTS[1]} != "" ]] && continue
            [[ ${PARTS[3]} != ${IMPORT_PARTS[2]} && ${IMPORT_PARTS[2]} != "" ]] && continue
            MIRROR_REFS="${MIRROR_REFS} $REF"
            break
        done
    done

    rm -rf ${PULL_REPO}
    ostree --repo=${PULL_REPO} init --mode=bare-user
    ostree --repo=${PULL_REPO} remote add --if-not-exists --gpg-import=gpg.key ${REMOTE} ${REMOTE_URL}

    echo "Mirroring refs from $REMOTE; ${MIRROR_REFS}"
    # We pull one at a time, because there is a max limit of fetchs (_OSTREE_MAX_OUTSTANDING_FETCHER_REQUESTS)
    for R in ${MIRROR_REFS}; do
        echo "Mirroring $R"
        # We retry this 5 times, because we keep getting weird timeouts
        for i in $(seq 1 5); do
            ostree --repo=${PULL_REPO} pull --disable-fsync --mirror $REMOTE ${R} && res=0 && break || res=$?;
        done;
        (exit $res)
    done

    # Rebase pulled refs on previous flathub revision
    echo "Rebasing on flathub revisions"

    rm -rf ${IMPORT_REPO}
    ostree --repo=${IMPORT_REPO} init --mode=archive-z2
    ostree --repo=${IMPORT_REPO} remote add --if-not-exists --gpg-import=gpg.key ${REMOTE} ${REMOTE_URL}

    # First we import the current version
    # This will just be a bunch of hardlinks, so its quick and cheap
    for R in ${MIRROR_REFS}; do
        # Don't fail if the ref doesn't exist locally already
        ostree --repo=${IMPORT_REPO} pull-local --disable-fsync $FLATHUB_REPO ${R} || true
    done

    # Then we add the rebase the new commits on top of that
    flatpak build-commit-from -v --disable-fsync --gpg-homedir=$GPG_HOMEDIR --gpg-sign=$GPG_KEY \
            --src-repo=${PULL_REPO} --no-update-summary $IMPORT_REPO ${MIRROR_REFS}

    rm -rf ${PULL_REPO}

    # We generate deltas in the import repo here, so it happens outside the repo lock
    echo "Generating deltas"
    flatpak build-update-repo --generate-static-deltas --static-delta-jobs=2 --gpg-homedir=$GPG_HOMEDIR --gpg-sign=$GPG_KEY $IMPORT_REPO

    echo "${MIRROR_REFS}" > refs-to-merge
fi

if [ $COMMAND == 'merge' ]; then
    echo "Merging mirrored refs"

    MIRROR_REFS=`cat refs-to-merge`

    set -x

    flatpak build-commit-from -v --gpg-homedir=$GPG_HOMEDIR --gpg-sign=$GPG_KEY \
            --src-repo=${IMPORT_REPO} --no-update-summary $FLATHUB_REPO ${MIRROR_REFS}

    flatpak build-update-repo --gpg-homedir=$GPG_HOMEDIR --gpg-sign=$GPG_KEY $FLATHUB_REPO
    flatpak build-update-repo --generate-static-deltas --static-delta-jobs=2  --gpg-homedir=$GPG_HOMEDIR --gpg-sign=$GPG_KEY $FLATHUB_REPO

    rm -rf ${IMPORT_REPO}
fi
