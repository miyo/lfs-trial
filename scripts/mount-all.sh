#!/bin/bash

set -e

: "${LFS:?LFS environment variable is not set}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <disk>" >&2
    exit 1
fi

LFS_DISK="$1"

if [[ "$LFS_DISK" =~ [0-9]$ ]]; then
    PART_PREFIX="${LFS_DISK}p" # for NVMe type
else
    PART_PREFIX="$LFS_DISK"
fi

mkdir -p "$LFS"

mount -v -t ext4 "$PART_PREFIX"5 "$LFS"/

mkdir -p "$LFS"/boot
mount -v -t ext2 "$PART_PREFIX"3 "$LFS"/boot

mkdir -p "$LFS"/boot/efi
mount -v -t vfat "$PART_PREFIX"1 "$LFS"/boot/efi

mkdir -p "$LFS"/{dev,dev/pts,proc,sys,run}

mount -v --bind /dev "$LFS"/dev
mount -vt devpts devpts -o gid=5,mode=0620 "$LFS"/dev/pts
mount -vt proc proc "$LFS"/proc
mount -vt sysfs sysfs "$LFS"/sys
mount -vt tmpfs tmpfs "$LFS"/run

if [ -h "$LFS"/dev/shm ]; then
 install -v -d -m 1777 "$LFS$(realpath /dev/shm)"
else
 mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS"/dev/shm
fi

mkdir -pv "$LFS"/{etc,var} "$LFS"/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i "$LFS"/$i
done

case $(uname -m) in
  x86_64) mkdir -pv "$LFS"/lib64 ;;
esac

mkdir -pv "$LFS"/tools

