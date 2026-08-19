# Log da trilha — Automação Python (controller + self-healing)

> Log detalhado desta trilha. Resumo consolidado em `PROJECT_LOG.md` (Sessão 2).

## Escopo desta rodada

Completar os gaps identificados na Sessão 2 do `PROJECT_LOG.md` para
`automation/`:

1. CLI real (`automation/cli/main.py` + `automation/cli/__main__.py`).
2. Geração de relatório de incidente (`automation/reports/incident_report.py`).
3. Orquestrador de self-healing (`automation/orchestrator.py`).
4. Testes pytest reais (`automation/tests/`), incluindo `moto` para AWS.
5. Este log.

Os módulos já existentes (`automation/troubleshooting/*.py`,
`automation/inventory/aws_inventory.py`) **não foram reescritos** — apenas
consumidos pelos novos módulos.

## O que foi implementado

### 1. CLI (`automation/cli/`)

- `automation/cli/main.py`: CLI com [Click](https://click.palletsprojects.com/),
  grupo raiz `cli` com subcomandos:
  - `health-check` — roda `run_health_check()` (porta TCP + processo local),
    saída humana ou `--json`, `exit code 1` se `healthy=False`.
  - `inventory` — roda `get_inventory()` (boto3 EC2+RDS), saída tabular ou
    `--json`. Erros de credenciais/API são capturados e reportados de forma
    amigável (sem traceback cru).
  - `incident run` — dispara o fluxo completo de self-healing via
    `automation.orchestrator.run_self_healing()`; aceita
    `--remediation local_process|ansible|powershell`, gera relatório em
    Markdown/JSON e pode salvar em arquivo (`--report-path`).
  - `report` — gera relatório a partir de um JSON local (`--from-json`), de
    um incidente específico no MySQL (`--incident-id`) ou dos N mais
    recentes (`--recent N`). Erro de banco indisponível vira mensagem clara
    + `exit code 2` (não crasha).
- `automation/cli/__main__.py`: permite `python -m automation.cli ...`.

### 2. Relatórios (`automation/reports/incident_report.py`)

- Contrato de campos idêntico à tabela `incidents` do `database/schema.sql`
  (`host, environment, problem, root_cause, action, validation,
  recovery_time_seconds, status, created_at, resolved_at`).
- `render_incident_markdown()` / `render_incident_json()` — renderizam um
  incidente único (formato bate com o exemplo "Incident #017" do
  `escopo.md`).
- `render_incidents_summary_markdown()` — tabela Markdown para múltiplos
  incidentes.
- `save_report()` — grava em arquivo, criando diretórios se necessário.
- Acesso a MySQL via `mysql-connector-python` (opcional): `fetch_incident_by_id()`,
  `fetch_recent_incidents()`, `insert_incident()`. Se o driver não estiver
  instalado, ou o banco não estiver acessível, todas essas funções levantam
  `DatabaseUnavailableError` com mensagem clara — nunca um traceback cru.
  Isso permite rodar os testes e o CLI **sem MySQL disponível** (como neste
  ambiente de desenvolvimento, onde `mysql-connector-python` não está
  instalado e o Docker/MySQL não está no ar).

### 3. Orquestrador de self-healing (`automation/orchestrator.py`)

Implementa o fluxo do `escopo.md`:

```
Health Check detecta falha
    -> Coleta diagnóstico (network_check + disk_check + service_check)
    -> Decide remediação (decide_remediation)
    -> Executa remediação (restart_local_process | Ansible | PowerShell)
    -> Valida recuperação (health check de novo)
    -> Retorna incidente pronto para relatório/persistência
```

`run_self_healing()`:
- Se o serviço já está saudável no health check inicial, retorna um
  incidente `RESOLVED` com `recovery_time_seconds=0` e ação `no_action`
  (short-circuit).
- Caso contrário, diagnostica causa raiz (processo parado / porta fechada /
  disco cheio), decide e executa a remediação, valida de novo e calcula o
  `recovery_time_seconds` real (wall clock).
- Remediação padrão (`remediation="local_process"`) reinicia um processo
  local (ex.: `python -m http.server <porta>`) — permite rodar o fluxo
  inteiro **sem infraestrutura externa**, em qualquer laptop. As variantes
  `"ansible"`/`"powershell"` delegam para os wrappers já existentes em
  `automation/troubleshooting/remediation.py`.

### 4. Testes (`automation/tests/`)

Todos rodados com o interpretador canônico
`C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe`.

| Arquivo | Cobre |
|---|---|
| `test_health_check.py` | `check_port`, `find_free_port`, `is_process_running`, `run_health_check` |
| `test_network_check.py` | `resolve_dns`, `check_connectivity` |
| `test_disk_check.py` | `check_disk_usage` (thresholds/alert) |
| `test_service_check.py` | `check_service_status` (up/down) |
| `test_remediation.py` | `decide_remediation`, `restart_local_process` (com `http.server` real), `run_ansible_playbook`/`run_powershell_script` (binário ausente → erro tratado) |
| `test_aws_inventory.py` | `list_ec2_instances`, `list_rds_instances`, `get_inventory` — **100% via `moto` (`@mock_aws`), nenhuma chamada real à AWS** |
| `test_orchestrator.py` | Fluxo completo de self-healing (serviço já saudável / serviço caído + restart real) |
| `test_incident_report.py` | Normalização, renderização Markdown/JSON, `save_report`, fallback `DatabaseUnavailableError` sem driver/DB |
| `test_cli.py` | Todos os subcomandos via `click.testing.CliRunner` (sem subprocess real do CLI) |

**Resultado da execução** (ver seção "Como rodar" abaixo para reproduzir):
todos os testes passaram (`pytest automation/tests`), incluindo o teste de
ponta a ponta do incidente via CLI (`incident run`), que sobe um
`python -m http.server` real, injeta a falha (porta fechada), remedia,
valida via HTTP/porta e confirma `status=RESOLVED`.

## Decisões

| Decisão | Motivo |
|---|---|
| CLI com Click (não argparse puro) | Grupos/subcomandos aninhados (`incident run`) e `--help` automático mais legíveis para a demo/entrevista |
| Remediação padrão = restart de processo local | Permite `incident run` e os testes rodarem 100% localmente, sem Ansible/PowerShell/AWS real |
| `mysql-connector-python` opcional, com `DatabaseUnavailableError` | Ambiente de dev não tem o driver nem o MySQL no ar (Docker Desktop parado); testes e CLI continuam funcionais com fallback claro em vez de crash |
| `moto` (`@mock_aws`) em todos os testes de inventário | Constitution/regra do projeto: nunca bater na AWS real durante testes |
| Testes de `remediation.py`/`orchestrator.py` usam `python -m http.server` real | Demonstra o fluxo de self-healing fim-a-fim sem depender de infraestrutura externa, alinhado ao exemplo "Incident #017" do `escopo.md` |

## Como rodar

```bash
# CLI
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m automation.cli --help
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m automation.cli health-check --port 8000
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m automation.cli inventory --region sa-east-1
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m automation.cli incident run --port 8000 ^
    --problem "nginx unavailable" --start-command "python -m http.server 8000" --report-path incident.md
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m automation.cli report --from-json incident.json

# Testes
C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe -m pytest automation/tests -v
```

## Pendências / próximos passos

- `mysql-connector-python` não está instalado neste ambiente — instalar
  (`pip install mysql-connector-python`) e subir `database/docker-compose.yml`
  quando o Docker Desktop estiver rodando, para exercitar `report
  --incident-id`/`--recent` contra o MySQL real.
- Integração fim-a-fim com a trilha CI/CD: rodar `pytest automation/tests`
  no GitHub Actions (Ubuntu runner) já é compatível — todos os testes usam
  `sys.executable`/`shutil.which`, sem hardcode de caminho Windows.
- Quando o projeto AWS comprado pelo usuário for incorporado, `inventory`
  pode ser apontado para os recursos reais bastando credenciais AWS válidas
  (nenhuma mudança de código necessária).
