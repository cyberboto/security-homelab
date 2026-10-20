#!/bin/bash
# n8n health watchdog - runs on the Wazuh VM (a different host than n8n).
# Alerts Slack ONCE when n8n stops answering and ONCE when it recovers.
#
# Install:  /usr/local/bin/n8n-watchdog.sh  (root, chmod 700)
# Secret:   Slack webhook URL stored in /root/.slack_webhook (chmod 600), entered with:
#             read -s -p "Paste Slack webhook URL: " U; echo "$U" > /root/.slack_webhook; chmod 600 /root/.slack_webhook
# Test an outage without stopping n8n:
#             N8N_URL=http://192.168.1.31:5999/healthz /usr/local/bin/n8n-watchdog.sh
N8N_URL="${N8N_URL:-http://192.168.1.31:5678/healthz}"
SLACK=$(cat /root/.slack_webhook)
STATE=/var/tmp/n8n-watchdog.down
post() { curl -s -m 10 -X POST -H 'Content-type: application/json' --data "{\"text\":\"$1\"}" "$SLACK" >/dev/null; }

if curl -s -m 5 "$N8N_URL" | grep -q '"ok"'; then
  if [ -f "$STATE" ]; then
    post "🟢 *RECOVERED* — n8n is back up. Alert processing resumed. ($(date -u +%FT%TZ))"
    rm -f "$STATE"
  fi
  echo "n8n OK"
else
  if [ ! -f "$STATE" ]; then
    post "🔴 *SERVICE DOWN* — n8n (${N8N_URL}) is not responding. Wazuh alerts are NOT reaching Slack/TheHive. ($(date -u +%FT%TZ))"
    touch "$STATE"
  fi
  echo "n8n DOWN"
fi
