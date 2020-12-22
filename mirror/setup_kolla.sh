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

if [ "${RELENG_KOLLA_BUID:-false}" == "true" ]; then
    SNAP=$HOME/.local/ kolla-build --config-file /etc/kolla/kolla-build.ini | jq "." | tee "$HOME/output.json"
    if [[ $(jq  '.failed | length ' "$HOME/output.json") != 0 ]]; then
        jq  '.failed[].name' "$HOME/output.json"
        exit 1
    fi
else
    while IFS= read -r image; do
        image_name="${image#*/}"
        if [ "$(curl "http://localhost:5000/v2/${image_name%:*}/tags/list" -o /dev/null -w '%{http_code}\n' -s)" != "200" ]; then
            skopeo copy --dest-tls-verify=false "docker://$image" "docker://localhost:5000/$image_name"
        fi
    done < kolla_images.txt
fi
