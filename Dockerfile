FROM alpine:3.20
RUN apk add --no-cache rsync openssh-client tzdata ca-certificates
WORKDIR /app
COPY pull.sh /app/pull.sh
COPY crontab /etc/crontabs/root
RUN chmod +x /app/pull.sh && chmod 600 /etc/crontabs/root
VOLUME /backups
ENV TZ=America/Argentina/Buenos_Aires
CMD /app/pull.sh && crond -f -l 8


