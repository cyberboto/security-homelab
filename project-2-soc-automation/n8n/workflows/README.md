# Exported n8n workflows

Put the three exported workflow files here: `soc-alert-pipeline.json`, `health-check.json` and `error-handler.json`.

**Export:** open each workflow in n8n, then `...` → **Download**.

**Sanitize before committing.** The Slack Incoming Webhook URL is saved in plain text inside the HTTP Request nodes, and anyone with that URL can post to the Slack workspace. API keys stay in n8n's encrypted credential store; the export only references them by name and ID. Run this in PowerShell on each file:

```powershell
(Get-Content .\health-check.raw.json -Raw) -replace 'https://hooks\.slack\.com/services/[^"]+','https://hooks.slack.com/services/REDACTED' | Set-Content .\health-check.json
Select-String -Path .\*.json -Pattern 'hooks.slack.com/services/T'   # must return nothing
```

(`*.raw.json` files are ignored by `.gitignore`, so only the sanitized copies get committed.)
