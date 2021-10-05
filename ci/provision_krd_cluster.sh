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
    export KRD_DEBUG=true
fi

# Configure KRD variables
if [ -n "${PKG_DOCKER_REGISTRY_MIRRORS:-}" ]; then
    KRD_REGISTRY_MIRRORS_LIST=${PKG_DOCKER_REGISTRY_MIRRORS//\"}
    KRD_INSECURE_REGISTRIES_LIST=${KRD_REGISTRY_MIRRORS_LIST##*/}
    export KRD_REGISTRY_MIRRORS_LIST KRD_INSECURE_REGISTRIES_LIST
fi
if [ -n "${PKG_KUBECTL_VERSION:-}" ]; then
    export KRD_KUBE_VERSION=${PKG_KUBECTL_VERSION}
fi
if [ -n "${RELENG_DNS_SERVER:-}" ]; then
    export KRD_MANUAL_DNS_SERVER=${RELENG_DNS_SERVER}
fi
export KRD_CERT_MANAGER_ENABLED=false
export KRD_INGRESS_NGINX_ENABLED=true
export KRD_HUGEPAGES_ENABLED=false
export KRD_ACTIONS_LIST=install_k8s,install_helm
export KRD_HELM_VERSION=3

# Provsion KRD cluster
curl -fsSL http://bit.ly/KRDaio | bash
