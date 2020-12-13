FROM ubuntu:20.10 as builder

ENV SHELLCHECK_VERSION=v0.7.1
ENV HADOLINT_VERSION=v1.19.0
ENV GOLANGCI_LINT_VERSION=v1.33.0

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  wget=1.20.3-1ubuntu1 \
  cabal-install=3.0.0.0-3build1 \
  ghc=8.8.3-3build1 \
  haskell-stack=2.3.3-1 \
  libghc-regex-tdfa-dev=1.3.1.0-2build1 \
  libghc-aeson-dev=1.4.7.1-2build1 \
  libghc-quickcheck2-dev=2.13.2-1build2 \
  libghc-diff-dev=0.4.0-1build1

# Fetch source code
RUN wget -c https://github.com/koalaman/shellcheck/archive/${SHELLCHECK_VERSION}.tar.gz -O - | tar -xz -C /opt
RUN wget -c https://github.com/hadolint/hadolint/archive/${HADOLINT_VERSION}.tar.gz -O - | tar -xz -C /opt

# Build binaries
# hadolint ignore=DL3003
RUN cd /opt/shellcheck-${SHELLCHECK_VERSION#v}/ && cabal install --dependencies-only && cabal install
# hadolint ignore=DL3003
RUN cd /opt/hadolint-${HADOLINT_VERSION#v}/ && stack install
# hadolint ignore=DL3003
RUN cd /; wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s $GOLANGCI_LINT_VERSION

FROM ubuntu:20.10

ENV PATH="/usr/lib/go-1.15/bin/:${PATH}"

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  tox=3.15.1-1 golang-1.15=1.15.2-1ubuntu1 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/.local/bin/hadolint /usr/local/bin/hadolint
COPY --from=builder /root/.cabal/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=builder /bin/golangci-lint /usr/local/bin/golangci-lint

COPY ./linter_entrypoint.sh /usr/local/bin/linter.sh

ENTRYPOINT ["/usr/local/bin/linter.sh"]
