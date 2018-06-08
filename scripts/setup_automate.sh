#!/bin/bash

GUEST_WKDIR=$1
apt-get update && apt-get install -y unzip ntp
sysctl -w vm.max_map_count=262144
sysctl -w vm.dirty_expire_centisecs=20000
echo 192.168.33.199 automate-deployment.test | sudo tee -a /etc/hosts
cd /home/vagrant && curl -s https://packages.chef.io/files/current/automate/latest/chef-automate_linux_amd64.zip |gunzip - > chef-automate && chmod +x chef-automate
sudo ./chef-automate init-config
sudo ./chef-automate deploy config.toml --accept-terms-and-mlsa --skip-preflight > ${GUEST_WKDIR}/logs/automate.deploy.log 2>&1
if [ -f ${GUEST_WKDIR}/automate.license ]; then
  sudo ./chef-automate license apply $(< ${GUEST_WKDIR}/automate.license) && sudo ./chef-automate license status
fi
sudo ./chef-automate admin-token > ${GUEST_WKDIR}/a2-token
