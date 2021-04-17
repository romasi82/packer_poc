#!/bin/bash
# Author: Ronald Silva
# Date: 2021-01-07
# Description:
#   Script to configure and run Consul (and configure systemd)

# Start Consul Service
sudo consul validate /etc/consul.d/consul.hcl
sudo systemctl enable consul
sudo systemctl start consul
sudo systemctl status consul

# Gruntwork Start Consul Service commands (better?)
# sudo systemctl daemon-reload
# sudo systemctl enable consul.service
# sudo systemctl restart consul.service

# Check syslog for Consul startup errors
# journalctl -xe

# Bootstrap ACLs System
# export CONSUL_CACERT=/opt/consul/tls/ca/ca.pem
# export CONSUL_CLIENT_CERT=/opt/consul/tls/cert.pem
# export CONSUL_CLIENT_KEY=/opt/consul/tls/key.pem

# readonly TOKEN=$( consul acl bootstrap )
# export CONSUL_HTTP_TOKEN="${TOKEN}"
# export CONSUL_MGMT_TOKEN=="${TOKEN}"