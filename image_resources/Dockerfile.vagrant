FROM kubevirt/libvirt:20201125-c4405e2

ENV VAGRANT_VERSION=2.2.14
ENV CONFIGURE_ARGS='with-ldflags=-L/opt/vagrant/embedded/lib with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib64'
ENV GEM_HOME=~/.vagrant.d/gems
ENV GEM_PATH=$GEM_HOME:/opt/vagrant/embedded/gems
ENV PATH=/opt/vagrant/embedded/bin:$PATH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /tmp

RUN dnf -y install gcc-10.2.1 cpio-2.13 perl-5.30.3 \
  byacc-1.9.20191125 cmake-3.17.4 zlib-devel-1.2.11 \
  libvirt-devel-6.1.0 gcc-10.2.1 && \
  dnf clean all

RUN dnf download --source libssh && \
  rpm2cpio libssh-0.9.5-1.fc32.src.rpm  | cpio -imdV && \
  mkdir -p /opt/libssh/build && \
  tar xf libssh-0.9.5.tar.xz --strip-components=1 -C /opt/libssh

RUN dnf download --source krb5-libs && \
  rpm2cpio krb5-1.18.2-29.fc32.src.rpm | cpio -imdV && \
  mkdir -p /opt/krb/ && \
  tar xf krb5-1.18.2.tar.gz --strip-components=1 -C /opt/krb/

RUN curl -o vagrant.rpm "https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_$(uname -m).rpm"
RUN dnf -y install vagrant.rpm rsync-3.2.3 \
  libvirt-daemon-driver-network-6.6.0 ebtables-legacy-2.0.11 \
  openssh-clients-8.3p1 && dnf clean all

RUN vagrant plugin install vagrant-libvirt

WORKDIR /opt/libssh/build
RUN cmake .. -DOPENSSL_ROOT_DIR=/opt/vagrant/embedded/ && \
  make && cp lib/libssh* /opt/vagrant/embedded/lib64

WORKDIR /opt/krb/src
RUN ./configure && \
  make && cp -P lib/crypto/libk5crypto.* /opt/vagrant/embedded/lib64/

RUN unset CONFIGURE_ARGS && vagrant plugin install vagrant-libvirt

RUN dnf -y remove gcc-10.2.1 cpio-2.13 perl-5.30.3 \
  byacc-1.9.20191125 cmake-3.17.4 zlib-devel-1.2.11 \
  libvirt-devel-6.1.0 gcc-10.2.1 && \
  rm -rf /tmp/* /opt/krb /opt/libssh

WORKDIR /
COPY ./libvirtd-lib.sh /libvirtd-lib.sh
