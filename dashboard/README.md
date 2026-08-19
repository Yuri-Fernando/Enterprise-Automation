# Dashboard — Enterprise Cloud Automation & Infrastructure Platform

Dashboard estático (sem build step) para visualizar execuções de automação,
incidentes de self-healing e inventário de recursos AWS.

## Stack

- HTML5 + Bootstrap 5 (CDN) — layout responsivo, cards, tabelas.
- jQuery 3.7 (CDN) — manipulação de DOM e `$.getJSON`.
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
- Tabela de inventário (ordenada por tipo de recurso).
- Tabela de execuções recentes (ordenada por `started_at` desc).
- Timeline de incidentes (ordenada por `created_at` desc), com badge de
  status (`OPEN`/`RESOLVED`), root cause, ação de remediação, validação e
  tempo de recovery.

Todo texto vindo dos dados é escapado (`esc()`) antes de ir para o HTML.
