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

# Install dependencies
pip install -r "${RELENG_FOLDER:-}./common/requeriments.txt"

# Configure kolla-ansible
sudo mkdir -p /etc/{kolla/config,ansible}
sudo cp -R kolla-ansible/* /etc/kolla/
sudo chown "$USER" /etc/kolla/passwords.yml

if [ -n "${PKG_DOCKER_REGISTRY_MIRRORS:-}" ]; then
    sudo sed -i "s|^#docker_registry:.*$|docker_registry: ${PKG_DOCKER_REGISTRY_MIRRORS/'http://'/}|g" /etc/kolla/globals.yml
fi
sudo sed -i "s/^enable_cinder: .*/enable_cinder: \"${RELENG_ENABLE_CINDER:-no}\"/g" /etc/kolla/globals.yml
sudo sed -i "s/^#network_interface: .*/network_interface: \"${RELENG_NETWORK_INTERFACE}\"/g" /etc/kolla/globals.yml
sudo sed -i "s/^#neutron_external_interface: .*/neutron_external_interface: \"${RELENG_NEUTRON_EXTERNAL_INTERFACE}\"/g" /etc/kolla/globals.yml
sudo sed -i "s/^kolla_internal_vip_address: .*/kolla_internal_vip_address: \"${RELENG_INTERNAL_VIP_ADDRESS}\"/g" /etc/kolla/globals.yml

sudo tee /etc/ansible/ansible.cfg << EOL
[defaults]
host_key_checking=False
pipelinig=True
forks=100
remote_tmp=/tmp/
EOL
