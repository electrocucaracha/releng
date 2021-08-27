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

if ! command -v virtualenv; then
    sudo -H pip install virtualenv
fi

virtualenv /tmp/devpi
# shellcheck disable=SC1091
source /tmp/devpi/bin/activate
PIP_INDEX_URL=http://localhost:3141/root/pypi/+simple/ pip install -r "${RELENG_FOLDER:-}./common/requeriments.txt"
deactivate
