# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2020
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

DOCKER_CMD ?= $(shell which docker 2> /dev/null || which podman 2> /dev/null || echo docker)

.PHONY: lint
lint:
	sudo -E $(DOCKER_CMD) run --rm -v $$(pwd):/tmp/lint \
	-e RUN_LOCAL=true \
	-e LINTER_RULES_PATH=/ \
	-e VALIDATE_TEKTON=false \
	-e VALIDATE_KUBERNETES_KUBEVAL=false \
	-e KUBERNETES_KUBECONFORM_OPTIONS='-ignore-missing-schemas' \
	ghcr.io/super-linter/super-linter
	tox -e lint

.PHONY: build
build:
	for image in apt-mirror ntpd devpi; do \
		sudo -E $(DOCKER_CMD) buildx build --platform linux/amd64,linux/arm64 -t electrocucaracha/$$image:0.0.1 --push --file mirror/$$image/Dockerfile mirror/$$image ; \
	done
	sudo -E $(DOCKER_CMD) image prune --force

.PHONY: fmt
fmt:
	command -v shfmt > /dev/null || curl -s "https://i.jpillora.com/mvdan/sh!!?as=shfmt" | bash
	shfmt -l -w -s .
	command -v yamlfmt > /dev/null || curl -s "https://i.jpillora.com/google/yamlfmt!!" | bash
	yamlfmt -dstar **/*.{yaml,yml}
	command -v prettier > /dev/null || npm install prettier
	npx prettier . --write
