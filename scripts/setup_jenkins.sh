#!/bin/bash
if [ "x$WKDIR" = "x" ]; then
  export WKDIR=$PWD
fi
CI_CONTAINER_NAME="blueocean"
CI_IMAGE="mtyler/blueocean"
CONTAINER_VOLUME="jenkins-data"
DOT_CHEF_DIR="/var/chef/.chef"
BUILD_CONTEXT="/scripts"
JENKINS_HOME="/var/jenkins_home"
ADMIN_USR="admin"
ADMIN_PWD="nimda"


#
# create an initialization script to create admin user and turn off startup wizard
#
create_basic-setup-groovy() {
    cat > $WKDIR$BUILD_CONTEXT/basic-setup.groovy <<EOL
#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstance()

println "--> creating local user '${ADMIN_USR}'"
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('${ADMIN_USR}', '${ADMIN_PWD}')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()
EOL
}

create_last-exec-version() {
    cat > $WKDIR$BUILD_CONTEXT/jenkins.install.InstallUtil.lastExecVersion <<EOL
2.121.2
EOL
}

create_upgrade-wizard-state() {
    cat > $WKDIR$BUILD_CONTEXT/jenkins.install.UpgradeWizard.state <<EOL
2.121.2
EOL
}

create_location-configuration() {
    cat > $WKDIR$BUILD_CONTEXT/jenkins.model.JenkinsLocationConfiguration.xml <<EOL
<?xml version='1.1' encoding='UTF-8'?>
<jenkins.model.JenkinsLocationConfiguration>
 <jenkinsUrl>http://localhost:8080/</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration>
EOL
}

open_url() {
  URL=$1
  [[ -x $BROWSER ]] && exec "$BROWSER" "$URL"
  path=$(which xdg-open || which gnome-open) && exec "$path" "$URL"
  echo "Can't find browser"
}
#
# copy knife and pem file to scripts to minimize the size of Docker build context
#
cp $WKDIR/.chef/cicdsvc-knife.rb $WKDIR$BUILD_CONTEXT/knife.rb
cp $WKDIR/.chef/cicdsvc.pem $WKDIR$BUILD_CONTEXT/client.pem

# ensure previous images are stopped
echo "calling docker stop $CI_CONTAINER_NAME..."
docker stop $CI_CONTAINER_NAME
echo "calling docker volume rm $CONTAINER_VOLUME..."
docker volume rm $CONTAINER_VOLUME
# ---
# working with a custom dockerfile
#

create_basic-setup-groovy
create_last-exec-version
create_upgrade-wizard-state
create_location-configuration

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
           -v $CONTAINER_VOLUME:$JENKINS_HOME \
           -v /var/run/docker.sock:/var/run/docker.sock \
           --name $CI_CONTAINER_NAME $CI_IMAGE

if [ ! $? -eq 0 ]; then
  echo ""
  echo "Error: Docker run failed"
  exit 1
fi


#
# running this will generate a list of installed plugins
# for f in $(ls -1 /var/jenkins_home/plugins | grep -v jpi); do echo $f:$(cat $f.jpi.version_from_image)>> plugins.txt; done
#

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

## --------------------------------------------------------------------
## Uncomment this while block to only start the container.
## the startup token will be printed to the console when it's available.
##
#echo ""
#echo "Jenkins starting..."
#while true; do
#  # wait for unlock token to be available
#  docker exec -it $CI_CONTAINER_NAME cat $JENKINS_HOME/secrets/initialAdminPassword > /dev/null 2>&1
#  if [ $? -eq 0 ]; then
#    echo "Jenkins started on http://localhost:8080"
#    echo "Startup password is:"
#    echo $(docker exec -it "$CI_CONTAINER_NAME" cat $JENKINS_HOME/secrets/initialAdminPassword)
#    break
#  else
#    echo "..."
#    sleep 3
#  fi
#done
##
## End of commented functionality
## ----------------------------------------------------------------------


#while true; do
#  # wait for service to be available
#  if [ "$(curl -v --silent http://localhost:8080 2>&1 | grep 'Authentication required')" = "Authentication required" ]; then
##    pwd=$(docker exec -it "$CI_CONTAINER_NAME" cat $JENKINS_HOME/secrets/initialAdminPassword)
##    echo "Jenkins token set $pwd"
#
#    # create files to deactivate the setup wizard
#    docker exec -it $CI_CONTAINER_NAME echo "2.121.2" > $JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion
#    docker exec -it $CI_CONTAINER_NAME echo "2.121.2" > $JENKINS_HOME/jenkins.install.UpgradeWizard.state
#    docker exec -it $CI_CONTAINER_NAME echo "<?xml version='1.1' encoding='UTF-8'?><jenkins.model.JenkinsLocationConfiguration><jenkinsUrl>http://localhost:8080/</jenkinsUrl></jenkins.model.JenkinsLocationConfiguration>" > $JENKINS_HOME/jenkins.model.JenkinsLocationConfiguration.xml
#
#    echo "Jenkins started.  Restarting container to apply initialization script..."
#    docker restart $CI_CONTAINER_NAME
#
#    if [ ! $? -eq 0 ]; then
#      echo ""
#      echo "Error: Docker restart failed"
#      exit 1
#    fi

    # give the service a moment
    # install plugins
    # docker exec -it "$CI_CONTAINER_NAME" /usr/local/bin/install-plugins.sh < $JENKINS_HOME/plugins.txt
    # create admin user
    # docker exec -u jenkins -it "$CI_CONTAINER_NAME" echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("$ADMIN_USR", "$ADMIN_PWD")' | java -jar $JENKINS_HOME/war/WEB-INF/jenkins-cli.jar -auth admin:$pwd -s http://172.17.0.1:8080/ groovy =
    # disable startup wizard
    # docker exec -u jenkins -it "$CI_CONTAINER_NAME" echo 'jenkins.install.InstallState.INITIAL_SETUP_COMPLETED.initializeState()' | java -jar $JENKINS_HOME/war/WEB-INF/jenkins-cli.jar -auth $ADMIN_USR:$ADMIN_PWD -s http://172.17.0.1:8080/ groovy =

    # run commands locally for initial server setup
#    curl http://localhost:8080/jnlpJars/jenkins-cli.jar --output jenkins-cli.jar
#    echo "client downloaded..."
#    java -jar ./jenkins-cli.jar -auth admin:$pwd -s http://localhost:8080/ groovy 'jenkins.model.Jenkins.instance.securityRealm.createAccount("$ADMIN_USR", "$ADMIN_PWD")'
##    echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("$ADMIN_USR", "$ADMIN_PWD")' | java -jar ./jenkins-cli.jar -auth admin:$pwd -s http://localhost:8080/ groovy =
#    echo "user created..."
#    # disable startup wizard
#    echo 'jenkins.install.InstallState.INITIAL_SETUP_COMPLETED.initializeState()' | java -jar ./jenkins-cli.jar -auth $ADMIN_USR:$ADMIN_PWD -s http://localhost:8080/ groovy =
#    echo "wizard turned off..."
#    echo "Jenkins started on localhost:8080"
#    echo "Startup credentials are: $ADMIN_USR/$ADMIN_PWD"
#    break
#  else
#    echo "...  ..."
#    sleep 3
#  fi
#done

# we're done here, open up the browser
open_url 'http://localhost:8080/blue'
exit 0
