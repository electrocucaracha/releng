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

trap exit_trap ERR

# Setup Horizontal Pod Autoscaler components
if ! heml repo list | grep -q prometheus-community; then
    helm repo add prometheus-community \
        https://prometheus-community.github.io/helm-charts
    helm repo update
fi
if ! helm ls | grep -q metric-collector; then
    helm upgrade --install metric-collector \
        prometheus-community/prometheus-operator --wait \
        -f helm/operator.yml
fi
if ! helm ls | grep -q metric-apiserver; then
    helm upgrade --install metric-apiserver \
        prometheus-community/prometheus-adapter --wait \
        -f helm/adapter.yml
fi
cat << EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: cpustats-monitor
spec:
  endpoints:
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 5s
    port: web
  selector:
    matchLabels:
      app: frontend
EOF

trap ERR
