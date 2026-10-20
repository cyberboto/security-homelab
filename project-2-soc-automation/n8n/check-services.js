// n8n Code node "Check Services" (Health Check workflow, runs every 5 minutes)
// Mode: Run Once for All Items. Output feeds an If node: down_count > 0 -> Slack.
const checks = [
  { name: 'TheHive',         url: 'http://192.168.1.184:9000/api/status', ok: s => s === 200 },
  { name: 'Wazuh API',       url: 'https://192.168.1.211:55000/',         ok: s => s === 401 || s === 200 }, // 401 = up, asking for auth
  { name: 'Wazuh Dashboard', url: 'https://192.168.1.211/',               ok: s => s > 0 && s < 500 },
];

const results = [];
for (const c of checks) {
  const start = Date.now();
  let status = 0, error = '';
  try {
    const res = await this.helpers.httpRequest({
      method: 'GET',
      url: c.url,
      timeout: 5000,
      returnFullResponse: true,
      ignoreHttpStatusErrors: true,
      skipSslCertificateValidation: true, // lab uses self-signed certs
    });
    status = res.statusCode;
  } catch (e) {
    error = e.message;
  }
  results.push({ service: c.name, status, up: !error && c.ok(status), ms: Date.now() - start, error });
}

const down = results.filter(r => !r.up);
return [{ json: {
  checked_at: new Date().toISOString(),
  all_up: down.length === 0,
  down_count: down.length,
  down_services: down.map(r => `${r.service} (${r.error || 'HTTP ' + r.status})`).join(', '),
  results,
}}];
