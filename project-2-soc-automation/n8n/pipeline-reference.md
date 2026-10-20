# n8n workflow reference

Exact node settings for the three workflows, so they can be rebuilt without the exported JSON.

## 1. SOC Alert Pipeline ("My workflow 2")

`Webhook → Edit Fields (Normalize) → Switch (Severity) → HTTP Request (AbuseIPDB) → Edit Fields1 (Enrich + Verdict) → [Slack, TheHive 5]`

**Error workflow:** Settings → Error Workflow = *Error Handler*

### Webhook
POST, path `wazuh-alerts` → production URL `http://<n8n-host>:5678/webhook/wazuh-alerts`

### Edit Fields: Normalize (Manual Mapping)
| Field | Type | Expression |
|---|---|---|
| rule_id | String | `{{ $json.body.rule.id }}` |
| level | Number | `{{ $json.body.rule.level }}` |
| description | String | `{{ $json.body.rule.description }}` |
| agent | String | `{{ $json.body.agent.name }}` |
| src_ip | String | `{{ $json.body.data?.srcip ?? $json.body.full_log?.match(/rhost=([^\s]+)/)?.[1] ?? 'none' }}` |
| user | String | `{{ $json.body.data?.srcuser ?? $json.body.data?.dstuser ?? 'none' }}` |
| mitre_id | String | `{{ $json.body.rule.mitre?.id?.join(', ') }}` |
| mitre_technique | String | `{{ $json.body.rule.mitre?.technique?.join(', ') }}` |
| timestamp | String | `{{ $json.body.timestamp }}` |
| full_log | String | `{{ $json.body.full_log }}` |

`src_ip` falls back to parsing `rhost=` from the raw log, because rule 2502 (PAM) alerts have no decoded `data.srcip`.

### Switch: Severity (Rules mode, "Convert types where required" ON)
| Output | Condition on `{{ $json.level }}` (Number) | Connected to |
|---|---|---|
| Critical | ≥ 12 | AbuseIPDB |
| High | ≥ 7 | AbuseIPDB |
| Low | < 7 | nothing (filtered) |

### HTTP Request: AbuseIPDB
- `GET https://api.abuseipdb.com/api/v2/check`
- Query: `ipAddress={{ $json.src_ip }}`, `maxAgeInDays=90`; header `Accept: application/json`
- Credential: Header Auth (`Key: <api key>`), **Allowed HTTP Request Domains = api.abuseipdb.com**

### Edit Fields1: Enrich + Verdict (Include Other Input Fields = All)
| Field | Expression |
|---|---|
| abuse_score | `{{ $json.data.abuseConfidenceScore }}` |
| abuse_reports | `{{ $json.data.totalReports }}` |
| ip_country | `{{ $json.data.countryCode ?? 'n/a' }}` |
| ip_isp | `{{ $json.data.isp ?? 'n/a' }}` |
| ip_public | `{{ $json.data.isPublic }}` |
| verdict | `{{ !$json.data.isPublic ? 'internal' : $json.data.abuseConfidenceScore >= 50 ? 'malicious' : $json.data.abuseConfidenceScore > 0 ? 'suspicious' : 'clean' }}` |
| alert (Object) | `{{ $('Switch').item.json }}` |

### Slack (HTTP Request POST to an Incoming Webhook; body field `text`)
```
🚨 *{{ $json.alert.level >= 12 ? 'CRITICAL' : 'HIGH' }} ALERT* — {{ $json.alert.description }}
*Rule:* {{ $json.alert.rule_id }} | *Level:* {{ $json.alert.level }} | *MITRE:* {{ $json.alert.mitre_id }} ({{ $json.alert.mitre_technique }})
*Host:* {{ $json.alert.agent }} | *Source IP:* {{ $json.alert.src_ip }} | *User:* {{ $json.alert.user }}
*Verdict:* {{ $json.verdict }} (AbuseIPDB score {{ $json.abuse_score }}, {{ $json.abuse_reports }} reports)
*Time:* {{ $json.alert.timestamp }}
```

### TheHive 5: Alert → Create
Credential: service account `n8n@soc.lab` (analyst role, API key), URL `http://192.168.1.184:9000`, allowed domain `192.168.1.184`.

| Field | Value |
|---|---|
| Title | `{{ $json.alert.description }} (Rule {{ $json.alert.rule_id }})` |
| Type / Source | `wazuh-alert` / `Wazuh` |
| Source Reference | `{{ $json.alert.rule_id }}-{{ $json.alert.timestamp }}` (dedup key) |
| Severity | `{{ $json.alert.level >= 12 ? 4 : 3 }}` (4 = Critical, 3 = High) |
| TLP / PAP / Status | Amber / Amber / New |
| Tags | `{{ ['wazuh', $json.alert.mitre_id, $json.verdict] }}` (must be an array) |
| Observable | type `ip`, value `{{ $json.alert.src_ip }}` |

## 2. Health Check
`Schedule Trigger (every 5 min) → Check Services (Code, see check-services.js) → If ({{ $json.down_count }} Number > 0) → Slack Down Alert (true branch only)`

```
🔴 *SERVICE DOWN* — {{ $json.down_services }}
*Checked at:* {{ $json.checked_at }}
*Action:* check the VM/service and restart it.
```

## 3. Error Handler
`Error Trigger → Slack Error Alert`
```
⚠️ *WORKFLOW FAILED* — {{ $json.workflow.name }}
*Node:* {{ $json.execution.lastNodeExecuted }}
*Error:* {{ $json.execution.error.message }}
*Execution:* {{ $json.execution.url }}
```
