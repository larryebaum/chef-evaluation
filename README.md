Purpose: Stand up an Automate v2.0 evaluation environment
Chef Automate v2.0
Chef Server
X Nodes to Bootstrap and manage

* !!SPECIAL NOTE!!
This is running a number of machines on a local environment.  As such,
it will be memory intensive.  Ensure you have the available resources
before running
(tested on MacBook w/ 7GB free physical mem)

Prereqs:
- Vitualbox (tested v5.2.12)
- vagrant (tested v2.1.1)
- vagrant box: bento/ubuntu-16.04
- vagrant box: archlinux/archlinux

Quick Start:
- Clone this repo and `cd` into it
- Edit add.license.key.tothis.before.init and add a valid a2 license key
- Make files executable `sudo chmod x+ *sh`
- From the base directory run `./init.sh`
- Once complete, navigate to https:://automate-deployment.test
- Retrieve a2 temp pwd: `vagrant ssh a2` then `sudo ./chef-automate config show | grep 'password'`
- user: admin


* For more details see the step-by-step setup instructions in the Vagrantfile .vm.provision sections

create/install a2 only
- vagrant up a2

create/install Chef Server only
- vagrant up srvr

configure knife/workstation
- see init.sh

create/bootstrap fleet only
- vagrant up node*

#TODO set node cnt in init.sh
