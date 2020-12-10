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

# mount_dev() - Formats and mounts storage devices
function mount_dev {
    dev_name="/dev/$1"
    mount_dir="$2"

    sudo mkdir -p "$mount_dir"

    # Format registry volume
    if lsblk --list | grep -q "^${dev_name##*/} .*disk" &&  ! mount | grep -q "${dev_name}1 on $mount_dir"; then
    sudo sfdisk "$dev_name" --no-reread << EOF
;
EOF
        sudo mkfs -t ext4 "${dev_name}1"
        sudo mount "${dev_name}1" "$mount_dir"
        echo "${dev_name}1 $mount_dir           ext4    errors=remount-ro,noatime,barrier=0 0       1" | sudo tee --append /etc/fstab
    fi
}

mount_dev "$1" "$2"
