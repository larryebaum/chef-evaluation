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
#if [ -f $WKDIR/.chef/cicdsvc.pem ];
#then
#  docker exec -it $CI_CONTAINER_NAME mkdir -p $DOT_CHEF_DIR
#  docker cp $WKDIR/.chef/cicdsvc.pem $CI_CONTAINER_NAME:$DOT_CHEF_DIR
#  docker cp $WKDIR/.chef/a2-validator.pem $CI_CONTAINER_NAME:$DOT_CHEF_DIR
#  docker cp $WKDIR/.chef/knife.rb $CI_CONTAINER_NAME:$DOT_CHEF_DIR
#  docker exec -it $CI_CONTAINER_NAME sed -i 's/admin/cicdsvc/g' $DOT_CHEF_DIR/knife.rb
#  #docker exec -it $CI_CONTAINER_NAME /bin/sh -c "echo 192.168.33.198 chef-server.test >> /etc/hosts"
#  #docker exec -it $CI_CONTAINER_NAME /bin/sh -c "echo 192.168.33.200 chef-server.test > /home/jenkins/.chef/etc_hosts"
#  #docker exec -it $CI_CONTAINER_NAME chown -R jenkins:jenkins /home/jenkins
#else
#  echo "cicdsvc.pem does not exist. Should have been created by chef-infra setup"
#fi
echo ""
echo "Jenkins startup password"
echo $(docker exec -it jenkinsci-blueocean cat /var/jenkins_home/secrets/initialAdminPassword)

# temporary github access_token
# 15f2dd374ab58397c17083f61b5dca53f2767227
