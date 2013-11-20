#!/bin/sh

cd ../openshift-extras/oo-install && bundle exec rake package
cd ../../oo/
ssh 527d40f55973cacf58000175@oo-install.rhcloud.com 'rm -rf $OPENSHIFT_DATA_DIR/*'
scp -r ../openshift-extras/oo-install/package/* 527d40f55973cacf58000175@oo-install.rhcloud.com:/var/lib/openshift/527d40f55973cacf58000175/app-root/data/
ssh 527d40f55973cacf58000175@oo-install.rhcloud.com 'gear restart --cart diy'
exit
