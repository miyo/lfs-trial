#!/bin/bash

set +m
set -e

: "${LFS:?LFS environment variable is not set}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/environments.sh"

SRC="$LFS/sources/"
BASE="$LFS/sources/"

cd $BASE

###############################
# binutils
###############################
tar xvf $SRC/binutils-2.47.tar.xz
cd binutils-2.47
mkdir -v build
cd build

../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT \
             --disable-nls \
             --enable-gprofng=no \
             --disable-werror \
             --enable-new-dtags \
             --enable-default-hash-style=gnu
make && make install
cd $BASE
rm -rf binutils-2.47

###############################
# gcc
###############################
tar xvf $SRC/gcc-16.2.0.tar.xz
cd gcc-16.2.0
tar xvf $SRC/mpfr-4.2.2.tar.xz
mv -v mpfr-4.2.2 mpfr
tar xvf $SRC/gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar xvf $SRC/mpc-1.4.1.tar.xz
mv -v mpc-1.4.1 mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

mkdir -v build
cd build

../configure \
    --target=$LFS_TGT \
    --prefix=$LFS/tools \
    --with-glibc-version=2.44 \
    --with-sysroot=$LFS \
    --with-newlib \
    --without-headers \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-fixincludes \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++

make && make install

cat ../gcc/{limitx,glimits,limity}.h > \
  $($LFS_TGT-gcc -print-file-name=include)/limits.h

cd $BASE
rm -rf gcc-16.2.0

###############################
# Linux-7.1.8 API headers
###############################
tar xvf linux-7.1.8.tar.xz
cd linux-7.1.8

make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

cd $BASE
rm -rf linux-7.1.8

###############################
# Glibc
###############################
tar xvf $SRC/glibc-2.44.tar.xz
cd glibc-2.44

case $(uname -m) in
  i?86) ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
  ;;
  x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
  ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
  ;;
esac

patch -Np1 -i $SRC/glibc-fhs-1.patch
patch -Np1 -i $SRC/glibc-2.44-upstream_fixes-1.patch

mkdir -v build
cd build

echo "rootsbindir=/usr/sbin" > configparms

../configure \
      --prefix=/usr \
      --host=$LFS_TGT \
      --build=$(../scripts/config.guess) \
      --disable-nscd \
      libc_cv_slibdir=/usr/lib \
      --enable-kernel=5.10

make && make DESTDIR=$LFS install

sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

cd $BASE
rm -rf glibc-2.44

###############################
# GCC
###############################
tar xvf $SRC/gcc-16.2.0.tar.xz
cd gcc-16.2.0

mkdir -v build
cd build

../libstdc++-v3/configure \
      --host=$LFS_TGT \
      --build=$(../config.guess) \
      CXX=$LFS_TGT-gcc \
      --prefix=/usr \
      --disable-multilib \
      --disable-nls \
      --disable-libstdcxx-pch \
      --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/16.2.0

make && make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

cd $BASE
rm -rf gcc-16.2.0

