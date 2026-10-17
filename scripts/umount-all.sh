#!/bin/bash

set -e

: "${LFS:?LFS environment variable is not set}"

for mp in \
    "$LFS/dev/pts" \
    "$LFS/dev/shm" \
    "$LFS/dev" \
    "$LFS/run" \
    "$LFS/proc" \
    "$LFS/sys" \
    "$LFS/boot/efi" \
    "$LFS/boot" \
    "$LFS"
do
    if mountpoint -q "$mp"; then
        umount -v "$mp"
    fi
done
