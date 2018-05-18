#!/bin/bash
# Author: Mike Tyler - mtyler - mtyler@chef.io
# Purpose: Stand up an Automate v2.0 evaluation environment

#
# helper functions
#
usage() {
  echo "Usage: $0 [setup|teardown] [options]"
  echo ""
  echo "setup options: Creat a local Chef Infrastructure"
  echo "-c, --count  TODO not implemented yet - Number of managed nodes to create and bootstrap"
  echo "-l, --local  Create/overwrite local files only, create Vagrantfile,"
  echo "              knife.rb, cookbook upload, etc."
  echo ""
  echo "teardown options: Remove files and objects created"
  echo "-h,--help    show this message"
  echo "-p,--pretend just list what will be done"
  echo "-f,--full    Remove .deb packages. The process downloads and creates .deb"
  echo "             packages. For convienience and speed, these are not removed"
  echo "             by default."
  echo "-y,--yes     answer yes to all prompts"; exit 1;
}
#
# append to /etc/hosts file
#
add_host() {
  if [ -n "$(grep "$2" /etc/hosts)" ]; then
    echo "$2, already exists";
  else
    echo "adding $2 to /etc/hosts";
    printf "%s\t%s\n" "$1" "$2" | sudo tee -a "/etc/hosts" > /dev/null;
  fi
}
#
# remove from /etc/hosts file
#
remove_host() {
  if [ -n "$(grep "$1" /etc/hosts)" ]; then
    echo "$1 found in /etc/hosts. Removing now..."
    if ! $2 ; then
      sudo sed -ie "/$1/d" "/etc/hosts"
    fi
  else
    echo "$1 was not found in /etc/hosts"
  fi
}

#
# create local knife config
#
create_base_rb() {
    mkdir -p ./roles && cat >./roles/base.rb <<EOL
name "base"
description "baseline config"
run_list(
  "recipe[audit::default]"
)
default_attributes(
  "audit": {
    "reporter": "chef-server-automate",
    "profiles": [
      {
        "name": "DevSec Linux Security Baseline",
        "compliance": "admin/linux-baseline"
      }
    ]
  }
)
EOL
}

