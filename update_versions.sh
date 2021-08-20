#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2021
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o errexit
set -o pipefail
if [[ "${DEBUG:-false}" == "true" ]]; then
    set -o xtrace
fi

eval "$(curl -fsSL https://raw.githubusercontent.com/electrocucaracha/pkg-mgr_scripts/master/ci/pinned_versions.env)"

sed -i "s/PKG_FLY_VERSION\".*/PKG_FLY_VERSION\"] || \"$PKG_FLY_VERSION\"/g" Vagrantfile
sed -i "s/PKG_FLY_VERSION:-.*/PKG_FLY_VERSION:-$PKG_FLY_VERSION}\" -f helm\/ci\.yml/g" ci/concourse/deploy.sh
sed -i "s|docker.io/concourse/concourse:.*|docker.io/concourse/concourse:$PKG_FLY_VERSION|g" mirror/kind_images.txt
sed -i "s|docker.io/concourse/concourse:.*|docker.io/concourse/concourse:$PKG_FLY_VERSION|g" mirror/krd_images.txt
