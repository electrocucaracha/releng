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

reg_name=local-registry

# Start local registry
running="$(sudo docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
    sudo -E docker run -d --name "${reg_name}" --restart=always \
    -p 5000:5000 \
    -v registry:/var/lib/registry registry:2
fi

while IFS= read -r image; do
    skopeo copy --dest-tls-verify=false "docker://$image" "docker://localhost:5000/${image#*/}"
done < images.txt

curl -s -X GET http://localhost:5000/v2/_catalog
