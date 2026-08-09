#!/usr/bin/env bash

# Update package lists and install PostgreSQL and its contrib package
apt update
apt install -y postgresql postgresql-contrib


# Install Zabbix
#https://www.zabbix.com/download?zabbix=7.0&os_distribution=ubuntu&os_version=22.04&components=server_frontend_agent_2&db=pgsql&ws=apache

wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu22.04_all.deb
dpkg -i zabbix-release_latest_7.0+ubuntu22.04_all.deb
apt update

apt install -y zabbix-server-pgsql zabbix-frontend-php php8.1-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent2

apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

#/etc/zabbix/zabbix_server.conf

systemctl restart zabbix-server zabbix-agent2 apache2
systemctl enable zabbix-server zabbix-agent2 apache2


### AGENT installation ###

wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu22.04_all.deb
dpkg -i zabbix-release_latest_7.0+ubuntu22.04_all.deb
apt update

apt install -y zabbix-agent2

apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

echo "UserParameter=etcd.metrics,curl -fsS http://127.0.0.1:2381/metrics" >> /etc/zabbix/zabbix_agent2.d/etcd.conf
echo "UserParameter=etcd.health,curl -fsS http://127.0.0.1:2381/health" >> /etc/zabbix/zabbix_agent2.d/etcd.conf

# Edite o arquivo de configuração do Zabbix Agent 2 para definir o hostname e o endereço do servidor Zabbix
#vi /etc/zabbix/zabbix_agent2.conf
# Adicione: 
# Server=192.168.56.41
#ServerActive=192.168.56.41:10051
#Hostname=<Hostneame do agente>

systemctl restart zabbix-agent2
systemctl enable zabbix-agent2


