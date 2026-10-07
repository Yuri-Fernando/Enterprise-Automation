# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui.

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/)
e versionamento [SemVer](https://semver.org/lang/pt-BR/).

O roadmap segue os releases definidos no escopo original (`escopo.md`):
Terraform Foundation → Automation → DevOps/CI-CD → Enterprise → Self-Healing.

## [Unreleased]
### Pending (fora do escopo do código — ver "Pendências / Sua Parte" em `PROJECT_LOG.md`)
- `terraform apply` real em `dev` (gera custo AWS).
- Secrets do GitHub Actions (OIDC/`AWS_ACCESS_KEY_ID`) para os workflows de
  CI rodarem `terraform plan` contra AWS de verdade.
- Docker Desktop rodando localmente para `database/docker-compose.yml`.

## [1.1.0-dev] - 2026-10-07 — DevOps/Cloud hardening
### Added
- **Observability real, local, versionada** (`observability/`):
  Prometheus + Grafana (datasources/dashboards provisionados como código,
  não clicados na UI) + Loki/Promtail (logs centralizados de todo
  container do stack), via `docker-compose.yml`, validados de ponta a
  ponta (todos os 6 containers up, Prometheus raspando os 3 targets,
  Grafana servindo o dashboard `automation-overview` provisionado, Loki
  recebendo logs reais do `automation-controller`). `run-local.sh`/`.ps1`
  contornam bind-mounts do Docker Desktop que falham quando o repo está
  numa pasta sincronizada por nuvem (Google Drive/OneDrive).
- **Exporter Prometheus real** (`automation/metrics/exporter.py`):
  `/metrics`, `/healthz`, `/ready` servidos por um HTTP server real
  (`http.server` + `prometheus_client`), lendo de MySQL quando disponível
  ou do dataset demo (`dashboard/js/data.example.json`) com fallback
  gracioso. Novo comando `automation metrics-serve` no CLI.
- **`Dockerfile`** (raiz do repo): primeira imagem real do
  `automation-controller` — até então `helm/automation-controller/`
  referenciava uma imagem que nunca existiu. Non-root (uid/gid 10001),
  sem `HEALTHCHECK` (liveness/readiness são dos probes do Kubernetes).
- **SLI/SLO/MTTR real** (`automation/reports/slo_report.py`): MTTR e SLI
  de disponibilidade (proxy: taxa de resolução) calculados a partir de
  incidentes reais, com error budget e alvo declarado. Novo comando
  `automation slo-report`. Painel de SLO/error budget adicionado ao
  dashboard Grafana.
- **Trivy + SBOM** (`security/trivy-scan.sh`/`.ps1`): scan real de
  filesystem (deps + Dockerfile/Helm/K8s, excluindo `terraform/` — já
  coberto pelo Checkov) e da imagem `automation-controller`, SBOM
  CycloneDX (`trivy`) + SPDX (`syft`) versionados em `security/sbom/`.
  Novo workflow `.github/workflows/trivy-sbom.yml`.
- **OPA/Conftest + Kyverno wired no CI de verdade**
  (`.github/workflows/policy-gate.yml`): fixtures reais testados
  (`tests/terraform/test-opa-policies.sh`,
  `tests/terraform/test-kyverno-policies.sh`) — ver "Fixed" abaixo pelo
  bug real encontrado na policy de tags.
- **`terraform/modules/gcp/`**: módulo pequeno (GCS bucket + VPC/subnet)
  demonstrando Terraform multi-cloud — nunca `plan`/`apply`'d contra um
  projeto GCP real, só `validate` (ver README do módulo).
- **`terraform/modules/budget/`**: AWS Budgets (orçamento mensal + alertas
  ACTUAL/FORECASTED, filtrado por tag) — `validate` apenas, nunca aplicado.
- **Chaos/failure tests** (`automation/tests/test_chaos_resilience.py`):
  injeção real de falha (kill -9 em processo real, repetido em loop) e
  verificação de convergência para RESOLVED; cenário de falha
  irrecuperável validando degradação correta para OPEN (não exceção, não
  falso RESOLVED).
- **Teste de propagação de tags** (`tests/python/test_tag_propagation.py`):
  valida estaticamente que todo recurso taggeável de `terraform/modules/*`
  propaga `var.tags`/`var.labels` — pré-condição para o `cost_filter` do
  módulo de budget funcionar.
- **`Jenkinsfile`**: pipeline espelhando os workflows reais do GitHub
  Actions (lint/security/policy-gate/test/build) — não testado contra um
  Jenkins real (sem infra Jenkins neste lab).
- **`requirements.txt`/`requirements-dev.txt`**: faltavam apesar de
  `python-tests.yml` já esperar por eles.

### Fixed
- **Bug real em `policies/opa/terraform_tags.rego`**: exigia chaves de tag
  minúsculas que nunca batiam com as tags reais (capitalizadas) deste
  projeto — a policy "passava" sempre, mas nunca validava nada de
  verdade. Corrigida para usar `tags_all` e as chaves reais; confirmado
  rodando `terraform plan` de verdade contra LocalStack (sem custo AWS).
- **`terraform/modules/compute`**: nome do ALB/target group excedia o
  limite de 32 caracteres da AWS para `name_prefix` longos (ex.:
  `enterprise-cloud-automation-dev`) — `terraform apply` real teria
  falhado. Truncado com `substr()`.
- **`automation/troubleshooting/remediation.py`**: `restart_local_process`
  deixava um `FileNotFoundError` não tratado escapar quando
  `start_command` apontava para um binário inexistente, em vez de
  degradar graciosamente como `run_ansible_playbook`/`run_powershell_script`
  já faziam — encontrado pelo teste de chaos engineering acima.
- **`helm/automation-controller/templates/deployment.yaml`**: faltava
  `securityContext` real (non-root, `readOnlyRootFilesystem`, capabilities
  dropped, seccomp) — 13 findings do Trivy (3 HIGH) reduzidos a 1 MEDIUM
  (falso positivo de allowlist de registry).

## [1.0.0] - 2026-08-20
### Added
- Dashboard: gráfico de pizza "Incidentes por status" e gráfico de barras
  empilhadas "Execuções por ferramenta" (Chart.js via CDN), em
  `dashboard/index.html` + `dashboard/js/app.js`.

## [0.4.0] - 2026-08-19 — Enterprise
### Added
- `terraform/modules/monitoring/`: alarmes CloudWatch (EC2/ASG, ALB, RDS)
  opt-in, tópico SNS opcional, log groups genéricos.
- `terraform/modules/database/outputs.tf` (endpoint, ARNs, subnet group).
- `database/`: schema MySQL (`executions`, `incidents`, `inventory`),
  `seed_data.sql`, `docker-compose.yml` para MySQL local de desenvolvimento.
- `dashboard/`: CSS/JS de observabilidade (cards de resumo, tabela de
  inventário, tabela de execuções, timeline de incidentes), lendo
  `js/data.example.json`.

## [0.3.0] - 2026-08-19 — DevOps
### Added
- `.github/workflows/`: `terraform-ci.yml` (fmt/validate/plan + checkov/
  tflint), `security-scan.yml`, `ansible-lint.yml`, `python-tests.yml`,
  `powershell-tests.yml`.
- `.checkov.yaml`, `.tflint.hcl`, `.pre-commit-config.yaml`, `SECURITY.md`.
- `tests/terraform/` e `tests/ansible/`: checagens estáticas locais
  (fmt/validate sem apply, yamllint/syntax-check).

## [0.2.0] - 2026-08-19 — Automation
### Added
- `automation/`: CLI (Click) com `health-check`, `inventory`,
  `incident run`, `report`; orquestrador de self-healing (detecta →
  diagnostica → remedia → valida → gera incidente); inventário AWS via
  boto3; 51 testes pytest (incl. `moto` para AWS mockada).
- `ansible/roles/webserver` completa (configure/firewall/vhost + healthz) e
  `ansible/playbooks/` (`site`, `deploy`, `healthcheck`, `remediation`).
- `powershell/modules/InfraOps` (health/service/disk/user/firewall) +
  scripts + testes Pester.
- 6 notebooks Jupyter executáveis em `notebooks/`, um por etapa do roadmap
  (00_overview → 05_self_healing_incident), todos rodados de ponta a ponta
  sem erro.

## [0.1.0] - 2026-08-19 — Terraform Foundation
### Added
- Estrutura inicial do repositório (Terraform, Ansible, PowerShell, automation
  Python, database, dashboard, notebooks, docs, testes).
- `terraform/modules/{networking,compute,database,iam,security}` e
  `terraform/environments/{dev,staging,prod}` (`terraform validate` OK nos
  3, sem `plan`/`apply`).
- `PROJECT_LOG.md` como registro central de decisões e histórico de sessões.
- `CHANGELOG.md` com versionamento semântico.
- Licença MIT, `.gitignore`, `VERSION`.
- Epics documentados em `docs/epics/` (Infrastructure Foundation, Compute,
  Configuration Automation, CI/CD, Observability, Security).

<!--
Template para novas entradas:

## [x.y.z] - AAAA-MM-DD
### Added
- ...
### Changed
- ...
### Fixed
- ...
### Security
- ...
-->
