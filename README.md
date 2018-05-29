Purpose: Stand up an Automate v2.0 evaluation environment (aka: YACv?, Yet Another Chef server setup)
- Chef Automate v2.0
- Chef Server (Manage-less)
- X Nodes to Bootstrap and manage

`chef-infra` is a bash script that will create or download all the resources needed to
setup an evaluation of the Chef Infrastructure.


Prereqs:
- Vitualbox (tested v5.2.12)
- vagrant (tested v2.1.1)
- vagrant box: bento/ubuntu-16.04
- chefdk (tested v2.5.3)
- WWW Internet access
- Automate License key
- tested on MacBook Pro w/ 7GB free physical mem
- a2+chef+2 nodes used 4GB memory & 1GB on disk


!Warning! This is running a number of machines on a local environment.  As such,
it is a resource hog. Attention to available resources is advised.


Quick Start:
- Clone this repo and `cd chef-evaluation`
- Create ./automate.license with a valid Automate license. Otherwise, add it when logging in for the first time
- From the base directory run `chef-infra setup`
- Log in instructions are printed to the terminal
- Look at `chef-infra -h` for more info & teardown instructions



Details:
Ideally, `chef-infra setup` will "just work" and give you everything required.  However, this isn't a perfect world.  If things don't work here are a few things to try.
1. Did a2 converge w/out error? Does ./a2-token exist? If no, try `vagrant provision a2`
1. Did srvr converge w/out error? Does ./.chef/admin.pem exist? If no, try `vagrant provision srvr`
1. Did nodeX converge w/out error? If no, check status of a2 and srvr.  Try `knife ssl fetch && knife cookbook upload audit && knife role from file base.rb`.  Was the DevSec profile added to Automate? If no, log in and do that.

- Step-by-step setup instructions are best viewed in the Vagrantfile `.vm.provision` sections
- Create/install a single node only: `vagrant up [a2|srvr|node1[n]]`
- Retry creation of a single node: `vagrant provision [a2|srvr|node1[n]]`

Development:
- TODO create Chef Workstation node
- TODO evaluate hab chef-server & chef-client
- TODO snapshot/recover functionality
