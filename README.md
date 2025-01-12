# Release Engineering

<!-- markdown-link-check-disable-next-line -->

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub Super-Linter](https://github.com/electrocucaracha/releng/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
![visitors](https://visitor-badge.laobi.icu/badge?page_id=electrocucaracha.releng)

## Summary

This project provisions the following servers used for validation and test of
personal projects.

- _Mirror Server_: Provides services to reduce external network traffic. Those
  are [Ubuntu mirror][3], [Docker registry][4] and [PyPI server][5].
- _CI Server_: Provides a Continuous Integration server on top of a Kubernetes
  Cluster. [Concourse CI][6] and [Tekton][7] are the options supported.
- _Cloud Server_: Provides an [OpenStack][8] server as Infrastructure as a
  Service solution.

## Virtual Machines

The [Vagrant tool][1] can be used for provisioning an Ubuntu Focal
Virtual Machine. It's highly recommended to use the _setup.sh_ script
of the [bootstrap-vagrant project][2] for installing Vagrant
dependencies and plugins required for this project. That script
supports two Virtualization providers (Libvirt and VirtualBox) which
are determine by the **PROVIDER** environment variable.

```bash
curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash
```

Once Vagrant is installed, it's possible to provision a Virtual
Machine using the following instructions:

```bash
VAGRANT_EXPERIMENTAL=disks vagrant up
vagrant up ci
```

The provisioning process will take some time to install all
dependencies required by this project and perform a Kubernetes
deployment on it.

[1]: https://www.vagrantup.com/
[2]: https://github.com/electrocucaracha/bootstrap-vagrant
[3]: http://apt-mirror.github.io/
[4]: https://docs.docker.com/registry/
[5]: https://www.devpi.net/
[6]: https://concourse-ci.org/
[7]: https://tekton.dev/
[8]: https://www.openstack.org/
