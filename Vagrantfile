# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

no_proxy = ENV["NO_PROXY"] || ENV["no_proxy"] || "127.0.0.1,localhost"
(1..254).each do |i|
  no_proxy += ",10.0.2.#{i}"
end
mirror_ip_address = "192.168.123.3"
ci_ip_address = "192.168.123.4"
cloud_ip_address = "192.168.123.5"
cloud_vip_address = "192.168.123.6"
public_nic = `ip r get 1.1.1.1 | awk 'NR==1{print $5}'`.strip! || "eth0"
cloud_public_cidr = `ip r | grep "dev $(ip r get 1.1.1.1 | awk 'NR==1{print $5}') .* scope link" | awk '{print $1}'`.strip! || "192.168.0.0/24"
cloud_public_gw = `ip r | grep "^default" | awk 'NR==1{print $3}'`.strip! || "192.168.0.1"
fly_version = ENV["PKG_FLY_VERSION"] || "7.4.0"
kubectl_version = "v1.20.7"
kolla_build = ENV["RELENG_KOLLA_BUILD"]
k8s_type = ENV["RELENG_K8S_TYPE"] || "krd"
ci_type = ENV["RELENG_CI_TYPE"] || "tekton"
debug = ENV["RELENG_DEBUG"] || "false"
ci_setup_enabled = "false"
mirror_file = ENV["RELENG_MIRROR_FILE"] || "mirror_releng.list"
releng_folder = "/opt/releng/"

def which(cmd)
  exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
  ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

