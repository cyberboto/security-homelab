# Security Homelab: Dylan Durandis

Cybersecurity student at the University at Albany (SUNY). Hands-on security engineering project built and tested in my own lab.

## [SOC Automation Lab: Detection, Response and Case Management](project-2-soc-automation/)

I built an automated SOC with SOAR capabilities in my home lab. It is an end-to-end pipeline that ingests security logs from Linux and Windows endpoints, detects attacks with a SIEM, triages and enriches alerts with threat intelligence, automatically blocks the attacker, and delivers each alert to the analyst team with an investigation ticket, all in under one second with no human intervention. Built-in health monitoring watches the pipeline itself, so if any component fails, I am alerted instead of attacks going unnoticed.

### Results
- **< 1 second** from detection to Slack alert and TheHive ticket
- **Automatic block** of SSH brute-force attackers after 8 attempts, released after 180 seconds
- **10 of 13** low-priority alerts filtered out automatically, so analysts see only what matters
- **2 attack techniques detected** across Linux and Windows: SSH brute force (MITRE T1110) and malicious file download (T1105)
- **16 of 16** test cases passed, documented with screenshots and logs

### Skills demonstrated
SIEM configuration and tuning · SOAR workflow automation · threat-intelligence enrichment · incident response and case management · Linux server administration · Docker · Windows endpoint monitoring · least-privilege access and secrets handling · systematic troubleshooting

**Tools:** Wazuh · n8n · TheHive · Sysmon · AbuseIPDB · Slack · Docker · Ubuntu · VMware

*All testing was done on systems I own, on my own home network.*
