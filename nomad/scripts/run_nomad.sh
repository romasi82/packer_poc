#!/bin/bash
# Author: Ronald Silva
# Date: 2021-02-17
# Description:
#   Script to configure and run Nomad (and configure systemd)

# Start Nomad Service
sudo systemctl enable nomad
sudo systemctl start nomad
sudo systemctl status nomad