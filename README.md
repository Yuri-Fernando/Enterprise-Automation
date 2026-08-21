# Enterprise-Cloud-Automation-Platform

### Terraform · AWS · Ansible · PowerShell · Python · CI/CD · MySQL · Self-Healing

## Status

🟡 **Em desenvolvimento — projeto ativo, com deploy real em AWS ainda pendente**

Plataforma de automação de infraestrutura corporativa, construída com **Terraform como núcleo de IaC**, camadas de configuração **Ansible (Linux) e PowerShell (Windows)**, um **controller Python** para inventário/observabilidade e **troubleshooting automatizado (self-healing)**, pipelines **GitHub Actions** de CI/CD e segurança, um schema **MySQL** de execuções/incidentes/inventário e um **dashboard de observabilidade**.

O projeto foi inspirado pelos requisitos técnicos de uma vaga pública de **Enterprise Automation Engineer**. **Não é software da Caterpillar nem a representa** — é uma plataforma simulada, construída inteiramente como peça de portfólio para demonstrar competências de automação de infraestrutura enterprise.

---

# Sobre o Projeto

O projeto reproduz, de ponta a ponta, o ciclo de vida de uma plataforma de automação de infraestrutura corporativa: provisionamento via **Infrastructure as Code**, configuração de servidores Linux/Windows, orquestração e troubleshooting via Python, governança/segurança no pipeline de CI/CD, e observabilidade via banco de dados + dashboard.

O fluxo conceitual é:

```text
Pull Request (GitHub)
      ↓
GitHub Actions (fmt / validate / plan + security scan)
      ↓
Terraform (VPC, EC2, RDS, IAM, S3, monitoring)
      ↓
Ansible (Linux) · PowerShell (Windows)
      ↓
Automation Controller (Python)
      ↓
Health Check → Diagnóstico → Remediação → Validação
      ↓
MySQL (execuções, incidentes, inventário)
      ↓
Dashboard de Observabilidade
```

`terraform apply` ainda **não foi executado** contra uma conta AWS real —
é a próxima etapa planejada (ver "Próximos passos"). Até lá, o pipeline
roda `fmt`, `validate`, `plan` e os scanners de segurança de verdade; o
restante da plataforma (automação, self-healing, dashboard, notebooks) já
roda 100% de forma real e offline, sem depender de infraestrutura
provisionada.

---

# Objetivo

O projeto tem como objetivos:

- Demonstrar Terraform como núcleo de Infrastructure as Code (módulos +
  múltiplos ambientes);
- Configurar servidores Linux via Ansible e Windows via PowerShell;
- Construir um controller Python de orquestração, inventário e
  troubleshooting;
- Implementar um fluxo de **self-healing** (detectar → diagnosticar →
  remediar → validar → registrar incidente);
- Integrar CI/CD com governança e segurança (GitHub Actions, checkov,
  tflint, ansible-lint, pytest, Pester);
- Registrar execuções e incidentes em um banco de dados relacional (MySQL);
- Expor os dados via um dashboard de observabilidade;
- Documentar todo o processo por meio de notebooks executáveis, um por
  etapa do roadmap.

---

# Principais funcionalidades

- **IaC modular** — 6 módulos Terraform (networking, compute, database,
  iam, security, monitoring) reutilizados em 3 ambientes (dev/staging/prod),
  todos validados (`terraform validate`) com sucesso.
- **Configuração multiplataforma** — role Ansible para Linux (Nginx,
  firewall, healthcheck) e módulo PowerShell `InfraOps` para Windows
  (serviços, disco, firewall, usuários), com testes reais (yamllint, Pester).
- **CLI de automação** (Click) com subcomandos `health-check`, `inventory`,
  `incident run` e `report`.
- **Self-healing automatizado** — orquestrador Python que detecta falhas,
  diagnostica (disco/CPU/serviço), executa remediação (via processo local,
  Ansible ou PowerShell), valida a recuperação e gera o relatório do
  incidente.
- **Inventário AWS via boto3**, testado com AWS mockada (`moto`) — sem
  custo nem credenciais reais.
- **CI/CD completo** — 5 workflows GitHub Actions (`terraform-ci`,
  `security-scan`, `ansible-lint`, `python-tests`, `powershell-tests`) com
  checkov, tflint e pre-commit.
