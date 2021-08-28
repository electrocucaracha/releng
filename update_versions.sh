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
if [[ "${DEBUG:-false}" == "true" ]]; then
    set -o xtrace
fi

function _get_pip_version {
    version=""
    attempt_counter=0
    max_attempts=5

    until [ "$version" ]; do
        metadata="$(curl -s "https://pypi.org/pypi/$1/json")"
        if [ "$metadata" ]; then
            version="$(echo "$metadata" | python -c 'import json,sys;print(json.load(sys.stdin)["info"]["version"])')"
            break
        elif [ ${attempt_counter} -eq ${max_attempts} ];then
            echo "Max attempts reached"
            exit 1
        fi
        attempt_counter=$((attempt_counter+1))
        sleep $((attempt_counter*2))
    done

    echo "${version#*v}"
}

if ! command -v pip-compile > /dev/null; then
    pip install pip-tools
fi

eval "$(curl -fsSL https://raw.githubusercontent.com/electrocucaracha/pkg-mgr_scripts/master/ci/pinned_versions.env)"

sed -i "s/PKG_FLY_VERSION\".*/PKG_FLY_VERSION\"] || \"$PKG_FLY_VERSION\"/g" Vagrantfile
sed -i "s/PKG_FLY_VERSION:-.*/PKG_FLY_VERSION:-$PKG_FLY_VERSION}\" -f helm\/ci\.yml/g" ci/concourse/deploy.sh
sed -i "s|docker.io/concourse/concourse:.*|docker.io/concourse/concourse:$PKG_FLY_VERSION|g" mirror/kind_images.txt
sed -i "s|docker.io/concourse/concourse:.*|docker.io/concourse/concourse:$PKG_FLY_VERSION|g" mirror/krd_images.txt
sed -i "s/devpi-server==.*/devpi-server==$(_get_pip_version devpi-server)/g" mirror/devpi/Dockerfile

for req_dir in mirror common; do
    pip-compile "$req_dir/requirements.in" \
    --output-file "$req_dir/requirements.txt" --upgrade
done
