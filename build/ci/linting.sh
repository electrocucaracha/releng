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

mkdir -p  /usr/local/bin/

# Install dependencies
pkgs=""
if ! command -v pip; then
    pkgs+=" python3-pip"
fi
for pkg in shellcheck wget; do
    if ! command -v "$pkg"; then
        pkgs+=" $pkg"
    fi
done
if [ -n "$pkgs" ]; then
    apt update
    apt-get install -y -qq -o=Dpkg::Use-Pty=0 --no-install-recommends $pkgs
    if command -v pip3; then
        ln -s "$(command -v pip3)" /usr/local/bin/pip
    fi
fi
if ! command -v tox; then
    pip install tox
fi

# Run Linting tasks
tox -e lint
shellcheck -x *.sh
