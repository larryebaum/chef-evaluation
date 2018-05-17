Purpose: Stand up an Automate v2.0 evaluation environment
Chef Automate v2.0
Chef Server
X Nodes to Bootstrap and manage

This script will create and download all the files needed to
accomplish the setup.

* !!SPECIAL NOTE!!
This is running a number of machines on a local environment.  As such,
it will be memory intensive.  Ensure you have the available resources
before running
(tested on MacBook w/ 7GB free physical mem)
(a2+chef+2 nodes requires a minimum of 5.2GB memory & 1GB on disk)

Prereqs:
- Vitualbox (tested v5.2.12)
- vagrant (tested v2.1.1)
- vagrant box: bento/ubuntu-16.04
- vagrant box: archlinux/archlinux

Quick Start:
- Clone this repo and `cd` into it
- If you have a license, Create ./automate.license and add valid Automate license. Otherwise, skip this, it can be added later.
- Make files executable `sudo chmod x+ chef-infra.sh`
- From the base directory run `./chef-infra.sh`


* For setup details see the step-by-step setup instructions in the Vagrantfile .vm.provision sections

create/install a2 only
- vagrant up a2

create/install Chef Server only
- vagrant up srvr

create/bootstrap fleet only
- vagrant up node*

#TODO set node cnt in init.sh