- **Persistência e observabilidade** — schema MySQL (`executions`,
  `incidents`, `inventory`) + dashboard estático (Bootstrap/jQuery/Chart.js)
  com cards de resumo, gráficos (incidentes por status, execuções por
  ferramenta), tabelas e timeline de incidentes.
- **51 testes pytest** (troubleshooting, inventário, orquestrador, CLI) e
  **testes Pester** (PowerShell) rodados de verdade.
- **6 notebooks Jupyter executáveis**, um por etapa do roadmap, todos
  validados de ponta a ponta (`jupyter nbconvert --execute`, 0 erros).

---

# Arquitetura / Pipeline

```text
                        GitHub
                          │
                    Pull Request
                          │
                          ▼
                  GitHub Actions
               ┌──────────┴──────────┐
               │                     │
        terraform fmt/validate   Security Scan
               │               (checkov / tflint)
               ▼                     │
          terraform plan             │
               │                     │
               └──────────┬──────────┘
                          ▼
                    Terraform Apply *
                          │
                          ▼
                         AWS
          ┌───────────────┼────────────────┐
          │               │                │
         VPC             EC2              RDS
          │               │                │
     Subnets / SG      Linux/Windows     MySQL
                          │
                ┌─────────┴─────────┐
                ▼                   ▼
             Ansible            PowerShell
                │                   │
        Linux configuration    Windows automation
                │                   │
                └─────────┬─────────┘
                          ▼
              Automation Controller (Python)
                          │
                ┌─────────┼─────────┐
                ▼         ▼         ▼
          Health Check  Inventory  Remediation
           (RCA/self-healing, boto3, MySQL)
                          │
                          ▼
              Dashboard (Bootstrap/jQuery/Chart.js)
```

`*` `terraform apply` é uma etapa manual/deliberada (gera custo real na AWS).
Por padrão o CI roda apenas `fmt`, `validate`, `plan` e os scanners de
segurança.

---

# Tecnologias e conceitos

| Categoria | Tecnologia |
|---|---|
| IaC | Terraform (módulos + workspaces por ambiente) |
| Cloud | AWS (VPC, EC2, RDS, IAM, S3, CloudWatch) |
| Configuração Linux | Ansible (roles, playbooks) |
| Configuração Windows | PowerShell (módulo `InfraOps`, Pester) |
| Orquestração/Automação | Python (Click, boto3, `moto`) |
| CI/CD | GitHub Actions |
| Segurança/Governança | Checkov, TFLint, ansible-lint, pre-commit |
| Banco de dados | MySQL (schema de execuções/incidentes/inventário) |
| Dashboard | HTML5, Bootstrap 5, jQuery, Chart.js |
| Testes | pytest, Pester, `terraform validate`/`fmt` |
| Documentação executável | Jupyter Notebooks |
| Conceitos | Infrastructure as Code, self-healing, observabilidade, CI/CD, segurança de pipeline, versionamento semântico |

---

# Desenvolvimento

O projeto foi construído em **trilhas paralelas**, seguindo o roadmap de
releases definido no escopo original (`escopo.md`), e documentado em duas
camadas: **decisões e histórico de sessões** em `PROJECT_LOG.md`, e
**log técnico por trilha** em `docs/logs/`.

Etapas do roadmap (versionadas com SemVer + tags git):

```text
v0.1 — Terraform Foundation (VPC, EC2, IAM, S3)
     ↓
v0.2 — Automation (Ansible + PowerShell, Linux + Windows)
     ↓
v0.3 — DevOps (CI/CD, terraform plan, security scan)
     ↓
v0.4 — Enterprise (Load Balancer, Auto Scaling, RDS, monitoring)
     ↓
v1.0 — Self-healing (troubleshooting automatizado, governança, docs)
```

Decisões técnicas relevantes:

- Nenhum `terraform apply` automático — decisão deliberada para não gerar
  custo AWS sem aprovação explícita; `validate`/`plan` sempre reais.
- Testes de infraestrutura sem dependência de nuvem real: AWS mockada via
  `moto`, servidores web locais/descartáveis para health checks.
- `ansible-lint`/Ansible completo não rodam localmente no Windows (limitação
  POSIX do `ansible-core`) — rodam de verdade no runner Ubuntu do CI.
