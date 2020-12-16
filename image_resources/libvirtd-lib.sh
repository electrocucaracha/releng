#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

LIBVIRTD_PIDFILE="/var/run/libvirt/libvirtd.pid"
LIBVIRTD_OPTS=${LIBVIRT_OPTS:-" -v -f /etc/libvirt/libvirtd.conf -p $LIBVIRTD_PIDFILE "}

if [ "${DEBUG:-false}" == "true" ]; then
    set -o xtrace
    printenv
    pwd
    for tool in vagrant virsh; do
        $tool --version
    done
fi

function start_libvirtd {
    if [ -f "$LIBVIRTD_PIDFILE" ];then
        echo "libvirt is already running..."
        exit 1
    fi
    trap stop_libvirtd EXIT
    sed -i 's|^stdio_handler = .*|stdio_handler = "file"|g' /etc/libvirt/qemu.conf

    echo "Starting libvirtd"
    mkdir -p "$(dirname "$LIBVIRTD_PIDFILE")"
    /usr/sbin/libvirtd -d -l "$LIBVIRTD_OPTS"
}

function stop_libvirtd {
    if [ ! -f "$LIBVIRTD_PIDFILE" ];then
        echo "libvirt is not running..."
        exit 2
    fi

    echo "Stopping libvirtd..."
    kill -TERM "$(cat $LIBVIRTD_PIDFILE)"
    sleep 3
}
