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

# Intall dependencies
if service --status-all | grep -Fq 'openntpd'; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=openntpd bash
    echo "server ${RELENG_NTP_SERVER}" | sudo tee /etc/openntpd/ntpd.conf
fi
sudo systemctl start openntpd
sudo systemctl enable openntpd
