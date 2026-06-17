FROM alpine:3.20

RUN apk add --no-cache curl jq

ENV CLOUDFLARE_ZONE_ID=""
ENV CLOUDFLARE_RECORD_ID=""
ENV CLOUDFLARE_API_TOKEN=""

COPY update-ip.sh /usr/local/bin/update-ip.sh
RUN chmod +x /usr/local/bin/update-ip.sh

VOLUME ["/data"]

CMD ["/usr/local/bin/update-ip.sh"]
