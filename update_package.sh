#!/bin/bash
set -eu

usage(){
  cat << EOF
  Usage: $0 [-h] [-s <ssh host>] [-u <app url>] [-l]

  -h             Display this help and exit

  -s <ssh host>  SSH address for the gear where the oo app is deployed.
                 (default: oo-install)

  -u <app url>   If specified overrides the deployed application URL in
                 generated packages (default: install.openshift.com).
                 This value is ignored if deploying to
                 oo-install.rhcloud.com.

  -l             Use local install script.  If not specified the
                 Enterprise install scripts are pulled from the official
                 github repos.
EOF
}

APP_URL=""
USE_LOCAL_SCRIPT=false
SSH_HOST="oo-install"

while getopts :hu:s:l option; do
  case $option in
    h)
      usage
      exit 1
      ;;
    s)
      SSH_HOST=$OPTARG
      ;;
    u)
      APP_URL=$OPTARG
      ;;
    l)
      USE_LOCAL_SCRIPT=true
      ;;
  esac
done

echo -e "\n\n#####################################################"
echo "Using ${SSH_HOST} as the SSH host"
echo -e "#####################################################\n\n"
sleep 5

if [ "x$APP_URL" == "x" ]; then
  echo 'Attempting to retrieve $OPENSHIFT_APP_DNS value from app...'
  app_url=$(ssh ${SSH_HOST} 'echo $OPENSHIFT_APP_DNS')

  if [ "x$app_url" == "x" ]; then
    echo 'Could not retrieve $OPENSHIFT_APP_DNS value from host'
    exit 1
  elif [ "$app_url" == "oo-install.rhcloud.com" ]; then
    APP_URL="install.openshift.com"
  else
    APP_URL=$app_url
  fi
fi

echo -e "\n\n#####################################################"
echo "Using ${APP_URL} as the application URL"
echo -e "#####################################################\n\n"
sleep 5

ARGS=""
if [ "x$APP_URL" != "x" ]; then
  ARGS="APP_URL='${APP_URL}'"
fi

if $USE_LOCAL_SCRIPT; then
  ARGS+=" USE_LOCAL_SCRIPT=1"
fi

echo "Generating packages for deployment..."
pushd ../openshift-extras/oo-install
bundle _1.3.5_ exec rake package $ARGS

popd

echo "Removing existing deployment files..."
ssh ${SSH_HOST} 'rm -rf app-root/data/*'

echo "Copying new deployment files to app..."
scp -r ../openshift-extras/oo-install/package/* ${SSH_HOST}:app-root/data/

echo "Restarting app..."
ssh ${SSH_HOST} 'gear restart --cart diy'

exit
