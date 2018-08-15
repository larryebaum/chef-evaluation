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
GITHUB_TOKEN="$(cat $WKDIR/github-token)"

##
## create an initialization script to create admin user and turn off startup wizard
## comment out this entire file inside the method (to avoid removing code) and then
## uncomment the block
create_basic-setup-groovy() {
    cat > $WKDIR$BUILD_CONTEXT/basic-setup.groovy <<EOL
#!groovy
//
// This script is generated by setup_jenkins
// it is meant to run during init on the Jenkins server to create a user

import hudson.security.*
import jenkins.model.*
//-------beg cp
import jenkins.branch.BranchProperty;
import jenkins.branch.BranchSource;
import jenkins.branch.DefaultBranchPropertyStrategy;
import jenkins.plugins.git.GitSCMSource;
import org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject;
// is needed // ----> import jenkins.model.Jenkins
// is needed // ----> def instance = Jenkins.getInstance()
//-------end cp

def out
def config = new HashMap()
def bindings = getBinding()
config.putAll(bindings.getVariables())
out = config['out']
out.println "--> Begin basic-setup.groovy"

def instance = Jenkins.getInstance()

out.println "--> creating local user '${ADMIN_USR}'"
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('${ADMIN_USR}', '${ADMIN_PWD}')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

//-- beg cp
def source = new GitSCMSource(null, "git://github.com/mtyler/chef-infra-base.git", "", "*", "", false)
def mp = instance.createProject(WorkflowMultiBranchProject.class, "chef-infra-base")
mp.getSourcesList().add(new BranchSource(source, new DefaultBranchPropertyStrategy(new BranchProperty[0])));
//BranchIndexing(mp,mp.getIndexing)
//mp.scheduleBuild2()
instance.getItemByFullName("chef-infra-base").scheduleBuild()
out.println "--> build scheduled"
//-- end cp

//// enable the use of jenkins-cli.jar
////instance.CLI.get().setEnabled(true)

instance.save()

out.println "--> instance saved"
EOL
}

##
## useful docs && commands for creating xml used to create jenkins objects
## credentials docs: https://github.com/jenkinsci/credentials-plugin/blob/master/docs/user.adoc
## java -jar jenkins-cli.jar -auth admin:pwd -s http://localhost:8080/ list-credentials user::user::admin
## java -jar jenkins-cli.jar -auth admin:pwd -s http://localhost:8080/ list-credentials-as-xml user::user::admin
## java -jar jenkins-cli.jar -auth admin:nimda -s http://localhost:8080/ get-credentials-domain-as-xml user::user::admin blueocean-github-domain
##
create_blueocean-github-domain() {
    cat > $WKDIR$BUILD_CONTEXT/blueocean-github-domain.xml <<EOL
    <com.cloudbees.plugins.credentials.domains.Domain plugin="credentials@2.1.18">
      <name>blueocean-github-domain</name>
      <description>blueocean-github-domain to store credentials by BlueOcean</description>
      <specifications>
        <io.jenkins.blueocean.rest.impl.pipeline.credential.BlueOceanDomainSpecification plugin="blueocean-pipeline-scm-api@1.7.1"/>
      </specifications>
    </com.cloudbees.plugins.credentials.domains.Domain>
EOL
}

