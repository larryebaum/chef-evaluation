#!/bin/bash
# Author: Mike Tyler - mtyler - mtyler@chef.io
# Purpose: Stand up a builder service in conjunction with an
# Automate v2.0 evaluation environment

create_bldr_env() {
      cat > bldr.env <<EOL
#!/bin/bash
export APP_SSL_ENABLED=false
export APP_URL=http://192.168.33.197
export OAUTH_PROVIDER=github
export OAUTH_USERINFO_URL=https://api.github.com/user
export OAUTH_AUTHORIZE_URL=https://github.com/login/oauth/authorize
export OAUTH_TOKEN_URL=https://github.com/login/oauth/access_token
export OAUTH_REDIRECT_URL=
export OAUTH_CLIENT_ID=d8474196e3e6e920f30c
export OAUTH_CLIENT_SECRET=d264a51110dde67360f80bb7bfb16ad8ba2b9fb6
export BLDR_CHANNEL=on-prem-stable
EOL
}

git clone https://github.com/habitat-sh/on-prem-builder
cd on-prem-builder
create_bldr_env

## temporary work around for hab user/group creation failing
sed -i.bak -e '431,435d' scripts/provision.sh

sudo ./install.sh