#
# create local knife config
#
create_knife_rb() {
    mkdir -p .chef && cat >./.chef/knife.rb <<EOL
current_dir = File.dirname(__FILE__)
node_name                "admin"
client_key               "../.chef/admin.pem"
validation_client_name   "a2-validator"
validation_key           "../.chef/a2-validator.pem"
chef_server_url          "https://chef-server.test/organizations/a2"
cookbook_path            ["#{current_dir}/../cookbooks"]
EOL
}
#
# create Vagrantfile
#
create_vagrantfile() {
    cat > Vagrantfile <<EOL
# -*- mode: ruby -*-
# vi: set ft=ruby :

# this is set high to give some flexiblity.
# ideally this should be passed from an environment var
NODE_COUNT = 10

Vagrant.configure(2) do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.define :a2 do |a2|
    a2.vm.box = "bento/ubuntu-16.04"
    a2.vm.synced_folder ".", "/opt/a2-testing", create: true
    a2.vm.hostname = 'automate-deployment.test'
    a2.vm.network 'private_network', ip: '192.168.33.199'
    a2.vm.boot_timeout = 600
    a2.vm.provision "shell", inline: "apt-get update && apt-get install -y unzip"
    a2.vm.provision "shell", inline: "sysctl -w vm.max_map_count=262144"
    a2.vm.provision "shell", inline: "sysctl -w vm.dirty_expire_centisecs=20000"
    a2.vm.provision "shell", inline: "echo 192.168.33.199 automate-deployment.test | sudo tee -a /etc/hosts"
    a2.vm.provision "shell", inline: "cd /home/vagrant && curl https://packages.chef.io/files/current/automate/latest/chef-automate_linux_amd64.zip |gunzip - > chef-automate && chmod +x chef-automate"
    a2.vm.provision "shell", inline: "sudo ./chef-automate init-config"
    a2.vm.provision "shell", inline: "sudo ./chef-automate deploy config.toml --skip-preflight"
    a2.vm.provision "shell", inline: "if [ -f /opt/a2-testing/automate.license ]; then sudo ./chef-automate license apply \$(< /opt/a2-testing/automate.license) && sudo ./chef-automate license status ; fi"
    a2.vm.provision "shell", inline: "sudo ./chef-automate admin-token > /opt/a2-testing/a2-token"
  end

  config.vm.define :srvr do |srvr|
    srvr.vm.box = "bento/ubuntu-16.04"
    srvr.vm.synced_folder ".", "/opt/a2-testing", create: true
    srvr.vm.hostname = 'chef-server.test'
    srvr.vm.network 'private_network', ip: '192.168.33.200'
    srvr.vm.provision "shell", inline: "echo 192.168.33.199 automate-deployment.test | sudo tee -a /etc/hosts"
    srvr.vm.provision "shell", inline: "echo 192.168.33.200 chef-server.test | sudo tee -a /etc/hosts"
    srvr.vm.provision "shell", inline: "cd /opt/a2-testing && wget -N -nv https://packages.chef.io/files/stable/chef-server/12.17.33/ubuntu/16.04/chef-server-core_12.17.33-1_amd64.deb && sudo dpkg -i /opt/a2-testing/chef-server-core*.deb && chef-server-ctl reconfigure"
    srvr.vm.provision "shell", inline: "mkdir -p /opt/a2-testing/.chef"
    srvr.vm.provision "shell", inline: "if [ \"\$(sudo chef-server-ctl user-show | grep 'admin')\" == \"\" ]; then sudo chef-server-ctl user-create admin first last admin@example.com 'adminpwd' --filename /opt/a2-testing/.chef/admin.pem; fi"
    srvr.vm.provision "shell", inline: "if [ \"\$(sudo chef-server-ctl org-show | grep 'a2')\" == \"\" ]; then sudo chef-server-ctl org-create a2 'automate2' --association_user admin --filename /opt/a2-testing/.chef/a2-validator.pem; fi"
    srvr.vm.provision "shell", inline: "sudo chef-server-ctl set-secret data_collector token \$(< /opt/a2-testing/a2-token) && sudo chef-server-ctl restart nginx && sudo chef-server-ctl restart opscode-erchef"
    srvr.vm.provision "shell", inline: "echo \"data_collector['root_url'] = 'https://automate-deployment.test/data-collector/v0/'\" | sudo tee -a /etc/opscode/chef-server.rb"
    srvr.vm.provision "shell", inline: "echo \"profiles['root_url'] = 'https://automate-deployment.test'\" | sudo tee -a /etc/opscode/chef-server.rb"
    srvr.vm.provision "shell", inline: "sudo chef-server-ctl reconfigure"
    srvr.vm.provision "shell", inline: "touch /home/vagrant/srvr-token"
  end

  NODE_COUNT.times do |i|
    node_id = "node1#{i}"
    config.vm.define node_id do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.memory = 512
        vb.cpus = 2
      end
      node.vm.box = "archlinux/archlinux"
      node.vm.hostname = "#{node_id}.test"
      node.vm.synced_folder ".", "/opt/a2-testing", create: true
      node.vm.network :private_network, ip: "192.168.33.1#{i}"
      node.ssh.username = "vagrant"
      node.ssh.password = "vagrant"
      node.vm.provision "shell", inline: "echo 192.168.33.200 chef-server.test | sudo tee -a /etc/hosts"
      node.vm.provision "shell", inline: "echo 192.168.33.1#{i} #{node_id}.test | sudo tee -a /etc/hosts"
      node.vm.provision "shell", inline: "sudo pacman -Sy --noconfirm wget binutils fakeroot cronie"
      node.vm.provision "shell", inline: "sudo -H -u vagrant bash -c 'cd /opt/a2-testing && wget -N -nv https://aur.archlinux.org/cgit/aur.git/snapshot/chef-dk.tar.gz && tar -xvzf *.tar.gz'"
      node.vm.provision "shell", inline: "if [ \"\$(ls /opt/a2-testing/chef-dk/chef*xz)\" == \"\" ]; then sudo -H -u vagrant bash -c 'cd /opt/a2-testing/chef-dk && makepkg -s'; fi"
      node.vm.provision "shell", inline: "cd /opt/a2-testing/chef-dk && sudo pacman -U --noconfirm *xz"
      node.vm.provision "shell", inline: "sudo mkdir -p /etc/chef && cat >/etc/chef/client.rb <<EOL
log_level        :info
log_location     STDOUT
chef_server_url  'https://chef-server.test/organizations/a2'
validation_client_name 'a2-validator'
validation_key '/opt/a2-testing/.chef/a2-validator.pem'
client_key '/etc/chef/client.pem'
ssl_verify_mode  :verify_none
EOL"
      node.vm.provision "shell", inline: "sudo /usr/bin/chef-client -r 'recipe[audit::default]'"
      node.vm.provision "shell", inline: "sudo systemctl enable cronie.service && sudo systemctl start cronie.service"
      node.vm.provision "shell", inline: "(crontab -l 2>/dev/null; echo \"*/5 * * * * sudo /usr/bin/chef-client >/dev/null 2>&1\") | crontab -"

    end
  end

end
EOL
}

