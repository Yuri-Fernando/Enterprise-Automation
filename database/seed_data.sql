-- =============================================================================
-- Enterprise Cloud Automation & Infrastructure Platform
-- Dados de exemplo (modo demo) — usados também em
-- `dashboard/js/data.example.json` para manter o dashboard estático
-- consistente com o banco de dev.
-- =============================================================================

USE `caterpillar_automation`;

-- -----------------------------------------------------------------------------
-- executions
-- -----------------------------------------------------------------------------
INSERT INTO `executions`
  (`id`, `tool`, `action`, `environment`, `status`, `started_at`, `finished_at`, `output_summary`)
VALUES
  (1, 'terraform', 'plan', 'dev',
      'success', '2026-08-15 09:12:03.120', '2026-08-15 09:14:47.900',
      'Plan: 12 to add, 0 to change, 0 to destroy. No security findings blocked by checkov.'),
  (2, 'ansible', 'playbook:configure_nginx', 'dev',
      'success', '2026-08-16 10:02:11.000', '2026-08-16 10:03:05.500',
      'PLAY RECAP: linux-web-02 ok=8 changed=3 unreachable=0 failed=0'),
  (3, 'powershell', 'script:Get-ServiceStatus', 'staging',
      'success', '2026-08-17 14:20:00.000', '2026-08-17 14:20:38.250',
      'Checked 6 Windows services on win-app-01. All Running.'),
  (4, 'python', 'script:health_check', 'prod',
      'failed', '2026-08-18 03:45:12.000', '2026-08-18 03:45:19.700',
      'HTTP health check failed for linux-web-05:443 (connection refused). Incident opened.'),
  (5, 'terraform', 'validate', 'staging',
      'success', '2026-08-18 22:10:00.000', '2026-08-18 22:10:26.400',
      'Success! The configuration is valid.');

-- -----------------------------------------------------------------------------
-- incidents
-- Linha 1 corresponde ao exemplo do escopo.md ("Incident #017": nginx caiu,
-- restart via Ansible, recovery 13s, RESOLVED). O número #017 é o
-- identificador narrativo do escopo; o id real da tabela segue AUTO_INCREMENT.
-- -----------------------------------------------------------------------------
INSERT INTO `incidents`
  (`id`, `host`, `environment`, `problem`, `root_cause`, `action`, `validation`, `recovery_time_seconds`, `status`, `created_at`, `resolved_at`)
VALUES
  (1, 'linux-web-02', 'dev',
      'nginx unavailable',
      'nginx service stopped unexpectedly',
      'restart via Ansible (playbook: restart_nginx.yml)',
      'HTTP 200 on http://linux-web-02/health',
      13, 'RESOLVED', '2026-08-16 03:14:02', '2026-08-16 03:14:15'),
  (2, 'win-app-01', 'staging',
      'IIS application pool stopped',
      'worker process crashed (out of memory)',
      'restart application pool via PowerShell (Restart-WebAppPool)',
      'HTTP 200 on /health',
      27, 'RESOLVED', '2026-08-17 08:02:10', '2026-08-17 08:02:37'),
  (3, 'linux-db-01', 'prod',
      'disk usage above threshold (92%)',
      'log rotation misconfigured, application logs filled /var/log',
      'cleared old logs and fixed logrotate config via Ansible',
      'disk usage back to 61%',
      95, 'RESOLVED', '2026-08-17 23:55:00', '2026-08-17 23:56:35'),
  (4, 'linux-web-05', 'prod',
      'service unresponsive on port 443',
      NULL,
      NULL,
      NULL,
      NULL, 'OPEN', '2026-08-19 07:30:00', NULL),
  (5, 'win-app-02', 'dev',
      'high CPU usage (98%) sustained for 10 minutes',
      'runaway background job stuck in a retry loop',
      'killed stuck process and restarted service via PowerShell',
      'CPU usage back to 12%',
      42, 'RESOLVED', '2026-08-18 16:12:00', '2026-08-18 16:12:42');

-- -----------------------------------------------------------------------------
-- inventory
-- -----------------------------------------------------------------------------
INSERT INTO `inventory`
  (`id`, `resource_id`, `resource_type`, `region`, `status`, `tags`, `last_checked_at`)
VALUES
  (1, 'i-0a1b2c3d4e5f67890', 'ec2', 'sa-east-1', 'running',
      JSON_OBJECT('Environment', 'dev', 'Project', 'enterprise-automation', 'ManagedBy', 'terraform', 'Owner', 'Yuri', 'CostCenter', 'lab'),
      '2026-08-19 07:58:00.000'),
  (2, 'i-0f9e8d7c6b5a43210', 'ec2', 'sa-east-1', 'stopped',
      JSON_OBJECT('Environment', 'staging', 'Project', 'enterprise-automation', 'ManagedBy', 'terraform', 'Owner', 'Yuri', 'CostCenter', 'lab'),
      '2026-08-19 07:58:00.000'),
  (3, 'db-caterpillar-dev', 'rds', 'sa-east-1', 'available',
      JSON_OBJECT('Environment', 'dev', 'Project', 'enterprise-automation', 'ManagedBy', 'terraform', 'Owner', 'Yuri', 'CostCenter', 'lab'),
      '2026-08-19 07:58:00.000'),
  (4, 'caterpillar-automation-artifacts', 's3', 'sa-east-1', 'active',
      JSON_OBJECT('Environment', 'prod', 'Project', 'enterprise-automation', 'ManagedBy', 'terraform', 'Owner', 'Yuri', 'CostCenter', 'lab'),
      '2026-08-19 07:58:00.000'),
  (5, 'caterpillar-web-alb', 'alb', 'sa-east-1', 'active',
      JSON_OBJECT('Environment', 'prod', 'Project', 'enterprise-automation', 'ManagedBy', 'terraform', 'Owner', 'Yuri', 'CostCenter', 'lab'),
      '2026-08-19 07:58:00.000');
