#!/bin/sh

ARGS=""
if [ -n "$1" ]; then
  ARGS="APP_URL='$1'"
fi

cd ../openshift-extras/oo-install && bundle exec rake package $ARGS
cd ../../oo/
ssh oo-install 'rm -rf $OPENSHIFT_DATA_DIR/*'
scp -r ../openshift-extras/oo-install/package/* oo-install:/var/lib/openshift/${OO_APP_USER}/app-root/data/
ssh oo-install 'gear restart --cart diy'
exit
