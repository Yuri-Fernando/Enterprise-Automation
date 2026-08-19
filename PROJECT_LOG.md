# PROJECT LOG — Enterprise Cloud Automation & Infrastructure Platform

> Este é o **arquivo central** do projeto: toda decisão, sessão de trabalho,
> bloqueio e próximo passo é registrado aqui. Antes de retomar o trabalho,
> leia a seção "Histórico de Sessões" (mais recente primeiro) e "Pendências".
> Cada trilha/agente grava seu próprio log detalhado em `docs/logs/<trilha>.md`
> e um resumo é consolidado aqui.

## Objetivo do projeto

Plataforma de portfólio (não é software da Caterpillar, nem a representa)
construída para demonstrar competências de **Enterprise Automation Engineer**:
Terraform (IaC) como núcleo, Ansible + PowerShell para configuração
Linux/Windows, GitHub Actions para CI/CD, Python para orquestração e
troubleshooting/self-healing, MySQL para registro de execuções/incidentes, e
um dashboard simples de observabilidade. Origem completa do escopo em
[`escopo.md`](escopo.md).

Link do repositório: preencher após criação via `gh repo create` (ver seção
Pendências).

## Decisões-chave

| Data | Decisão | Motivo |
|------|---------|--------|
| 2026-08-19 | Terraform como tecnologia central; Ansible/PowerShell como camadas de configuração | Alinhar 1:1 com os requisitos da vaga (IaC + enterprise automation) |
| 2026-08-19 | Nenhum `terraform apply` automático nesta fase | Evitar custo AWS sem aprovação explícita do usuário; só `validate`/`plan` |
| 2026-08-19 | `ansible-lint`/`checkov` não rodam localmente (dependem de módulos POSIX no Windows) | Rodam de verdade no GitHub Actions (Ubuntu runner); documentado em `docs/setup/local-dev-setup.md` |
| 2026-08-19 | Projeto AWS comprado pelo usuário ainda não incorporado | Arquivos não disponíveis ainda; módulo placeholder criado em `workloads/serverless/` |
| 2026-08-19 | Repositório GitHub criado como público | Peça de portfólio — precisa ser visível para recrutadores |
| 2026-08-19 | Versionamento segue o roadmap do escopo (v0.1 Terraform Foundation → v1.0 Self-Healing) | Facilita contar a história em entrevista via `git log`/tags |

## Sistema de versionamento e histórico

- **SemVer** em [`VERSION`](VERSION) + tags git (`v0.1.0`, `v0.2.0`, ...).
- **CHANGELOG.md**: o que mudou em cada versão (formato Keep a Changelog).
- **PROJECT_LOG.md** (este arquivo): por quê e quando — decisões e sessões.
- **docs/logs/\*.md**: log detalhado por trilha (terraform, automation,
  cicd-security, database-dashboard, notebooks-docs), preenchido pelo agente
  responsável por aquela trilha.
- **Commits convencionais** (`feat:`, `fix:`, `chore:`, `docs:`, `test:`)
  com escopo por trilha, ex.: `feat(terraform): add networking module`.
- **Branches por trilha** durante a construção paralela inicial
  (`feat/terraform-foundation`, `feat/config-automation`, ...), mergeadas em
  `main` após validação.

## Histórico de Sessões

### 2026-08-19 — Sessão 1: Bootstrap do projeto (Claude)

**Contexto:** Projeto criado do zero a partir de `escopo.md` (conversa sobre a
vaga de Enterprise Automation Engineer na Caterpillar). Usuário pediu
estrutura completa, execução paralela de agentes, notebooks executáveis por
etapa, arquivo central de registro e sistema de versionamento.

**Feito:**
- Ambiente mapeado: git, Python 3.10, AWS CLI (credenciais já configuradas,
  região `sa-east-1`), gh (autenticado como Yuri-Fernando), Docker Desktop
  (instalado, daemon parado), PowerShell 7.5, Jupyter completo.
