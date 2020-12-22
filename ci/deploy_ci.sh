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

function exit_trap {
    set +o xtrace
    printf "CPU usage: "
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage " %"}'
    printf "Memory free(Kb):"
    awk -v low="$(grep low /proc/zoneinfo | awk '{k+=$2}END{print k}')" '{a[$1]=$2}  END{ print a["MemFree:"]+a["Active(file):"]+a["Inactive(file):"]+a["SReclaimable:"]-(12*low);}' /proc/meminfo
    if command -v kubectl; then
        kubectl get all -A -o wide
        kubectl describe nodes
    fi
}

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

trap exit_trap ERR
if ! helm ls | grep -q concourse-ci; then
    helm upgrade --install concourse-ci concourse/concourse --wait \
        --set secrets.localUsers="${RELENG_LOCAL_USER:-test}:${RELENG_LOCAL_PASSWORD:-test}" \
        --set image="$concourse_image" \
        --set worker.replicas="$(kubectl get nodes --no-headers | wc -l)" \
        --set imageTag="${PKG_FLY_VERSION:-6.7.2}" -f helm/ci.yml
fi

kubectl rollout status deployment/concourse-ci-web --timeout=5m
until curl --output /dev/null --silent --head --fail http://localhost; do
    sleep 5
done
trap ERR