#
# set up Host/Local Dev/Workstation
#
do_local_setup() {
  echo "Setting up Host/Local Dev/Workstation..."
  echo "Configuring knife.rb..."
  if [ -f ./.chef/knife.rb ] ; then
    echo "knife.rb exists.  Nothing to do here."
  else
    create_knife_rb
  fi
  echo "knife.rb complete."

  knife ssl fetch
  knife client list

  # upload cookbooks
  echo "Uploading cookbooks..."
  mkdir -p cookbooks && cd cookbooks

  ckbks=(audit)
  for c in $ckbks; do
    if [ "$( knife cookbook list | grep $c )" == "" ]; then
      knife cookbook site download $c
      tar -xzvf $c*.tar.gz
      knife cookbook upload $c
    else
      echo "$c exists. Nothing to do here."
    fi
  done
  echo "Cookbook upload complete."
  echo "Uploading Roles..."
  if [ -f ./roles/base.rb ] ; then
    echo "base.rb exists.  Nothing to do here."
  else
    create_base_rb
    knife role from file base.rb
  fi
  echo "base.rb complete."
  knife cookbook list >/dev/tty 2>&1
  knife status >/dev/tty 2>&1
  echo "setting up Host/Local Dev/Workstation complete."
}
#
# set up managed nodes
# $1 = node count
do_node_setup() {
  echo "Setting up managed nodes..."
  for (( i=0; i<$1; i++ ))
  do
    if [ "$(vagrant status node1$i | grep 'running (virtualbox)')" == "" ];
    then
      vagrant up node1$i >/dev/tty 2>&1
    else
      echo "node1$i is running. Nothing to do here."
    fi
    add_host 192.168.33.1$i node1$i.test
  done
  echo "Managed nodes set up complete."

}
#
# set up Chef Server vm
#
do_chef_server_setup() {
  echo "Setting up Chef Server..."
  if [ "$(vagrant status srvr | grep 'running (virtualbox)')" == "" ];
  then
    echo "vagrant up Chef Server..."
    #clean up any last_run leftovers that will get in the way
    rm -f srvr-token
    vagrant up srvr >/dev/tty 2>&1
    if [ ! -f ./srvr-token ] ; then echo "srvr-token doesn't exist" ; fi
  else
    echo "Chef Server is running.  Nothing to do here."
  fi
  add_host 192.168.33.200 chef-server.test
  echo "Chef Server set up complete."
}
#
# set up Automate vm
#
do_automate_setup() {
echo "Setting up Automate..."
  if [ "$(vagrant status a2 | grep 'running (virtualbox)')" == "" ];
  then
    echo "vagrant up automate..."
    # clean up any last_run leftovers that will get in the way
    rm -f a2-token
    vagrant up a2 >/dev/tty 2>&1
    # check for token
    if [ ! -f ./a2-token ] ; then echo "a2-token doesn't exist" ; fi
  else
    echo "Automate is running.  Nothing to do here."
  fi
  add_host 192.168.33.199 automate-deployment.test
  echo "Automate set up complete."
}
#
# test setup
init_test() {
  if [ ! -f ./.chef/knife.rb ] ; then echo "ERROR: knife.rb doesn't exist" ; fi
  if [[ "$(vagrant ssh srvr -c 'hostname -f')" != *"chef-server.test"* ]] ; then echo "ERROR: chef-server setup not complete" ; fi
}

