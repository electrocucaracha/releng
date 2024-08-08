FROM ubuntu:24.04

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  apt-mirror=0.5.4-2 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/apt-mirror"]
