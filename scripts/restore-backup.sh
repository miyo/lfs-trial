#!/bin/bash

set -e
set +m

: "${LFS:?LFS environment variable is not set}"

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <disk> <backupfile>" >&2
    exit 1
fi

LFS_DISK="$1"
BACKUP_FILE="$(realpath "$2")"

if [[ ! -b "$LFS_DISK" ]]; then
    echo "Error: $LFS_DISK is not a block device" >&2
    exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: Backup file not found: $BACKUP_FILE" >&2
    exit 1
fi

echo "Target disk: $LFS_DISK"
lsblk "$LFS_DISK"

read -r -p "Erase all data in $LFS on $LFS_DISK? [yes/NO] " answer
[[ "$answer" == "yes" ]] || exit 1

if [[ "$LFS_DISK" =~ [0-9]$ ]]; then
    PART_PREFIX="${LFS_DISK}p"
else
    PART_PREFIX="$LFS_DISK"
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Unmount existing LFS filesystems
/bin/bash "$SCRIPT_DIR/umount-all.sh"

# Recreate filesystems without changing the partition table
mkfs.ext4 -F "${PART_PREFIX}5"
mkfs.ext2 -F "${PART_PREFIX}3"
mkfs.vfat "${PART_PREFIX}1"

# Mount fresh filesystems
/bin/bash "$SCRIPT_DIR/mount-all.sh" "$LFS_DISK"

# Restore backup
echo "extract backup file"
tar -xJpf "$BACKUP_FILE" -C "$LFS"

# Refresh mounts
/bin/bash "$SCRIPT_DIR/umount-all.sh"
/bin/bash "$SCRIPT_DIR/mount-all.sh" "$LFS_DISK"