#
# Begin setup
# the purpose of this file is to be the entry point for setting up a
# local test/evaluation environment for Chef Automate v2
#
do_setup() {
  echo "Begin Chef Infrastructure setup..."
  echo "Creating Vagrantfile..."
  if [ -f ./Vagrantfile ] ; then
    echo "Vagrantfile exists.  Nothing to do here."
  else
    create_vagrantfile 2>/dev/null
  fi
  echo "Vagrantfile complete."
  do_automate_setup
  do_chef_server_setup
  do_local_setup
  do_node_setup $cnt
  #init_test
  # wrap up and repeat the user instructions that are buried in the logs
  echo "*******************************************************************"
  echo ""
  echo "To login to Chef Automate, use the following credentials"
  echo "        URL: https://automate-deployment.test to try Chef Automate"
  echo "        User: admin"
  vagrant ssh a2 -c "sudo ./chef-automate config show | grep 'password'" >/dev/tty 2>&1
  echo ""
  echo "cleanup using ./chef-infra.sh teardown"
  echo ""
  echo "Chef Infrastructure setup completed."
  echo "*******************************************************************"
}

do_teardown() {
  echo "Begin Chef Infrastructure teardown"
  if $is_pre ; then echo "-p specified. Only printing actions of this script..." ; fi

  remove_host automate-deployment.test $is_pre
  remove_host chef-server.test $is_pre
  #TODO remove nodeX.test

  if $is_full ; then
    echo "clear contents of add.license.etc..."
    echo "delete binaries ./chef-dk, *.deb..."
    if ! $is_pre ; then
      # file containing automate license
      cp automate.license ./removing
      echo "" > automate.license
      # directory containing compiled archlinux chef-dk package
      mv ./chef-dk ./removing
      mv *.deb ./removing
    fi
  fi

  echo "create temporary removing dir..."
  if ! $is_pre ; then mkdir -p removing ; fi
  echo "remove token file..."
  if ! $is_pre ; then mv -f a2-token ./removing ; fi
  echo "remove files from .chef..."
  if ! $is_pre ; then mv -f ./.chef ./removing ; fi
  echo "remove chef-dk.tar.gz..."
  if ! $is_pre ; then mv -f ./chef-dk.tar.gz ./removing ; fi
  echo "remove ./cookbooks dir..."
  if ! $is_pre ; then mv -f ./cookbooks ./removing ; fi
  echo "remove ./roles dir..."
  if ! $is_pre ; then mv -f ./roles ./removing ; fi

# make sure user really wants to delete if they did
# not pass cli argument -y
  if ! $is_yes ;
  then
    while true; do
      read -p "Do you want to clean up? (y/n)" yn
      case $yn in
          [Yy]* ) break;;
          [Nn]* )
            echo "Ok. Stopping now."
            if ! $is_pre ; then echo "Recovery can be done manually by moving files out of ./removing" ; fi
            exit;;
          * ) echo "Please answer yes or no.";;
      esac
    done
  fi

  echo "vagrant destroy -f removing these vms..."
  vagrant status >/dev/tty 2>&1
  if ! $is_pre ; then vagrant destroy -f ; fi
  echo "remove Vagrantfile..."
  if ! $is_pre ; then rm -f Vagrantfile ./removing ; fi
  echo "remove ./vagrant dir..."
  if ! $is_pre ; then mv -f ./.vagrant ./removing/.vagrant ; fi
  echo "nuke the temporary ./removing dir..."
  if ! $is_pre ; then rm -rf ./removing ; fi

  echo " "
  echo "Teardown of Chef Infrastructure complete. Thanks for playing... :)"
}


#
# Begin chef-infra.sh
#
# initalize default flags
is_setup=false
is_local=false
is_teardown=false
cnt=2
is_full=false
is_yes=false
is_pre=false

for i in "$@"
do
case $i in
    setup)
    is_setup=true
    ;;
    teardown)
    is_teardown=true
    ;;
    -l|--local)
    is_local=true
    ;;
    -f|--full)
    is_full=true
    ;;
    -y|--yes)
    is_yes=true
    ;;
    -p|--pretend)
    is_pre=true
    ;;
    -h|--help)
    usage
    ;;
    *)
    usage
    ;;
esac
done

# record and print elapsed time
start=`date +%s`
if [ $is_setup == $is_teardown ] ;
then
  echo " "
  echo "Error: specify one task, setup or teardown"
  echo " "
  usage
elif $is_setup ;
then
  if $is_local ;
  then
    create_base_rb
    create_knife_rb
    do_local_setup
    create_vagrantfile 2>/dev/null
  else
    do_setup
  fi
elif $is_teardown ;
then
  do_teardown
else
  echo " "
  echo "Error: specify one task, setup or teardown"
  echo " "
  usage
fi

end=`date +%s`
runtime=$((end-start))
echo ""
echo "script completed in $runtime seconds"
