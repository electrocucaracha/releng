FROM python:3.13-alpine3.22

EXPOSE 3141
VOLUME /devpi/server

WORKDIR /opt/devpi
COPY ./requirements.txt .
RUN apk --no-cache add \
  gcc=14.2.0-r6 \
  musl-dev=1.2.5-r10 \
  libffi-dev=3.4.8-r0 && \
  pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["/usr/local/bin/devpi-server", "--serverdir=/devpi/server"]
CMD ["--host=0.0.0.0", "--port=3141"]
