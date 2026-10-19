#!/bin/bash

set +m
set -e
set -x

SRC=/sources
BASE=/sources
MY_TIMEZONE=Asia/Tokyo

cd $BASE

###############################
# Create a user for test
###############################
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester


###############################
# Man-pages
###############################
tar xvf $SRC/man-pages-6.18.tar.xz
pushd man-pages-6.18

rm -fv man3/crypt*
make -R GIT=false prefix=/usr install

popd
rm -rf man-pages-6.18

###############################
# Iana-Etc
###############################
tar xvf $SRC/iana-etc-20260805.tar.gz
pushd iana-etc-20260805

cp -v services protocols /etc

popd
rm -rf iana-etc-20260805

###############################
# Glibc
###############################
tar xvf $SRC/glibc-2.44.tar.xz
pushd glibc-2.44

patch -Np1 -i $SRC/glibc-fhs-1.patch
patch -Np1 -i $SRC/glibc-2.44-upstream_fixes-1.patch

mkdir -v build
cd build

../configure --prefix=/usr \
             --disable-werror \
             --disable-nscd \
             libc_cv_slibdir=/usr/lib \
             --enable-stack-protector=strong \
             --enable-kernel=5.10

make

make check || true # skip for some error

touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

make install

sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf</literal>
EOF

tar -xf $SRC/tzdata2026c.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz

# tzselect
ln -sfv /usr/share/zoneinfo/$MY_TIMEZONE /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib
EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf
EOF
mkdir -pv /etc/ld.so.conf.d

popd
rm -rf glibc-2.44

###############################
# Zlib
###############################
tar xvf $SRC/zlib-1.3.2.tar.gz
pushd zlib-1.3.2

./configure --prefix=/usr

make
make check
make install

rm -fv /usr/lib/libz.a

popd
rm -rf zlib-1.3.2

###############################
# Bzip2
###############################
tar xvf $SRC/bzip2-1.0.8.tar.gz
pushd bzip2-1.0.8

patch -Np1 -i $SRC/bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so
make clean

make
make PREFIX=/usr install

cp -av libbz2.so.* /usr/lib
ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so

ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so.1
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
    ln -sfv bzip2 $i
done

rm -fv /usr/lib/libbz2.a

popd
rm -rf bzip2-1.0.8

###############################
# Xz
###############################
tar xvf $SRC/xz-5.8.3.tar.xz
pushd xz-5.8.3

./configure --prefix=/usr \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.8.3

make
make check
make install

popd
rm -rf xz-5.8.3

###############################
# Lz4
###############################
tar xvf $SRC/lz4-1.10.0.tar.gz
pushd lz4-1.10.0

make BUILD_STATIC=no PREFIX=/usr
make -j1 check
make BUILD_STATIC=no PREFIX=/usr install

popd
rm -rf lz4-1.10.0

###############################
# Zstd
###############################
tar xvf $SRC/zstd-1.5.7.tar.gz
pushd zstd-1.5.7

make prefix=/usr
make check
make prefix=/usr install
rm -v /usr/lib/libzstd.a

popd
rm -rf zstd-1.5.7

###############################
# File
###############################
tar xvf $SRC/file-5.48.tar.gz
pushd file-5.48

./configure --prefix=/usr
make
make check
make install

popd
rm -rf file-5.48

###############################
# Readline
###############################
tar xvf $SRC/readline-8.3.tar.gz
pushd readline-8.3

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

sed -e '270a\
     else\
       chars_avail = 1;' \
    -e '288i\ result = -1;' \
    -i.orig input.c

./configure --prefix=/usr \
            --disable-static \
            --with-curses \
            --docdir=/usr/share/doc/readline-8.3

make SHLIB_LIBS="-lncursesw"
make install

install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.3

popd
rm -rf readline-8.3

###############################
# Pcre2
###############################
tar xvf $SRC/pcre2-10.47.tar.bz2
pushd pcre2-10.47

./configure --prefix=/usr \
--docdir=/usr/share/doc/pcre2-10.47 \
--enable-unicode \
--enable-jit \
--enable-pcre2-16 \
--enable-pcre2-32 \
--enable-pcre2grep-libz \
--enable-pcre2grep-libbz2 \
--enable-pcre2test-libreadline \
--disable-static