create_github-credentials() {
cat > $WKDIR$BUILD_CONTEXT/github-credentials.xml <<EOL
      <com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
        <scope>USER</scope>
        <id>github</id>
        <description>GitHub Access Token</description>
        <username>admin</username>
        <password>${GITHUB_TOKEN}</password>
      </com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOL
}
## generate xml from existing project
## java -jar jenkins-cli.jar -auth admin:nimda -s http://localhost:8080 get-job chef-infra-base
##
create_job-config() {
cat > $WKDIR$BUILD_CONTEXT/job-config.xml <<EOL
<?xml version='1.1' encoding='UTF-8'?>
<org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject plugin="workflow-multibranch@2.20">
  <properties>
    <io.jenkins.blueocean.rest.impl.pipeline.credential.BlueOceanCredentialsProvider_-FolderPropertyImpl plugin="blueocean-pipeline-scm-api@1.7.1">
      <domain plugin="credentials@2.1.18">
        <name>blueocean-folder-credential-domain</name>
        <description>Blue Ocean Folder Credentials domain</description>
        <specifications/>
      </domain>
      <user>admin</user>
      <id>github</id>
    </io.jenkins.blueocean.rest.impl.pipeline.credential.BlueOceanCredentialsProvider_-FolderPropertyImpl>
  </properties>
  <folderViews class="jenkins.branch.MultiBranchProjectViewHolder" plugin="branch-api@2.0.20">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </folderViews>
  <healthMetrics>
    <com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric plugin="cloudbees-folder@6.5.1">
      <nonRecursive>false</nonRecursive>
    </com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
  </healthMetrics>
  <icon class="jenkins.branch.MetadataActionFolderIcon" plugin="branch-api@2.0.20">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </icon>
  <orphanedItemStrategy class="com.cloudbees.hudson.plugins.folder.computed.DefaultOrphanedItemStrategy" plugin="cloudbees-folder@6.5.1">
    <pruneDeadBranches>true</pruneDeadBranches>
    <daysToKeep>-1</daysToKeep>
    <numToKeep>-1</numToKeep>
  </orphanedItemStrategy>
  <triggers/>
  <disabled>false</disabled>
  <sources class="jenkins.branch.MultiBranchProject$BranchSourceList" plugin="branch-api@2.0.20">
    <data>
      <jenkins.branch.BranchSource>
        <source class="org.jenkinsci.plugins.github_branch_source.GitHubSCMSource" plugin="github-branch-source@2.3.6">
          <id>blueocean</id>
          <apiUri>https://api.github.com</apiUri>
          <credentialsId>github</credentialsId>
          <repoOwner>mtyler</repoOwner>
          <repository>chef-infra-base</repository>
          <traits>
            <org.jenkinsci.plugins.github__branch__source.BranchDiscoveryTrait>
              <strategyId>3</strategyId>
            </org.jenkinsci.plugins.github__branch__source.BranchDiscoveryTrait>
            <org.jenkinsci.plugins.github__branch__source.ForkPullRequestDiscoveryTrait>
              <strategyId>1</strategyId>
              <trust class="org.jenkinsci.plugins.github_branch_source.ForkPullRequestDiscoveryTrait$TrustPermission"/>
            </org.jenkinsci.plugins.github__branch__source.ForkPullRequestDiscoveryTrait>
            <org.jenkinsci.plugins.github__branch__source.OriginPullRequestDiscoveryTrait>
              <strategyId>1</strategyId>
            </org.jenkinsci.plugins.github__branch__source.OriginPullRequestDiscoveryTrait>
            <jenkins.plugins.git.traits.CleanBeforeCheckoutTrait plugin="git@3.9.1">
              <extension class="hudson.plugins.git.extensions.impl.CleanBeforeCheckout"/>
            </jenkins.plugins.git.traits.CleanBeforeCheckoutTrait>
            <jenkins.plugins.git.traits.CleanAfterCheckoutTrait plugin="git@3.9.1">
              <extension class="hudson.plugins.git.extensions.impl.CleanCheckout"/>
            </jenkins.plugins.git.traits.CleanAfterCheckoutTrait>
            <jenkins.plugins.git.traits.LocalBranchTrait plugin="git@3.9.1">
              <extension class="hudson.plugins.git.extensions.impl.LocalBranch">
                <localBranch>**</localBranch>
              </extension>
            </jenkins.plugins.git.traits.LocalBranchTrait>
          </traits>
        </source>
      </jenkins.branch.BranchSource>
    </data>
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
  </sources>
  <factory class="org.jenkinsci.plugins.workflow.multibranch.WorkflowBranchProjectFactory">
    <owner class="org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject" reference="../.."/>
    <scriptPath>Jenkinsfile</scriptPath>
  </factory>
</org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject>
EOL
}

