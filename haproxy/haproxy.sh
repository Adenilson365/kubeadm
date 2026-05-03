#!/usr/bin/env bash
set -euo pipefail

HAPROXY_VERSION="3.1.5"
HAPROXY_URL="https://www.haproxy.org/download/3.1/src/haproxy-${HAPROXY_VERSION}.tar.gz"

sudo apt-get update
sudo apt-get install -y \
  build-essential \
  wget \
  libssl-dev \
  libpcre3-dev \
  zlib1g-dev \
  libcrypt-dev

cd /tmp
wget "$HAPROXY_URL" -O haproxy.tar.gz
tar xvzf haproxy.tar.gz

cd "/tmp/haproxy-${HAPROXY_VERSION}"

make TARGET=linux-glibc \
  USE_PCRE=1 \
  USE_OPENSSL=1 \
  USE_ZLIB=1 \
  USE_CRYPT_H=1 \
  USE_LIBCRYPT=1 \
  USE_SYSTEMD=1

sudo make install

sudo groupadd --system haproxy 2>/dev/null || true
sudo useradd --system \
  --gid haproxy \
  --home-dir /var/lib/haproxy \
  --shell /usr/sbin/nologin \
  haproxy 2>/dev/null || true

sudo mkdir -p /etc/haproxy
sudo mkdir -p /var/lib/haproxy/dev
sudo touch /etc/default/haproxy

sudo tee /etc/haproxy/haproxy.cfg > /dev/null <<'EOF'
global
    log /dev/log local0
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    maxconn 256
    stats socket /var/lib/haproxy/stats level admin

defaults
    log global
    option dontlognull
    timeout queue 1m
    timeout connect 10s
    timeout client 1m
    timeout server 1m
    timeout check 10s
    maxconn 3000

frontend front-cp
    bind *:6443
    default_backend back-cp

backend back-cp
    balance roundrobin
    server cp1 192.168.56.11:6443 check
    server cp2 192.168.56.12:6443 check
    server cp3 192.168.56.13:6443 check


listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:admin123
EOF

sudo tee /etc/systemd/system/haproxy.service > /dev/null <<'EOF'
[Unit]
Description=HAProxy Load Balancer
After=network-online.target
Wants=network-online.target

[Service]
Environment="CONFIG=/etc/haproxy/haproxy.cfg" "PIDFILE=/run/haproxy.pid" "OPTIONS="
EnvironmentFile=-/etc/default/haproxy
ExecStartPre=/usr/local/sbin/haproxy -f $CONFIG -c -q $OPTIONS
ExecStart=/usr/local/sbin/haproxy -Ws -f $CONFIG -p $PIDFILE $OPTIONS
ExecReload=/usr/local/sbin/haproxy -f $CONFIG -c -q $OPTIONS
ExecReload=/bin/kill -USR2 $MAINPID
SuccessExitStatus=143
KillMode=mixed
Type=notify

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/rsyslog.d/haproxy.conf > /dev/null <<'EOF'
$AddUnixListenSocket /var/lib/haproxy/dev/log

:programname, startswith, "haproxy" {
  /var/log/haproxy.log
  stop
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart rsyslog
sudo systemctl enable haproxy
sudo systemctl restart haproxy

sudo systemctl status haproxy --no-pager