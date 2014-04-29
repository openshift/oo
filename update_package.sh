#!/bin/bash

usage(){
  cat << EOF
  Usage: $0 [-h] [-u <app url>] [-l]

  -h             Display this help and exit

  -u <app url>   If specified overrides the deployed application URL in 
                 generated packages (default: install.openshift.com).

  -l             Use local install script.  If not specified the
                 Enterprise install scripts are pulled from the official
                 github repos.
EOF
}

APP_URL=""
USE_LOCAL_SCRIPT=false

while getopts :hu:l option; do
  case $option in
    h) 
      usage
      exit 1
      ;;
    u) 
      APP_URL=$OPTARG
      ;;
    l)
      USE_LOCAL_SCRIPT=true
      ;;
  esac
done

ARGS=""
if [ "x$APP_URL" != "x" ]; then
  ARGS="APP_URL='${APP_URL}'"
fi

if $USE_LOCAL_SCRIPT; then
  ARGS+=" USE_LOCAL_SCRIPT=1"
fi

cd ../openshift-extras/oo-install && bundle exec rake package $ARGS
cd ../../oo/
ssh oo-install 'rm -rf $OPENSHIFT_DATA_DIR/*'
scp -r ../openshift-extras/oo-install/package/* oo-install:/var/lib/openshift/${OO_APP_USER}/app-root/data/
ssh oo-install 'gear restart --cart diy'
exit
