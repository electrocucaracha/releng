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

if [ "${DEBUG:-false}" == "true" ]; then
    set -o xtrace
    printenv
    pwd
    for tool in hadolint shellcheck tox golangci-lint; do
        $tool --version
    done
fi

case ${RELENG_LINTER_TOOL} in
    hadolint)
        find . -type f -iname "*Dockerfile*" -print0 | xargs -0 hadolint
    ;;
    shellcheck)
        find . -type f -iname "*sh" -print0 | xargs -0 shellcheck -x
    ;;
    tox)
        tox -v
    ;;
    golangci-lint)
        CGO_ENABLED=0 golangci-lint run --enable-all ./...
    ;;
esac
