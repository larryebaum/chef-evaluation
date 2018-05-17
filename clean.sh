#!/bin/bash

#
# helper functions
#
remove() {
  if [ -n "$(grep "$1" /etc/hosts)" ]; then
    echo "$1 found in /etc/hosts. Removing now..."
    if ! $2 ; then
      sudo sed -ie "/$1/d" "/etc/hosts"
    fi
  else
    echo "$1 was not found in /etc/hosts"
  fi
}

usage() {
  echo "Usage: $0 [-f|--full] [-p|--pretend] [-y|--yes] [-h|--help]"
  echo " "
  echo "Removes files and objects created"
  echo "options:"
  echo "-h,--help    show this message"
  echo "-p,--pretend just list what will be done"
  echo "-f,--full    Remove .deb packages. The process downloads and creates .deb"
  echo "             packages. For convienience and speed, these are not removed"
  echo "             by default."
  echo "-y,--yes     answer yes to all prompts"; exit 1;
}

# initalize flags
is_full=false
is_yes=false
is_pre=false

for i in "$@"
do
case $i in
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

if $is_pre ; then echo "-p specified. Only printing actions of this script..." ; fi

remove automate-deployment.test $is_pre
remove chef-server.test $is_pre
#TODO remove nodeX.test

if $is_full ; then
  echo "clear contents of add.license.etc..."
  echo "delete binaries ./chef-dk, *.deb..."
  if ! $is_pre ; then
    echo "UNCOMMENT AFTER CONFIDENT IN -p"
# file containing automate license
#cp automate.license ./removing
#echo "" > automate.license
# directory containing compiled archlinux chef-dk package
#mv ./chef-dk ./removing
#mv *.deb ./removing
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
