#!/usr/bin/env python3
import json
import os
import sys
import time
import urllib.request
from datetime import datetime, timezone

INTERVAL = 300
LAST_IP_FILE = "/data/last_ip"

ZONE_ID = os.environ.get("CLOUDFLARE_ZONE_ID")
RECORD_ID = os.environ.get("CLOUDFLARE_RECORD_ID")
API_TOKEN = os.environ.get("CLOUDFLARE_API_TOKEN")


def log(msg):
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")
    print(f"{ts} {msg}", flush=True)


def get_public_ip():
    with urllib.request.urlopen("https://api.ipify.org?format=json", timeout=10) as r:
        return json.loads(r.read())["ip"]


def get_last_ip():
    try:
        with open(LAST_IP_FILE) as f:
            return f.read().strip()
    except FileNotFoundError:
        return ""


def save_ip(ip):
    with open(LAST_IP_FILE, "w") as f:
        f.write(ip)


def update_cloudflare(ip):
    url = f"https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/dns_records/{RECORD_ID}"
    data = json.dumps({"content": ip}).encode()
    req = urllib.request.Request(url, data=data, method="PATCH")
    req.add_header("Authorization", f"Bearer {API_TOKEN}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())


if not all([ZONE_ID, RECORD_ID, API_TOKEN]):
    log("ERROR: CLOUDFLARE_ZONE_ID, CLOUDFLARE_RECORD_ID and CLOUDFLARE_API_TOKEN must be set")
    sys.exit(1)

os.makedirs("/data", exist_ok=True)
log("Starting update-ip loop (interval: 5 min)")

while True:
    try:
        current_ip = get_public_ip()
    except Exception as e:
        log(f"ERROR: Failed to retrieve public IP: {e}")
        time.sleep(INTERVAL)
        continue

    last_ip = get_last_ip()

    if current_ip == last_ip:
        log(f"IP unchanged ({current_ip}), skipping update")
        time.sleep(INTERVAL)
        continue

    log(f"IP changed: '{last_ip}' -> '{current_ip}', updating Cloudflare...")

    try:
        response = update_cloudflare(current_ip)
        if response.get("success"):
            save_ip(current_ip)
            log(f"Cloudflare DNS updated successfully to {current_ip}")
        else:
            log(f"ERROR: Cloudflare update failed: {response.get('errors')}")
    except Exception as e:
        log(f"ERROR: Cloudflare request failed: {e}")

    time.sleep(INTERVAL)
