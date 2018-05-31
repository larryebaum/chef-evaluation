#!/bin/bash
# Author: Mike Tyler - mtyler - mtyler@chef.io
# Purpose: helper functions


#
# print start and record to print elapsed time
START=0
#
do_start() {
  START=`date +%s`
  echo "Running ${0}..."
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