make
make check
make install

popd
rm -rf pcre2-10.47

###############################
# M4
###############################
tar xvf $SRC/m4-1.4.21.tar.xz
pushd m4-1.4.21

./configure --prefix=/usr
make
make check
make install

popd
rm -rf m4-1.4.21

###############################
# Bc
###############################
tar xvf $SRC/bc-7.0.3.tar.xz
pushd bc-7.0.3

CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r
make
make test
make install

popd
rm -rf bc-7.0.3

###############################
# Flex
###############################
tar xvf $SRC/flex-2.6.4.tar.gz
pushd flex-2.6.4

./configure --prefix=/usr \
--disable-static \
--docdir=/usr/share/doc/flex-2.6.4

make
make check
make install

ln -sv flex /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1

popd
rm -rf flex-2.6.4

###############################
# Tcl
###############################
tar xvf $SRC/tcl8.6.18-src.tar.gz
pushd tcl8.6.18

SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr \
            --mandir=/usr/share/man \
            --disable-rpath

make
sed -e "s|$SRCDIR/unix|/usr/lib|" \
-e "s|$SRCDIR|/usr/include|" \
-i tclConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.13|/usr/lib/tdbc1.1.13|" \
-e "s|$SRCDIR/pkgs/tdbc1.1.13/generic|/usr/include|" \
-e "s|$SRCDIR/pkgs/tdbc1.1.13/library|/usr/lib/tcl8.6|" \
-e "s|$SRCDIR/pkgs/tdbc1.1.13|/usr/include|" \
-i pkgs/tdbc1.1.13/tdbcConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.7|/usr/lib/itcl4.3.7|" \
-e "s|$SRCDIR/pkgs/itcl4.3.7/generic|/usr/include|" \
-e "s|$SRCDIR/pkgs/itcl4.3.7|/usr/include|" \
-i pkgs/itcl4.3.7/itclConfig.sh
unset SRCDIR

LC_ALL=C.UTF-8 make test

make install
chmod 644 /usr/lib/libtclstub8.6.a

chmod -v u+w /usr/lib/libtcl8.6.so

make install-private-headers

ln -sfv tclsh8.6 /usr/bin/tclsh

mv -v /usr/share/man/man3/{Thread,Tcl_Thread}.3

