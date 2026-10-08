# 🏗️ Enterprise Cloud Automation Platform — IaC, self-healing e observabilidade para infraestrutura corporativa

### Terraform · AWS · GCP · Ansible · PowerShell · Python · GitHub Actions · Jenkins · MySQL · Prometheus/Grafana/Loki · OPA/Kyverno · Trivy

[![terraform-ci](https://github.com/Yuri-Fernando/enterprise-cloud-automation-platform/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/Yuri-Fernando/enterprise-cloud-automation-platform/actions/workflows/terraform-ci.yml)
[![policy-gate](https://github.com/Yuri-Fernando/enterprise-cloud-automation-platform/actions/workflows/policy-gate.yml/badge.svg)](https://github.com/Yuri-Fernando/enterprise-cloud-automation-platform/actions/workflows/policy-gate.yml)
![testes](https://img.shields.io/badge/testes-74%20pytest%20%2B%209%20pester-0a8a0a)
![MTTR](https://img.shields.io/badge/MTTR-44.25s-c8742a)
![versão](https://img.shields.io/badge/vers%C3%A3o-v1.1.0--dev-4a5563) ![license](https://img.shields.io/badge/license-MIT-4a5563)

## Status

🟡 **Em desenvolvimento — v1.1.0-dev (DevOps/Cloud hardening)**

O roadmap de código completo do escopo original (Terraform Foundation →
Automation → DevOps → Enterprise → Self-Healing) está implementado e
testado localmente, incluindo uma segunda rodada de hardening (observabilidade
real, segurança de imagem/supply chain, policy as code testado de ponta a
ponta, multi-cloud, chaos engineering, SLO/MTTR). O que falta para
"concluído" é o `terraform apply` real contra uma conta AWS/GCP — decisão
deliberada do usuário, pois gera custo de nuvem.

| Capacidade | Status |
|---|---|
| Terraform (VPC · compute · RDS · IAM · monitoring) | ✅ 6 módulos + 3 environments, `validate` OK |
| Ansible (Linux) / PowerShell (Windows) | ✅ roles + playbooks + módulo `InfraOps` + Pester |
| Controller Python (inventário · self-healing · CLI) | ✅ com 74 testes pytest |
| CI/CD (GitHub Actions: 7 workflows) | ✅ fmt/validate/plan, security scan, policy gate, Trivy+SBOM |
| CI alternativo (Jenkins) | 🗺️ `Jenkinsfile` espelha os workflows reais — não testado contra Jenkins real |
| Schema MySQL + dashboard de observabilidade | ✅ com gráficos Chart.js |
| Observabilidade (Prometheus · Grafana · Loki/Promtail) | ✅ stack local real via `docker compose`, validada ponta a ponta |
| Segurança de imagem/supply chain (Trivy + SBOM) | ✅ 0 CRITICAL, SBOM CycloneDX/SPDX versionado |
| Policy as Code (OPA/conftest + Kyverno) | ✅ testado no CI contra fixtures reais — bug de case-sensitivity corrigido |
| Multi-cloud (GCP) | 🗺️ módulo validado, nunca `plan`/`apply`'d |
| Custo/orçamento (AWS Budgets) | 🗺️ módulo validado, nunca aplicado |
| Chaos/failure testing | ✅ `test_chaos_resilience.py` |
| SLI/SLO/MTTR | ✅ calculado a partir de incidentes reais + painel Grafana |
| `terraform apply` real (AWS/GCP) | 🗺️ planejado — decisão/custo do usuário |

---

## Descrição / Contexto

Plataforma de automação de infraestrutura corporativa construída inteiramente
como peça de portfólio, inspirada pelos requisitos técnicos de uma vaga
pública de **Enterprise Automation Engineer**. **Não é software da
Caterpillar nem a representa** — nenhum dado, cliente ou ambiente de produção
real está envolvido.

O projeto reproduz o ciclo de vida completo de uma plataforma enterprise:
provisionamento via **Infrastructure as Code** (Terraform, AWS + GCP),
configuração de servidores Linux/Windows (Ansible/PowerShell), orquestração e
troubleshooting automatizado em Python (self-healing), governança de pipeline
(CI/CD, Policy as Code, scan de segurança/SBOM), observabilidade real
(Prometheus/Grafana/Loki) e persistência de execuções/incidentes em MySQL.

Posicionamento no portfólio: esta é a **Cloud Platform Engineering Reference
Implementation** — a camada de infraestrutura e entrega sobre a qual outros
workloads do portfólio rodam (ver `## 🔗 Projetos Relacionados`).

---

## 🧭 Origem do Projeto

O projeto nasceu de uma análise dos requisitos técnicos de uma vaga pública
de Enterprise Automation Engineer (Terraform como núcleo de IaC, Ansible +
PowerShell para configuração multiplataforma, CI/CD com governança, Python
para orquestração/self-healing). Dessas premissas vieram as decisões que
definiram a construção:

1. Terraform central, com Ansible/PowerShell como camadas de configuração —
   alinhamento 1:1 com os requisitos técnicos do perfil.
2. Nenhum `terraform apply` automático desde o início — evitar custo AWS sem
   aprovação explícita; apenas `validate`/`plan` reais em todas as fases.
3. Self-healing como fluxo central de automação (detectar → diagnosticar →
   remediar → validar → registrar incidente), reproduzindo o cenário
   "Incident #017" descrito no escopo original da vaga.
4. Versionamento SemVer alinhado ao roadmap (`v0.1` Terraform Foundation →
   `v1.0` Self-Healing), para poder contar a evolução via `git log`/changelog
   em entrevista.
5. Numa segunda rodada de auditoria de portfólio (item "DevOps/Cloud" de
   `Auditoria_Portfolio_Skills_Stacks_Repos_Certificacoes.txt`), identificada
   a lacuna de observabilidade real, segurança de supply chain, Policy as
   Code testado de verdade, multi-cloud e SLO — motivando a sessão de
   hardening que gerou a v1.1.0-dev.

O projeto foi construído em trilhas paralelas, com histórico completo de
decisões e sessões em [`PROJECT_LOG.md`](PROJECT_LOG.md) e changelog por
versão em [`CHANGELOG.md`](CHANGELOG.md).

---

## 🎯 Objetivo

- Demonstrar Terraform como núcleo de Infrastructure as Code (módulos
  reutilizados em múltiplos ambientes e, opcionalmente, múltiplas nuvens).
- Configurar servidores Linux via Ansible e Windows via PowerShell.
- Construir um controller Python de orquestração, inventário e
  troubleshooting automatizado (self-healing).
- Integrar CI/CD com governança real: lint/scan de segurança, Policy as Code
  (OPA/Kyverno) testado contra fixtures, SBOM e scan de imagem.
- Expor observabilidade real (métricas, logs, dashboards) via Prometheus,
  Grafana e Loki — não apenas um dashboard estático.
- Calcular indicadores de confiabilidade (MTTR, disponibilidade/SLO) a partir
  de dados reais de incidentes, com seus limites declarados explicitamente.
- Documentar todo o processo com notebooks executáveis e logs de decisão.

---

## 🔬 Linha de Desenvolvimento

- Infrastructure as Code multi-cloud (Terraform: AWS + GCP).
- Configuração de servidores multiplataforma (Ansible/Linux, PowerShell/Windows).
- Orquestração e self-healing em Python (detecção → diagnóstico → remediação → validação).
- Governança de pipeline: CI/CD, Policy as Code, scan de segurança/SBOM.
- Observabilidade: métricas (Prometheus), logs (Loki/Promtail), dashboards (Grafana).
- Confiabilidade: chaos engineering, SLI/SLO/MTTR.
- FinOps básico: tagging e orçamento (AWS Budgets).

---

## 🏗️ Arquitetura

```text
                        GitHub
                          │
                    Pull Request
                          │
                          ▼
                  GitHub Actions (7 workflows)
     ┌──────────┬──────────┼──────────┬──────────┐
     │          │          │          │          │
terraform-ci  security-  policy-   trivy-sbom  python/powershell
(fmt/validate/  scan     gate      (Trivy +       -tests
   plan)      (checkov/  (OPA/       SBOM)
              tflint)    Kyverno)
                          │
                          ▼
                    Terraform Apply *
                          │
                          ▼
                    AWS            GCP (módulo validado)
          ┌───────────────┼────────────────┐
          │               │                │
         VPC             EC2              RDS
          │               │                │
     Subnets/SG      Linux/Windows       MySQL
                          │
                ┌─────────┴─────────┐
                ▼                   ▼
             Ansible            PowerShell
                │                   │
                └─────────┬─────────┘
                          ▼
              Automation Controller (Python)
                          │
          ┌───────────────┼────────────────┐
          ▼               ▼                ▼
    Health Check      Inventory        Remediation
   (self-healing)      (boto3)       (local/Ansible/PS)
          │                                 │
          └────────────────┬────────────────┘
                            ▼
                 MySQL (execuções/incidentes)
                            │
              ┌─────────────┼─────────────┐
              ▼                           ▼
    Dashboard (Bootstrap/Chart.js)   Observability stack
                                    (Prometheus/Grafana/Loki)
```

`*` `terraform apply` é uma etapa manual/deliberada (gera custo real). Por
padrão o CI roda apenas `fmt`, `validate`, `plan` e os scanners.

| Módulo | Função | Teste |
|---|---|---|
| `terraform/modules/{networking,compute,database,iam,security,monitoring}` | VPC, EC2/ASG+ALB, RDS, IAM/OIDC, SGs, CloudWatch | `terraform validate` (3 environments) |
| `terraform/modules/gcp` | GCS bucket + VPC/subnet (multi-cloud) | `terraform validate` apenas |
| `terraform/modules/budget` | AWS Budgets (orçamento + alertas por tag) | `terraform validate` apenas |
| `ansible/roles/{base,webserver}` + `playbooks/` | Configuração Linux (Nginx, firewall, healthz) | `yamllint` local + `ansible-playbook` no CI (Ubuntu) |
| `powershell/modules/InfraOps` | Configuração Windows (serviço, disco, firewall, usuário) | Pester (9 testes) |
| `automation/orchestrator.py` + `troubleshooting/` | Self-healing (detectar→diagnosticar→remediar→validar) | pytest |
| `automation/metrics/exporter.py` | Exporter Prometheus (`/metrics`,`/healthz`,`/ready`) | `test_metrics_exporter.py` |
| `automation/reports/slo_report.py` | MTTR/SLI a partir de incidentes reais | `test_slo_report.py` |
| `policies/opa` + `policies/kyverno` | Policy as Code (tags, segurança K8s) | `conftest`/`opa` + `kyverno test` no CI |
| `observability/` (`docker-compose.yml`) | Prometheus+Grafana+Loki/Promtail | subida real validada via API |

---

## ⚙️ Funcionamento

1. PR dispara GitHub Actions: `terraform fmt`/`validate`/`plan`, `checkov`/`tflint`, `conftest`/`kyverno test` contra as policies, `trivy` (fs + imagem) com geração de SBOM, `pytest`/`Pester`.
2. (Manual, fora do CI) `terraform apply` provisiona VPC/EC2/RDS/IAM na AWS — ainda não executado nesta revisão.
3. Ansible configura hosts Linux; PowerShell (`InfraOps`) configura hosts Windows.
4. O `automation-controller` Python roda o ciclo de self-healing: `health-check` detecta falha → `troubleshooting` diagnostica (disco/CPU/serviço) → `remediation` executa (processo local, Ansible ou PowerShell) → valida a recuperação → grava o incidente em MySQL.
5. O `exporter.py` expõe métricas Prometheus do controller; Prometheus as coleta; Grafana renderiza o dashboard `automation-overview`; Promtail envia logs do container para o Loki.
6. `slo_report.py` lê os incidentes do MySQL (ou do dataset demo) e calcula MTTR/SLI de disponibilidade, exibidos também num painel Grafana dedicado.
7. O dashboard estático (`dashboard/`) consome os mesmos dados (hoje via `data.example.json`) e exibe cards, gráficos (Chart.js) e timeline de incidentes.

Fluxo ponta a ponta reproduzido de verdade (notebook `05_self_healing_incident.ipynb` + chaos tests):

```text
Processo derrubado (kill real)
      ↓
service_check detecta falha
      ↓
Diagnóstico (disco + CPU/RAM)
      ↓
Remediação (restart_local_process / Ansible / PowerShell)
      ↓
Validação (HTTP 200 real)
      ↓
Incidente gerado (MTTR calculado, INSERT SQL pronto)
```

---

## 🧠 Validação / Verificação

| Camada | O que prova | Resultado |
|---|---|---|
| `terraform validate` (6 módulos × 3 environments + `gcp` + `budget`) | Sintaxe/semântica HCL correta, sem `apply` | *Success!* em todos |
| pytest (`automation/tests` + `tests/python`) | Self-healing, inventário AWS mockado (`moto`), CLI, exporter, SLO, propagação de tags | 74 testes passed |
| Pester (`powershell/tests/InfraOps.Tests.ps1`) | Módulo `InfraOps`, chamadas ao SO mockadas | 8 passed, 1 skipped (módulo `LocalAccounts` ausente nesta instalação PS7) |
| Chaos engineering (`test_chaos_resilience.py`) | `kill -9` real e repetido num processo real; cenário de falha irrecuperável | Convergência correta para `RESOLVED`; degradação correta para `OPEN` (sem exceção, sem falso `RESOLVED`) |
| OPA/conftest (`policy-gate.yml`) | Policy de tags obrigatórias contra `terraform plan` real (LocalStack, sem custo AWS) | Bug de case-sensitivity encontrado e corrigido; 2 fixtures reais passando |
| `kyverno test` | 2 Pods fixture, incluindo 1 teste negativo manual (resultado esperado trocado de propósito) | 4/4 resultados esperados confirmados |
| Trivy (filesystem + imagem `automation-controller`) | Vulnerabilidades de dependências e má configuração de Helm/K8s/Dockerfile | 0 CRITICAL; Helm chart: 13 findings (3 HIGH) → 1 MEDIUM (falso positivo de allowlist de registry) após correção |
| `docker compose` (stack de observabilidade) | Prometheus/Grafana/Loki sobem e se comunicam de verdade | 6/6 containers `Up`; Prometheus raspando 3/3 targets; Grafana com 2 datasources + dashboard `automation-overview` provisionados (confirmado via API); Loki recebendo logs reais do `automation-controller` (confirmado via query) |

O oráculo de cada camada é independente do código testado: `moto` mocka a
AWS sem depender do `boto3` real retornar dados corretos por acaso; o
`terraform plan` usado para testar as policies OPA foi gerado contra
LocalStack (infraestrutura real simulada), não um JSON fabricado à mão.

---

## 🧪 Desenvolvimento Experimental

Fluxo seguido em cada trilha: implementar → rodar teste real (pytest/Pester/
`terraform validate`/scanner) → se falhar, investigar causa raiz → corrigir →
re-rodar até passar.

**Achados reais (não plantados):**

| Bug / hipótese | O que foi testado | Causa real | Correção |
|---|---|---|---|
| Policy OPA de tags "passava" sempre | `terraform plan` real (LocalStack) + `conftest` contra `policies/opa/terraform_tags.rego` | Chaves de tag minúsculas na policy nunca batiam com as tags reais do projeto (capitalizadas); usava `tags` em vez de `tags_all` | Policy corrigida para `tags_all` + chaves reais; confirmado contra `plan` real |
| `terraform apply` falharia no ambiente `dev` | Nome do ALB/target group em `modules/compute` | `name_prefix` longo (`enterprise-cloud-automation-dev`) excedia o limite de 32 caracteres da AWS | Truncado com `substr()` |
| `restart_local_process` podia derrubar o orquestrador | Chaos test (`test_chaos_resilience.py`) com binário inexistente | `FileNotFoundError` não tratado escapava, diferente de `run_ansible_playbook`/`run_powershell_script` | Tratamento de exceção adicionado, espelhando o padrão já usado nas outras variantes |
| Helm chart inseguro | Scan Trivy na imagem `automation-controller` | `deployment.yaml` sem `securityContext` (non-root, `readOnlyRootFilesystem`, capabilities, seccomp) | `securityContext` real adicionado — 13 findings (3 HIGH) → 1 MEDIUM (falso positivo) |
| `health-check --json` retornava exit code 0 com serviço não saudável | pytest do CLI | `return` antecipado antes da checagem de exit code | Corrigido no CLI |
| `terraform validate` falhava nos módulos | `terraform validate` | Atributo `storage_encrypted` duplicado em `modules/database/main.tf`; `thumbprint_list` do OIDC com 39 (não 40) caracteres hex em `modules/iam/main.tf` | Ambos corrigidos |
| Testes Pester do módulo `InfraOps` falhavam | Pester 5 | `New-LocalUser` fazia *shadowing* do cmdlet nativo (quebrava `Mock`); `Set-FirewallRule` passava objeto via pipeline, falhando o binding | Função renomeada para `Set-LocalUserPresent`; `Set-FirewallRule` trocado para `-DisplayName` direto |

Log detalhado por trilha em [`docs/logs/`](docs/logs/); decisões e contexto
completo de cada sessão em [`PROJECT_LOG.md`](PROJECT_LOG.md).

---

## 🛠️ Tecnologias

| Categoria | Tecnologia |
|---|---|
| **Linguagens** | HCL (Terraform), Python, PowerShell, YAML (Ansible), Bash |
| **IaC** | Terraform (módulos + 3 environments + módulo GCP + módulo de budget) |
| **Cloud** | AWS (VPC, EC2, ALB/ASG, RDS, IAM/OIDC, S3, CloudWatch, Budgets) · GCP (GCS, VPC — módulo validado) |
| **Configuração** | Ansible (Linux), PowerShell/`InfraOps` (Windows) |
| **Orquestração/Automação** | Python (Click, boto3, `moto`, `prometheus_client`) |
| **CI/CD** | GitHub Actions (7 workflows) · Jenkins (`Jenkinsfile`, espelha os workflows — não testado contra Jenkins real) |
| **Policy as Code** | OPA/conftest (Terraform), Kyverno (Kubernetes) |
| **Segurança/Supply chain** | Trivy (fs + imagem), SBOM CycloneDX (`trivy`) + SPDX (`syft`), Checkov, TFLint, `ansible-lint`, pre-commit |
| **Observabilidade** | Prometheus, Grafana (dashboards/datasources como código), Loki + Promtail |
| **Banco de dados** | MySQL (execuções, incidentes, inventário) |
| **Dashboard** | HTML5, Bootstrap 5, jQuery, Chart.js |
| **Testes** | pytest, Pester, `terraform validate`/`fmt`, `kyverno test`, `conftest` |
| **Documentação executável** | Jupyter Notebooks (6, um por etapa do roadmap) |
| **Entrega/Plataforma** | Docker, Kubernetes/Helm (skeleton), Argo CD (GitOps, skeleton) |

---

## 📊 Resultados

- **MTTR = 44,25s** e **disponibilidade (proxy: taxa de resolução) = 80%**,
  calculados por `automation/reports/slo_report.py` a partir do dataset real
  de incidentes (`dashboard/js/data.example.json`), com error budget
  declarado. É uma métrica de laboratório, não de produção — ver
  `## ⚠️ Limitações`.
- **74 testes pytest passando** (70 em `automation/tests` + 4 em
  `tests/python`, incluindo a nova suíte de chaos engineering e de
  propagação de tags) e **9 testes Pester** (8 passed, 1 skipped e
  documentado).
- **`terraform validate`: *Success!*** nos 3 environments (dev/staging/prod)
  e nos módulos `gcp` e `budget`, sem depender de credenciais reais.
- **Observability stack real**: 6/6 containers `Up` via `docker compose`;
  Prometheus raspando 3/3 targets; Grafana com 2 datasources (Prometheus +
  Loki) e o dashboard `automation-overview` provisionados (confirmado via
  API); Loki recebendo logs reais do `automation-controller` (confirmado via
  query).
- **Trivy**: 0 findings CRITICAL em filesystem + imagem. Achado real no Helm
  chart — 13 findings (3 HIGH) → reduzidos a 1 MEDIUM (falso positivo de
  allowlist de registry) após adicionar `securityContext`.
- **Kyverno**: `kyverno test` confirmou 4/4 resultados esperados contra 2
  Pods fixture, incluindo 1 teste negativo manual (prova de que o teste
  realmente detecta divergência).
- **OPA/conftest**: bug real de case-sensitivity na policy de tags
  encontrado e corrigido, validado contra um `terraform plan` real gerado
  via LocalStack (sem custo AWS).

---

## 🖼️ Evidências

Sem screenshots capturados nesta revisão (ambiente sem browser interativo
durante a sessão). As evidências de funcionamento real são as saídas de CLI/
API citadas nas seções `📊 Resultados` e `🧠 Validação`: confirmação via API
do Grafana (datasources + dashboard provisionados), query real no Loki,
`docker compose ps` com os 6 containers `Up`, e os relatórios
`security/sbom/trivy-fs-report.txt` / `trivy-image-report.txt` versionados no
repositório.

---

## 🚀 Aplicações

- Referência de como estruturar uma plataforma de Enterprise Automation
  Engineering (IaC + configuração + self-healing + observabilidade +
  governança) de ponta a ponta.
- Base de infraestrutura/entrega para outros workloads do portfólio (ver
  `## 🔗 Projetos Relacionados`).
- Material de estudo/demonstração para entrevistas técnicas envolvendo
  Terraform, CI/CD, Policy as Code, observabilidade e SRE básico.

---

## 🔭 Visão de Longo Prazo

```text
Hoje: código completo, validado localmente, nunca aplicado contra nuvem real
      ↓
terraform apply real (dev) — infraestrutura AWS provisionada de verdade
      ↓
CI rodando terraform plan automaticamente via OIDC (sem secrets estáticos)
      ↓
Dashboard plugado numa API real (hoje consome data.example.json)
      ↓
Cluster Kubernetes real consumindo os manifests/Helm/GitOps já versionados
      ↓
Multi-cloud real (GCP) além do módulo validado
```

---

## 🗺️ Roadmap

- **F0 — Terraform Foundation** ✅ Concluída — `terraform validate` com
  sucesso nos 3 environments (v0.1.0).
- **F1 — Automation (Ansible/PowerShell/Python self-healing)** ✅ Concluída —
  51 testes pytest iniciais + 9 testes Pester + 6 notebooks executados ponta
  a ponta (v0.2.0).
- **F2 — DevOps (CI/CD, segurança estática)** ✅ Concluída — 5 workflows
  GitHub Actions + checkov/tflint/pre-commit (v0.3.0).
- **F3 — Enterprise (monitoring, RDS, dashboard)** ✅ Concluída — módulo
  CloudWatch + schema MySQL + dashboard com gráficos Chart.js (v0.4.0/v1.0.0).
- **F4 — DevOps/Cloud hardening (observabilidade, segurança, multi-cloud,
  chaos, SLO)** ✅ Concluída — stack Prometheus/Grafana/Loki real, Trivy+SBOM,
  OPA/Kyverno testados, módulos GCP/Budget, chaos tests, Jenkinsfile
  (v1.1.0-dev).
- **F5 — Deploy real (`terraform apply` AWS/GCP)** ⏳ Planejada — depende de
  decisão de custo do usuário.

---

## 🕓 Histórico e Mudanças

| Versão | Data | O que mudou |
|---|---|---|
| v0.1.0 | 2026-08-19 | Terraform Foundation: módulos networking/compute/database/iam/security, 3 environments (`validate` OK) |
| v0.2.0 | 2026-08-19 | Automation: CLI Python (Click), orquestrador self-healing, inventário AWS via `moto`, 51 testes pytest; roles Ansible; módulo PowerShell `InfraOps` + Pester; 6 notebooks |
| v0.3.0 | 2026-08-19 | DevOps: 5 workflows GitHub Actions, checkov/tflint/pre-commit, testes estáticos locais |
| v0.4.0 | 2026-08-19 | Enterprise: módulo `monitoring` (CloudWatch), outputs do módulo `database`, schema MySQL + `docker-compose`, dashboard (cards/tabelas/timeline) |
| v1.0.0 | 2026-08-20 | Dashboard: gráficos Chart.js (incidentes por status, execuções por ferramenta) |
| v1.1.0-dev | 2026-10-07 | DevOps/Cloud hardening: observabilidade real (Prometheus/Grafana/Loki), exporter + `Dockerfile`, SLO/MTTR real, Trivy+SBOM, OPA/Kyverno testados no CI (bug de tags corrigido), módulo GCP, módulo AWS Budgets, chaos tests, `Jenkinsfile` |

Changelog completo em [`CHANGELOG.md`](CHANGELOG.md); histórico de decisões e
sessões em [`PROJECT_LOG.md`](PROJECT_LOG.md).

---

## 🔮 Próximos Passos

**Concluído nesta versão (v1.1.0-dev):**
- ✅ Observabilidade real, Trivy+SBOM, OPA/Kyverno testados no CI, módulos
  GCP/Budget, chaos tests, SLO/MTTR, Jenkinsfile.

**Dependem de terceiros/decisão do usuário:**
- [ ] `terraform apply` real no ambiente `dev` (gera custo AWS: EC2, RDS, NAT
  Gateway).
- [ ] Cadastrar secrets/OIDC no GitHub Actions para o CI rodar `terraform
  plan` automaticamente nos PRs.
- [ ] Iniciar Docker Desktop localmente para `database/docker-compose.yml`
  (MySQL de desenvolvimento).
- [ ] Jenkins real para validar o `Jenkinsfile` contra uma instância de
  verdade.

**Próximos técnicos (o que faria numa v2):**
- Plugar o dashboard numa API real (hoje consome `data.example.json`).
- Persistir timestamp de início do problema / heartbeat para calcular MTTD e
  disponibilidade real (uptime %), não apenas o proxy atual.
- Aplicar o módulo GCP e o módulo de budget contra projetos reais (hoje só
  `validate`).

---

## ▶️ Como rodar localmente

Pré-requisitos: Python 3.10, Terraform ≥ 1.15, Docker Desktop (para MySQL e
para a stack de observabilidade), PowerShell 7 (para os testes Pester).

```bash
# Testes Python (74 testes)
python -m pytest automation/tests tests/python -v

# Terraform (sem custo — fmt/validate apenas)
cd terraform/environments/dev
terraform init -backend=false
terraform validate
terraform fmt -check -recursive

# Stack de observabilidade (Prometheus/Grafana/Loki) local
bash observability/run-local.sh up      # Linux/macOS/Git Bash
# ou: observability/run-local.ps1 up    # Windows PowerShell

# Scan de segurança (Trivy + SBOM)
bash security/trivy-scan.sh

# Notebooks (um por etapa do roadmap)
jupyter lab notebooks/
```

| Ambiente | Observação |
|---|---|
| Windows | `ansible-playbook` não roda nativamente (dependência POSIX) — usar WSL ou confiar no CI (Ubuntu) |
| Linux/CI | Todos os workflows (`terraform-ci`, `security-scan`, `policy-gate`, `trivy-sbom`, `ansible-lint`, `python-tests`, `powershell-tests`) rodam no GitHub Actions |
| Pasta sincronizada (Google Drive/OneDrive) | Bind mounts do Docker Desktop falham na pasta sincronizada — `observability/run-local.{sh,ps1}` fazem stage em `C:\tmp` antes de subir o `docker compose` |

Guia completo em [`docs/setup/local-dev-setup.md`](docs/setup/local-dev-setup.md),
[`docs/setup/aws-setup.md`](docs/setup/aws-setup.md) e
[`docs/setup/github-setup.md`](docs/setup/github-setup.md).

---

## 📁 Estrutura do repositório

```text
terraform/         IaC: módulos (networking/compute/database/iam/security/
                    monitoring/gcp/budget) + environments dev/staging/prod
ansible/            Configuração Linux (roles, playbooks)
powershell/         Automação Windows (módulo InfraOps, scripts, testes Pester)
automation/         Controller Python: CLI, orquestrador self-healing,
                    troubleshooting, inventário (boto3), metrics (exporter
                    Prometheus), reports (SLO/incident), tests (74 pytest)
observability/      Prometheus + Grafana (provisioning como código) +
                    Loki/Promtail, docker-compose.yml, run-local.{sh,ps1}
security/           Trivy scan scripts + security/sbom/ (CycloneDX/SPDX)
policies/           Policy as Code: OPA/rego (Terraform) + Kyverno (K8s)
database/           Schema MySQL (execuções, incidentes, inventário)
dashboard/          Dashboard estático (HTML/JS/Bootstrap/Chart.js)
notebooks/          6 notebooks Jupyter, um por etapa do roadmap
kubernetes/         Manifests base dos workloads da plataforma (skeleton)
helm/               Chart do automation-controller (com securityContext real)
gitops/             Argo CD Applications (GitOps — ADR-002)
workloads/          Workloads adicionais (ex.: serverless, não incorporado)
tests/              Testes agregados (python/terraform/ansible)
docs/               Arquitetura, ADRs (docs/decisions/), epics, setup, logs
.github/workflows/  7 pipelines de CI/CD
Dockerfile          Imagem do automation-controller (non-root, uid/gid 10001)
Jenkinsfile         Pipeline alternativo, espelha os workflows do GitHub Actions
```

---

## 📚 Documentação

| Documento | Conteúdo |
|---|---|
| [`PROJECT_LOG.md`](PROJECT_LOG.md) | Decisões-chave e histórico completo de sessões de trabalho |
| [`CHANGELOG.md`](CHANGELOG.md) | O que mudou em cada versão (Keep a Changelog) |
| [`docs/architecture.md`](docs/architecture.md) | Arquitetura geral do sistema |
| [`docs/decisions/`](docs/decisions/) | ADRs (ADR-001 Terraform foundation, ADR-002 GitOps/Argo CD, ADR-003 self-healing, ADR-004 secrets) |
| [`docs/platform-consumers.md`](docs/platform-consumers.md) | Relação desta plataforma com outros workloads do portfólio |
| [`docs/epics/`](docs/epics/) | Epics do roadmap original (infraestrutura, compute, automação, CI/CD, observabilidade, segurança) |
| [`docs/logs/`](docs/logs/) | Log técnico detalhado por trilha de desenvolvimento |
| [`docs/setup/`](docs/setup/) | Setup AWS, GitHub Actions e ambiente de desenvolvimento local |
| [`security/sbom/README.md`](security/sbom/README.md) | Explicação dos relatórios Trivy e SBOMs versionados |
| [`SECURITY.md`](SECURITY.md) | Política de segurança do projeto (portfólio) |

---

## ⚠️ Limitações

- `terraform apply` nunca foi executado contra uma conta AWS ou GCP real —
  tudo validado via `fmt`/`validate`/`plan` (e, para as policies OPA, um
  `plan` real contra LocalStack).
- MTTR e disponibilidade (SLO) são calculados a partir do dataset de
  incidentes do projeto, não de uma série temporal de produção real — são
  proxies de laboratório, declarados como tal no próprio `slo_report.py`. Não
  há MTTD (tempo até detecção) por falta de timestamp de início do problema.
- `Jenkinsfile` espelha os workflows do GitHub Actions mas nunca rodou contra
  uma instância Jenkins real.
- Módulos Terraform `gcp` e `budget` só passaram por `terraform validate` —
  nunca `plan`/`apply`'d contra um projeto GCP ou conta AWS real.
- Dashboard estático consome `data.example.json`; não há API real por trás
  dele nesta revisão.
- `ansible-playbook`/`ansible-lint` não rodam nativamente no Windows
  (dependência POSIX) — validados de verdade apenas no runner Ubuntu do CI.
- Sem screenshots/evidência visual do dashboard ou dos painéis Grafana nesta
  revisão (ver `## 🖼️ Evidências`).

---

## Status

🟡 **Em desenvolvimento — v1.1.0-dev, deploy real em nuvem ainda pendente**

O código cobre o roadmap completo do escopo original (v0.1 → v1.0) mais uma
rodada de hardening DevOps/Cloud (v1.1.0-dev): observabilidade real,
segurança de supply chain, Policy as Code testado, multi-cloud, chaos
engineering e SLO/MTTR — tudo validado localmente com testes reais. O que
falta para "concluído" é o `terraform apply` real (AWS/GCP), que é decisão
deliberada e pendente do usuário por gerar custo de nuvem.

---

## Contexto / Observações

- Peça de portfólio pessoal — não afiliado, não representa e não é software
  da Caterpillar ou de qualquer empregador real.
- Código 100% público, sem dados/credenciais reais: AWS mockada via `moto`,
  policies testadas contra LocalStack (sem custo), banco de dados e
  dashboard em modo demo.
- Métricas de MTTR/disponibilidade/SLO são medições reais sobre dados de
  laboratório (não estimativas de ferramenta), com seus limites declarados em
  `## ⚠️ Limitações` — não representam SLAs de produção.
- Histórico completo de decisões e sessões em [`PROJECT_LOG.md`](PROJECT_LOG.md).

---

## 🔗 Projetos Relacionados

| Projeto | Relação |
|---|---|
| Argus (Enterprise AI & Data Platform) | Workload principal que consome esta plataforma como camada de infraestrutura/entrega (cluster + GitOps) — ver [`docs/platform-consumers.md`](docs/platform-consumers.md) |

---

## 🤖 Autor

**Yuri Fernando Dubbern**

Engenharia Elétrica · Ciência da Computação · Inteligência Artificial ·
Sistemas Embarcados · Projeto de Hardware · Pesquisa e Desenvolvimento

[LinkedIn](https://www.linkedin.com/in/yuridubbern) · [GitHub](https://github.com/Yuri-Fernando) · [Lattes](http://lattes.cnpq.br/7151392692642166) · [Linktree](https://linktr.ee/yuri.f.dubbern)

---

## Licença

MIT — ver [LICENSE](LICENSE).
