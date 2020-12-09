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
for pkg in docker kind kubectl; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
fi

if ! sudo kind get clusters | grep -q kind; then
    containerd_patch=""
    if [ -n "${PKG_DOCKER_REGISTRY_MIRRORS:-}" ]; then
        containerd_patch+="containerdConfigPatches:
    - |
        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"local-mirror:5000\"]
            endpoint = [$PKG_DOCKER_REGISTRY_MIRRORS]"
    fi
    cat << EOF | sudo kind create cluster --wait=300s --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
$containerd_patch
networking:
    kubeProxyMode: "ipvs"
nodes:
    - role: control-plane
      image: kindest/node:${PKG_KUBECTL_VERSION:-v1.18.8}
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
    mkdir -p "$HOME/.kube"
    sudo cp /root/.kube/config "$HOME/.kube/config"
    sudo chown -R "$USER" "$HOME/.kube/"
    chmod 600 "$HOME/.kube/config"

    if [ -n "${PKG_DOCKER_REGISTRY_MIRRORS:-}" ]; then
        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "${PKG_DOCKER_REGISTRY_MIRRORS##*/}
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
        # TODO: Try to use https://github.com/NextDeveloperTeam/kubernetes-webhooks/tree/main/docker-proxy-webhook solution
    fi
fi

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
sleep 30
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s