cd ..
tar -xf $SRC/tcl8.6.18-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.18
cp -v -r ./html/* /usr/share/doc/tcl-8.6.18

popd
rm -rf tcl8.6.18

###############################
# Expect
###############################
tar xvf $SRC/expect5.45.4.tar.gz
pushd expect5.45.4

python3 -c 'from pty import spawn; spawn(["echo", "ok"])'

patch -Np1 -i $SRC/expect-5.45.4-gcc15-1.patch

./configure --prefix=/usr \
            --with-tcl=/usr/lib \
            --enable-shared \
            --disable-rpath \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

make
make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib

popd
rm -rf expect5.45.4

###############################
# DejaGNU
###############################
tar xvf $SRC/dejagnu-1.6.3.tar.gz
pushd dejagnu-1.6.3

mkdir -v build
cd build

../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext -o doc/dejagnu.txt ../doc/dejagnu.texi

make check

make install
install -v -dm755 /usr/share/doc/dejagnu-1.6.3
install -v -m644 doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

popd
rm -rf dejagnu-1.6.3

###############################
# Ninja
###############################
tar xvf $SRC/ninja-1.13.2.tar.gz
pushd ninja-1.13.2

export NINJAJOBS=4

sed -i '/int Guess/a \
int j = 0;\
char* jobs = getenv( "NINJAJOBS" );\
if ( jobs != NULL ) j = atoi( jobs );\
if ( j > 0 ) return j;\
' src/ninja.cc

python3 configure.py --bootstrap --verbose

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja

popd
rm -rf ninja-1.13.2

###############################
# Pkgconf
###############################
tar xvf $SRC/pkgconf-3.0.5.tar.xz
pushd pkgconf-3.0.5

tar -xf ../meson-1.12.0.tar.gz

mkdir -v build
cd build

python3 ../meson-1.12.0/meson.py setup --prefix=/usr --buildtype=release ..

ninja
ninja test

ninja install
mv /usr/share/doc/pkgconf{,-3.0.5}

ln -sv pkgconf /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

popd
rm -rf pkgconf-3.0.5

###############################
# Binutils
###############################
tar xvf $SRC/binutils-2.47.tar.xz
pushd binutils-2.47

mkdir -v build
cd build

../configure --prefix=/usr \
             --sysconfdir=/etc \
             --enable-ld=default \
             --enable-plugins \
             --enable-shared \
             --disable-werror \
             --enable-64-bit-bfd \
             --enable-new-dtags \
             --with-system-zlib \
             --with-lib-path=/usr/lib \
             --enable-default-hash-style=gnu

make tooldir=/usr

make -k check || true # skip for some error
grep '^FAIL:' $(find -name '*.log')

make tooldir=/usr install

rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
   /usr/share/doc/gprofng/

popd
rm -rf binutils-2.47

###############################
# GMP
###############################
tar xvf $SRC/gmp-6.3.0.tar.xz
pushd gmp-6.3.0

sed -i '/long long t1;/,+1s/()/(...)/' configure

./configure --prefix=/usr \
            --enable-cxx \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0

make
make html
make check
cat $(find -name '*.log') | grep -c ^PASS

make install
make install-html

popd
rm -rf gmp-6.3.0

###############################
# MPFR
###############################
tar xvf $SRC/mpfr-4.2.2.tar.xz
pushd mpfr-4.2.2

./configure --prefix=/usr \
            --disable-static \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.2

make
make html

make check

make install
make install-html

popd
rm -rf mpfr-4.2.2

###############################
# MPC
###############################
tar xvf $SRC/mpc-1.4.1.tar.xz
pushd mpc-1.4.1

./configure --prefix=/usr \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.4.1

make
make html

make check

make install
make install-html

popd
rm -rf mpc-1.4.1

###############################
# Attr
###############################
tar xvf $SRC/attr-2.6.0.tar.gz
pushd attr-2.6.0

./configure --prefix=/usr \
            --disable-static \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.6.0

make
make check
make install

popd
rm -rf attr-2.6.0

###############################
# Acl
###############################
tar xvf $SRC/acl-2.4.0.tar.xz
pushd acl-2.4.0

./configure --prefix=/usr \
            --disable-static \
            --docdir=/usr/share/doc/acl-2.4.0

make
make check || true # skip for some errors
make install

popd
rm -rf acl-2.4.0

###############################
# Libcap
###############################
tar xvf $SRC/libcap-2.78.tar.xz
pushd libcap-2.78

sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make test
make prefix=/usr lib=lib install

popd
rm -rf libcap-2.78

###############################
# Libxcrypt
###############################
tar xvf $SRC/libxcrypt-4.5.2.tar.xz
pushd libxcrypt-4.5.2

sed -i '/strchr/s/const//' lib/crypt-{sm3,gost}-yescrypt.c

./configure --prefix=/usr \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no \
            --disable-static \
            --disable-failure-tokens

make
make check
make install

popd
rm -rf libxcrypt-4.5.2

###############################
# Shadow
###############################
tar xvf $SRC/shadow-4.20.2.tar.xz
pushd shadow-4.20.2

find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;

sed -e 's:#ENCRYPT_METHOD SHA512:ENCRYPT_METHOD YESCRYPT:' \
-e 's:/var/spool/mail:/var/mail:' \
-e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
    -i etc/login.defs

touch /usr/bin/passwd

./configure --sysconfdir=/etc \
            --disable-static \
            --with-{b,yes}crypt \
            --without-libbsd \
            --disable-logind \
            --with-group-name-max-length=32

make
make exec_prefix=/usr install
make -C man install-man

pwconv
grpconv

mkdir -p /etc/default
useradd -D --gid 999

sed -i '/MAIL/s/yes/no/' /etc/default/useradd

touch /etc/sub{u,g}id

# passwd root

popd
rm -rf shadow-4.20.2

###############################
# Gawk
###############################
tar xvf $SRC/gawk-5.4.1.tar.xz
pushd gawk-5.4.1

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr

make

chown -R tester .
su tester -c "PATH=$PATH make check"

rm -f /usr/bin/gawk-5.4.1
make install

ln -sv gawk.1 /usr/share/man/man1/awk.1

install -vDm644 doc/{awkforai.txt,*.{eps,pdf,jpg}} -t /usr/share/doc/gawk-5.4.1

popd
rm -rf gawk-5.4.1

###############################
# GCC
###############################
tar xvf $SRC/gcc-16.2.0.tar.xz
pushd gcc-16.2.0

case $(uname -m) in
x86_64)
sed -e '/m64=/s/lib64/lib/' \
-i.orig gcc/config/i386/t-linux64
;;
esac

mkdir -v build
cd build

../configure --prefix=/usr \
             LD=ld \
             --enable-languages=c,c++ \
             --enable-default-pie \
             --enable-default-ssp \
             --enable-host-pie \
             --enable-targets=all \
             --disable-multilib \
             --disable-bootstrap \
             --disable-fixincludes \
             --with-system-zlib

make

ulimit -s -H unlimited

chown -R tester .
su tester -c "PATH=$PATH make -k check"

../contrib/test_summary -t

make install

chown -v -R root:root $(gcc -print-file-name=include){,-fixed}

ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfvr $(gcc -print-prog-name=liblto_plugin.so) /usr/lib/bfd-plugins/

echo 'int main(){}' | cc -x c - -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v a.out dummy.log

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

popd
rm -rf gcc-16.2.0

###############################
# Ncurses
###############################
tar xvf $SRC/ncurses-6.6.tar.gz
pushd ncurses-6.6

./configure --prefix=/usr \
            --mandir=/usr/share/man \
            --with-shared \
            --without-debug \
            --without-normal \
            --with-cxx-shared \
            --enable-pc-files \
            --with-pkg-config-libdir=/usr/lib/pkgconfig

make

make DESTDIR=$PWD/dest install

sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h

cp --remove-destination -av dest/* /

for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncursesw.so /usr/lib/libcurses.so

cp -v -R doc -T /usr/share/doc/ncurses-6.6

popd
rm -rf ncurses-6.6

###############################
# Sed
###############################
tar xvf $SRC/sed-4.10.tar.xz
pushd sed-4.10

./configure --prefix=/usr

make
make html

chown -R tester .
su tester -c "PATH=$PATH make check"

make install
install -vDm644 doc/sed.html -t /usr/share/doc/sed-4.10

popd
rm -rf sed-4.10

###############################
# Psmisc
###############################
tar xvf $SRC/psmisc-23.7.tar.xz
pushd psmisc-23.7

./configure --prefix=/usr
make
make check
make install

popd
rm -rf psmisc-23.7

###############################
# Gettext
###############################
tar xvf $SRC/gettext-1.0.tar.xz
pushd gettext-1.0

./configure --prefix=/usr \
            --disable-static \
            --docdir=/usr/share/doc/gettext-1.0

make
make check
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so

popd
rm -rf gettext-1.0

###############################
# Bison
###############################
tar xvf $SRC/bison-3.8.2.tar.xz
pushd bison-3.8.2

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
make check
make install

popd
rm -rf bison-3.8.2

###############################
# Grep
###############################
tar xvf $SRC/grep-3.12.tar.xz
pushd grep-3.12

sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr
make
make check
make install

popd
rm -rf grep-3.12

###############################
# Bash
###############################
tar xvf $SRC/bash-5.3.tar.gz
pushd bash-5.3

./configure --prefix=/usr \
--without-bash-malloc \
--with-installed-readline \
--docdir=/usr/share/doc/bash-5.3

make

chown -R tester .

LC_ALL=C.UTF-8 su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

make install

# exec /usr/bin/bash --login

popd
rm -rf bash-5.3

###############################
# Libtool
###############################
tar xvf $SRC/libtool-2.6.2.tar.xz
pushd libtool-2.6.2

./configure --prefix=/usr

make
make check
make install

rm -fv /usr/lib/libltdl.a

popd
rm -rf libtool-2.6.2

###############################
# GDBM
###############################
tar xvf $SRC/gdbm-1.26.tar.gz
pushd gdbm-1.26

./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat

make
make check
make install

popd
rm -rf gdbm-1.26

###############################
# Gperf
###############################
tar xvf $SRC/gperf-3.3.tar.gz
pushd gperf-3.3

./configure --prefix=/usr \
            --docdir=/usr/share/doc/gperf-3.3

make
make check
make install

popd
rm -rf gperf-3.3

###############################
# Expat
###############################
tar xvf $SRC/expat-2.8.3.tar.xz
pushd expat-2.8.3

./configure --prefix=/usr \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.8.3

make
make check
make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.8.3

popd
rm -rf expat-2.8.3

###############################
# Inetutils
###############################
tar xvf $SRC/inetutils-2.8.tar.gz
pushd inetutils-2.8

sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c

./configure --prefix=/usr \
            --bindir=/usr/bin \
            --localstatedir=/var \
            --disable-logger \
            --disable-whois \
            --disable-rcp \
            --disable-rexec \
            --disable-rlogin \
            --disable-rsh \
            --disable-servers

make
make check
make install

mv -v /usr/{,s}bin/ifconfig

popd
rm -rf inetutils-2.8

###############################
# Less
###############################
tar xvf $SRC/less-704.tar.gz
pushd less-704

./configure --prefix=/usr --sysconfdir=/etc
make
make check
make install

popd
rm -rf less-704

###############################
# Perl
###############################
tar xvf $SRC/perl-5.44.0.tar.xz
pushd perl-5.44.0

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des \
             -D prefix=/usr \
             -D vendorprefix=/usr \
             -D privlib=/usr/lib/perl5/5.44/core_perl \
             -D archlib=/usr/lib/perl5/5.44/core_perl \
             -D sitelib=/usr/lib/perl5/5.44/site_perl \
             -D sitearch=/usr/lib/perl5/5.44/site_perl \
             -D vendorlib=/usr/lib/perl5/5.44/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.44/vendor_perl \
             -D man1dir=/usr/share/man/man1 \
             -D man3dir=/usr/share/man/man3 \
             -D pager="/usr/bin/less -isR" \
             -D useshrplib \
             -D usethreads

make
TEST_JOBS=$(nproc) make test_harness || true # skip for some erorrs
make install
unset BUILD_ZLIB BUILD_BZIP2

popd
rm -rf perl-5.44.0

###############################
# Autoconf
###############################
tar xvf $SRC/autoconf-2.73.tar.xz
pushd autoconf-2.73

./configure --prefix=/usr

make
make check
make install

popd
rm -rf autoconf-2.73

###############################
# Automake
###############################
tar xvf $SRC/automake-1.18.1.tar.xz
pushd automake-1.18.1

./configure --prefix=/usr \
	    --docdir=/usr/share/doc/automake-1.18.1

make
make -j$(($(nproc)>4?$(nproc):4)) check
make install

popd
rm -rf automake-1.18.1

###############################
# OpenSSL
###############################
tar xvf $SRC/openssl-4.0.1.tar.gz
pushd openssl-4.0.1

./config --prefix=/usr \
         --openssldir=/etc/ssl \
         --libdir=lib \
                  shared \
                  zlib-dynamic
make
make test

make INSTALL_LIBS= MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-4.0.1
cp -vfr doc/* /usr/share/doc/openssl-4.0.1

popd
rm -rf openssl-4.0.1

###############################
# Libelf (from Elfutils)
###############################
tar xvf $SRC/elfutils-0.195.tar.bz2
pushd elfutils-0.195

./configure --prefix=/usr \
            --disable-debuginfod \
            --enable-libdebuginfod=dummy

make -C lib
make -C libelf
make -k check
make -C libelf install

install -vm644 config/libelf.pc /usr/lib/pkgconfig

rm /usr/lib/libelf.a

popd
rm -rf elfutils-0.195

###############################
# Libffi
###############################
tar xvf $SRC/libffi-3.8.0.tar.gz
pushd libffi-3.8.0

./configure --prefix=/usr \
            --disable-static \
            --with-gcc-arch=native

make
make check
make install

popd
rm -rf libffi-3.8.0

###############################
# Sqlite
###############################
tar xvf $SRC/sqlite-autoconf-3530400.tar.gz
pushd sqlite-autoconf-3530400

python3 -m zipfile -e $SRC/sqlite-doc-3530400.zip .
./configure --prefix=/usr \
            --disable-static \
            --enable-fts{4,5} \
            CPPFLAGS="-D SQLITE_ENABLE_COLUMN_METADATA=1 \
                      -D SQLITE_ENABLE_UNLOCK_NOTIFY=1 \
                      -D SQLITE_ENABLE_DBSTAT_VTAB=1 \
                      -D SQLITE_SECURE_DELETE=1"

make LDFLAGS.rpath=""
make install

cp -v -R sqlite-doc-3530400 -T /usr/share/doc/sqlite-3.53.4

popd
rm -rf sqlite-autoconf-3530400

###############################
# mpdecimal
###############################
tar xvf $SRC/mpdecimal-4.0.1.tar.gz
pushd mpdecimal-4.0.1

./configure --prefix=/usr \
            --disable-static \
            --docdir=/usr/share/doc/mpdecimal-4.0.1

make
make check_local
make install

popd
rm -rf mpdecimal-4.0.1

###############################
# Python
###############################
tar xvf $SRC/Python-3.14.7.tar.xz
pushd Python-3.14.7

patch -Np1 -i $SRC/Python-3.14.7-openssl_4-1.patch

./configure --prefix=/usr \
            --enable-shared \
            --with-system-expat \
            --enable-optimizations \
            --without-static-libpython

make
make test TESTOPTS="--timeout 120" || true # skip for some errors
make install

cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

install -v -dm755 /usr/share/doc/python-3.14.7/html

tar --strip-components=1 \
    --no-same-owner \
    --no-same-permissions \
    -C /usr/share/doc/python-3.14.7/html \
    -xvf $SRC/python-3.14.7-docs-html.tar.bz2

popd
rm -rf Python-3.14.7

###############################
# Flit-Core
###############################
tar xvf $SRC/flit_core-4.0.2.tar.gz
pushd flit_core-4.0.2

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist flit_core

popd
rm -rf flit_core-4.0.2

###############################
# Packaging
###############################
tar xvf $SRC/packaging-26.3.tar.gz
pushd packaging-26.3

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist packaging

popd
rm -rf packaging-26.3

###############################
# Wheel
###############################
tar xvf $SRC/wheel-0.48.0.tar.gz
pushd wheel-0.48.0

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist wheel

popd
rm -rf wheel-0.48.0

###############################
# Setuptools
###############################
tar xvf $SRC/setuptools-84.0.0.tar.gz
pushd setuptools-84.0.0

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools

popd
rm -rf setuptools-84.0.0

###############################
# Meson
###############################
tar xvf $SRC/meson-1.12.0.tar.gz
pushd meson-1.12.0

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson

install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

popd
rm -rf meson-1.12.0

###############################
# Kmod
###############################
tar xvf $SRC/kmod-34.2.tar.xz
pushd kmod-34.2

mkdir -v build
cd build

meson setup --prefix=/usr .. \
            --buildtype=release \
            -D manpages=false

ninja
ninja install

popd
rm -rf kmod-34.2

###############################
# Coreutils
###############################
tar xvf $SRC/coreutils-9.11.tar.xz
pushd coreutils-9.11

patch -Np1 -i $SRC/coreutils-9.11-i18n-1.patch

autoreconf -fv
automake -af
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr

make
make NON_ROOT_USERNAME=tester check-root

groupadd -g 102 dummy -U tester
chown -R tester .
su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" \
   < /dev/null
groupdel dummy

make install

mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

popd
rm -rf coreutils-9.11

###############################
# Diffutils
###############################
tar xvf $SRC/diffutils-3.12.tar.xz
pushd diffutils-3.12

./configure --prefix=/usr

make
make check
make install

popd
rm -rf diffutils-3.12

###############################
# Findutils
###############################
tar xvf $SRC/findutils-4.11.0.tar.xz
pushd findutils-4.11.0

./configure --prefix=/usr \
            --localstatedir=/var/lib/locate

make

chown -R tester .
su tester -c "PATH=$PATH make check -k" || true # skip for some errors

make install

popd
rm -rf findutils-4.11.0

###############################
# Groff
###############################
tar xvf $SRC/groff-1.24.1.tar.gz
pushd groff-1.24.1

PAGE=A4 ./configure --prefix=/usr

make -j1
make check || true # skip for some errors
make install

popd
rm -rf groff-1.24.1

###############################
# GRUB
###############################
tar xvf $SRC/grub-2.14.tar.xz
pushd grub-2.14

# Installation of GRUB for 64-bit UEFI

./configure --prefix=/usr \
            --sysconfdir=/etc \
            --target=x86_64 \
            --with-platform=efi \
            --disable-efiemu \
            --disable-werror

make
make install

popd
rm -rf grub-2.14

###############################
# Gzip
###############################
tar xvf $SRC/gzip-1.14.tar.xz
pushd gzip-1.14

./configure --prefix=/usr

make
make check
make install

popd
rm -rf gzip-1.14

###############################
# IPRoute2
###############################
tar xvf $SRC/iproute2-7.1.0.tar.xz
pushd iproute2-7.1.0

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install

install -vDm644 COPYING README* -t /usr/share/doc/iproute2-7.1.0

popd
rm -rf iproute2-7.1.0

###############################
# Kbd
###############################
tar xvf $SRC/kbd-2.10.0.tar.xz
pushd kbd-2.10.0

patch -Np1 -i $SRC/kbd-2.10.0-backspace-1.patch

sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

./configure --prefix=/usr --disable-vlock

make
make check
make install

cp -R -v docs/doc -T /usr/share/doc/kbd-2.10.0

popd
rm -rf kbd-2.10.0

###############################
# Libpipeline
###############################
tar xvf $SRC/libpipeline-1.5.8.tar.gz
pushd libpipeline-1.5.8

./configure --prefix=/usr

make
make install

popd
rm -rf libpipeline-1.5.8

###############################
# Make
###############################
tar xvf $SRC/make-4.4.1.tar.gz
pushd make-4.4.1

./configure --prefix=/usr

make
chown -R tester .
su tester -c "PATH=$PATH make check"
make install

popd
rm -rf make-4.4.1

###############################
# Patch
###############################
tar xvf $SRC/patch-2.8.tar.xz
pushd patch-2.8

./configure --prefix=/usr

make
make check
make install

popd
rm -rf patch-2.8

###############################
# Tar
###############################
tar xvf $SRC/tar-1.35.tar.xz
pushd tar-1.35

patch -Np1 -i $SRC/tar-1.35-acl_fix-1.patch

FORCE_UNSAFE_CONFIGURE=1 \
./configure --prefix=/usr

make
make check || true # skip for some errors
make install

make -C doc install-html docdir=/usr/share/doc/tar-1.35

popd
rm -rf tar-1.35

###############################
# Texinfo
###############################
tar xvf $SRC/texinfo-7.3.tar.xz
pushd texinfo-7.3

./configure --prefix=/usr

make
make check
make install

make TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info
    rm -v dir
    for f in *
        do install-info $f dir 2>/dev/null
    done
popd

popd
rm -rf texinfo-7.3

###############################
# Vim
###############################
tar xvf $SRC/vim-9.2.1025.tar.gz
pushd vim-9.2.1025

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr

make

chown -R tester .
sed '/test_plugin_glvs/d' -i src/testdir/Make_all.mak

su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" \
    &> vim-test.log || true # skip for some errors

make install

ln -sv vim /usr/bin/vi

for L in /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

ln -sv ../vim/vim92/doc /usr/share/doc/vim-9.2.1025

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc
" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1
set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
set background=dark
endif
" End /etc/vimrc
EOF

# vim -c ':options'

popd
rm -rf vim-9.2.1025

###############################
# MarkupSafe
###############################
tar xvf $SRC/markupsafe-3.0.3.tar.gz
pushd markupsafe-3.0.3

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Markupsafe

popd
rm -rf markupsafe-3.0.3

###############################
# Jinja2
###############################
tar xvf $SRC/jinja2-3.1.6.tar.gz
pushd jinja2-3.1.6

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Jinja2

popd
rm -rf jinja2-3.1.6

###############################
# Systemd
###############################
tar xvf $SRC/systemd-261.2.tar.gz
pushd systemd-261.2

sed -e 's/GROUP="render"/GROUP="video"/' \
    -e 's/GROUP="sgx", //' \
    -i rules.d/50-udev-default.rules.in

mkdir -v build
cd build

meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      -D default-dnssec=no \
      -D firstboot=false \
      -D install-tests=false \
      -D ldconfig=false \
      -D sysusers=false \
      -D rpmmacrosdir=no \
      -D homed=disabled \
      -D man=disabled \
      -D mode=release \
      -D pamconfdir=no \
      -D dev-kvm-mode=0660 \
      -D nobody-group=nogroup \
      -D sysupdate=disabled \
      -D ukify=disabled \
      -D docdir=/usr/share/doc/systemd-261.2

ninja

echo 'NAME="Linux From Scratch"' > /etc/os-release
unshare -m ninja test || true # skip for some errors

ninja install

tar -xf $SRC/systemd-man-pages-261.2.tar.xz \
    --no-same-owner --strip-components=1 \
    -C /usr/share/man

systemd-machine-id-setup

systemctl preset-all

popd
rm -rf systemd-261.2

###############################
# D-Bus
###############################
tar xvf $SRC/dbus-1.16.2.tar.xz
pushd dbus-1.16.2

mkdir -v build
cd build

meson setup \
      --prefix=/usr \
      --buildtype=release \
      --wrap-mode=nofallback ..

ninja
ninja test
ninja install

ln -sfv /etc/machine-id /var/lib/dbus

popd
rm -rf dbus-1.16.2

###############################
# Man-DB
###############################
tar xvf $SRC/man-db-2.13.1.tar.xz
pushd man-db-2.13.1

./configure --prefix=/usr \
            --docdir=/usr/share/doc/man-db-2.13.1 \
            --sysconfdir=/etc \
            --disable-setuid \
            --enable-cache-owner=bin \
            --with-browser=/usr/bin/lynx \
            --with-vgrind=/usr/bin/vgrind \
            --with-grap=/usr/bin/grap

make
make check
make install

popd
rm -rf man-db-2.13.1

###############################
# Procps-ng
###############################
tar xvf $SRC/procps-ng-4.0.7.tar.xz
pushd procps-ng-4.0.7

./configure --prefix=/usr \
            --docdir=/usr/share/doc/procps-ng-4.0.7 \
            --disable-static \
            --disable-kill \
            --enable-watch8bit \
            --with-systemd

make

chown -R tester .
su tester -c "PATH=$PATH make check"

make install

popd
rm -rf procps-ng-4.0.7

###############################
# Util-linux
###############################
tar xvf $SRC/util-linux-2.42.2.tar.xz
pushd util-linux-2.42.2

./configure --bindir=/usr/bin \
            --libdir=/usr/lib \
            --runstatedir=/run \
            --sbindir=/usr/sbin \
            --disable-chfn-chsh \
            --disable-login \
            --disable-nologin \
            --disable-su \
            --disable-setpriv \
            --disable-runuser \
            --disable-pylibmount \
            --disable-liblastlog2 \
            --disable-static \
            --without-python \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.42.2

make

touch /etc/fstab
chown -R tester .
su tester -c "make -k check"
make install

popd
rm -rf util-linux-2.42.2

###############################
# E2fsprogs
###############################
tar xvf $SRC/e2fsprogs-1.47.4.tar.gz
pushd e2fsprogs-1.47.4

mkdir -v build
cd build

../configure --prefix=/usr \
             --sysconfdir=/etc \
             --enable-elf-shlibs \
             --disable-libblkid \
             --disable-libuuid \
             --disable-uuidd \
             --disable-fsck

make
make check || true # skip for some errors
make install

rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo

install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf

popd
rm -rf e2fsprogs-1.47.4

###############################
# Stripping
###############################

save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.36
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug --compress-debug-sections=zstd $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.47.20260726.so
               libsframe.so.3.0.0
               libhistory.so.8.3
               libncursesw.so.6.6
               libm.so.6
               libreadline.so.8.3
               libz.so.1.3.2
               libzstd.so.1.5.7
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
    $(find /usr/lib -type f -name \*.a) \
    $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * )
            if file -b "$i" | grep -Eq 'ELF|ar archive'; then # only ELE or static lib 
                strip --strip-unneeded "$i"
            fi
            ;;
    esac
done

unset BIN LIB save_usrlib online_usrbin online_usrlib

rm -rf /tmp/{*,.*}

###############################
# Cleaning
###############################

find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf

###############################
# Delete a user for test
###############################
userdel -r tester || true # ignore an error for deleting mail spool
