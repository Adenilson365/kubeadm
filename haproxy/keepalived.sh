#!/usr/bin/env bash
set -euo pipefail

KEEPALIVED_VERSION="2.3.4"
KEEPALIVED_URL="https://www.keepalived.org/software/keepalived-${KEEPALIVED_VERSION}.tar.gz"

sudo apt-get update
sudo apt-get install -y \
  wget \
  build-essential \
  pkg-config \
  automake \
  autoconf \
  libssl-dev \
  libnl-3-dev \
  libnl-genl-3-dev \
  libipset-dev \
  libxtables-dev \
  libip4tc-dev \
  libip6tc-dev \
  libsystemd-dev

cd /tmp

wget "$KEEPALIVED_URL" -O keepalived.tar.gz
tar xvzf keepalived.tar.gz

cd "/tmp/keepalived-${KEEPALIVED_VERSION}"

./configure \
  --prefix=/usr \
  --sysconfdir=/etc \
  --localstatedir=/var \
  --enable-systemd

make
sudo make install

sudo mkdir -p /etc/keepalived

cat << EOF | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance VRRP1 {
    state BACKUP
    interface enp0s8
    virtual_router_id 51
    priority 110
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass secret
    }

    virtual_ipaddress {
        192.168.56.30
    }
}
EOF

sudo keepalived -t -f /etc/keepalived/keepalived.conf

sudo systemctl daemon-reload
sudo systemctl enable keepalived
sudo systemctl restart keepalived