##
## create files required for Docker build to copy to container
##
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

create_global-libraries() {
    cat > $WKDIR$BUILD_CONTEXT/org.jenkinsci.plugins.workflow.libs.GlobalLibraries.xml <<EOL
<?xml version='1.1' encoding='UTF-8'?>
<org.jenkinsci.plugins.workflow.libs.GlobalLibraries plugin="workflow-cps-global-lib@2.9">
  <libraries>
    <org.jenkinsci.plugins.workflow.libs.LibraryConfiguration>
      <name>jenkins-cookbook-library</name>
      <retriever class="org.jenkinsci.plugins.workflow.libs.SCMSourceRetriever">
        <scm class="org.jenkinsci.plugins.github_branch_source.GitHubSCMSource" plugin="github-branch-source@2.3.6">
          <id>b7c8fb5b-d375-4b72-96fa-0b80c9cf2023</id>
          <repoOwner>mtyler</repoOwner>
          <repository>jenkins-cookbook-library</repository>
          <traits>
            <org.jenkinsci.plugins.github__branch__source.BranchDiscoveryTrait>
              <strategyId>1</strategyId>
            </org.jenkinsci.plugins.github__branch__source.BranchDiscoveryTrait>
            <org.jenkinsci.plugins.github__branch__source.OriginPullRequestDiscoveryTrait>
              <strategyId>1</strategyId>
            </org.jenkinsci.plugins.github__branch__source.OriginPullRequestDiscoveryTrait>
            <org.jenkinsci.plugins.github__branch__source.ForkPullRequestDiscoveryTrait>
              <strategyId>1</strategyId>
              <trust class="org.jenkinsci.plugins.github_branch_source.ForkPullRequestDiscoveryTrait$TrustPermission"/>
            </org.jenkinsci.plugins.github__branch__source.ForkPullRequestDiscoveryTrait>
          </traits>
        </scm>
      </retriever>
      <defaultVersion>master</defaultVersion>
      <implicit>true</implicit>
      <allowVersionOverride>true</allowVersionOverride>
      <includeInChangesets>true</includeInChangesets>
    </org.jenkinsci.plugins.workflow.libs.LibraryConfiguration>
  </libraries>
</org.jenkinsci.plugins.workflow.libs.GlobalLibraries>
EOL
}
#
# copy knife and pem file to scripts to minimize the size of Docker build context
#
cp $WKDIR/.chef/cicdsvc-knife.rb $WKDIR$BUILD_CONTEXT/knife.rb
cp $WKDIR/.chef/cicdsvc.pem $WKDIR$BUILD_CONTEXT/client.pem

# ---------------------------------------------------------------------------
# cleanup any previous images and volumes
# uncomment this block to keep docker clean. helpful when running a lot
#
echo "calling docker stop $CI_CONTAINER_NAME..."
docker stop $CI_CONTAINER_NAME
docker rm -f $CI_CONTAINER_NAME
docker image prune -f
echo "calling docker volume rm $CONTAINER_VOLUME..."
docker volume rm $CONTAINER_VOLUME
#
# ---------------------------------------------------------------------------

# ---
# Begin working with a custom Dockerfile that should be in
# the same directory as this
#
create_basic-setup-groovy
create_last-exec-version
create_upgrade-wizard-state
create_location-configuration
create_global-libraries

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

##
## script needs to wait while server comes up and runs through it's initialization
##
for i in $(seq 1 10); do
  curl -u $ADMIN_USR:$ADMIN_USR -s http://localhost:8080/user/$ADMIN_USR
  if [ $? -eq 0 ]; then
    echo "$ADMIN_USR found."
    break
  fi
  echo "$ADMIN_USR not created retry in 3..."
  sleep 3
