# -*- mode: ruby -*-
# vi: set ft=ruby :
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

$no_proxy = ENV['NO_PROXY'] || ENV['no_proxy'] || "127.0.0.1,localhost"
# NOTE: This range is based on vagrant-libvirt network definition CIDR 192.168.121.0/24
(1..254).each do |i|
  $no_proxy += ",192.168.121.#{i}"
end
$no_proxy += ",10.0.2.15"
$mirror_ip_address="192.168.123.3"
$ci_ip_address="192.168.123.4"
$cloud_ip_address="192.168.123.5"
$cloud_vip_address="192.168.123.6"
$fly_version="6.7.2"
$kubectl_version="v1.18.8"
$k8s_type = ENV['RELENG_K8S_TYPE'] || "kind"

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.box = "generic/ubuntu1804"
  config.vm.box_check_update = false

  config.vm.provider "virtualbox" do |v|
    v.gui = false
  end

  config.vm.provider :libvirt do |v|
    v.random_hostname = true
    v.management_network_address = "192.168.121.0/24"
  end

  if ENV['http_proxy'] != nil and ENV['https_proxy'] != nil
    if Vagrant.has_plugin?('vagrant-proxyconf')
      config.proxy.http     = ENV['http_proxy'] || ENV['HTTP_PROXY'] || ""
      config.proxy.https    = ENV['https_proxy'] || ENV['HTTPS_PROXY'] || ""
      config.proxy.no_proxy = $no_proxy
      config.proxy.enabled = { docker: false }
    end
  end

  config.vm.define :mirror do |mirror|
    mirror.vm.hostname = "mirror"
    mirror.vm.network "private_network", ip: $mirror_ip_address
    mirror.vm.synced_folder './mirror', '/vagrant'

    [:virtualbox, :libvirt].each do |provider|
      mirror.vm.provider provider do |p|
        p.cpus = 1
        p.memory = 512
      end
    end
    mirror.vm.disk :disk, name: "packages", size: "50GB"
    mirror.vm.disk :disk, name: "images", size: "10GB"
    {
      "sdb"=>"/var/local/packages",
      "sdc"=>"/var/local/images",
    }.each do |device, mount_path|
      mirror.vm.provision "shell" do |s|
        s.path   = "pre-install.sh"
        s.args   = [device, mount_path]
      end
    end

    mirror.vm.provision 'shell', privileged: false do |sh|
      sh.env = {
        'PKG_FLY_VERSION': $fly_version,
        'PKG_KUBECTL_VERSION': $kubectl_version,
        'MIRROR_FILENAME': 'releng_mirror.list',
        'RELENG_K8S_TYPE': $k8s_type,
      }
      sh.inline = <<-SHELL
        set -o errexit
        set -o pipefail

        cd /vagrant/
        ./install.sh | tee ~/install.log
        ./deploy.sh | tee ~/deploy.log
        ./setup_k8s.sh | tee ~/setup_k8s.log
        ./setup_kolla.sh | tee ~/setup_kolla.log

        curl -s -X GET http://localhost:5000/v2/_catalog
      SHELL
    end
  end # mirror

  config.vm.define :ci, primary: true, autostart: false do |ci|
    ci.vm.hostname = "ci"
    ci.vm.network "private_network", ip: $ci_ip_address
    ci.vm.synced_folder './ci', '/vagrant'
    ci.vm.synced_folder './', '/opt/releng'

    [:virtualbox, :libvirt].each do |provider|
      ci.vm.provider provider do |p|
        p.cpus = ENV["CPUS"] || 2
        p.memory = ENV['MEMORY'] || 6144
      end
    end

    ci.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--nested-hw-virt","on"]
    end
    ci.vm.disk :disk, name: "postgresql", size: "10GB"
    ci.vm.disk :disk, name: "worker0", size: "25GB"
    ci.vm.provider :libvirt do |v|
      v.nested = true
      v.storage :file, :bus => 'sata', :device => "sdb", :size => '10G'
      v.storage :file, :bus => 'sata', :device => "sdc", :size => '25G'
    end

    {
      "sdb"=>"/mnt/disks/postgresql",
      "sdc"=>"/mnt/disks/worker0",
    }.each do |device, mount_path|
      ci.vm.provision "shell" do |s|
        s.path   = "pre-install.sh"
        s.args   = [device, mount_path]
      end
    end

    ci.vm.provision 'shell', privileged: false do |sh|
      sh.env = {
        'PKG_DOCKER_REGISTRY_MIRRORS': "\"http://#{$mirror_ip_address}:5000\"",
        'PKG_FLY_VERSION': $fly_version,
        'PKG_KUBECTL_VERSION': $kubectl_version,
        'RELENG_K8S_TYPE': $k8s_type,
      }
      sh.inline = <<-SHELL
        set -o errexit
        set -o pipefail

        cd /vagrant/
        ./provision_${RELENG_K8S_TYPE:-kind}_cluster.sh | tee ~/provision_cluster.log
        ./deploy_hpa.sh | tee ~/deploy_hpa.log
        ./deploy_ci.sh | tee ~/deploy_ci.log
        ./setup.sh | tee ~/setup.log
        kubectl describe nodes
      SHELL
    end
  end # ci

  config.vm.define :cloud, autostart: false do |cloud|
    cloud.vm.hostname = "cloud"
    cloud.vm.network "private_network", ip: $cloud_ip_address
    cloud.vm.synced_folder './cloud', '/vagrant'
    cloud.vm.network :private_network, ip: '172.24.4.225', :netmask => "255.255.255.224", :auto_config => false

    [:virtualbox, :libvirt].each do |provider|
      cloud.vm.provider provider do |p|
        p.cpus = ENV["CPUS"] || 2
        p.memory = ENV['MEMORY'] || 6144
      end
    end

    cloud.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--nested-hw-virt","on"]
    end
    cloud.vm.disk :disk, name: "cinder", size: "50GB"
    cloud.vm.provider :libvirt do |v|
      v.nested = true
      v.storage :file, :bus => 'sata', :device => "sdb", :size => '50G'
    end

    cloud.vm.provision 'shell', privileged: false do |sh|
      sh.env = {
        'PKG_DOCKER_REGISTRY_MIRRORS': "\"http://#{$mirror_ip_address}:5000\"",
        'RELENG_CINDER_VOLUME': "/dev/sdb",
        'RELENG_ENABLE_CINDER': "yes",
        'RELENG_INTERNAL_VIP_ADDRESS': $cloud_vip_address,
        'RELENG_NETWORK_INTERFACE': "eth1",
        'RELENG_NEUTRON_EXTERNAL_INTERFACE': "eth2",
      }
      sh.inline = <<-SHELL
        set -o errexit
        set -o pipefail

        for os_var in $(printenv | grep RELENG_); do echo "export $os_var" | sudo tee --append /etc/environment ; done
        cd /vagrant
        ./pre-install.sh | tee ~/pre-install.log
        ./install.sh | tee ~/install.log
        echo "127.0.0.1 localhost" | sudo tee /etc/hosts
        ./provision_openstack_cluster.sh | tee ~/provision_openstack_cluster.log
      SHELL
    end
  end # cloud
end
