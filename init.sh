#!/bin/bash

#
# helper functions
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
# Begin init.sh
# the purpose of this file is to be the entry point for setting up a
# local test/evaluation environment for Chef Automate v2
#
# set up host /etc/hosts file
#
add_host 192.168.33.199 automate-deployment.test
add_host 192.168.33.200 chef-server.test

NODE_COUNT=2
for (( i=0; i<$NODE_COUNT; i++ ))
do
   add_host 192.168.33.1$i node1$i.test
done

#
# set up Automate vm
#
echo "Setting up Automate..."
if [ '$(vagrant status a2 | grep "running (virtualbox)")' == '' ];
then
  echo "vagrant up automate..."
  # clean up any last_run leftovers that will get in the way
  rm -f a2-token
  vagrant up a2
  # wait until admin-token exists
  until [ ! -f ./a2-token ]
  do
    sleep 5
    echo "sleep..."
  done
else
  echo "Automate is running.  Nothing to do here."
fi
echo "Automate set up complete."

#
# set up Chef Server vm
#
echo "Setting up Chef Server..."
if [ '$(vagrant status srvr | grep "running (virtualbox)")' == '' ];
then
  echo "vagrant up Chef Server..."
  #clean up any last_run leftovers that will get in the way
  rm -f srvr-token
  vagrant up srvr
  #wait until chef-server is up
  until [ ! -f ./srvr-token ]
  do
    sleep 5
    echo "sleep..."
  done
else
  echo "Chef Server is running.  Nothing to do here."
fi
echo "Chef Server set up complete."

#
# set up Host/Local Dev/Workstation
#
echo "Setting up Host/Local Dev/Workstation..."
knife ssl fetch
knife client list

# upload cookbooks
echo "Uploading cookbooks..."
mkdir -p cookbooks && cd cookbooks

ckbks=(audit)
for c in $ckbks; do
  if [ '$(knife cookbook list | grep chef-client)' == '']; then
    knife cookbook site download $c
    tar -xzvf $c*.tar.gz
    knife cookbook upload $c
  fi
done
echo "Cookbook upload complete."
knife cookbook list
knife status
echo "setting up Host/Local Dev/Workstation complete."
#
# stand up fleet
#
echo "Setting up managed nodes..."
for (( i=0; i<$NODE_COUNT; i++ ))
do
   vagrant up node1$i
done
echo "Managed nodes set up complete."
