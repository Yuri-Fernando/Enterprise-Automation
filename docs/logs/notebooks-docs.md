# Log da trilha: Notebooks + Documentação

> Log detalhado desta trilha. Resumo consolidado em
> [`PROJECT_LOG.md`](../../PROJECT_LOG.md), seção "Histórico de Sessões".

## O que foi feito

`notebooks/` estava completamente vazio (pendência crítica pedida
explicitamente pelo usuário: "quero notebooks pra cada etapa do projeto pra
eu ver rodando"). Foram criados 6 notebooks Jupyter executáveis, um por
etapa do roadmap (`CHANGELOG.md`), todos validados de ponta a ponta com
`jupyter nbconvert --to notebook --execute` usando o Python 3.10 canônico
do projeto (`C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe`).

| Notebook | Etapa do roadmap | Conteúdo |
|----------|-------------------|----------|
| `00_overview.ipynb` | — (visão geral) | Localiza a raiz do projeto, lê `PROJECT_LOG.md`, mostra a arquitetura (ASCII), lista o estado atual dos diretórios-chave e resume o que cada notebook seguinte demonstra |
| `01_terraform_foundation.ipynb` | v0.1 Terraform Foundation | `terraform fmt -check -recursive` real sobre `terraform/`; descreve os 6 módulos (variáveis/outputs) por leitura estática; monta um **root sintético temporário** (fora do repo) que referencia os 6 módulos reais via `source = "./modules/..."` com valores plausíveis, roda `terraform init -backend=false` + `terraform validate` de verdade — sem nunca fazer `apply`/`plan` contra a AWS real |
| `02_automation_linux_windows.ipynb` | v0.2 Automation | Roda `automation/troubleshooting/health_check.py`, `disk_check.py` e `service_check.py` **de verdade** contra um `python -m http.server` descartável (webroot temporário, não a árvore do projeto); inspeciona a estrutura das roles Ansible (`ansible/roles/`) e do módulo PowerShell `InfraOps` por leitura de arquivos (sem executar `ansible-playbook`/`pwsh`) |
| `03_cicd_security.ipynb` | v0.3 DevOps/CI-CD | Faz parsing real (PyYAML) dos 5 workflows em `.github/workflows/*.yml` — jobs, steps, triggers e condições `if` — e explica a política de severidade do `checkov` (`.checkov.yaml`), regras do `tflint` (`.tflint.hcl`) e hooks do `pre-commit` (`.pre-commit-config.yaml`) |
| `04_enterprise_observability.ipynb` | v0.4 Enterprise | Roda `automation/inventory/aws_inventory.py` contra AWS **mockada com `moto`** (`@mock_aws`) — cria VPC/subnet/2 EC2/1 RDS fake e lista o inventário normalizado, zero custo e zero credencial real; lê e explica o schema MySQL (`database/schema.sql`, 3 tabelas); mostra como o dashboard consome os dados (`dashboard/js/app.js` + `data.example.json`), com fallback gracioso quando não há MySQL local |
| `05_self_healing_incident.ipynb` | v1.0 Self-Healing | Reproduz o **Incident #017** do `escopo.md` de ponta a ponta e de verdade: derruba um processo local ("nginx"), detecta a falha com `service_check`, coleta diagnóstico (disco + CPU/RAM via `psutil`), decide a remediação (`decide_remediation`), executa `restart_local_process` (com tentativa real de `run_ansible_playbook` quando `ansible-playbook` está disponível), valida a recuperação com um novo health check + requisição HTTP, e gera o relatório final no mesmo formato do incidente do escopo, incluindo o SQL de `INSERT` pronto para a tabela `incidents` |

## Decisões de design

- **Sem `terraform apply` em nenhum notebook.** O Notebook 01 só roda
  `fmt`/`init -backend=false`/`validate` — comandos read-only que não criam
  recursos. O `init` baixa o *plugin* do provider AWS do registry público
  (não usa credenciais AWS); se não houver rede, o notebook degrada
  graciosamente e explica o que não pôde ser validado.
- **`terraform/environments/<env>/` não é uma dependência rígida.** Como
  essa pasta estava sendo completada em paralelo por outra trilha, o
  Notebook 01 monta seu próprio root sintético (em `tempfile.mkdtemp()`,
  fora do repositório, sempre removido ao final) que referencia
  `terraform/modules/*` diretamente — funciona independente do estado de
  `environments/`.
- **Zero custo/zero credencial real em qualquer lugar.** Nenhum notebook
  chama a AWS de verdade: o Notebook 04 usa `moto` (`@mock_aws`); o
  Notebook 01 usa `access_key/secret_key = "test"` +
  `skip_credentials_validation = true` no provider sintético.
- **Serviços de demonstração usam webroots minúsculos e descartáveis**
  (não a árvore inteira do projeto) para os checks HTTP responderem
  instantaneamente — evita timeouts por listagem de diretório grande.
- **Fallback gracioso em tudo que é opcional**: `terraform` ausente,
  `moto`/`pymysql` ausentes, `ansible-playbook`/`pwsh` ausentes,
  `powershell/` ou `ansible/playbooks/` ainda vazios — cada célula
  detecta a ausência e imprime uma mensagem clara em vez de quebrar.
- **`find_project_root()`**: todos os notebooks localizam a raiz do
  projeto subindo diretórios até encontrar `PROJECT_LOG.md`, então
  funcionam tanto executados de dentro de `notebooks/` (caso normal)
  quanto de outro diretório de trabalho.

## Como rodar

Interpretador canônico do projeto (Python 3.10, já tem Jupyter completo +
boto3 + moto instalados):

```
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe
```

### Rodar um notebook específico e validar que executa sem erro

```bash
cd notebooks
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m jupyter nbconvert \
  --to notebook --execute --inplace --ExecutePreprocessor.timeout=180 \
  01_terraform_foundation.ipynb
```

Repita trocando o nome do arquivo para os outros 5. `--inplace` sobrescreve
o próprio `.ipynb` com as saídas da execução (o que permite abrir o
notebook depois e já ver os resultados sem precisar rodar de novo).

### Rodar todos de uma vez

```bash
cd notebooks
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m jupyter nbconvert \
  --to notebook --execute --inplace --ExecutePreprocessor.timeout=180 \
  00_overview.ipynb 01_terraform_foundation.ipynb 02_automation_linux_windows.ipynb \
  03_cicd_security.ipynb 04_enterprise_observability.ipynb 05_self_healing_incident.ipynb
```

### Abrir interativamente

```bash
cd notebooks
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m jupyter lab
```

Nenhum notebook precisa de: credenciais AWS reais, Docker rodando, MySQL
rodando, `ansible-playbook`/`pwsh` instalados, ou conexão com um host
remoto. A única dependência de rede é o download do provider `hashicorp/aws`
pelo Terraform no Notebook 01 (do registry público, sem autenticação) — se
indisponível, o notebook ainda roda até o fim, apenas pulando a etapa de
`validate` com uma mensagem explicativa.

## Dependências Python usadas (já instaladas no ambiente)

`boto3`, `moto`, `psutil`, `pyyaml`, `nbformat`, `nbclient`/`nbconvert`/`jupyter`.
Nenhuma dependência nova precisou ser instalada além das já presentes no
ambiente (ver `PROJECT_LOG.md`, Sessão 1).

## Validação de execução (evidência)

Todos os 6 notebooks foram executados com `jupyter nbconvert --execute`
nesta sessão e terminaram com exit code 0 (sem exceções não tratadas).
Destaques observados na execução real:

- Notebook 01: `terraform fmt -check -recursive` passou; `terraform validate`
  contra o root sintético retornou `Success! The configuration is valid.`
- Notebook 02: health/disk/service check rodaram contra um `http.server`
  local real, subido e derrubado dentro do próprio notebook.
- Notebook 04: `moto` criou 2 instâncias EC2 (`linux-web-01`,
  `linux-web-02`) + 1 RDS MySQL fake, e `aws_inventory.get_inventory()`
  listou os 3 recursos corretamente.
- Notebook 05: o incidente completo rodou de ponta a ponta — porta
  derrubada, detectada como `down`, remediada via `restart_local_process`
  (recovery time medido em segundos reais), validada como `up`, relatório
  final igual ao formato do `Incident #017` do escopo.

## Pendências / observações para quem for revisar

- `powershell/modules/InfraOps` e `ansible/playbooks/` ainda podem estar
  vazios dependendo do progresso paralelo de outra trilha no momento em
  que este notebook rodar — o Notebook 02 detecta isso e imprime a
  estrutura esperada em vez de falhar.
- O Notebook 05 tenta `ansible-playbook` real antes do fallback local; em
  Windows sem WSL isso sempre cai no fallback (`restart_local_process`),
  o que é o comportamento esperado e documentado no próprio notebook.
