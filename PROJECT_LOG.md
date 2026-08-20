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

### 2026-08-19 — Sessão 2: Retomada após limite de sessão da API (Claude)

**Contexto:** As 5 trilhas paralelas da Sessão 1 pararam no meio da execução
por terem batido o limite de sessão da API (reset 17h50 America/Sao_Paulo).
Auditoria do repositório mostra o que cada trilha completou e o que falta.

**Gaps identificados:**
- `terraform/`: falta módulo `monitoring/`, `environments/{dev,staging,prod}`
  estão vazios (sem `main.tf`/`variables.tf`/`.tfvars.example`), módulo
  `database` sem `outputs.tf`.
- `ansible/`: role `webserver` vazia (sem tasks), `ansible/playbooks/` vazio.
- `powershell/`: módulo `InfraOps`, `scripts/` e `tests/` (Pester) vazios.
- `automation/`: `cli/` só tem `__init__.py` (sem controller real),
  `reports/` idem, `automation/tests/` vazio (sem pytest real).
- `dashboard/`: falta `css/` e `js/app.js` (só existe `data.example.json`).
- `notebooks/`: **completamente vazio** — pendência crítica pedida
  explicitamente pelo usuário (um notebook executável por etapa do roadmap).
- `tests/terraform` e `tests/ansible`: vazios.
- `docs/logs/`: vazio (nenhuma trilha gravou seu log detalhado ainda).

**Ação:** re-disparar as trilhas em paralelo, focadas em completar apenas os
gaps acima (evitar retrabalho do que já existe). Cada trilha grava
`docs/logs/<trilha>.md` e atualiza esta seção ao final.

**Trilha Automação Python — concluída (Claude):** gaps de `automation/`
fechados sem reescrever `troubleshooting/`/`inventory/` já existentes:
- `automation/cli/main.py` + `automation/cli/__main__.py`: CLI real (Click)
  com subcomandos `health-check`, `inventory`, `incident run` e `report`
  (`python -m automation.cli --help`).
- `automation/reports/incident_report.py`: renderização de incidente em
  Markdown/JSON (contrato de campos = tabela `incidents` do
  `database/schema.sql`), leitura/gravação em MySQL via
  `mysql-connector-python` com `DatabaseUnavailableError` como fallback
  claro quando driver/DB não estão disponíveis (caso deste ambiente).
- `automation/orchestrator.py`: orquestrador de self-healing
  (detecta → diagnostica → remedia → valida → gera incidente), reproduzindo
  o fluxo "Incident #017" do `escopo.md`; remediação padrão reinicia um
  processo local (`python -m http.server`) para rodar 100% offline, com
  variantes Ansible/PowerShell delegando para
  `automation/troubleshooting/remediation.py`.
- `automation/tests/`: 51 testes pytest reais cobrindo troubleshooting
  (health/network/disk/service/remediation), inventário AWS via `moto`
  (`@mock_aws`, nenhuma chamada real à AWS), orquestrador e CLI
  (`click.testing.CliRunner`). Rodados com
  `C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m pytest automation/tests`
  — **51 passed** (um bug real encontrado e corrigido no processo: o
  subcomando `health-check --json` retornava `exit code 0` mesmo com
  serviço não saudável, por causa de um `return` antecipado antes da
  checagem de exit code).
- Log detalhado: `docs/logs/automation-python.md`.

**Trilha Terraform / IaC — concluída (Claude):** gaps fechados sem reescrever
`providers.tf`/`variables.tf`/`backend.tf` (raiz) nem os módulos
`networking`/`compute`/`iam`/`security` já existentes:
- `terraform/modules/database/outputs.tf` (faltava): `endpoint`, `address`,
  `port`, `db_instance_id`/`arn`, `db_name`, `username`,
  `master_user_secret_arn`, `db_subnet_group_name`.
- `terraform/modules/monitoring/` (módulo novo): alarmes CloudWatch de
  EC2/ASG (CPU alto, status check), ALB (5xx, unhealthy hosts) e RDS (CPU,
  free storage), todos opt-in via `enable_*_alarms`; tópico SNS opcional
  (próprio ou externo); log groups genéricos via `for_each`.
- `terraform/environments/{dev,staging,prod}/` (vazios → populados):
  `providers.tf`, `backend.tf` (S3+DynamoDB comentado, key por ambiente),
  `variables.tf`, `main.tf` (idêntico nos 3 — chama todos os módulos,
  diferença só em variáveis) e `terraform.tfvars.example`. dev = mínimo
  (t3.micro, 1 instância, sem NAT/Multi-AZ); staging = intermediário
  (t3.small, 2 instâncias); prod = mais redundância parametrizada
  (NAT por AZ, Multi-AZ RDS, deletion protection) mas **tudo opt-in** —
  nenhum ambiente força custo AWS só pelos defaults de `variables.tf`.
