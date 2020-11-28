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
$registry_ip_address="192.168.123.3"
$ci_ip_address="192.168.123.4"
$volume_file="registry.vdi"
$fly_version="6.7.1"
$kubectl_version="v1.18.8"

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.box = "generic/ubuntu2004"
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

  config.vm.define :registry do |registry|
    registry.vm.network "private_network", ip: $registry_ip_address
    registry.vm.synced_folder './registry', '/vagrant'

    [:virtualbox, :libvirt].each do |provider|
      registry.vm.provider provider do |p|
        p.cpus = 1
        p.memory = 512
      end
    end
    registry.vm.provider "virtualbox" do |v|
      unless File.exist?($volume_file)
        v.customize ['createmedium', 'disk', '--filename', $volume_file, '--size', 25600]
      end
      v.customize ['storageattach', :id, '--storagectl', "IDE Controller" , '--port', 1, '--device', 1, '--type', 'hdd', '--medium', $volume_file]
    end

    registry.vm.provider :libvirt do |v|
      v.storage :file, :bus => 'sata', :device => "sdb", :size => 25
    end
    registry.vm.provision 'shell', privileged: false do |sh|
      sh.env = {
        'PKG_FLY_VERSION': $fly_version,
        'PKG_KUBECTL_VERSION': $kubectl_version,
      }
      sh.inline = <<-SHELL
        set -o errexit

        cd /vagrant/
        ./install.sh | tee ~/install.log
        ./setup.sh | tee ~/setup.log
      SHELL
    end
  end # registry

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
        'PKG_DOCKER_REGISTRY_MIRRORS': "\"http://#{$registry_ip_address}:5000\"",
        'PKG_FLY_VERSION': $fly_version,
        'PKG_KUBECTL_VERSION': $kubectl_version,
      }
      sh.inline = <<-SHELL
        set -o errexit

        cd /vagrant/
        ./install.sh | tee ~/install.log
        ./deploy.sh | tee ~/deploy.log
        ./setup.sh | tee ~/setup.log
      SHELL
    end
  end # ci
end
