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
# M4
###############################
tar xvf $SRC/m4-1.4.21.tar.xz
cd m4-1.4.21

cat > $LFS/usr/share/config.site << EOF
ac_cv_func_posix_spawn_file_actions_addchdir=yes
ac_cv_func_posix_spawn_file_actions_addfchdir=yes
EOF

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $BASE
rm -rf m4-1.4.21

###############################
# Ncurses
###############################
tar xvf $SRC/ncurses-6.6.tar.gz
cd ncurses-6.6

mkdir build
pushd build
  ../configure --prefix=$LFS/tools AWK=gawk
  make -C include
  make -C progs tic
  install progs/tic $LFS/tools/bin
popd

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(./config.guess) \
            --mandir=/usr/share/man \
            --with-manpage-format=normal \
            --with-shared \
            --without-normal \
            --with-cxx-shared \
            --without-debug \
            --without-ada \
            --disable-stripping \
            AWK=gawk

make && make DESTDIR=$LFS install

ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

cd $BASE
rm -rf ncurses-6.6

###############################
# Bash
###############################
tar xvf $SRC/bash-5.3.tar.gz
cd bash-5.3

./configure --prefix=/usr \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT \
            --without-bash-malloc \
            --docdir=/usr/share/doc/bash-5.3

make && make DESTDIR=$LFS install

ln -sv bash $LFS/bin/sh

cd $BASE
rm -rf bash-5.3

###############################
# Coreutils
###############################
tar xvf $SRC/coreutils-9.11.tar.xz
cd coreutils-9.11

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname

make && make DESTDIR=$LFS install

mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8

cd $BASE
rm -rf coreutils-9.11

###############################
# Diffutils
###############################
tar xvf $SRC/diffutils-3.12.tar.xz
cd diffutils-3.12

./configure --prefix=/usr \
            --host=$LFS_TGT \
            gl_cv_func_strcasecmp_works=yes \
            --build=$(./build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $BASE
rm -rf diffutils-3.12


###############################
# File
###############################
tar xvf $SRC/file-5.48.tar.gz
cd file-5.48

mkdir build
pushd build
  ../configure --disable-bzlib \
               --disable-libseccomp \
               --disable-xzlib \
               --disable-zlib
  make
popd

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la

cd $BASE
rm -rf file-5.48

###############################
# Findutils
###############################
tar xvf $SRC/findutils-4.11.0.tar.xz
cd findutils-4.11.0

./configure --prefix=/usr \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $BASE
rm -rf findutils-4.11.0

###############################
# Gawk
###############################
tar xvf $SRC/gawk-5.4.1.tar.xz
cd gawk-5.4.1

sed -i 's/extras//' Makefile.in
./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $BASE
rm -rf gawk-5.4.1

###############################
# Grep
###############################
tar xvf $SRC/grep-3.12.tar.xz
cd grep-3.12

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $BASE
rm -rf grep-3.12

###############################
# Gzip
###############################
tar xvf $SRC/gzip-1.14.tar.xz
cd gzip-1.14

./configure --prefix=/usr --host=$LFS_TGT

make && make DESTDIR=$LFS install

cd $BASE
rm -rf gzip-1.14

###############################
# Make
###############################
tar xvf $SRC/make-4.4.1.tar.gz
cd make-4.4.1

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $BASE
rm -rf make-4.4.1

###############################
# Patch
###############################
tar xvf $SRC/patch-2.8.tar.xz
cd patch-2.8

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $BASE
rm -rf patch-2.8

###############################
# Sed
###############################
tar xvf $SRC/sed-4.10.tar.xz
cd sed-4.10

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $BASE
rm -rf sed-4.10

###############################
# Tar
###############################
tar xvf $SRC/tar-1.35.tar.xz
cd tar-1.35

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $BASE
rm -rf tar-1.35

###############################
# Xz
###############################
tar xvf $SRC/xz-5.8.3.tar.xz
cd xz-5.8.3

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.8.3

make && make DESTDIR=$LFS install

rm -v $LFS/usr/lib/liblzma.la

cd $BASE
rm -rf xz-5.8.3

###############################
# Binutils - Pass 2
###############################
tar xvf $SRC/binutils-2.47.tar.xz
cd binutils-2.47

sed '6031s/$add_dir//' -i ltmain.sh

mkdir -v build
cd build

../configure \
      --prefix=/usr \
      --build=$(../config.guess) \
      --host=$LFS_TGT \
      --disable-nls \
      --enable-shared \
      --enable-gprofng=no \
      --disable-werror \
      --enable-64-bit-bfd \
      --enable-new-dtags \
      --enable-default-hash-style=gnu

make && make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

cd $BASE
rm -rf binutils-2.47

###############################
# GCC - Pass 2
###############################
tar xvf $SRC/gcc-16.2.0.tar.xz
cd gcc-16.2.0

tar -xf $SRC/mpfr-4.2.2.tar.xz
mv -v mpfr-4.2.2 mpfr
tar -xf $SRC/gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf $SRC/mpc-1.4.1.tar.xz
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
      --build=$(../config.guess) \
      --host=$LFS_TGT \
      --target=$LFS_TGT \
      --prefix=/usr \
      --with-build-sysroot=$LFS \
      --enable-default-pie \
      --enable-default-ssp \
      --disable-fixincludes \
      --disable-nls \
      --disable-multilib \
      --disable-libatomic \
      --disable-libgomp \
      --disable-libquadmath \
      --disable-libsanitizer \
      --disable-libssp \
      --disable-libvtv \
      --enable-languages=c,c++ \
      CXX_FOR_TARGET="$LFS_TGT-gcc -nostdinc++" \
      LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc \
      target_configargs=gcc_cv_target_thread_file=posix

make && make DESTDIR=$LFS install

ln -sv gcc $LFS/usr/bin/cc

cd $BASE
rm -rf gcc-16.2.0
