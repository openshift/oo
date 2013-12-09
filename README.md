# oo-install.rhcloud.com
This code base serves the `oo-install.rhcloud.com` application, better known as [install.openshift.com](https://install.openshift.com/).

## How It Works
The DIY app itself is very simple; it serves the contents of `$OPENSHIFT_DATA_DIR` using a low-tech WEBrick web server. If the user agent is `curl`, the server returns the installer bootstrap that is appropriate to the requested package. If the user agent is anything else, the server returns the landing page.

## How to Update the Site Contents
The web server logic for the `oo` application lives in this codebase. However, the files that are served by the app are stored in `$OPENSHIFT_DATA_DIR`. The site contents are repackaged and pushed to the `oo` application gear using the `update_package.sh` script that is part of this application.

1. Make sure that the `oo` repo is cloned into the same directory as the [openshift-extras](https://github.com/openshift/openshift-extras) repo.
2. `cd` into the `oo` directory.
3. Run `./update_package.sh`

Under normal circumstances, this will be sufficient to update the `oo` application with the latest complete set of `oo-install` distribution files.

## How to Change the Site Contents
If you examine the contents of `update_package.sh`, you will see that all of the heavy lifting is actually being done in the `openshift-extras` repo. The update script simply calls the "package" rake task from `openshift-extras/oo-install/Rakefile`, replaces the old site contents with the new, and then restarts the `oo` application. Therefore, any major changes to organization of the installer site must be performed in the installer's own Rakefile.