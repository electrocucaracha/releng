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
pkgs=""
for pkg in helm kubectl; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
fi

if ! helm repo list | grep -e concourse; then
    helm repo add concourse https://concourse-charts.storage.googleapis.com/
    helm repo update
fi

concourse_image=""
if [ "${RELENG_K8S_TYPE:-kind}" == "kind" ] && \
[ -n "${PKG_DOCKER_REGISTRY_MIRRORS:-}" ] && \
[ -n "$(curl -s -X GET "${PKG_DOCKER_REGISTRY_MIRRORS//\"}/v2/_catalog" | jq '.repositories[] | select(.=="concourse/concourse")')" ]; then
    curl -s -X GET "${PKG_DOCKER_REGISTRY_MIRRORS//\"}/v2/_catalog" | jq '.repositories[] | select(.=="concourse/concourse")'
    concourse_image="local-mirror:5000/"
fi
concourse_image+="concourse/concourse"

if ! helm ls | grep -q concourse-ci; then
    helm upgrade --install concourse-ci concourse/concourse --wait \
        --set secrets.localUsers="${RELENG_LOCAL_USER:-test}:${RELENG_LOCAL_PASSWORD:-test}" \
        --set image="$concourse_image" \
        --set imageTag="${PKG_FLY_VERSION:-6.7.1}" -f values.yml
fi

kubectl rollout status deployment/concourse-ci-web --timeout=5m
until curl --output /dev/null --silent --head --fail http://localhost; do
    sleep 5
done
