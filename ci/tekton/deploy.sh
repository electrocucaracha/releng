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
fi

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

echo "Deploying Tekton CI services"

trap exit_trap ERR

kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply -f "https://github.com/tektoncd/dashboard/releases/download/v${RELENG_TKN_DASHBOARD_VERSION:-0.20.0}/tekton-dashboard-release.yaml"

for deployment in $(kubectl get deployment --namespace tekton-pipelines -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
    kubectl rollout status "deployment/$deployment" --timeout=5m --namespace tekton-pipelines
done

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: tekton-ingress
  namespace: tekton-pipelines
spec:
  rules:
    - http:
        paths:
          - path: /
            backend:
              serviceName: tekton-dashboard
              servicePort: 9097
EOF
until curl --output /dev/null --silent --head --fail "http://$(ip route get 8.8.8.8 | grep "^8." | awk '{ print $7 }')"; do
    sleep 5
done
trap ERR
