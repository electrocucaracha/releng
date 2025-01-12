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
if [[ ${DEBUG:-false} == "true" ]]; then
    set -o xtrace
fi

trap "make fmt" EXIT

function _get_pip_version {
    version=""
    attempt_counter=0
    max_attempts=5

    until [ "$version" ]; do
        metadata="$(curl -s "https://pypi.org/pypi/$1/json")"
        if [ "$metadata" ]; then
            version="$(echo "$metadata" | python -c 'import json,sys;print(json.load(sys.stdin)["info"]["version"])')"
            break
        elif [ ${attempt_counter} -eq ${max_attempts} ]; then
            echo "Max attempts reached"
            exit 1
        fi
        attempt_counter=$((attempt_counter + 1))
        sleep $((attempt_counter * 2))
    done

    echo "${version#*v}"
}

function get_github_latest_release {
    version=""
    attempt_counter=0
    max_attempts=5

    until [ "$version" ]; do
        url_effective=$(curl -sL -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")
        if [ "$url_effective" ]; then
            version="${url_effective##*/}"
            break
        elif [ ${attempt_counter} -eq ${max_attempts} ]; then
            echo "Max attempts reached"
            exit 1
        fi
        attempt_counter=$((attempt_counter + 1))
        sleep $((attempt_counter * 2))
    done
    echo "${version#v}"
}

if ! command -v pip-compile >/dev/null; then
    pip install pip-tools
fi

eval "$(curl -fsSL https://raw.githubusercontent.com/electrocucaracha/pkg-mgr_scripts/master/ci/pinned_versions.env)"

sed -i "s/PKG_FLY_VERSION\".*/PKG_FLY_VERSION\"] || \"$PKG_FLY_VERSION\"/g" Vagrantfile
sed -i "s/PKG_FLY_VERSION:-.*/PKG_FLY_VERSION:-$PKG_FLY_VERSION}\" -f helm\/ci\.yml/g" ci/concourse/deploy.sh
sed -i "s|docker.io/concourse/concourse:.*|docker.io/concourse/concourse:$PKG_FLY_VERSION|g" mirror/kind_images.txt
sed -i "s|docker.io/concourse/concourse:.*|docker.io/concourse/concourse:$PKG_FLY_VERSION|g" mirror/krd_images.txt
sed -i "s/devpi-server==.*/devpi-server==$(_get_pip_version devpi-server)/g" mirror/devpi/Dockerfile
sed -i "s/RELENG_TKN_DASHBOARD_VERSION:.*/RELENG_TKN_DASHBOARD_VERSION:-$(get_github_latest_release tektoncd/dashboard)}\/tekton-dashboard-release.yaml\"/g" ci/tekton/deploy.sh

for req_dir in "mirror" "common" "mirror/devpi"; do
    pip-compile "$req_dir/requirements.in" \
        --output-file "$req_dir/requirements.txt" --upgrade
done

# Update GitHub Action commit hashes
gh_actions=$(grep -r "uses: [a-zA-Z\-]*/[\_a-z\-]*@" .github/ | sed 's/@.*//' | awk -F ': ' '{ print $3 }' | sort -u)
for action in $gh_actions; do
    commit_hash=$(git ls-remote "https://github.com/$action" | grep 'refs/tags/[v]\?[0-9][0-9\.]*$' | sed 's|refs/tags/[vV]\?[\.]\?||g' | sort -u -k2 -V | tail -1 | awk '{ printf "%s # %s\n",$1,$2 }')
    # shellcheck disable=SC2267
    grep -ElRZ "uses: $action@" .github/ | xargs -0 -l sed -i -e "s|uses: $action@.*|uses: $action@$commit_hash|g"
done
