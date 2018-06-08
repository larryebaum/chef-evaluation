#!/bin/bash

GUEST_WKDIR=$1
echo 192.168.33.199 automate-deployment.test | sudo tee -a /etc/hosts
echo 192.168.33.200 chef-server.test | sudo tee -a /etc/hosts
if [ ! -f ${GUEST_WKDIR}/pkgs/srvr/*.deb ]; then
  mkdir -p ${GUEST_WKDIR}/pkgs/srvr;
  cd ${GUEST_WKDIR}/pkgs/srvr;
  wget -q https://packages.chef.io/files/stable/chef-server/12.17.33/ubuntu/16.04/chef-server-core_12.17.33-1_amd64.deb;
fi
dpkg -i ${GUEST_WKDIR}/pkgs/srvr/*.deb && sudo chef-server-ctl reconfigure
# check for the existing user
sudo chef-server-ctl user-show | grep 'admin'
if [[ $? != 0 ]]; then
  sudo chef-server-ctl user-create admin first last admin@example.com 'adminpwd' --filename ${GUEST_WKDIR}/.chef/admin.pem
fi
# check for the existing org
sudo chef-server-ctl org-show | grep 'a2'
if [[ $? != 0 ]]; then
  sudo chef-server-ctl org-create a2 'automate2' --association_user admin --filename ${GUEST_WKDIR}/.chef/a2-validator.pem
fi
while [ ! -f ${GUEST_WKDIR}/a2-token ] ; do
  sleep 5 && echo '.'
done
sudo chef-server-ctl set-secret data_collector token $(< ${GUEST_WKDIR}/a2-token) && sudo chef-server-ctl restart nginx && sudo chef-server-ctl restart opscode-erchef
echo "data_collector['root_url'] = 'https://automate-deployment.test/data-collector/v0/'" | sudo tee -a /etc/opscode/chef-server.rb
echo "profiles['root_url'] = 'https://automate-deployment.test'" | sudo tee -a /etc/opscode/chef-server.rb
sudo chef-server-ctl reconfigure
