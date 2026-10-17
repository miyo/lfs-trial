#!/bin/bash

set -e

FORCE=false

while getopts "f" opt; do
    case "$opt" in
        f) FORCE=true ;;
        *) exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 [-f] <disk>" >&2
    exit 1
fi

LFS_DISK="$1"

if [[ ! -b "$LFS_DISK" ]]; then
    echo "Error: $LFS_DISK is not a block device" >&2
    exit 1
fi

echo "Target disk: $LFS_DISK"

if ! $FORCE; then
    read -r -p "Erase partition table? [yes/NO] " answer
    [[ "$answer" == "yes" ]] || exit 1
fi

parted -s "$LFS_DISK" -- mklabel gpt

parted -s "$LFS_DISK" -- mkpart primary 1MiB 11MiB
parted -s "$LFS_DISK" -- set 1 esp on

parted -s "$LFS_DISK" -- mkpart primary 11MiB 12MiB
parted -s "$LFS_DISK" -- set 2 bios_grub on

parted -s "$LFS_DISK" -- mkpart primary 12MiB 512MiB
parted -s "$LFS_DISK" -- name 3 /boot

parted -s "$LFS_DISK" -- mkpart primary linux-swap 512MiB 2560MiB
parted -s "$LFS_DISK" -- set 4 swap on
parted -s "$LFS_DISK" -- name 4 swap

parted -s "$LFS_DISK" -- mkpart primary ext4 2560MiB 100%
parted -s "$LFS_DISK" -- name 5 lfs

parted -s "$LFS_DISK" -- unit MiB print

partprobe "$LFS_DISK"
udevadm settle

if [[ "$LFS_DISK" =~ [0-9]$ ]]; then
    PART_PREFIX="${LFS_DISK}p" # for NVMe type
else
    PART_PREFIX="$LFS_DISK"
fi

mkfs.vfat "$PART_PREFIX"1
mkfs.ext2 -F "$PART_PREFIX"3
mkfs.ext4 -F "$PART_PREFIX"5

mkswap -f "$PART_PREFIX"4

lsblk -o NAME,SIZE,PARTTYPENAME,PARTLABEL,FSTYPE "$LFS_DISK"
