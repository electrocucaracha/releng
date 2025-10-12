#checkov:skip=CKV_DOCKER_2:Ensure that HEALTHCHECK instructions have been added to container images
FROM alpine:3.20

EXPOSE 123/udp

RUN apk --no-cache add openntpd==6.8_p1-r9

ENTRYPOINT ["/usr/sbin/ntpd"]
CMD ["-d" ,"-f", "/etc/ntpd.conf", "-s"]
