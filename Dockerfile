FROM alpine:3.20

RUN apk add --no-cache curl jq dcron

ENV CLOUDFLARE_ZONE_ID=""
ENV CLOUDFLARE_RECORD_ID=""
ENV CLOUDFLARE_API_TOKEN=""

COPY update-ip.sh /usr/local/bin/update-ip.sh
RUN chmod +x /usr/local/bin/update-ip.sh

RUN mkdir -p /data

# Pass env vars to cron jobs (cron doesn't inherit env by default)
RUN echo '* * * * * export $(cat /etc/environment | xargs) && /usr/local/bin/update-ip.sh >> /proc/1/fd/1 2>&1' > /etc/crontabs/root

VOLUME ["/data"]

CMD ["/bin/sh", "-c", "printenv | grep -E '^(CLOUDFLARE)' > /etc/environment && crond -f -l 8"]