done
## if the admin user wasn't created
curl -u $ADMIN_USR:$ADMIN_USR -s http://localhost:8080/user/$ADMIN_USR
if [ $? -ne 0 ]; then
  echo "Error: $ADMIN_USR not created. Jenkins cannot be configured."
  echo "The server is probably up and accessible on http://localhost:8080/blue"
  echo "Pipelines will require manual configuation after logging in"
  exit 1
fi

while true; do
  # wait for service to be available
  ### if [ "$(curl -v --silent http://localhost:8080 2>&1 | grep 'Authentication required')" = "Authentication required" ]; then
  if [ "$(curl -v --silent http://localhost:8080 2>&1 | grep 'Connected to localhost')" = "Connected to localhost" ]; then
    echo "..."
    sleep 3
  else
    ## retry until jenkins-cli is available
    while true; do
      curl --fail http://localhost:8080/jnlpJars/jenkins-cli.jar --output jenkins-cli.jar 2>&1 \
      && break \
      || echo "Download failed for jenkins-cli.jar retrying..." \
      && sleep 3
    done
    echo "client downloaded..."
sleep 3
    if [ "x$GITHUB_TOKEN" = "x" ]; then
      echo "Github Access Token is not set, blueocean pipeline will need to be created manually.
            Be sure to create $WKDIR/secrets/github-token with a valid token.
            https://github.com/settings/tokens"
      exit 1
    else
      ## ----------------------------------------------------------------------
      ## Begin creating a github access token
      ## https://github.com/jenkinsci/credentials-plugin/blob/master/docs/user.adoc
      ##
      echo "Creating github credentials..."

## TODO replace these jenkins-cli commands with the blueocean rest calls
##  curl -v -u admin:admin -d '{"accessToken": boo"}' -H "Content-Type:application/json" -XPUT http://localhost:8080/jenkins/blue/rest/organizations/jenkins/scm/github/validate
## from: https://github.com/jenkinsci/blueocean-plugin/tree/master/blueocean-rest#multibranch-pipeline-api
## curl -v -u $ADMIN_USR:$ADMIN_PWD -d '{"accessToken": "$GITHUB_TOKEN"}' -H "Content-Type:application/json" -XPUT http://localhost:8080/jenkins/blue/rest/organizations/jenkins/scm/github/validate

      create_github-credentials
      create_blueocean-github-domain
      java -jar ./jenkins-cli.jar -s http://localhost:8080/ who-am-i --username $ADMIN_USR --password $ADMIN_PWD
      if [ $? -eq 0 ]; then echo "Connections successful!"; fi
#sleep 3
      java -jar ./jenkins-cli.jar -auth $ADMIN_USR:$ADMIN_PWD -s http://localhost:8080/ create-credentials-domain-by-xml user::user::$ADMIN_USR < $WKDIR$BUILD_CONTEXT/blueocean-github-domain.xml
      if [ $? -eq 0 ]; then echo "Domain created!"; fi
#sleep 3
      java -jar ./jenkins-cli.jar -auth $ADMIN_USR:$ADMIN_PWD -s http://localhost:8080/ create-credentials-by-xml user::user::$ADMIN_USR blueocean-github-domain < $WKDIR$BUILD_CONTEXT/github-credentials.xml
      if [ $? -eq 0 ]; then echo "Github Access Token added!"; fi
#sleep 3
      ##
      ## End creating github access token
      ## ----------------------------------------------------------------------

      ## ----------------------------------------------------------------------
      ## Begin creating a job
      echo "Creating piplines..."
    ##  java -jar jenkins-cli.jar -auth $ADMIN_USR:$ADMIN_PWD -s http://localhost:8080 create-job chef-infra-base < $WKDIR/scripts/config.xml
      echo "Pipeline created."
##sleep 3
      #java -jar jenkins-cli.jar -auth $ADMIN_USR:$ADMIN_PWD -s http://localhost:8080/ build chef-infra-base/master
      ## End creating job
      ## ----------------------------------------------------------------------
    fi
    echo "Jenkins started on localhost:8080"
    echo "Startup credentials user: $ADMIN_USR pwd: $ADMIN_PWD"
    break
  fi
done

exit 0
