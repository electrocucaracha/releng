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

sudo systemctl stop systemd-resolved
if [ -f /etc/resolv.conf ]; then
    echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
fi
sudo "$(command -v docker-compose)" up -d
