FROM python:3.12-alpine3.20

EXPOSE 3141
VOLUME /devpi/server

WORKDIR /opt/devpi
COPY ./requirements.txt .
RUN apk --no-cache add \
  gcc=13.2.1_git20240309-r0 \
  musl-dev=1.2.5-r0 \
  libffi-dev=3.4.6-r0 && \
  pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["/usr/local/bin/devpi-server", "--serverdir=/devpi/server"]
CMD ["--host=0.0.0.0", "--port=3141"]
