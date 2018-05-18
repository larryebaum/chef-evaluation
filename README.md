Purpose: Stand up an Automate v2.0 evaluation environment
- Chef Automate v2.0
- Chef Server (Manage-less)
- X Nodes to Bootstrap and manage

`chef-infra` will create or download all the resources needed to
accomplish the setup.


Prereqs:
- Vitualbox (tested v5.2.12)
- vagrant (tested v2.1.1)
- vagrant box: bento/ubuntu-16.04
- vagrant box: archlinux/archlinux
- chefdk (tested v2.5.3)
- WWW Internet access
- Automate License key
- tested on MacBook Pro w/ 7GB free physical mem
- a2+chef+2 nodes used 5.2GB memory & 1GB on disk
!Warning! This is running a number of machines on a local environment.  As such,
it is a resource hog. Attention to available resources is advised.


Quick Start:
- Clone this repo and `cd a2-testing`
- Create ./automate.license with a valid Automate license. Otherwise, add it when logging in for the first time
- From the base directory run `chef-infra setup`
- Log in & Download 'DevSec Linux Security Baseline' from the Asset Store
- Look at `chef-infra -h` for more info & teardown instructions

Details:
- Step-by-step setup instructions are best viewed in the Vagrantfile `.vm.provision` sections
- Create/install a single node only: `vagrant up [a2|srvr|node1[n]]`
- Retry creation of a single node: `vagrant provision [a2|srvr|node1[n]]`

Development:
- TODO create Chef Workstation node
- TODO move chef-dk, .deb to ./bin
- TODO set node cnt in init.sh
- TODO cli cmd for loading profiles in automate
