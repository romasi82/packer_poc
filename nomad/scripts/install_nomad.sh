#!/bin/bash
# Author: Ronald Silva
# Date: 2021-02-17
# Description:
#   Script to install Nomad (and its dependencies).

set -e

readonly SCRIPT_NAME=$(basename $0)
readonly NOMAD_DOWNLOAD_URL="https://releases.hashicorp.com/nomad"
readonly NOMAD_DOWNLOAD_PATH="/tmp/nomad"
readonly NOMAD_INSTALL_PATH="/opt/nomad"
readonly NOMAD_USER="nomad"

NOMAD_VERSION=
SERVER=

usage() {
[[ -n $1 ]] && echo "$1" >&2
cat <<EOF
Usage:
  ${SCRIPT_NAME} --version <version_number> [--server]

Options:
  --version     version of Nomad to download
  -h, --help    show usage info

EOF
exit 1
}

while [[ $# -gt 0 ]]; do
  option="$1"

  case ${option} in
    --version)    NOMAD_VERSION=$2; shift;;
    --server)     SERVER=1;;
    *) usage;;
  esac

  shift
done

[[ -z ${NOMAD_VERSION} ]] && usage "The --version option is required."

# Install necessary dependencies
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
sudo apt-get update -y -qq
sudo apt-get install -y -qq curl unzip

# Download and verify Nomad
mkdir ${NOMAD_DOWNLOAD_PATH}
cd ${NOMAD_DOWNLOAD_PATH}
curl --location --silent --fail --show-error --remote-name ${NOMAD_DOWNLOAD_URL}/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip
curl --location --silent --fail --show-error --remote-name ${NOMAD_DOWNLOAD_URL}/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS
curl --location --silent --fail --show-error --remote-name ${NOMAD_DOWNLOAD_URL}/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig
sha256sum --check --ignore-missing --quiet nomad_${NOMAD_VERSION}_SHA256SUMS

# Install Nomad
unzip -qq nomad_${NOMAD_VERSION}_linux_amd64.zip
sudo chown root:root nomad
sudo mkdir --parents /opt/nomad/{bin,config,data,tls/ca}
sudo mv nomad /opt/nomad/bin
sudo ln -s /opt/nomad/config /etc/nomad.d
sudo ln -s /opt/nomad/bin/nomad /usr/local/bin/nomad
nomad -autocomplete-install
complete -C /usr/local/bin/nomad nomad

# Set up TLS certificates
sudo cp /tmp/packer/nomad/certificates/ca.pem /opt/nomad/tls/ca
sudo cp /tmp/packer/nomad/certificates/{cert,key}.pem /opt/nomad/tls

# Configure Nomad Base Settings
sudo cp /tmp/packer/nomad/config/nomad.hcl /opt/nomad/config
sudo chmod 640 /opt/nomad/config/nomad.hcl

# Configure Nomad Server or Client Settings
if [[ -n ${SERVER} ]]; then
  sudo cp /tmp/packer/nomad/config/server.hcl /opt/nomad/config
  sudo chmod 640 /opt/nomad/config/server.hcl
else
  sudo cp /tmp/packer/nomad/config/client.hcl /opt/nomad/config
  sudo chmod 640 /opt/nomad/config/client.hcl
fi

# Install Nomad Run Script
sudo cp /tmp/packer/nomad/scripts/run_nomad.sh /opt/nomad/bin

# Configure Nomad User and Ownership
sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad
sudo chown --recursive nomad:nomad /opt/nomad

# Set up Nomad log directory
sudo mkdir /var/log/nomad
sudo chown nomad:nomad /var/log/nomad

# Configure Nomad Process
sudo cp /tmp/packer/nomad/config/nomad.service /usr/lib/systemd/system
sudo chown root:root /usr/lib/systemd/system/nomad.service

# Install Nomad Drivers
if [[ -z ${SERVER} ]]; then
  # Install Docker
  sudo apt-get -y -qq install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get -y -qq update
  sudo apt-get -y -qq install docker-ce docker-ce-cli containerd.io

  # Install Java
  sudo apt install -y -qq openjdk-8-jre-headless
fi

# Install and Configure CNI plugins
curl --silent -L -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v0.9.0/cni-plugins-linux-amd64-v0.9.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -xzf cni-plugins.tgz -C /opt/cni/bin

[[ ! -d /proc/sys/net/bridge ]] && sudo modprobe br_netfilter

echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-arptables > /dev/null
echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-ip6tables > /dev/null
echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables > /dev/null

sudo tee /etc/sysctl.d/10-cni-bridge.conf << EOF
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

echo "Nomad installed and configured."