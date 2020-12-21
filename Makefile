# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2020
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

.PHONY: build
build:
	@docker buildx build --platform linux/amd64,linux/arm64 -t electrocucaracha/apt-mirror:0.0.1 --push --file mirror/apt/Dockerfile mirror/apt
	@docker image prune --force
