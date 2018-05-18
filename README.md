Purpose: Stand up an Automate v2.0 evaluation environment
- Chef Automate v2.0
- Chef Server (Manage-less)
- X Nodes to Bootstrap and manage

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
- chefdk (tested v2.5.3)

Quick Start:
- Clone this repo and `cd a2-testing` 
- Create ./automate.license with a valid Automate license. Otherwise, add it when logging in for the first time
- From the base directory run `./chef-infra.sh setup`
- Log in & Download 'DevSec Linux Security Baseline' from the Asset Store

- look at `./chef-infra.sh -h` for more info & teardown instructions

* For setup details see the step-by-step setup instructions in the Vagrantfile .vm.provision sections

create/install a single node only
- vagrant up [a2|srvr|node1[n]]

retry creation of a single node
- vagrant provision [a2|srvr|node1[n]]


#TODO set node cnt in init.sh
#TODO find a way
