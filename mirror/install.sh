#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o xtrace
set -o errexit
set -o nounset

# Install dependencies
pkgs=""
for pkg in docker skopeo docker-compose; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
fi

if [ "${RELENG_KOLLA_BUILD:-false}" == "true" ]; then
    pip install -r requirements.txt

    # Configure custom values
    sudo mkdir -p /etc/kolla
    sudo cp ./kolla/kolla-build.ini /etc/kolla/kolla-build.ini
    sudo sed -i "s/^tag = .*$/tag = ${OPENSTACK_TAG:-wallaby}/g" /etc/kolla/kolla-build.ini
    sudo sed -i "s/^profile = .*$/profile = ${OS_KOLLA_PROFILE:-custom}/g" /etc/kolla/kolla-build.ini
    sudo sed -i "s/^#openstack_release = .*$/openstack_release = \"${OPENSTACK_RELEASE:-wallaby}\"/g" /etc/kolla/kolla-build.ini
fi
