#!/bin/bash
# Author: Ronald Silva
# Date: 2021-01-07
# Description:
#   Script to install Consul (and its dependencies).

set -e

readonly SCRIPT_NAME=$(basename $0)
readonly CONSUL_DOWNLOAD_URL="https://releases.hashicorp.com/consul"
readonly CONSUL_DOWNLOAD_PATH="/tmp/consul"
readonly CONSUL_INSTALL_PATH="/opt/consul"
readonly CONSUL_USER="consul"

# VERSION=
# SERVER=

usage() {
[[ -n $1 ]] && echo "$1" >&2
cat <<EOF
Usage:
  ${SCRIPT_NAME} --version <version_number> [--server]

Options:
  --version     version of Consul to download
  -h, --help    show usage info

EOF
exit 1
}

while [[ $# -gt 0 ]]; do
  option="$1"

  case ${option} in
    --version)    version=$2; shift;;
    --server)     server=1;;
    *) usage;;
  esac

  shift
done

[[ -z ${version} ]] && usage "The --version option is required."

# Install necessary dependencies
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
sudo apt-get update -y -qq
sudo apt-get install -y -qq curl unzip jq  # awscli

# Download and verify Consul
mkdir ${CONSUL_DOWNLOAD_PATH}
cd ${CONSUL_DOWNLOAD_PATH}
curl --location --silent --fail --show-error --remote-name ${CONSUL_DOWNLOAD_URL}/${version}/consul_${version}_linux_amd64.zip
curl --location --silent --fail --show-error --remote-name ${CONSUL_DOWNLOAD_URL}/${version}/consul_${version}_SHA256SUMS
curl --location --silent --fail --show-error --remote-name ${CONSUL_DOWNLOAD_URL}/${version}/consul_${version}_SHA256SUMS.sig
sha256sum --check --ignore-missing --quiet consul_${version}_SHA256SUMS

# Install Consul
unzip -qq consul_${version}_linux_amd64.zip
sudo chown root:root consul
sudo mkdir --parents /opt/consul/{bin,config,data,tls/ca}
sudo mv consul /opt/consul/bin
sudo ln -s /opt/consul/config /etc/consul.d
sudo ln -s /opt/consul/bin/consul /usr/local/bin/consul
consul -autocomplete-install
complete -C /usr/local/bin/consul consul

# Set up TLS certificates
sudo cp /tmp/packer/consul/certificates/ca.pem /opt/consul/tls/ca
sudo cp /tmp/packer/consul/certificates/{cert,key}.pem /opt/consul/tls

# Configure Consul Base Settings
sudo cp /tmp/packer/consul/config/consul.hcl /opt/consul/config
sudo chmod 640 /opt/consul/config/consul.hcl

# Configure Consul Server Settings
if [[ -n ${server} ]]; then
  sudo cp /tmp/packer/consul/config/server.hcl /opt/consul/config
  sudo chmod 640 /opt/consul/config/server.hcl
fi

# Install Consul Run Script
sudo cp /tmp/packer/consul/scripts/run_consul.sh /opt/consul/bin

# Configure Consul User and Ownership
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo chown --recursive consul:consul /opt/consul

# Set up Consul log directory
sudo mkdir /var/log/consul
sudo chown consul:consul /var/log/consul

# Configure Consul Process
sudo cp /tmp/packer/consul/config/consul.service /usr/lib/systemd/system
sudo chown root:root /usr/lib/systemd/system/consul.service

# Add Consul to path (for Nomad to use connect)
export PATH=${PATH}:/opt/consul/bin/consul

echo "Consul installed and configured."