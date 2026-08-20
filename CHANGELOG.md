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
