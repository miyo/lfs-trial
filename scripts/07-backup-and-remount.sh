#!/bin/bash

set -e
set +m
set -x

: "${LFS:?LFS environment variable is not set}"
: "${LFS_TARGET_DISK:?LFS_TARGET_DISK environment variable is not set}"

LFS_DISK="$LFS_TARGET_DISK"

for mp in \
    "$LFS/dev/pts" \
    "$LFS/dev/shm" \
    "$LFS/dev" \
    "$LFS/run" \
    "$LFS/proc" \
    "$LFS/sys"
do
    if mountpoint -q "$mp"; then
        umount -v "$mp"
    fi
done

pushd $LFS
tar -cJpf $HOME/lfs-temp-tools-13.1-systemd.tar.xz .
popd

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

/bin/bash "$SCRIPT_DIR"/umount-all.sh
/bin/bash "$SCRIPT_DIR"/mount-all.sh $LFS_DISK