- Instalado: Terraform 1.15.8 (winget), boto3 e moto (pip, para mockar AWS
  nos testes/notebooks sem custo).
- Estrutura de pastas criada (terraform, ansible, powershell, automation,
  workloads, database, dashboard, notebooks, tests, docs).
- `git init`, `.gitignore`, `LICENSE` (MIT), `VERSION`, `CHANGELOG.md`,
  `PROJECT_LOG.md`.
- Repositório GitHub criado e primeiro push feito (ver seção Pendências para
  confirmar a URL final).
- Disparadas 6 trilhas em paralelo (agentes em worktrees isolados):
  1. Terraform / IaC (módulos + environments)
  2. Ansible + PowerShell (configuração Linux/Windows)
  3. Automação Python (controller, troubleshooting/self-healing, boto3)
  4. CI/CD + Segurança (GitHub Actions, checkov, tflint, testes)
  5. Database + Dashboard (schema MySQL + dashboard Bootstrap/JS)
  6. Notebooks + Documentação (um notebook executável por etapa do roadmap)

**Próximos passos:** ver seção "Pendências / Sua Parte" abaixo — a maior
parte é decisão/execução do usuário (login AWS para apply real, iniciar
Docker Desktop, revisar PRs das trilhas).

<!--
Template para novas sessões:

### AAAA-MM-DD — Sessão N: <título> (<quem: Claude / agente / você>)

**Contexto:** ...
**Feito:** ...
**Decisões:** ...
**Próximos passos:** ...
-->

## Pendências / Sua Parte

- [ ] **AWS**: revisar `terraform plan` gerado e decidir quando rodar
      `terraform apply` no ambiente `dev` (vai gerar custo real: EC2, RDS,
      NAT Gateway). Ver `docs/setup/aws-setup.md`.
- [ ] **Docker Desktop**: iniciar o daemon localmente para subir o MySQL de
      desenvolvimento (`docker compose up` em `database/`) e, opcionalmente,
      LocalStack para testar Terraform sem custo.
- [ ] **GitHub Secrets**: cadastrar `AWS_ACCESS_KEY_ID` /
      `AWS_SECRET_ACCESS_KEY` (ou preferencialmente OIDC role) no repositório
      para o GitHub Actions rodar `terraform plan` automaticamente nos PRs.
      Ver `docs/setup/github-setup.md`.
- [ ] **Projeto AWS comprado**: quando quiser incorporar, me passe o
      caminho/arquivos — será plugado em `workloads/serverless/`.
- [ ] **Revisão de conteúdo**: os textos técnicos foram gerados a partir do
      escopo; revisar antes de usar em entrevista/currículo.
- [ ] **GitHub Projects**: criar o board com os 6 epics (`docs/epics/`) como
      colunas/milestones, se quiser reforçar a narrativa ágil.

## Estrutura do repositório

```
terraform/        IaC (módulos + environments dev/staging/prod)
ansible/           Configuração Linux (roles, playbooks)
powershell/        Automação Windows (módulos, scripts, testes Pester)
automation/        Controller Python, troubleshooting/self-healing, boto3
workloads/         Workloads adicionais (ex.: projeto AWS serverless)
database/          Schema MySQL (execuções, incidentes, inventário)
dashboard/         Dashboard estático (HTML/JS/Bootstrap)
notebooks/         Um notebook Jupyter executável por etapa do roadmap
tests/             Testes agregados (python/terraform/ansible)
docs/              Arquitetura, epics, guias de setup, logs por trilha
.github/workflows/ Pipelines de CI/CD
```

## Links úteis

- Escopo original: [`escopo.md`](escopo.md)
- Arquitetura: [`docs/architecture.md`](docs/architecture.md)
- Epics: [`docs/epics/`](docs/epics/)
- Setup AWS: [`docs/setup/aws-setup.md`](docs/setup/aws-setup.md)
- Setup GitHub: [`docs/setup/github-setup.md`](docs/setup/github-setup.md)
- Setup dev local: [`docs/setup/local-dev-setup.md`](docs/setup/local-dev-setup.md)
