# Dashboard — Enterprise Cloud Automation & Infrastructure Platform

Dashboard estático (sem build step) para visualizar execuções de automação,
incidentes de self-healing e inventário de recursos AWS.

## Stack

- HTML5 + Bootstrap 5 (CDN) — layout responsivo, cards, tabelas.
- jQuery 3.7 (CDN) — manipulação de DOM e `$.getJSON`.
- Chart.js 4 (CDN) — gráfico de status de incidentes e execuções por
  ferramenta.
- Bootstrap Icons (CDN).
- CSS próprio em [`css/style.css`](css/style.css) (tema enterprise/clean sobre
  o Bootstrap).
- JS em [`js/app.js`](js/app.js) — sem framework pesado (React/Vue), conforme
  pedido no escopo do projeto (jQuery + Bootstrap).

## Como abrir localmente

Basta abrir `index.html` diretamente no navegador (`file://`). Como usa
`fetch`/`$.getJSON` para carregar `js/data.example.json`, alguns navegadores
bloqueiam `fetch` em `file://` por CORS. Se isso acontecer, sirva a pasta com
um servidor HTTP simples:

```bash
cd dashboard
python -m http.server 8080
# depois abra http://localhost:8080
```

## Fonte de dados (modo demo)

O dashboard lê `js/data.example.json`, que espelha o schema MySQL definido em
[`../database/schema.sql`](../database/schema.sql) — três coleções:

- `executions`: histórico de execuções de Terraform/Ansible/PowerShell/Python.
- `incidents`: incidentes detectados/remediados pelo módulo de self-healing
  (`OPEN` / `RESOLVED`), com `recovery_time_seconds`.
- `inventory`: snapshot de recursos AWS coletado via boto3 (EC2, RDS, S3,
  ALB...), com tags.

## Plugando uma API real

Troque a constante `DATA_URL` no topo de `js/app.js` pelo endpoint da API
(ex.: `GET /api/dashboard`) que retorne o mesmo formato JSON (mesmas chaves
usadas em `executions`, `incidents`, `inventory`). O restante da renderização
não muda.

## Renderização

`js/app.js`:

- Cards de resumo: total de recursos, incidentes abertos, incidentes
  resolvidos, MTTR médio (média de `recovery_time_seconds` dos incidentes
  `RESOLVED`).
- Gráfico de pizza: incidentes por status (`OPEN` vs `RESOLVED`).
- Gráfico de barras empilhadas: execuções por ferramenta
  (terraform/ansible/powershell/python), sucesso vs falha.
- Tabela de inventário (ordenada por tipo de recurso).
- Tabela de execuções recentes (ordenada por `started_at` desc).
- Timeline de incidentes (ordenada por `created_at` desc), com badge de
  status (`OPEN`/`RESOLVED`), root cause, ação de remediação, validação e
  tempo de recovery.

Todo texto vindo dos dados é escapado (`esc()`) antes de ir para o HTML.

## Relação com `observability/` (Grafana)

Este dashboard estático (HTML/JS, sem backend) e o Grafana em
`observability/` são **complementares, não duplicados**:

- Este dashboard lê um snapshot (`js/data.example.json` ou uma API futura)
  e é pensado para abrir direto no navegador, sem infraestrutura.
- `observability/`'s Grafana lê métricas **ao vivo** via Prometheus,
  raspando `automation/metrics/exporter.py` (que por sua vez lê os mesmos
  dados — MySQL ou o mesmo `data.example.json` em modo demo). O painel
  "Automation Platform — Overview & SLO" do Grafana cobre o mesmo
  MTTR/incidentes por status que este dashboard, mais o que este
  dashboard não tem: CPU/memória por container (cAdvisor) e o painel de
  SLO/error budget (ver `automation/reports/slo_report.py`).

Use este dashboard para a demo rápida sem Docker; use `observability/`
quando quiser dados ao vivo + logs centralizados (Loki) + alertas reais
do Prometheus.