- Corrigidos 2 bugs pré-existentes que bloqueavam `terraform validate`:
  atributo `storage_encrypted` duplicado em `modules/database/main.tf`, e
  `thumbprint_list` do OIDC do GitHub Actions com 39 (não 40) caracteres
  hex em `modules/iam/main.tf`.
- `terraform fmt -recursive` (limpo, sem diffs) e `terraform init
  -backend=false && terraform validate` rodados nos 3 ambientes —
  **Success! The configuration is valid.** nos 3. `terraform plan`/`apply`
  **não** executados (decisão do projeto — evitar custo/depender de
  credenciais reais).
- Log detalhado: `docs/logs/terraform.md`.

**Trilha Dashboard + Testes de Infraestrutura — concluída (Claude):** log
detalhado em [`docs/logs/dashboard-tests.md`](docs/logs/dashboard-tests.md).

- `dashboard/css/style.css` criado (tema enterprise/clean sobre Bootstrap 5,
  navbar navy, badges de ambiente, timeline de incidentes).
- `dashboard/js/app.js` criado — jQuery puro, lê `js/data.example.json` e
  renderiza cards de resumo (recursos, incidentes abertos/resolvidos, MTTR),
  tabela de inventário, tabela de execuções recentes e timeline de
  incidentes. `index.html` não foi reescrito, só ganhou a tag `<script>` do
  jQuery (faltava) e um `dashboard/README.md` novo (o HTML já linkava para
  ele).
- `dashboard/js/data.example.json` conferido contra `database/schema.sql`:
  já estava coerente (mesmos campos/enums de `executions`/`incidents`/
  `inventory`), nenhum ajuste de shape necessário.
- `tests/terraform/test-terraform.sh` + `.ps1` criados: rodam `terraform
  fmt -check` e `terraform validate` (via `init -backend=false`, sem
  `plan`/`apply`) em todo diretório com `.tf` sob `terraform/modules/*` e
  `terraform/environments/*` (descoberta dinâmica — os environments já
  tinham sido preenchidos pela trilha de Terraform em paralelo e foram
  cobertos automaticamente). Achados: bug real de HCL em
  `terraform/modules/database/main.tf` (`storage_encrypted` duplicado) e
  formatação fora do padrão em `environments/*` e `modules/compute`
  (não corrigidos por esta trilha). `validate` ficou `SKIP` nesta sandbox
  local por rede muito lenta para baixar o provider AWS do Registry
  (documentado — funciona no runner Ubuntu do CI).
- `tests/ansible/test-ansible.sh` criado: `yamllint` (PASS local, real) +
  `ansible-playbook --syntax-check` (SKIP local — confirmado que o próprio
  `ansible-core` não inicializa no Python nativo do Windows por depender de
  `os.get_blocking`, POSIX-only; reforça a decisão já registrada acima de
  que Ansible completo roda de verdade só no CI/Ubuntu ou WSL).

**Trilha Notebooks + Documentação — concluída (Claude):** fechada a
pendência crítica pedida explicitamente pelo usuário (`notebooks/`
completamente vazio). Criados 6 notebooks Jupyter em `notebooks/`, um por
etapa do roadmap (`CHANGELOG.md` v0.1→v1.0), todos validados de ponta a
ponta com `jupyter nbconvert --to notebook --execute` (Python 3.10
canônico) — 0 erros em todas as células, em todos os 6 notebooks:
- `00_overview.ipynb`: localiza a raiz do projeto, lê `PROJECT_LOG.md`,
  mostra a arquitetura (ASCII) e resume o papel de cada notebook seguinte.
- `01_terraform_foundation.ipynb`: `terraform fmt -check -recursive` real
  (passou) sobre `terraform/`; monta um root sintético temporário (fora do
  repo) referenciando os 6 módulos reais (`networking`, `compute`,
  `database`, `iam`, `security`, `monitoring`) via `source = "./modules/..."`
  e roda `terraform init -backend=false` + `terraform validate` de verdade
  (`Success! The configuration is valid.`) — sem nunca `apply`/`plan` contra
  AWS real; provider baixado do registry público, sem credenciais.
- `02_automation_linux_windows.ipynb`: roda `health_check`/`disk_check`/
  `service_check` de verdade contra um `http.server` local descartável
  (webroot temporário); inspeciona a estrutura das roles Ansible e do
  módulo PowerShell `InfraOps` por leitura de arquivos.
