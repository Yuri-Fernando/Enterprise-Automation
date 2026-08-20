-- =============================================================================
-- Enterprise Cloud Automation & Infrastructure Platform
-- Schema MySQL 8 — executions, incidents, inventory
-- =============================================================================
-- Contrato de dados para `incidents` (compatibilidade com a trilha de
-- automação Python, que grava relatórios de incidente com estas chaves):
--   host, environment, problem, root_cause, action, validation,
--   recovery_time_seconds, status, created_at
-- =============================================================================

SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE DATABASE IF NOT EXISTS `caterpillar_automation`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `caterpillar_automation`;

-- -----------------------------------------------------------------------------
-- Tabela: executions
-- Registra cada execução de ferramenta de automação (Terraform, Ansible,
-- PowerShell, Python) disparada pelo Automation Controller. Usada para
-- auditoria/histórico ("o que rodou, quando, com qual resultado").
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `executions` (
  `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  -- ferramenta que gerou a execução
  `tool`           ENUM('terraform', 'ansible', 'powershell', 'python')
                                    NOT NULL,
  -- ação executada, ex.: 'apply', 'plan', 'playbook:configure_nginx',
  -- 'script:health_check', livre o suficiente para cobrir os 4 tools
  `action`         VARCHAR(255)     NOT NULL,
  -- ambiente alvo da execução (dev/staging/prod), consistente com o
  -- contrato de dados usado em `incidents`
  `environment`    VARCHAR(50)      NOT NULL,
  `status`         ENUM('success', 'failed') NOT NULL,
  `started_at`     DATETIME(3)      NOT NULL,
  `finished_at`    DATETIME(3)      NULL,
  -- resumo humano-legível da saída (stdout truncado, mensagem de erro, etc.)
  `output_summary` TEXT             NULL,
  `created_at`     TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  -- consultas mais comuns no dashboard/relatórios: filtrar por status,
  -- por ambiente, e ordenar/filtrar por data de criação
  KEY `idx_executions_status`      (`status`),
  KEY `idx_executions_environment` (`environment`),
  KEY `idx_executions_created_at`  (`created_at`),
  KEY `idx_executions_tool`        (`tool`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Histórico de execuções de Terraform/Ansible/PowerShell/Python disparadas pelo automation controller';

-- -----------------------------------------------------------------------------
-- Tabela: incidents
-- Registra incidentes detectados pelo módulo de self-healing
-- (automation/troubleshooting/) e sua remediação. Formato de campos segue
-- o contrato de dados combinado com a trilha de automação Python
-- (ex.: INCIDENT #017 do escopo.md — nginx caiu, restart via Ansible).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `incidents` (
  `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- host afetado, ex.: 'linux-web-02'
  `host`                   VARCHAR(255)    NOT NULL,
  -- ambiente do host afetado (dev/staging/prod)
  `environment`            VARCHAR(50)     NOT NULL,
  -- descrição do problema detectado, ex.: 'nginx unavailable'
  `problem`                VARCHAR(500)    NOT NULL,
  -- causa raiz diagnosticada, ex.: 'service stopped'
  `root_cause`             TEXT            NULL,
  -- ação de remediação executada, ex.: 'restart via Ansible'
  `action`                 VARCHAR(500)    NULL,
  -- como a recuperação foi validada, ex.: 'HTTP 200'
  `validation`             VARCHAR(500)    NULL,
  -- tempo total de recuperação em segundos (detecção -> validação OK)
  `recovery_time_seconds`  INT UNSIGNED    NULL,
  `status`                 ENUM('OPEN', 'RESOLVED') NOT NULL DEFAULT 'OPEN',
  `created_at`             TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `resolved_at`            TIMESTAMP       NULL,
  PRIMARY KEY (`id`),
  -- dashboard filtra/ordena incidentes por status (OPEN vs RESOLVED),
  -- por ambiente e por data (timeline de incidentes recentes)
  KEY `idx_incidents_status`      (`status`),
  KEY `idx_incidents_environment` (`environment`),
  KEY `idx_incidents_created_at`  (`created_at`),
  KEY `idx_incidents_host`        (`host`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Incidentes detectados e remediados pelo módulo de self-healing (automation/troubleshooting/)';

-- -----------------------------------------------------------------------------
-- Tabela: inventory
-- Snapshot do inventário de recursos AWS coletado via boto3
-- (automation/inventory/). Usada pelo dashboard para mostrar o estado
-- atual da infraestrutura (EC2, RDS, etc.).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `inventory` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  -- identificador do recurso na AWS, ex.: 'i-0abcd1234ef567890'
  `resource_id`      VARCHAR(255)    NOT NULL,
  -- tipo de recurso: ec2, rds, s3, alb, asg, etc.
  `resource_type`    VARCHAR(50)     NOT NULL,
  `region`           VARCHAR(50)     NOT NULL,
  -- status reportado pela AWS (running, stopped, available, etc.)
  `status`           VARCHAR(50)     NOT NULL,
  -- tags do recurso (Environment, Project, ManagedBy, Owner, CostCenter...)
  -- armazenadas como JSON para flexibilidade sem precisar de tabela extra
  `tags`             JSON            NULL,
  `last_checked_at`  DATETIME(3)     NOT NULL,
  `created_at`       TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  -- um recurso AWS não deve aparecer duplicado no inventário
  UNIQUE KEY `uq_inventory_resource_id` (`resource_id`),
  -- dashboard filtra por tipo de recurso, status e região com frequência
  KEY `idx_inventory_resource_type`   (`resource_type`),
  KEY `idx_inventory_status`          (`status`),
  KEY `idx_inventory_region`          (`region`),
  KEY `idx_inventory_last_checked_at` (`last_checked_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Inventário de recursos AWS coletado via boto3 (automation/inventory/)';
