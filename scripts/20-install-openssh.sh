#!/bin/bash

set -e

SRC=/sources
BASE=/sources

cd $BASE

#######################
# Openssh
#######################
tar xvf openssh-10.5p1.tar.gz
pushd openssh-10.5p1

install -v -g sys -m700 -d /var/lib/sshd

groupadd -g 50 sshd
useradd -c 'sshd PrivSep' \
    -d /var/lib/sshd \
    -g sshd \
    -s /bin/false \
    -u 50 sshd

./configure --prefix=/usr \
            --sysconfdir=/etc/ssh \
            --with-privsep-path=/var/lib/sshd \
            --with-default-path=/usr/bin \
            --with-superuser-path=/usr/sbin:/usr/bin \
            --with-pid-dir=/run

make
make -j1 tests
make install
install -v -m755    contrib/ssh-copy-id /usr/bin
install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1
install -v -m755 -d /usr/share/doc/openssh-10.5p1
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-10.5p1

ssh-keygen -A

cat > /etc/systemd/system/sshd.service <<'EOF'
[Unit]
Description=OpenSSH Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/sshd -D
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

systemctl enable sshd

popd
rm -rf openssh-10.5p1