- `03_cicd_security.ipynb`: parsing real (PyYAML) dos 5 workflows em
  `.github/workflows/*.yml` (jobs/steps/triggers/condições `if`) + explica
  `.checkov.yaml`, `.tflint.hcl`, `.pre-commit-config.yaml`.
- `04_enterprise_observability.ipynb`: `automation/inventory/aws_inventory.py`
  rodando contra AWS mockada com `moto` (`@mock_aws`, zero custo/credencial
  real) — cria VPC/subnet/2 EC2/1 RDS fake e lista o inventário; lê e
  explica o schema MySQL (`database/schema.sql`); mostra como
  `dashboard/js/app.js` consome `data.example.json` (fallback gracioso
  quando MySQL local não está rodando).
- `05_self_healing_incident.ipynb`: reproduz o **Incident #017** do
  `escopo.md` de ponta a ponta e de verdade — derruba um processo local
  ("nginx"), detecta via `service_check`, coleta diagnóstico (disco +
  CPU/RAM), decide e executa remediação (`restart_local_process`, com
  tentativa real de Ansible quando disponível), valida a recuperação
  (`HTTP 200` real) e gera o relatório final no formato do incidente do
  escopo, com o `INSERT SQL` pronto para a tabela `incidents`.

Decisões: nenhum notebook depende de `terraform/environments/` estar
completo (usa root sintético próprio, sempre limpo ao final); nenhum
notebook chama AWS real, precisa de Docker/MySQL rodando ou de credenciais;
todo processo de demonstração usa webroots minúsculos/descartáveis (não a
árvore do projeto) para os health checks responderem instantaneamente; e
toda dependência opcional ausente (`terraform`, `ansible-playbook`, `pwsh`,
`pymysql`) degrada graciosamente com mensagem clara em vez de quebrar o
notebook. Log detalhado: [`docs/logs/notebooks-docs.md`](docs/logs/notebooks-docs.md).

**Trilha Ansible + PowerShell — concluída (Claude, assumida diretamente
depois que o agente em background ficou lento demais):** gaps fechados sem
reescrever `ansible/roles/base/*` nem `ansible/inventory/*` já existentes.

- Role `webserver` completada: `tasks/configure.yml` (vhost + ativação +
  `nginx -t`), `tasks/firewall.yml` (libera porta HTTP no ufw),
  `templates/vhost.conf.j2` (com endpoint `/healthz` consumido pelo health
  check), handler `reload ufw` adicionado (faltava).
- `ansible/playbooks/` (vazio → 4 playbooks): `site.yml` (base + webserver),
  `deploy.yml` (sync de artefato + versão + reload), `healthcheck.yml`
  (espelha `health_check.py` no lado remoto), `remediation.yml` (restart +
  revalidação, chamado pelo orchestrator Python na variante Ansible).
- Módulo PowerShell `InfraOps` (novo, `powershell/modules/InfraOps/`):
  `Get-SystemHealth`, `Get-ServiceStatus`, `Restart-ServiceSafe`,
  `Get-DiskUsage`, `Set-LocalUserPresent`, `Set-FirewallRule` — espelha no
  Windows o que os roles Ansible fazem no Linux.
- `powershell/scripts/`: `health-check.ps1`, `install-app.ps1`,
  `configure-firewall.ps1`, todos usando o módulo `InfraOps`.
- `powershell/tests/InfraOps.Tests.ps1` (Pester 5+): 9 testes, todas as
  chamadas ao SO mockadas. Instalado Pester (`Install-Module Pester
  -MinimumVersion 5.0.0 -Scope CurrentUser` — só havia Pester 3.4 nativo do
  Windows) e **rodado de verdade**: `Tests Passed: 8, Failed: 0, Skipped:
  1` (skip documentado — depende do módulo
  `Microsoft.PowerShell.LocalAccounts`, ausente nesta instalação PS7
  standalone, presente no CI `windows-latest`).
- 2 bugs reais encontrados e corrigidos rodando os testes: a função
  `New-LocalUser` fazia *shadowing* do cmdlet nativo de mesmo nome
  (quebrava o `Mock` do Pester) — renomeada para `Set-LocalUserPresent`;
  `Set-FirewallRule` passava o objeto via pipeline para
  `Set-NetFirewallRule`, o que falhava o binding em teste — trocado para
  `-DisplayName` direto.
- Log detalhado: [`docs/logs/config-automation.md`](docs/logs/config-automation.md).

**Sessão 2 encerrada — as 6 trilhas identificadas nos gaps estão concluídas
e commitadas localmente (nenhum `git push` feito ainda).** Próximo passo:
revisão do usuário + decisões da seção "Pendências / Sua Parte" abaixo.

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
