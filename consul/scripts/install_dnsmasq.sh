#!/bin/bash
# Author: Ronald Silva
# Date: 2021-01-07
# Description:
#   Script to install dnsmasq so that DNS requests meant for Consul are routed accordingly.

set -e

readonly CONSUL_DOMAIN="consul"
readonly CONSUL_IP="127.0.0.1"
readonly CONSUL_DNS_PORT=8600

readonly DNS_MASQ_CONFIG_DIR="/etc/dnsmasq.d"
readonly CONSUL_DNS_MASQ_CONFIG_FILE="${DNS_MASQ_CONFIG_DIR}/10-consul"

# usage () {
# [[ -n $1 ]] && echo "$1" >&2
# cat <<EOF
# Usage:
#   ${SCRIPT_NAME}

# Options:
#   -h, --help  show usage info

# EOF

# exit 1
# }

# while [[ $# -gt 0 ]]; then

# done

# Install necessary dependencies
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
sudo apt-get install -y -qq dnsmasq

#
sudo mkdir -p ${DNS_MASQ_CONFIG_DIR}
sudo cp /tmp/packer/consul.config/dnsmasq ${CONSUL_DNS_MASQ_CONFIG_FILE}

# 


echo "Dnsmasq installed and configured."
