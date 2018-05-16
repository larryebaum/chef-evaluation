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
  echo "-f,--full    cleanup reusable compiled binaries and license file"
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
  echo "delete ./chef-dk..."
  if ! $is_pre ; then
    echo "UNCOMMENT AFTER CONFIDENT IN -p"
# file containing automate license
#cp add.license.key.tothis.before.init ./removing
#echo "" > add.license.key.tothis.before.init
# directory containing compiled archlinux chef-dk package
#mv ./chef-dk ./removing
  fi
fi

echo "create temporary removing dir..."
if ! $is_pre ; then mkdir removing; fi
echo "remove token files..."
if ! $is_pre ; then
  mv a2-token ./removing
  mv srvr-token ./removing
fi
echo "remove files from .chef..."
if ! $is_pre ; then
  mv ./.chef/cache ./removing
  mv ./.chef/syntaxcache ./removing
  mv ./.chef/trusted_certs ./removing
  mv ./.chef/*.pem ./removing
fi
echo "remove chef-dk.tar.gz..."
if ! $is_pre ; then mv ./chef-dk.tar.gz ./removing ; fi
echo "remove ./cookbooks dir..."
if ! $is_pre ; then mv ./cookbooks ./removing/cookbooks ; fi

# make sure user really wants to delete
while true; do
    read -p "Do you want to clean up? (y/n)" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* )
          echo "The response was not affirmative. stopping now."
          if ! $is_pre ; then echo "Recovery can be done manually by moving files out of ./removing" ; fi
          exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "vagrant destroy -f removing these vms..."
vagrant status > /dev/tty
if ! $is_pre ; then vagrant destroy -f ; fi
echo "remove ./vagrant dir..."
if ! $is_pre ; then mv ./.vagrant ./removing/.vagrant ; fi
echo "nuke the temporary ./removing dir..."
if ! $is_pre ; then rm -rf ./removing ; fi

echo " "
echo "done. Thanks for playing... :)"
