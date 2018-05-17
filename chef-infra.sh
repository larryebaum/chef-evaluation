#!/bin/bash

usage() {
  echo "Usage: $0 [setup|teardown] [options]"
  echo ""
  echo "setup options: Creat a local Chef Infrastructure"
  echo "-c, --count  Number of managed nodes to create and bootstrap"
  echo ""
  echo "teardown options: Remove files and objects created"
  echo "-h,--help    show this message"
  echo "-p,--pretend just list what will be done"
  echo "-f,--full    Remove .deb packages. The process downloads and creates .deb"
  echo "             packages. For convienience and speed, these are not removed"
  echo "             by default."
  echo "-y,--yes     answer yes to all prompts"; exit 1;
}

do_setup() {
  echo "Begin Chef Infrastructure setup"
}

do_teardown() {
  echo "Begin Chef Infrastructure teardown"
}

#!/bin/bash

#
# helper functions
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
do_knife_rb() {
  echo "Configuring knife.rb..."
  if [ -f ./.chef/knife.rb ] ; then
    echo "knife.rb exists.  Nothing to do here."
  else
    mkdir -p .chef && cat >./.chef/knife.rb <<EOL
current_dir = File.dirname(__FILE__)
user = admin
client_key               "../.chef/admin.pem"
validation_client_name   "a2-validator"
validation_key           "../.chef/a2-validator.pem"
chef_server_url          "https://chef-server.test/organizations/a2"
cookbook_path            ["#{current_dir}/../cookbooks"]
EOL
  fi
  echo "knife.rb complete."
}
#
# set up Host/Local Dev/Workstation
#
do_local_setup() {
  echo "Setting up Host/Local Dev/Workstation..."
  do_knife_rb
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
  do_automate_setup
  do_chef_server_setup
  do_local_setup
  do_node_setup $cnt
  #init_test
  # wrap up and repeat the user instructions that are buried in the logs
  echo "To login to Chef Automate, use the following credentials"
  echo "        URL: https://automate-deployment.test to try Chef Automate"
  echo "        User: admin"
  vagrant ssh a2 -c "sudo ./chef-automate config show | grep 'password'" >/dev/tty 2>&1
  echo ""
  echo "cleanup using ./clean.sh"
  echo ""
  echo "Chef Infrastructure setup completed."
}

do_teardown() {
if $is_pre ; then echo "-p specified. Only printing actions of this script..." ; fi

  remove automate-deployment.test $is_pre
  remove chef-server.test $is_pre
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
  if ! $is_pre ; then mv -f ./cookbooks ./removing/cookbooks ; fi

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
  echo "remove ./vagrant dir..."
  if ! $is_pre ; then mv -f ./.vagrant ./removing/.vagrant ; fi
  echo "nuke the temporary ./removing dir..."
  if ! $is_pre ; then rm -rf ./removing ; fi

  echo " "
  echo "done. Thanks for playing... :)"
}


#
# Begin chef-infra.sh
#
# initalize default flags
is_setup=false
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
  do_setup
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
