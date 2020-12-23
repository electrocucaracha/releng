FROM alpine:3.12

EXPOSE 123/udp

RUN apk --no-cache add openntpd==6.2_p3-r3

ENTRYPOINT ["/usr/sbin/ntpd"]
CMD ["-d" ,"-f", "/etc/ntpd.conf", "-s"]