- Dashboard consome um JSON de exemplo (`data.example.json`) espelhando o
  schema MySQL, com ponto de extensão documentado para plugar uma API real.
- Bugs reais encontrados e corrigidos durante o desenvolvimento (exit code
  incorreto no CLI, atributo HCL duplicado, shadowing de cmdlet no Pester,
  binding de pipeline no PowerShell) — documentados em `docs/logs/`.

---

# Resultados / Aplicação

- Todos os módulos Terraform validam com sucesso nos 3 ambientes
  (`terraform validate` → *Success!*), sem depender de credenciais AWS
  reais.
- 51 testes pytest + testes Pester passando, cobrindo troubleshooting,
  inventário, orquestrador de self-healing e CLI.
- Reprodução de ponta a ponta de um incidente de self-healing (derrubar
  serviço → detectar → diagnosticar → remediar → validar → gerar relatório),
  demonstrada no notebook `05_self_healing_incident.ipynb`.
- Dashboard funcional (cards de resumo, gráficos, tabelas, timeline de
  incidentes) rodando 100% estático, sem backend.
- 6 notebooks Jupyter executáveis documentando cada etapa do roadmap,
  todos rodados de ponta a ponta sem erro.

---

# Próximos passos

- [ ] `terraform apply` real no ambiente `dev` (provisionar VPC/EC2/RDS na
  AWS) e validação do pipeline completo contra infraestrutura real.
- [ ] Cadastrar credenciais/OIDC no GitHub Actions para o CI rodar
  `terraform plan` automaticamente nos PRs.
- [ ] Subir MySQL local via Docker Compose e plugar o dashboard numa API
  real (hoje consome `data.example.json`).
- [ ] Incorporar o workload serverless (projeto AWS complementar) em
  `workloads/serverless/`.
- [ ] Revisão final de conteúdo técnico antes de usar em entrevista/CV.

---

# Estrutura do projeto

```text
terraform/        IaC (módulos + environments dev/staging/prod)
ansible/           Configuração Linux (roles, playbooks)
powershell/        Automação Windows (módulos, scripts, testes Pester)
automation/        Controller Python, troubleshooting/self-healing, boto3
workloads/         Workloads adicionais (ex.: serverless)
database/          Schema MySQL (execuções, incidentes, inventário)
dashboard/         Dashboard estático (HTML/JS/Bootstrap/Chart.js)
notebooks/         Um notebook Jupyter executável por etapa do roadmap
tests/             Testes agregados (python/terraform/ansible)
docs/              Arquitetura, epics, guias de setup, logs por trilha
.github/workflows/ Pipelines de CI/CD
```

Guia de quickstart completo em
[`docs/setup/local-dev-setup.md`](docs/setup/local-dev-setup.md).

---

# Status

🟡 **Em desenvolvimento — projeto ativo, com deploy real em AWS ainda pendente**

O código já cobre o roadmap completo definido no escopo (v0.1 → v1.0):

- ✅ Terraform Foundation (VPC, EC2, IAM, S3);
- ✅ Automation (Ansible + PowerShell);
- ✅ DevOps (CI/CD, plan, security scan);
- ✅ Enterprise (monitoring, RDS, alarmes);
- ✅ Self-healing (troubleshooting automatizado, governança, documentação).

O que falta para considerar o projeto encerrado é o `terraform apply` real
contra uma conta AWS (e os itens listados em "Próximos passos") — por isso
o projeto permanece em desenvolvimento, não concluído.

---

# Contexto / Observações

- Código 100% público, sem dados/credenciais reais (AWS mockada via
  `moto`, banco de dados de exemplo, dashboard em modo demo).
- Histórico completo de decisões técnicas e sessões de trabalho em
  [`PROJECT_LOG.md`](PROJECT_LOG.md); changelog por versão em
  [`CHANGELOG.md`](CHANGELOG.md); log técnico detalhado por trilha em
  [`docs/logs/`](docs/logs/).

---

# Autor

**Yuri Fernando Dubbern**

Engenheiro de Dados · AI Engineer · Enterprise Automation · IaC · DevOps · Robótica e Automação

[LinkedIn](https://www.linkedin.com/in/yuridubbern) · [GitHub](https://github.com/Yuri-Fernando) · [Lattes](http://lattes.cnpq.br/7151392692642166) · [Linktree](https://linktr.ee/yuri.f.dubbern)
