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

fly_version=6.7.1

# get_cpu_arch() - Gets CPU architecture of the server
function get_cpu_arch {
    case "$(uname -m)" in
        x86_64)
            echo "amd64"
        ;;
        armv8*|aarch64*)
            echo "arm64"
        ;;
        armv*)
            echo "armv7"
        ;;
    esac
}

# Install dependencies
pkgs=""
for pkg in podman kind kubectl helm; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if [ -n "$pkgs" ]; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
fi

if ! sudo kind get clusters | grep -q kind; then
    sudo podman pull kindest/node:v1.18.8
    cat << EOF | sudo kind create cluster --wait=300s --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  kubeProxyMode: "ipvs"
nodes:
  - role: control-plane
    image: kindest/node:v1.18.8
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
fi

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
sleep 30
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s

if ! command -v fly; then
    tarball="fly-$fly_version-$(uname | tr '[:upper:]' '[:lower:]')-$(get_cpu_arch).tgz"
    url="https://github.com/concourse/concourse/releases/download/v$fly_version/$tarball"
    pushd "$(mktemp -d)" > /dev/null
    curl -fsSLO "$url" 2> /dev/null
    tar -xzf "$tarball"
    chmod +x ./fly
    sudo mkdir -p  /usr/local/bin/
    sudo mv ./fly /usr/local/bin/fly
    export PATH=$PATH:/usr/local/bin/
    popd > /dev/null
fi

if ! helm repo list | grep -e concourse; then
    helm repo add concourse https://concourse-charts.storage.googleapis.com/
    helm repo update
fi

if ! helm ls | grep -q concourse-ci; then
    helm upgrade --install concourse-ci concourse/concourse --wait \
        --set secrets.localUsers="${RELENG_LOCAL_USER:-test}:${RELENG_LOCAL_PASSWORD:-test}" \
        --set imageTag="$fly_version" -f values.yml
fi

kubectl rollout status deployment/concourse-ci-web --timeout=5m
until curl --output /dev/null --silent --head --fail http://localhost; do
    sleep 5
done
