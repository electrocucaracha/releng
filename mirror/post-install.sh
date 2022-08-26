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
if [[ ${RELENG_DEBUG:-false} == "true" ]]; then
    set -o xtrace
fi

sudo tee /etc/systemd/system/docker-compose-mirror.service <<EOF >/dev/null
[Unit]
Description=Docker Compose Mirror Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
Environment="MIRROR_FILENAME=${MIRROR_FILENAME}"
WorkingDirectory=$(pwd)
ExecStart=$(command -v docker-compose) up -d
ExecStop=$(command -v docker-compose) down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start docker-compose-mirror.service
sudo systemctl enable docker-compose-mirror.service
