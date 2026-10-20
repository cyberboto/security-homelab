#!/usr/bin/env python3
"""
Wazuh -> n8n custom integration.

Wazuh's integratord calls this script for every alert at or above the
configured <level>, passing:
  argv[1] = path to a temp file containing the alert JSON
  argv[3] = the <hook_url> from ossec.conf
It POSTs the full alert JSON to the n8n webhook and logs the result.

Install: /var/ossec/integrations/custom-n8n.py (root:wazuh, chmod 750)
Wrapper: cp /var/ossec/integrations/slack /var/ossec/integrations/custom-n8n
         (Wazuh's stock shell wrapper; runs custom-n8n.py with the same args)
Only the Python standard library is used, so nothing extra has to be installed.
"""
import sys
import json
import urllib.request
from datetime import datetime

LOG = "/var/ossec/logs/integrations.log"


def log(msg):
    with open(LOG, "a") as f:
        f.write(f"{datetime.now()} custom-n8n: {msg}\n")


def main():
    alert_file = sys.argv[1]
    hook_url = sys.argv[3]
    with open(alert_file) as f:
        alert = json.load(f)
    data = json.dumps(alert).encode("utf-8")
    req = urllib.request.Request(hook_url, data=data,
                                 headers={"Content-Type": "application/json"},
                                 method="POST")
    with urllib.request.urlopen(req, timeout=10) as r:
        log(f"sent rule {alert.get('rule', {}).get('id')} to {hook_url} -> HTTP {r.status}")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"ERROR: {e}")
        sys.exit(1)
