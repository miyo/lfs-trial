#!/bin/bash

set -e
set -x

: "${NET_IF_NAME:?NET_IF_NAME environment variable is not set}"
: "${HOST_NAME:?HOST_NAME environment variable is not set}"

#############################
# Network
#############################

# interface

cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
[Match]
Name=$NET_IF_NAME

[Network]
## Address=192.168.0.2/24
## Gateway=192.168.0.1
## DNS=192.168.0.1
## Domains=<Your Domain Name>
DHCP=ipv4

[DHCPv4]
UseDomains=true

EOF

# hostname

echo "$HOST_NAME" > /etc/hostname

# /etc/hosts

cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost

::1 ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

# End /etc/hosts
EOF


#############################
# System Clock
#############################

# /etc/adjtime

cat > /etc/adjtime << "EOF"
0.0 0 0.0
0
LOCAL
EOF

# # Use localtime
# !! It is not allowed under chroot environment
# timedatectl set-local-rtc 1

#############################
# System Locale
#############################

# /etc/locale.conf
cat > /etc/locale.conf << "EOF"
LANG=C
EOF

# /etc/profile
cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  source /etc/locale.conf
  for i in $(locale); do
    key=${i%=*}
    if [[ -v $key ]]; then
      export $key
    fi
  done
fi

# End /etc/profile
EOF

#############################
# Misc.
#############################

# /etc/inputrc
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# uncomment for history search mode with up/down
# "\e[A": history-search-backward
# "\e[B": history-search-forward

# End /etc/inputrc
EOF

# /etc/shells

cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

# Disable screen clearing at boot time

mkdir -pv /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf << EOF
[Service]
TTYVTDisallocate=no
EOF

# /etc/fstab
cat > /etc/fstab << "EOF"
# Begin /etc/fstab
# file system mount-point type options dump fsck
# order

/dev/sda5 /          ext4 defaults 1 1
/dev/sda3 /boot/     ext2 defaults 1 2
/dev/sda1 /boot/efi  vfat defaults 0 2
/dev/sda4 swap       swap pri=1    0 0

# End /etc/fstab
EOF


