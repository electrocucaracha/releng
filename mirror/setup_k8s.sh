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
fi

while IFS= read -r image; do
    image_name="${image#*/}"
    if [ "$(curl "http://localhost:5000/v2/${image_name%:*}/tags/list" -o /dev/null -w '%{http_code}\n' -s)" != "200" ] || [ "$(curl "http://localhost:5000/v2/${image_name%:*}/manifests/${image_name#*:}" -o /dev/null -w '%{http_code}\n' -s)" != "200" ]; then
        if command -v skopeo; then
            skopeo copy --dest-tls-verify=false "docker://$image" "docker://localhost:5000/$image_name"
        else
            docker pull "$image"
            docker tag "$image" "localhost:5000/$image_name"
            docker push "localhost:5000/$image_name"
        fi
    fi
done < "${RELENG_K8S_TYPE:-kind}_images.txt"
