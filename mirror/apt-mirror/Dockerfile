#checkov:skip=CKV_DOCKER_2:Ensure that HEALTHCHECK instructions have been added to container images
#checkov:skip=CKV_DOCKER_3:Ensure that a user for the container has been created
FROM ubuntu:24.04

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  apt-mirror=0.5.4-2 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/apt-mirror"]
