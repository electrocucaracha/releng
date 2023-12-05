FROM python:3.9-alpine3.18

EXPOSE 3141
VOLUME /devpi/server

WORKDIR /opt/devpi
COPY ./requirements.txt .
RUN apk --no-cache add \
  gcc=12.2.1_git20220924-r10 \
  musl-dev=1.2.4-r2 \
  libffi-dev=3.4.4-r2 && \
  pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["/usr/local/bin/devpi-server", "--serverdir=/devpi/server"]
CMD ["--host=0.0.0.0", "--port=3141"]
