#!/bin/bash
if [ "x$WKDIR" = "x" ]; then
  export WKDIR=$PWD
fi
CI_CONTAINER_NAME='jenkinsci-blueocean'
CI_IMAGE='jenkinsci/blueocean'
DOT_CHEF_DIR='/var/chef/.chef'
docker run -u root --rm -d -p 8080:8080 -p 50000:50000 \
           --dns 192.168.1.1 \
           --add-host chef-server.test:192.168.33.200 \
           -v $WKDIR/.chef:/root/.altchef \
           -v jenkins-data:/var/jenkins_home \
           -v /var/run/docker.sock:/var/run/docker.sock \
           --name $CI_CONTAINER_NAME $CI_IMAGE
echo ""
echo "Jenkins startup password"
echo $(docker exec -it jenkinsci-blueocean cat /var/jenkins_home/secrets/initialAdminPassword)
