#!/bin/bash
GUEST_WKDIR=$1
NODE_ID=$2
echo 192.168.33.200 chef-server.test | sudo tee -a /etc/hosts
echo 192.168.33.1${NODE_ID} node1${NODE_ID}.test | sudo tee -a /etc/hosts
if [ ! -f ${GUEST_WKDIR}/pkgs/client/*.deb ]; then mkdir -p ${GUEST_WKDIR}/pkgs/client; cd ${GUEST_WKDIR}/pkgs/client; wget -q https://packages.chef.io/files/stable/chef/14.1.12/ubuntu/16.04/chef_14.1.12-1_amd64.deb; fi
dpkg -i ${GUEST_WKDIR}/pkgs/client/*.deb
sudo mkdir -p /etc/chef && cat >/etc/chef/client.rb <<EOL
log_level        :info
log_location     STDOUT
chef_server_url  'https://chef-server.test/organizations/a2'
validation_client_name 'a2-validator'
validation_key '${GUEST_WKDIR}/.chef/a2-validator.pem'
client_key '/etc/chef/client.pem'
ssl_verify_mode  :verify_none
EOL
sudo /usr/bin/chef-client -r 'role[base]'
(crontab -l 2>/dev/null; echo "*/5 * * * * sudo /usr/bin/chef-client >/dev/null 2>&1") | crontab -
