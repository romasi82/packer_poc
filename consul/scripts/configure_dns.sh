#!/bin/bash
# Author: Ronald Silva
# Date: 2021-01-07
# Description:
#   Script to config DNS forwarding to Consul for Consul services.

set -e

readonly CONSUL_DOMAIN="searchfunc13"
readonly CONSUL_IP="127.0.0.1"
readonly CONSUL_DNS_PORT=8600

readonly SYSTEMD_RESVOLDED_CONFIG_FILE="/etc/systemd/resolved.conf"

# Install dependencies
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get install -y -qq iptables-persistent

# Configure systemd-resolved
sudo iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 53 -j REDIRECT --to-ports ${CONSUL_DNS_PORT}
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6
sudo sed -i "s/#DNS=/DNS=${CONSUL_IP}/g" ${SYSTEMD_RESVOLDED_CONFIG_FILE}
sudo sed -i "s/#Domains=/Domains=~${CONSUL_DOMAIN}/g" ${SYSTEMD_RESVOLDED_CONFIG_FILE}

echo "DNS configured."