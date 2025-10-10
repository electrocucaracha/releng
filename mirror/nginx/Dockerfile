FROM debian:bookworm-slim AS build

ARG NGINX_VERSION=1.27.2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ make unzip \
    libaio-dev libc-dev libxslt1-dev libxml2-dev zlib1g-dev \
    libpcre3-dev libbz2-dev libssl-dev autoconf wget \
    lsb-release apt-transport-https ca-certificates

ENV USER=nonroot
ENV UID=10000

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/home/${USER}" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -q "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O - | tar xz -C /opt/

WORKDIR /opt/nginx-${NGINX_VERSION}
RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/dev/stderr \
    --http-log-path=/dev/stdout \
    --pid-path=/var/run/nginx/pid \
    --lock-path=/var/run/nginx/lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nonroot \
    --group=nonroot \
    --with-compat \
    --with-file-aio \
    --with-threads \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_degradation_module \
    --with-pcre \
    --with-pcre-jit \
    --with-cc-opt="-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -fPIC" \
    --with-ld-opt="-Wl,-z,relro -Wl,-z,now -pie" \
    && make -j"$(nproc)" \
    && make install

# Place libraries in a common output folder
RUN mkdir -p /var/cache/nginx/ /var/run/nginx /lib64 /out && \
  ldd "$(command -v nginx)" | awk 'NF == 4 { system("cp --parents " $3 " /out")}'

FROM scratch

ENV TZ="UTC"

COPY nginx.conf /etc/nginx/conf.d/nginx.conf
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/sbin/nginx /usr/sbin/
COPY --from=build --chown=10000:10001 /var/cache/nginx /var/cache/nginx
COPY --from=build --chown=10000:10001 /var/run/nginx /var/run/nginx

# Copy required libraries
COPY --from=build /out/ /

# Copy dynamic linker
COPY --from=build /lib64/ld-linux-*.so.* /lib64/

EXPOSE 8080

USER 10000:10001
STOPSIGNAL SIGTERM

ENTRYPOINT ["nginx"]
CMD ["-c", "/etc/nginx/conf.d/nginx.conf"]
