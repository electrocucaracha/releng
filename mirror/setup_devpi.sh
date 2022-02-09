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

attempt_counter=0
max_attempts=5

python -m venv /tmp/devpi
until sudo "$(command -v docker-compose)" logs devpi | grep "Serving on "; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
        echo "Max attempts reached"
        exit 1
    fi
    attempt_counter=$((attempt_counter+1))
    sleep $((attempt_counter*30))
done

# shellcheck disable=SC1091
source /tmp/devpi/bin/activate
attempt_counter=0
until PIP_INDEX_URL=http://localhost:3141/root/pypi/+simple/ pip install -r "${RELENG_FOLDER:-}./common/requirements.txt"; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
        echo "Max attempts reached"
        exit 1
    fi
    attempt_counter=$((attempt_counter+1))
done
deactivate
