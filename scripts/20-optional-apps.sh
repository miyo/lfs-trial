#!/bin/bash

set -e

SRC=/sources
BASE=/sources

cd $BASE

#######################
# libtasn
#######################
tar xvf libtasn1-4.21.0.tar.gz
pushd libtasn1-4.21.0

./configure --prefix=/usr --disable-static
make
make install
make -C doc/reference install-data-local

popd
rm -rf libtasn1-4.21.0

#######################
# p11-kit
#######################
tar xvf p11-kit-0.26.5.tar.xz
pushd p11-kit-0.26.5

sed '20,$ d' -i trust/trust-extract-compat

cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF

mkdir p11-build
cd    p11-build

meson setup .. \
      --prefix=/usr \
      --buildtype=release \
      -D trust_paths=/etc/pki/anchors
ninja

ninja install
ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
        /usr/bin/update-ca-certificates

ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

popd
rm -rf p11-kit-0.26.5

#######################
# make-ca
#######################
tar xvf make-ca-1.16.1.tar.gz
pushd make-ca-1.16.1

sed '/mktemp/s/-t //' -i make-ca

make install
install -vdm755 /etc/ssl/local

/usr/sbin/make-ca -g

systemctl enable update-pki.timer

#wget http://www.cacert.org/certs/root.crt
#wget http://www.cacert.org/certs/class3.crt
#openssl x509 -in root.crt -text -fingerprint -setalias "CAcert Class 1 root" \
#        -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
#        > /etc/ssl/local/CAcert_Class_1_root.pem
#openssl x509 -in class3.crt -text -fingerprint -setalias "CAcert Class 3 root" \
#        -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
#        > /etc/ssl/local/CAcert_Class_3_root.pem
#/usr/sbin/make-ca -r
#
#openssl x509 -in /etc/ssl/certs/Makebelieve_CA_Root.pem \
#             -text \
#             -fingerprint \
#             -setalias "Disabled Makebelieve CA Root" \
#             -addreject serverAuth \
#             -addreject emailProtection \
#             -addreject codeSigning \
#       > /etc/ssl/local/Disabled_Makebelieve_CA_Root.pem
#/usr/sbin/make-ca -r

popd
rm -rf make-ca-1.16.1

#######################
# libpsl
#######################
tar xvf libpsl-0.23.3.tar.gz
pushd libpsl-0.23.3

mkdir build
cd    build

meson setup --prefix=/usr --buildtype=release

ninja
ninja install

popd
rm -rf libpsl-0.23.3

#######################
# cURL
#######################
tar xvf curl-8.21.0.tar.xz
pushd curl-8.21.0

./configure --prefix=/usr    \
            --disable-static \
            --with-openssl   \
            --with-ca-path=/etc/ssl/certs
make

make install

rm -rf docs/examples/.deps

find docs \( -name Makefile\* -o  \
             -name \*.1       -o  \
             -name \*.3       -o  \
             -name CMakeLists.txt \) -delete

cp -v -R docs -T /usr/share/doc/curl-8.21.0

popd
rm -rf curl-8.21.0

#######################
# Git
#######################
tar xvf git-2.55.0.tar.xz
pushd git-2.55.0

./configure --prefix=/usr \
    --with-gitconfig=/etc/gitconfig \
    --with-python=python3 \
    --with-libpcre2

make NO_RUST=1 -j$(nproc)
make NO_RUST=1 perllibdir=/usr/lib/perl5/5.44/site_perl install

popd
rm -rf git-2.55.0
