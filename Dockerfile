FROM python:3.12-alpine

ENV CLOUDFLARE_ZONE_ID=""
ENV CLOUDFLARE_RECORD_ID=""
ENV CLOUDFLARE_API_TOKEN=""

COPY update-ip.py /usr/local/bin/update-ip.py

RUN mkdir -p /data

VOLUME ["/data"]

CMD ["python3", "/usr/local/bin/update-ip.py"]
