FROM python:3.9-alpine3.12

EXPOSE 3141
VOLUME /devpi/server

RUN apk --no-cache add \
  gcc=9.3.0-r2 \
  musl-dev=1.1.24-r10 \
  libffi-dev=3.3-r2 && \
  pip install --no-cache-dir devpi-server==6.3.1

ENTRYPOINT ["/usr/local/bin/devpi-server", "--serverdir=/devpi/server"]
CMD ["--host=0.0.0.0", "--port=3141"]
