#!/bin/bash
wget -q https://packages.chef.io/files/stable/chef-workstation/0.1.120/ubuntu/16.04/chef-workstation_0.1.120-1_amd64.deb && sudo dpkg -i chef*.deb"
chef-run -v
