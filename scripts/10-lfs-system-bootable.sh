#!/bin/bash

set -e
set -x

SRC=/sources
BASE=/sources

cd $BASE

#####################
# Linux
#####################

tar xvf linux-7.1.8.tar.xz
pushd linux-7.1.8

make mrproper
cp $SRC/linux-7.1.8.config.default .config
make
make modules_install

cp -iv arch/x86/boot/bzImage /boot/vmlinuz-7.1.8-lfs-13.1-systemd
cp -iv System.map /boot/System.map-7.1.8
cp -iv .config /boot/config-7.1.8

cp -r Documentation -T /usr/share/doc/linux-7.1.8

#####################
# Setup GRUB
#####################
grub-install --target=x86_64-efi --removable

cat > /boot/grub/grub.cfg << "EOF"
set default=0
set timeout=5

menuentry "LFS 13.1" {
    insmod part_gpt
    insmod ext2
    set root=(hd0,gpt3)
    linux /vmlinuz-7.1.8-lfs-13.1-systemd root=/dev/sda5 ro \
    console=tty0 console=ttyS0,115200n8 \
    loglevel=7 ignore_loglevel 
}
EOF

#####################
# Misc.
#####################

# /etc/lfs-release
echo 13.1-systemd > /etc/lfs-release

# /etc/lsb-release
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="13.1-systemd"
DISTRIB_CODENAME="lfs"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

# /etc/os-release
cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="13.1-systemd"
ID=lfs
PRETTY_NAME="Linux From Scratch 13.1-systemd"
VERSION_CODENAME="lfs 0.1.0"
HOME_URL="https://www.linuxfromscratch.org/lfs/"
RELEASE_TYPE="stable"
EOF
