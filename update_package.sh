#!/bin/sh

cd ../openshift-extras/oo-install && bundle exec rake package
cd ../../oo/
scp -r ../openshift-extras/oo-install/package/* 527d40f55973cacf58000175@oo-install.rhcloud.com:/var/lib/openshift/527d40f55973cacf58000175/app-root/data/
ssh 527d40f55973cacf58000175@oo-install.rhcloud.com 'gear restart --cart diy'
exit
