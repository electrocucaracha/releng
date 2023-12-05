FROM alpine:3.18

EXPOSE 123/udp

RUN apk --no-cache add openntpd==6.8_p1-r9

ENTRYPOINT ["/usr/sbin/ntpd"]
CMD ["-d" ,"-f", "/etc/ntpd.conf", "-s"]
