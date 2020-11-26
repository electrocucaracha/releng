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

export PKG_FLY_VERSION=6.7.1
export PKG_KUBECTL_VERSION=v1.18.8

# Install dependencies
pkgs=""
for pkg in docker kind kubectl helm fly; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
fi

if ! sudo kind get clusters | grep -q kind; then
newgrp docker <<EONG
    cat << EOF | kind create cluster --wait=300s --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  kubeProxyMode: "ipvs"
nodes:
  - role: control-plane
    image: kindest/node:$PKG_KUBECTL_VERSION
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
EOF
EONG
    sudo chown -R "$USER" "$HOME/.kube/"
fi

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
sleep 30
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s

if ! helm repo list | grep -e concourse; then
    helm repo add concourse https://concourse-charts.storage.googleapis.com/
    helm repo update
fi

if ! helm ls | grep -q concourse-ci; then
    helm upgrade --install concourse-ci concourse/concourse --wait \
        --set secrets.localUsers="${RELENG_LOCAL_USER:-test}:${RELENG_LOCAL_PASSWORD:-test}" \
        --set imageTag="$PKG_FLY_VERSION" -f values.yml
fi

kubectl rollout status deployment/concourse-ci-web --timeout=5m
until curl --output /dev/null --silent --head --fail http://localhost; do
    sleep 5
done
