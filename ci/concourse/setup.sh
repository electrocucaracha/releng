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

echo "Configuring Concourse CI pipelines"

# Install dependencies
if ! command -v fly; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=fly bash
fi

fly_target="${RELENG_TARGET:-releng}"

if ! fly targets | grep -e "$fly_target"; then
    fly --target "$fly_target" login -c "http://${RELENG_CI_SERVER:-$(ip route get 8.8.8.8 | grep "^8." | awk '{ print $7 }')}" -u "${RELENG_CI_USER:-test}" -p "${RELENG_CI_PASSWORD:-test}"
fi

for pipeline in pipelines/*.yml; do
    pipeline_lower=$(basename "${pipeline/.yml/}" | tr '[:upper:]' '[:lower:]')
    fly --target "$fly_target" set-pipeline -c "${pipeline}" -p "${pipeline_lower}" -n
    fly --target "$fly_target" unpause-pipeline -p "${pipeline_lower}"
done
