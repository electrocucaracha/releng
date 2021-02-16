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

echo "Configuring Tekton CI pipelines"

# Install dependencies
pkgs=""
for pkg in tkn kubectl; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG="$pkgs" bash
fi

for task in linter vind; do
    kubectl apply -f "https://raw.githubusercontent.com/electrocucaracha/$task/master/tkn.yml"
done

for pipeline in pkg-mgr_scripts; do
    kubectl apply -f "https://raw.githubusercontent.com/electrocucaracha/$pipeline/master/build/ci/tkn.yml"
done

kubectl apply -f ./pipelines
tkn pipeline list -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
