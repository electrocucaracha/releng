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

# PEP 370 -- Per user site-packages directory
[[ "$PATH" != *.local/bin* ]] && export PATH=$PATH:$HOME/.local/bin
kolla-genpwd

for action in bootstrap-servers prechecks pull deploy check post-deploy; do
    ./run_kaction.sh "$action" | tee "$HOME/$action.log"
done

sudo sed -i  '/OS_*/d' /etc/environment
# shellcheck disable=SC2002
sudo cat /etc/kolla/admin-openrc.sh | sudo tee --append /etc/environment
