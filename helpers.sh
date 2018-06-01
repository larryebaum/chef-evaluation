#!/bin/bash
# Author: Mike Tyler - mtyler - mtyler@chef.io
# Purpose: helper functions


#
# print start and record to print elapsed time
#
START=`date +%s`
WKDIR=$PWD

do_start() {
  echo "Running ${0} from ${WKDIR}..."
}
#
# finish up with some metrics
#
do_end() {
  end=`date +%s`
  runtime=$((end-$START))
  echo ""
  echo "${0} completed in ${runtime} seconds"
}
#
# print error and exit
#
do_error() {
  echo ""
  echo "ERROR: ${1}"
  echo ""
  echo ""
  do_end
  exit 1
}
#
# upload cookbooks
# params 1 = working Directory
#        2 = array of cookbooks
#
do_cookbook_upload() {
  echo "Uploading cookbooks..."
  if [ ! -f $1/.chef/knife.rb ] ; then do_error "knife.rb doesn't exist" ; fi
  mkdir -p $1/cookbooks && cd $1/cookbooks
  #ckbks=(audit)
  for c in $2
  do
    # cookbooks
    if [ "$( knife cookbook list | grep $c )" == "" ]; then
      knife cookbook site download $c
      tar -xzvf $c*.tar.gz
      knife cookbook upload $c
    else
      echo "$c exists. Nothing to do here."
    fi
  done
  echo "Uploading Cookbooks complete."
}
#
# upload cookbooks
# params 1 = working Directory
#        2 = array of roles
#
do_roles_upload() {
  echo "Uploading Roles..."
  cd $1
  for r in $2
  do
    if [ ! -f $1/roles/$r ] ; then do_error "${r} does not exist." ; fi
    knife role from file $r
  done
  echo "Uploading Roles complete."
}

#
# append to /etc/hosts file
# params 1 = ip
#        2 = hostname/fqdn
add_host() {
  if [ -n "$(grep "$2" /etc/hosts)" ] ; then
    echo "$2, already exists";
  else
    echo "adding $2 to /etc/hosts";
    printf "%s\t%s\n" "$1" "$2" | sudo tee -a "/etc/hosts" > /dev/null;
  fi
}
#
# remove from /etc/hosts file
# params 1 = ip
#        2 = hostname/fqdn
remove_host() {
  if [ -n "$(grep "$1" /etc/hosts)" ] ; then
    echo "$1 found in /etc/hosts. Removing now..."
    if ! $2 ; then
      sudo sed -ie "/$1/d" "/etc/hosts"
    fi
  else
    echo "$1 was not found in /etc/hosts"
  fi
}
#
# test setup
#
do_infra_test() {
  echo "Begin testing setup..."
  # check for local setup
  if [ ! -f ${WKDIR}/.chef/knife.rb ] ; then do_error "knife.rb doesn't exist" ; fi
  # test for a functioning chef-server
  if [[ ! "$(vagrant ssh srvr -c 'hostname -f')" = *"chef-server.test"* ]] ; then do_error "chef-server setup not complete" ; fi
  # test for a functioning automate
  if [[ ! "$(vagrant ssh a2 -c 'hostname -f')" = *"automate-deployment.test"* ]] ; then do_error "automate setup not complete" ; fi
  # test for a validator client proving correct knife config and a working chef-server
  if [[ ! "$(knife client list)" = *"a2-validator"* ]] ; then do_error "a2-validator doesn't exist, something went wrong" ; fi
  echo "Testing complete."
}
