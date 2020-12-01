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

sudo docker-compose up -d

while IFS= read -r image; do
    skopeo copy --dest-tls-verify=false "docker://$image" "docker://localhost/${image#*/}"
done < images.txt

curl -s -X GET http://localhost/v2/_catalog
