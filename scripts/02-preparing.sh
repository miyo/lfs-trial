#!/bin/bash

set +m
set -e

: "${LFS:?LFS environment variable is not set}"
: "${LFS_TARGET_DISK:?LFS_TARGET_DISK environment variable is not set}"

echo "Target disk: $LFS_TARGET_DISK"
lsblk "$LFS_TARGET_DISK"
read -r -p "Erase partition table? [yes/NO] " answer
[[ "$answer" == "yes" ]] || exit 1

echo 'install required packages'

apt install -y \
  build-essential \
  bison \
  gawk \
  m4 \
  texinfo

ln -sf bash /bin/sh

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

/bin/bash "$SCRIPT_DIR"/version-check.sh
/bin/bash "$SCRIPT_DIR"/umount-all.sh
/bin/bash "$SCRIPT_DIR"/make-partitions.sh -f "$LFS_TARGET_DISK"
/bin/bash "$SCRIPT_DIR"/mount-all.sh "$LFS_TARGET_DISK"

mkdir -pv "$LFS"/sources
chmod -v a+wt "$LFS"/sources

if ! /bin/bash "$SCRIPT_DIR/download-and-check.sh" "$SCRIPT_DIR/download.list"; then
    echo "Download failed. Run 'bash $SCRIPT_DIR/download-and-check.sh $SCRIPT_DIR/download.list' again to retry."
    exit 1
fi
