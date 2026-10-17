#!/bin/bash

set +m
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "This script should run in chroot environment."
read -r -p "Are you in chroot environment? [yes/NO] " answer
[[ "$answer" == "yes" ]] || exit 1


/bin/bash $SCRIPT_DIR/create-dirs-files.sh

SRC=/sources
BASE=/sources

cd $BASE

###############################
# Gettext
###############################
tar xvf $SRC/gettext-1.0.tar.xz
cd gettext-1.0

./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd $BASE
rm -rf gettext-1.0

###############################
# Bison
###############################
tar xvf $SRC/bison-3.8.2.tar.xz
cd bison-3.8.2

./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make && make install

cd $BASE
rm -rf bison-3.8.2

###############################
# Perl
###############################
tar xvf $SRC/perl-5.44.0.tar.xz
cd perl-5.44.0

sh Configure -des \
             -D prefix=/usr \
             -D vendorprefix=/usr \
             -D useshrplib \
             -D privlib=/usr/lib/perl5/5.44/core_perl \
             -D archlib=/usr/lib/perl5/5.44/core_perl \
             -D sitelib=/usr/lib/perl5/5.44/site_perl \
             -D sitearch=/usr/lib/perl5/5.44/site_perl \
             -D vendorlib=/usr/lib/perl5/5.44/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.44/vendor_perl

make && make install

cd $BASE
rm -rf perl-5.44.0

###############################
# Zlib
###############################
tar xvf $SRC/zlib-1.3.2.tar.gz
cd zlib-1.3.2

./configure --prefix=/usr

make && make install

rm -fv /usr/lib/libz.a

cd $BASE
rm -rf zlib-1.3.2

###############################
# mpdecimal
###############################
tar xvf $SRC/mpdecimal-4.0.1.tar.gz
cd mpdecimal-4.0.1

./configure --prefix=/usr \
            --disable-static \
            --docdir=/usr/share/doc/mpdecimal-4.0.1

make && make install

cd $BASE
rm -rf mpdecimal-4.0.1

###############################
# Python
###############################
tar xvf $SRC/Python-3.14.7.tar.xz
cd Python-3.14.7

./configure --prefix=/usr \
            --enable-shared \
            --without-ensurepip \
            --without-static-libpython

make && make install

cd $BASE
rm -rf Python-3.14.7

###############################
# Texinfo
###############################
tar xvf $SRC/texinfo-7.3.tar.xz
cd texinfo-7.3

./configure --prefix=/usr

make && make install

cd $BASE
rm -rf texinfo-7.3

###############################
# Util-linux
###############################
tar xvf $SRC/util-linux-2.42.2.tar.xz
cd util-linux-2.42.2

./configure --libdir=/usr/lib \
            --runstatedir=/run \
            --disable-chfn-chsh \
            --disable-login \
            --disable-nologin \
            --disable-su \
            --disable-setpriv \
            --disable-runuser \
            --disable-pylibmount \
            --disable-static \
            --disable-liblastlog2 \
            --without-python \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.42.2

make && make install

cd $BASE
rm -rf util-linux-2.42.2

###############################
# Cleaning
###############################

rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools

