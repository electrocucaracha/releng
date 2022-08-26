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

PROVIDER=${PROVIDER:-virtualbox}
msg=""

function _get_box_version {
    version=""
    attempt_counter=0
    max_attempts=5
    name="$1"

    if [ -f ./pinned_vagrant_boxes.txt ] && grep -q "^${name} .*$PROVIDER" ./pinned_vagrant_boxes.txt; then
        version=$(grep "^${name} .*$PROVIDER" ./pinned_vagrant_boxes.txt | awk '{ print $2 }')
    else
        until [ "$version" ]; do
            metadata="$(curl -s "https://app.vagrantup.com/api/v1/box/$name")"
            if [ "$metadata" ]; then
                version="$(echo "$metadata" | python -c 'import json,sys;print(json.load(sys.stdin)["current_version"]["version"])')"
                break
            elif [ ${attempt_counter} -eq ${max_attempts} ]; then
                echo "Max attempts reached"
                exit 1
            fi
            attempt_counter=$((attempt_counter + 1))
            sleep $((attempt_counter * 2))
        done
    fi

    echo "${version#*v}"
}

function _vagrant_pull {
    local name="$1"

    version=$(_get_box_version "$name")

    if [ "$(curl "https://app.vagrantup.com/${name%/*}/boxes/${name#*/}/versions/$version/providers/$PROVIDER.box" -o /dev/null -w '%{http_code}\n' -s)" == "302" ] && [ "$(vagrant box list | grep -c "$name .*$PROVIDER, $version")" != "1" ]; then
        vagrant box remove --provider "$PROVIDER" --all --force "$name" || :
        vagrant box add --provider "$PROVIDER" --box-version "$version" "$name"
    elif [ "$(vagrant box list | grep -c "$name .*$PROVIDER, $version")" == "1" ]; then
        echo "$name($version, $PROVIDER) box is already present in the host"
    else
        msg+="$name($version, $PROVIDER) box doesn't exist\n"
        return
    fi

    if sed --version >/dev/null 2>&1; then
        sed -i "s|config.vm.box = \".*|config.vm.box = \"$name\"|g" Vagrantfile
        sed -i "s|config.vm.box_version = \".*|config.vm.box_version = \"$version\"|g" Vagrantfile
    else
        sed -i '.bak' "s|config.vm.box = \".*|config.vm.box = \"$name\"|g" Vagrantfile
        sed -i '.bak' "s|config.vm.box_version = \".*|config.vm.box_version = \"$version\"|g" Vagrantfile
        find . -type f -name "*.bak" -delete
    fi
}

if ! command -v vagrant >/dev/null; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/bootstrap-vagrant
    curl -fsSL http://bit.ly/initVagrant | bash
fi

_vagrant_pull "generic/ubuntu2004"