vb_public_nic = `VBoxManage list bridgedifs | grep "^Name:.*#{public_nic}" | awk -F "Name:[ ]*" '{ print $2}'`.strip! if which "VBoxManage"

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.box = "generic/ubuntu2004"
  config.vm.box_check_update = false
  config.vm.box_version = "3.3.2"

  config.vm.provider "virtualbox" do |v|
    v.gui = false
    # VirtualBox's NAT gateway will accept DNS traffic from the guest and
    # forward it to the resolver used by the host
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    # https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/network_performance.html
    v.customize ["modifyvm", :id, "--nictype1", "virtio", "--cableconnected1", "on"]
    v.customize ["modifyvm", :id, "--nictype2", "virtio", "--cableconnected2", "on"]
    # https://bugs.launchpad.net/cloud-images/+bug/1829625/comments/2
    v.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    v.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
    # Enable nested paging for memory management in hardware
    v.customize ["modifyvm", :id, "--nestedpaging", "on"]
    # Use large pages to reduce Translation Lookaside Buffers usage
    v.customize ["modifyvm", :id, "--largepages", "on"]
    # Use virtual processor identifiers  to accelerate context switching
    v.customize ["modifyvm", :id, "--vtxvpid", "on"]
  end

  config.vm.provider :libvirt do |v|
    v.management_network_address = "10.0.2.0/24"
    # Administration - Provides Internet access for all nodes and is
    # used for administration to install software packages
    v.management_network_name = "administration"
    v.cpu_mode = "host-passthrough"
    v.disk_device = "sda"
    v.disk_bus = "sata"
  end

  if !ENV["http_proxy"].nil? && !ENV["https_proxy"].nil? && Vagrant.has_plugin?("vagrant-proxyconf")
    config.proxy.http = ENV["http_proxy"] || ENV["HTTP_PROXY"] || ""
    config.proxy.https    = ENV["https_proxy"] || ENV["HTTPS_PROXY"] || ""
    config.proxy.no_proxy = no_proxy
    config.proxy.enabled = { docker: false }
  end

  config.vm.synced_folder "./common", "#{releng_folder}common"
  config.vm.define :mirror do |mirror|
    mirror.vm.hostname = "mirror"
    mirror.vm.network :private_network, ip: mirror_ip_address, libvirt__network_name: "management"
    mirror.vm.synced_folder "./mirror", "/vagrant"
    mirror.vm.network :public_network, dev: public_nic, bridge: vb_public_nic

    %i[virtualbox libvirt].each do |provider|
      mirror.vm.provider provider do |p|
        p.cpus = 1
        p.memory = 512
      end
    end

    # Mirror's volumes
    mirror.vm.disk :disk, name: "packages", size: "250GB"
    mirror.vm.disk :disk, name: "images", size: "10GB"
    mirror.vm.disk :disk, name: "pypi", size: "10GB"
    mirror.vm.provider :libvirt do |v|
      v.storage :file, bus: "sata", device: "sdb", size: "350G"
      v.storage :file, bus: "sata", device: "sdc", size: "10G"
      v.storage :file, bus: "sata", device: "sdd", size: "10G"
    end
    {
      "sdb" => "/var/local/packages",
      "sdc" => "/var/local/images",
      "sdd" => "/var/local/pypi_packages"
    }.each do |device, mount_path|
      mirror.vm.provision "shell" do |s|
        s.path   = "pre-install.sh"
        s.args   = [device, mount_path]
      end
    end

    mirror.vm.provision "shell", privileged: false do |sh|
      sh.env = {
        PKG_FLY_VERSION: fly_version,
        PKG_KUBECTL_VERSION: kubectl_version,
        MIRROR_FILENAME: mirror_file,
        RELENG_K8S_TYPE: k8s_type,
        RELENG_FOLDER: releng_folder,
        RELENG_KOLLA_BUILD: kolla_build
      }
      sh.inline = <<-SHELL
        set -o errexit
        set -o pipefail

        echo "export MIRROR_FILENAME=#{mirror_file}" | sudo tee --append /etc/environment
        # Prefer IPv4 over IPv6 in dual-stack environment
        sudo sed -i "s|^#precedence ::ffff:0:0/96  100$|precedence ::ffff:0:0/96  100|g" /etc/gai.conf

        cd /vagrant/
        ./install.sh | tee ~/install.log
        ./deploy.sh | tee ~/deploy.log
        ./setup_k8s.sh | tee ~/setup_k8s.log
        ./setup_kolla.sh | tee ~/setup_kolla.log
        ./setup_devpi.sh | tee ~/setup_devpi.log
        ./post-install.sh | tee ~/post-install.log

        curl -s -X GET http://localhost:5000/v2/_catalog
      SHELL
    end
  end

  config.vm.define :ci, primary: true, autostart: false do |ci|
    ci.vm.hostname = "ci"
    ci.vm.network :private_network, ip: ci_ip_address, libvirt__network_name: "management"
    ci.vm.network :forwarded_port, guest: 80, host: 8080
    ci.vm.synced_folder "./ci", "/vagrant"
    ci.vm.synced_folder "./", "/opt/releng"
    ci.vm.synced_folder "./apt/", "/etc/apt/" if File.exist?("#{File.dirname(__FILE__)}./apt/sources.list")

    %i[virtualbox libvirt].each do |provider|
      ci.vm.provider provider do |p|
        p.cpus = ENV["CPUS"] || 4
        p.memory = ENV["MEMORY"] || 16_384
      end
    end

    ci.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    end

    # CI's volumes
    ci.vm.disk :disk, name: "postgresql", size: "10GB"
    ci.vm.disk :disk, name: "worker0", size: "25GB"
    ci.vm.disk :disk, name: "containers", size: "100GB"
    ci.vm.provider :libvirt do |v|
      v.nested = true
      v.storage :file, bus: "sata", device: "sdb", size: "10G"
      v.storage :file, bus: "sata", device: "sdc", size: "25G"
      v.storage :file, bus: "sata", device: "sdd", size: "100G"
    end
    {
      "sdb" => "/mnt/disks/postgresql",
      "sdc" => "/mnt/disks/worker0",
      "sdd" => "/var/lib/containers/storage"
    }.each do |device, mount_path|
      ci.vm.provision "shell" do |s|
        s.path   = "pre-install.sh"
        s.args   = [device, mount_path]
      end
    end

    ci.vm.provision "shell", privileged: false do |sh|
      sh.env = {
        RELENG_DEVPI_HOST: mirror_ip_address,
        RELENG_NTP_SERVER: mirror_ip_address
      }
      sh.path = "install.sh"
    end
    ci.vm.provision "shell", privileged: false do |sh|
      sh.env = {
        PKG_DOCKER_REGISTRY_MIRRORS: "\"http://#{mirror_ip_address}:5000\"",
        PKG_FLY_VERSION: fly_version,
        PKG_KUBECTL_VERSION: kubectl_version,
        RELENG_K8S_TYPE: k8s_type,
        RELENG_CI_TYPE: ci_type,
        RELENG_DEBUG: debug,
        RELENG_NTP_SERVER: mirror_ip_address
      }
      sh.inline = <<-SHELL
        set -o errexit
        set -o pipefail

        for os_var in $(printenv | grep RELENG_); do echo "export $os_var" | sudo tee --append /etc/environment ; done
        cd /vagrant/
        ./provision_${RELENG_K8S_TYPE:-kind}_cluster.sh | tee ~/provision_cluster.log
        cd ${RELENG_CI_TYPE}
        ./deploy.sh | tee ~/deploy.log
        if [ "#{ci_setup_enabled}" == "true" ]; then
            ./setup.sh | tee ~/setup.log
        fi
        kubectl describe nodes
      SHELL
    end
  end

  config.vm.define :cloud, autostart: false do |cloud|
    cloud.vm.hostname = "cloud"
    # Management/API - Used for communication between the OpenStack
    # services.
    cloud.vm.network :private_network, ip: cloud_ip_address, libvirt__network_name: "management"
    cloud.vm.network :forwarded_port, guest_ip: cloud_vip_address, guest: 80, host: 9090
    cloud.vm.network :forwarded_port, guest_ip: cloud_vip_address, guest: 6080, host: 6080
    cloud.vm.synced_folder "./cloud", "/vagrant"
    # Public - Provides external access to OpenStack services. For
    # instances, it provides the route out to the external network and
    # the IP addresses to enable inbound connections to the instances.
    # This network can also provide the public API endpoints to
    # connect to OpenStack services.
    cloud.vm.network :public_network, dev: public_nic, bridge: vb_public_nic, auto_config: false

    %i[virtualbox libvirt].each do |provider|
      cloud.vm.provider provider do |p|
        p.cpus = ENV["CPUS"] || 4
        p.memory = ENV["MEMORY"] || 32_768
      end
    end

    cloud.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--nested-hw-virt", "on"]

      # Cable connected enables you to temporarily disconnect a
      # virtual network interface, as if a network cable had been
      # pulled from a real network card.
      # Performance-wise the virtio network adapter is preferable over
      # Intel PRO/1000 emulated adapters.
      v.customize ["modifyvm", :id, "--nictype1", "virtio", "--cableconnected1", "on"]
      v.customize ["modifyvm", :id, "--nictype2", "virtio", "--cableconnected2", "on"]
      v.customize ["modifyvm", :id, "--nictype3", "virtio", "--cableconnected3", "on"]

      v.customize ["modifyvm", :id, "--nic3", "natnetwork", "--nat-network3", "public", "--nicpromisc3", "allow-all"]
    end
    cloud.vm.disk :disk, name: "cinder", size: "50GB"
    cloud.vm.provider :libvirt do |v|
      v.nested = true
      v.storage :file, bus: "sata", device: "sdb", size: "50G"
    end

    cloud.vm.provision "shell", privileged: false do |sh|
      sh.env = {
        RELENG_CINDER_VOLUME: "/dev/sdb"
      }
      sh.path = "cloud/pre-install.sh"
    end
    cloud.vm.provision "shell", privileged: false do |sh|
      sh.env = {
        RELENG_DEVPI_HOST: mirror_ip_address,
        RELENG_NTP_SERVER: mirror_ip_address
      }
      sh.path = "install.sh"
    end
    cloud.vm.provision "shell", privileged: false do |sh|
      sh.env = {
        PKG_DOCKER_REGISTRY_MIRRORS: "\"http://#{mirror_ip_address}:5000\"",
        RELENG_CINDER_VOLUME: "/dev/sdb",
        RELENG_ENABLE_CINDER: "yes",
        RELENG_INTERNAL_VIP_ADDRESS: cloud_vip_address,
        RELENG_NETWORK_INTERFACE: "eth1",
        RELENG_NEUTRON_EXTERNAL_INTERFACE: "eth2",
        RELENG_NTP_SERVER: mirror_ip_address,
        RELENG_DEVPI_HOST: mirror_ip_address,
        RELENG_FOLDER: releng_folder,
        EXT_NET_RANGE: "start=#{cloud_public_cidr.sub('0/24', '50')},end=#{cloud_public_cidr.sub('0/24', '100')}",
        EXT_NET_CIDR: cloud_public_cidr.to_s,
        EXT_NET_GATEWAY: cloud_public_gw.to_s
      }
      sh.inline = <<-SHELL
        set -o errexit
        set -o pipefail

        sudo ip link set $RELENG_NEUTRON_EXTERNAL_INTERFACE promisc on
        echo "127.0.0.1 localhost" | sudo tee /etc/hosts

        for os_var in $(printenv | grep "RELENG_\|EXT_NET_" ); do
            echo "export $os_var" | sudo tee --append /etc/environment
        done

        cd /vagrant
        ./post-install.sh | tee ~/post-install.log
        ./provision_openstack_cluster.sh | tee ~/provision_openstack_cluster.log

        cd $HOME
        source <(sudo cat /etc/kolla/admin-openrc.sh)
        # PEP 370 -- Per user site-packages directory
        [[ "$PATH" != *.local/bin* ]] && export PATH=$PATH:$HOME/.local/bin
        ./.local/share/kolla-ansible/init-runonce
      SHELL
    end
  end
end
