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
$fly_version="6.7.1"
$kubectl_version="v1.18.8"

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.box = "generic/ubuntu2004"
  config.vm.box_check_update = false


  config.vm.provider "virtualbox" do |v|
    v.gui = false
    v.auto_nat_dns_proxy = false
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

    mirror.vm.provision 'shell', privileged: false do |sh|
      sh.env = {
        'PKG_FLY_VERSION': $fly_version,
        'PKG_KUBECTL_VERSION': $kubectl_version,
        'MIRROR_FILENAME': 'releng_mirror.list',
      }
      sh.inline = <<-SHELL
        set -o errexit

        cd /vagrant/
        ./install.sh | tee ~/install.log
        ./setup.sh | tee ~/setup.log
      SHELL
    end
  end # mirror

  config.vm.define :ci, primary: true, autostart: false do |ci|
    ci.vm.network "private_network", ip: $ci_ip_address
    ci.vm.synced_folder './ci', '/vagrant'
    ci.vm.network "forwarded_port", guest: 80, host: 8080

    [:virtualbox, :libvirt].each do |provider|
      ci.vm.provider provider do |p|
        p.cpus = ENV["CPUS"] || 2
        p.memory = ENV['MEMORY'] || 6144
      end
    end
    ci.vm.provision 'shell', privileged: false do |sh|
      sh.env = {
        'PKG_DOCKER_REGISTRY_MIRRORS': "\"http://#{$mirror_ip_address}:5000\"",
        'PKG_FLY_VERSION': $fly_version,
        'PKG_KUBECTL_VERSION': $kubectl_version,
      }
      sh.inline = <<-SHELL
        set -o errexit

        echo "nameserver #{$mirror_ip_address}" | sudo tee  /etc/resolv.conf
        cd /vagrant/
        ./install.sh | tee ~/install.log
        ./deploy.sh | tee ~/deploy.log
        ./setup.sh | tee ~/setup.log
      SHELL
    end
  end # ci
end
