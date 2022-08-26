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
if [[ ${RELENG_DEBUG:-false} == "true" ]]; then
    set -o xtrace
fi

function exit_trap {
    set +o xtrace
    sudo fdisk -l
}

trap exit_trap ERR

if [ -n "${RELENG_CINDER_VOLUME-}" ]; then
    if ! command -v vgs; then
        # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
        curl -fsSL http://bit.ly/install_pkg | PKG="lvm2" bash
    fi
    sudo pvcreate "$RELENG_CINDER_VOLUME"
    sudo vgcreate cinder-volumes "$RELENG_CINDER_VOLUME"
    sudo modprobe dm_thin_pool
    echo "dm_thin_pool" | sudo tee /etc/modules-load.d/dm_thin_pool.conf
    sudo modprobe target_core_mod
    echo "target_core_mod" | sudo tee /etc/modules-load.d/target_core_mod.conf
fi
