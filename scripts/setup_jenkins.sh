#!/bin/bash
if [ "x$WKDIR" = "x" ]; then
  export WKDIR=$PWD
fi
CI_CONTAINER_NAME='blueocean'
CI_IMAGE='mtyler/blueocean'
CONTAINER_VOLUME='jenkins-data'
DOT_CHEF_DIR='/var/chef/.chef'
BUILD_CONTEXT='/scripts'

#
# copy knife and pem file to scripts to minimize the size of Docker build context
#
cp $WKDIR/.chef/cicdsvc-knife.rb $WKDIR$BUILD_CONTEXT
cp $WKDIR/.chef/cicdsvc.pem $WKDIR$BUILD_CONTEXT

# ensure previous images are stopped
echo "calling docker stop $CI_CONTAINER_NAME..."
docker stop $CI_CONTAINER_NAME > /dev/null 2>&1
echo "calling docker volume rm $CONTAINER_VOLUME..."

# ---
# working with a custom dockerfile
#
echo "calling docker build -t $CI_IMAGE"
docker build -t $CI_IMAGE \
             --build-arg KNIFE_RB=cicdsvc-knife.rb \
             --build-arg CLIENT_KEY=cicdsvc.pem \
             $WKDIR$BUILD_CONTEXT

if [ ! $? -eq 0 ]; then
  echo ""
  echo "Error: Docker build failed"
  exit 1
fi

echo "calling docker run..."
docker run -u root --rm -d -p 8080:8080 -p 50000:50000 \
           --dns 192.168.1.1 \
           --add-host chef-server.test:192.168.33.200 \
           -v $CONTAINER_VOLUME:/var/jenkins_home \
           -v /var/run/docker.sock:/var/run/docker.sock \
           --name $CI_CONTAINER_NAME $CI_IMAGE

if [ ! $? -eq 0 ]; then
  echo ""
  echo "Error: Docker run failed"
  exit 1
fi



#### TODO add github token directly to cat ./users/admin/config.xml
#### TODO If docker run fails, exit
####
#docker run -u root --rm -d -p 8080:8080 -p 50000:50000 \
#           --dns 192.168.1.1 \
#           --add-host chef-server.test:192.168.33.200 \
#           -v $WKDIR/.chef:/root/.altchef \
#           -v jenkins-data:/var/jenkins_home \
#           -v /var/run/docker.sock:/var/run/docker.sock \
#           --name $CI_CONTAINER_NAME $CI_IMAGE

# -----------------------
#
# working before Dockefile intro
#
#docker run -u root --rm -d -p 8080:8080 -p 50000:50000 \
#           --dns 192.168.1.1 \
#           --add-host chef-server.test:192.168.33.200 \
#           -v $WKDIR/.chef:/root/.altchef \
#           -v jenkins-data:/var/jenkins_home \
#           -v /var/run/docker.sock:/var/run/docker.sock \
#           --name $CI_CONTAINER_NAME $CI_IMAGE
# -----------------------

#
# wait for the service to be available before moving on
#
echo ""
echo "Jenkins starting..."
while true; do
  docker exec -it $CI_CONTAINER_NAME cat /var/jenkins_home/secrets/initialAdminPassword > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Jenkins started on http://localhost:8080"
    echo "Startup password is:"
    echo $(docker exec -it "$CI_CONTAINER_NAME" cat /var/jenkins_home/secrets/initialAdminPassword)
    break
  else
    echo "..."
    sleep 3
  fi
done
