# Release Engineering
[![Build Status](https://api.travis-ci.com/electrocucaracha/releng.svg)](https://travis-ci.com/github/electrocucaracha/releng)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Summary

This project provisions a Continuous Integration server used for
validate personal projects.

## Virtual Machines

The [Vagrant tool][1] can be used for provisioning an Ubuntu Focal
Virtual Machine. It's highly recommended to use the  *setup.sh* script
of the [bootstrap-vagrant project][2] for installing Vagrant
dependencies and plugins required for this project. That script
supports two Virtualization providers (Libvirt and VirtualBox) which
are determine by the **PROVIDER** environment variable.

    $ curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to provision a Virtual
Machine using the following instructions:

    $ VAGRANT_EXPERIMENTAL=disks vagrant up
    $ vagrant up ci

The provisioning process will take some time to install all
dependencies required by this project and perform a Kubernetes
deployment on it.

The Concourse CI Dashboard is accesible through
[this URL.](http://192.168.123.4/)

[1]: https://www.vagrantup.com/
[2]: https://github.com/electrocucaracha/bootstrap-vagrant
