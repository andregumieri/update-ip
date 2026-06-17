#!/bin/sh
set +m  # disable job control so sleep doesn't trigger setpgid

LAST_IP_FILE="/data/last_ip"
INTERVAL=300

log() {
  echo "$(date '+%Y-%m-%dT%H:%M:%S') $*"
}

if [ -z "$CLOUDFLARE_ZONE_ID" ] || [ -z "$CLOUDFLARE_RECORD_ID" ] || [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  log "ERROR: CLOUDFLARE_ZONE_ID, CLOUDFLARE_RECORD_ID and CLOUDFLARE_API_TOKEN must be set"
  exit 1
fi

mkdir -p /data

while true; do
  CURRENT_IP=$(curl -sf "https://api.ipify.org?format=json" | jq -r '.ip')

  if [ -z "$CURRENT_IP" ]; then
    log "ERROR: Failed to retrieve public IP, retrying in ${INTERVAL}s"
    sleep "$INTERVAL"
    continue
  fi

  LAST_IP=""
  if [ -f "$LAST_IP_FILE" ]; then
    LAST_IP=$(cat "$LAST_IP_FILE")
  fi

  if [ "$CURRENT_IP" = "$LAST_IP" ]; then
    log "IP unchanged ($CURRENT_IP), skipping update"
    sleep "$INTERVAL"
    continue
  fi

  log "IP changed: '$LAST_IP' -> '$CURRENT_IP', updating Cloudflare..."

  RESPONSE=$(curl -sf -X PATCH \
    "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${CLOUDFLARE_RECORD_ID}" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"content\":\"${CURRENT_IP}\"}")

  SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

  if [ "$SUCCESS" = "true" ]; then
    echo "$CURRENT_IP" > "$LAST_IP_FILE"
    log "Cloudflare DNS updated successfully to $CURRENT_IP"
  else
    ERRORS=$(echo "$RESPONSE" | jq -r '.errors')
    log "ERROR: Cloudflare update failed: $ERRORS"
  fi

  sleep "$INTERVAL"
done
