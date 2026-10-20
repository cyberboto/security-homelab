# Queries and commands used to reach each conclusion

| Question | Command / query | Where |
|---|---|---|
| Is Wazuh delivering alerts to n8n? | `tail -f /var/ossec/logs/integrations.log` | Wazuh VM |
| Is the integration loaded? | `grep "Enabling integration" /var/ossec/logs/ossec.log` | Wazuh VM |
| Why is it failing? | `grep "192.168.1.100" /var/ossec/logs/integrations.log` · `grep "unexpected EOF" /var/ossec/logs/ossec.log` | Wazuh VM |
| What does the integration config look like? | `grep -n -A6 "<integration>" /var/ossec/etc/ossec.conf` | Wazuh VM |
| Can Wazuh reach n8n? | `curl --max-time 10 -H "Content-Type: application/json" -d '{"test":"hello"}' http://192.168.1.31:5678/webhook/wazuh-alerts` | Wazuh VM |
| Is n8n listening? | `netstat -ano \| findstr LISTENING \| findstr :5678` | Host PC |
| Did my PC's IP change? | `ipconfig` | Host PC |
| Did active response run? | `tail -5 /var/ossec/logs/active-responses.log` | Wazuh VM |
| Which SSH rules fired, and do they have srcip? | `grep -o '"rule":{"level":[0-9]*,"description":"[^"]*","id":"5[0-9]*"\|"srcip":"[^"]*"' /var/ossec/logs/alerts/alerts.json \| tail -8` | Wazuh VM |
| Is the attacker blocked? | `iptables -L INPUT -n` | Wazuh VM |
| Is the attacker really cut off? | `ssh -o ConnectTimeout=5 fakeuser@192.168.1.211` → `Connection timed out` | Attacker VM |
| Are TheHive's containers up? | `docker ps` · `sudo docker stop/start thehive` (outage test) | TheHive VM |
| Is each service healthy? | `curl -s http://192.168.1.184:9000/api/status` · `curl -sk -w "%{http_code}" https://192.168.1.211:55000/` · `curl -s http://localhost:5678/healthz` | Host PC |
| Is the watchdog scheduled? | `systemctl list-timers n8n-watchdog.timer --no-pager` | Wazuh VM |
| Did each alert reach n8n and how long did it take? | n8n → Executions list (duration per run) | n8n UI |
| Was the ticket created and deduplicated? | TheHive → Alerts (Reference column); duplicate run returned *"Alert ... already exists in organisation SOC-Lab"* | TheHive UI |
