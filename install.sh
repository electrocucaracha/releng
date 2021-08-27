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
set -o errexit
set -o nounset
if [[ "${RELENG_DEBUG:-false}" == "true" ]]; then
    set -o xtrace
    export PKG_DEBUG=true
fi

# Install dependencies
pkgs=""
for pkg in pip jq; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if ! systemctl list-unit-files | grep -q "openntpd.*enabled"; then
    pkgs+=" openntpd"
fi
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
fi
echo "server ${RELENG_NTP_SERVER}" | sudo tee /etc/openntpd/ntpd.conf
sudo systemctl start openntpd
sudo systemctl enable openntpd

# Configure pip mirror
mkdir -p "$HOME/.pip/"
cat <<EOL > "$HOME/.pip/pip.conf"
[global]
trusted-host = $RELENG_DEVPI_HOST
index-url = http://$RELENG_DEVPI_HOST:3141/root/pypi/+simple/

[search]
index = http://$RELENG_DEVPI_HOST:3141/root/pypi
EOL
