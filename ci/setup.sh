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
if ! command -v fly; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=fly bash
fi

fly_target="${RELENG_TARGET:-releng}"

fly --target "$fly_target" login -c http://localhost -u "${RELENG_LOCAL_USER:-test}" -p "${RELENG_LOCAL_PASSWORD:-test}"
for pipeline in k8s-HorizontalPodAutoscaler-demo releng; do
    fly --target "$fly_target" set-pipeline -c "pipelines/${pipeline}.yml" -p "${pipeline,,}" -n
    fly --target "$fly_target" unpause-pipeline -p "${pipeline,,}"
done
