# Chef Evaluation
## Purpose: Stand up an Automate v2.0 evaluation environment (aka: YACv?, Yet Another Chef server setup)
- Chef Automate v2.0
- Chef Server (Manage-less)
- X Nodes to Bootstrap and manage

`chef-infra` is a bash script that will create or download all the resources needed to
setup an evaluation of the Chef Infrastructure. For a production scenario, cookbooks and
the Chef DSL should be used. bash was used here to make getting started consumable
by humans that may be new to Chef and/or automation.

### Prereqs:
- [Vitualbox](https://www.virtualbox.org/wiki/Downloads) (tested v5.2.12)
- [vagrant](https://www.vagrantup.com/downloads.html) (tested => v2.1.1)
- [chefdk](https://downloads.chef.io/chefdk/3.0.36) (tested v2.5.3)
- tested on MacBook Pro w/ 7GB free physical mem where a2+chef+2 nodes used 4GB memory & 1GB on disk

_!Warning! This is running a number of machines on a local environment.  As such,
it is a resource hog. Attention to available resources is advised._

## Quick Start:
- Clone this repo and `cd chef-evaluation`
- Create ./automate.license with a valid Automate license. Otherwise, add it when logging in for the first time
- From the base directory run `chef-infra setup`
- Instructions for logging in are printed to the terminal when setup is complete
- Look at `chef-infra -h` for more info & teardown instructions

### Troubleshooting:
Ideally, `chef-infra setup` will "just work" and give you everything required.  However, this isn't a perfect world.  If things don't work here are a few things to try.
1. View automate logs `chef-infra log`
1. Did a2 converge w/out error? Does ./a2-token exist? If no, try `vagrant provision a2`
1. Did srvr converge w/out error? Does ./.chef/admin.pem exist? If no, try `vagrant provision srvr`
1. Did nodeX converge w/out error? If no, check status of a2 and srvr.  Try `knife ssl fetch && knife cookbook upload audit && knife role from file base.rb`.  Was the DevSec profile added to Automate? If no, log in and do that.

### Manage nodes
- Create/install a single node only: `vagrant up [a2|srvr|node1[n]]`
- Retry creation of a single node: `vagrant provision [a2|srvr|node1[n]]`

---
## Chef Workstation:
[Chef Workstation](https://www.chef.sh/about/chef-workstation/) is a single package with a lot of helpful tools. Adding the `-w` option will include a Chef Workstation in the setup
- `chef-infra setup -w`

---
## Habitat on-prem Builder:
Habitat Builder can be included in the setup with the `-b` option.  [Habitat Builder](https://www.habitat.sh/docs/using-builder/) is also available in the inter-cloud.
- `chef-infra setup -b`

---
## CICD pipeline:
Adding the `-p` option to the setup command will create a Jenkins Blueocean instance.  Note: This requires Docker and currently some manual setup.  
- `chef-infra setup -p` once that completes, continue.
- To get the activation key run `docker exec -it jenkinsci-blueocean cat /var/jenkins_home/secrets/initialAdminPassword`
- Once up, navigate to http://localhost:8080/blue
- Follow instructions and install all recommended plugins.
- In Github, Fork the repo https://github.com/mtyler/chef-infra-base
- Create a github access token:
  - In github, top right click your avatar > Settings > Developer Settings > Personal Access Settings.
  - Generate a new token with Full control of Repo, User:email
  - Use this token to create a pipeline for your newly forked repo     

---

### Patterns:
- Bootstrap during provisioning: scripts/setup_node.sh
- Backup: see `chef-infra do_backup()`

### Development:
- TODO habichef pipeline
- TODO add windows node

### Contributions Welcome and encouraged.  Ways to contribute:
- Open an issue: https://github.com/mtyler/chef-evaluation/issues
- Submit a PR: clone the repo, create a branch, make the change, submit
