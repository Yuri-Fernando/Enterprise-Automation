# Log da trilha: Dashboard + Testes de Infraestrutura

Data: 2026-08-19 (Sessão 2, retomada)

## Escopo desta trilha

1. `dashboard/css/` — estilo enterprise/clean sobre Bootstrap 5.
2. `dashboard/js/app.js` — renderização jQuery a partir de
   `dashboard/js/data.example.json`.
3. Conferência dos dados de exemplo contra `database/schema.sql`.
4. `tests/terraform/` — checagens estáticas (`fmt` + `validate`, sem
   `plan`/`apply`) em `terraform/modules/*` e `terraform/environments/*`.
5. `tests/ansible/` — lint/sintaxe (`yamllint` + `ansible-playbook
   --syntax-check`), sem execução real de playbook.

## O que foi encontrado ao iniciar

- `dashboard/index.html` já existia com estrutura completa (navbar, cards
  de resumo, tabela de inventário, tabela de execuções, timeline de
  incidentes) — **não foi reescrito**, apenas ajustado (ver abaixo).
- `dashboard/css/` e `dashboard/js/app.js` estavam vazios/ausentes.
- `dashboard/js/data.example.json` já existia e já era coerente com
  `database/schema.sql` (`executions`, `incidents`, `inventory`, mesmos
  nomes de campo e mesmos enums `OPEN`/`RESOLVED`, `success`/`failed`) —
  não precisou de ajuste de shape, só validado.
- `tests/terraform/` e `tests/ansible/` estavam vazios.
- Enquanto esta trilha rodava, a trilha de Terraform já tinha preenchido
  `terraform/environments/{dev,staging,prod}/main.tf` (não mais vazios) —
  os testes foram escritos para descobrir dinamicamente os diretórios com
  `.tf`, então passaram a cobrir também os environments automaticamente.

## Dashboard

### CSS (`dashboard/css/style.css`)

Tema enterprise/clean por cima do Bootstrap 5 (CDN, sem internet
necessária além do carregamento inicial da página — decisão já tomada
pela trilha anterior de usar Bootstrap via CDN no `index.html`): navbar
com gradiente navy, cards de resumo com hover sutil, badges de ambiente
(dev/staging/prod) com cores distintas, timeline de incidentes com marcador
verde (RESOLVED) / vermelho (OPEN), tabelas com cabeçalho sticky.

### JS (`dashboard/js/app.js`)

jQuery puro (sem framework pesado), carrega `js/data.example.json` via
`$.getJSON` e renderiza:

- 4 cards de resumo: total de recursos (inventário), incidentes abertos,
  incidentes resolvidos, MTTR médio (média de `recovery_time_seconds` dos
  incidentes `RESOLVED`).
- Tabela de inventário (ordenada por tipo de recurso), com badge de
  ambiente extraído de `tags.Environment`.
- Tabela de execuções recentes (ordenada por `started_at` desc), com
  `title` mostrando `output_summary` no hover.
- Timeline de incidentes (ordenada por `created_at` desc) com root cause,
  ação, validação e tempo de recovery quando disponíveis.
- Todo valor vindo do JSON passa por `esc()` antes de virar HTML (evita
  XSS caso o `data.example.json` seja um dia trocado por uma API real).
- Ponto de extensão documentado: trocar a constante `DATA_URL` por um
  endpoint real de API — nenhuma outra mudança necessária.

### Ajuste no `index.html`

O HTML já existente carregava Bootstrap Bundle JS mas **não jQuery**, e
`app.js` (agora escrito) depende de jQuery. Adicionado:

```html
<script src="https://code.jquery.com/jquery-3.7.1.min.js" ...></script>
```

antes do bundle do Bootstrap e de `js/app.js`. Também criado
`dashboard/README.md` (o `index.html` já linkava para ele no footer, mas
o arquivo não existia).

## Testes de Terraform (`tests/terraform/`)

Dois scripts equivalentes — `test-terraform.sh` (Bash/Git Bash/CI) e
`test-terraform.ps1` (PowerShell nativo) — que:

1. Descobrem dinamicamente todo diretório em `terraform/modules/*` e
   `terraform/environments/*` que já contenha `.tf` (diretórios ainda
   vazios são `SKIP`, não `FAIL` — importante porque a trilha de
   Terraform pode estar escrevendo em paralelo).
2. Rodam `terraform fmt -check -diff` (offline, sempre real).
3. Rodam `terraform init -backend=false -input=false` com timeout
   configurável (padrão 60s) seguido de `terraform validate`. Se o
   `init` não conseguir baixar o provider AWS a tempo, reporta
   `validate: SKIP` em vez de falhar o run inteiro.
4. Nunca chamam `terraform plan`/`terraform apply`.

### Execução local nesta sessão

Rodado com `TF_TEST_INIT_TIMEOUT=20` (e testado manualmente até 150s em
um diretório) — o download do provider `hashicorp/aws` do Terraform
Registry não completou em nenhum teste manual (chegou a passar de 2m30s
sem terminar), então **todo `validate` ficou `SKIP` nesta sandbox**. Isso
é esperado aqui e documentado em `tests/terraform/README.md` — no runner
Ubuntu do GitHub Actions a rede é normal e `validate` roda de verdade.

`terraform fmt`, que não depende de rede, rodou de verdade e encontrou:

- **Bug real** em `terraform/modules/database/main.tf`: o atributo
  `storage_encrypted` é definido duas vezes dentro de
  `aws_db_instance.this` (linhas 17 e 32) — erro de sintaxe HCL
  (`Attribute redefined`) que quebra `fmt`, `validate`, `plan` e `apply`
  daquele módulo até ser corrigido pela trilha de Terraform.
- Problemas de formatação (alinhamento de `=`) em
  `terraform/environments/{dev,staging,prod}/main.tf` e
  `terraform/modules/compute/main.tf`.
- `modules/iam`, `modules/monitoring`, `modules/networking`,
  `modules/security` passaram no `fmt` sem problemas.

Esses achados **não foram corrigidos por esta trilha** (pertencem à
trilha de Terraform) — reportados aqui e no
`tests/terraform/README.md` para quem revisar aquele código depois.

## Testes de Ansible (`tests/ansible/`)

`tests/ansible/test-ansible.sh` roda:

1. `yamllint` em todo `*.yml`/`*.yaml` sob `ansible/` — funciona em
   qualquer SO, sem dependência POSIX. **PASS** nesta execução (nenhum
   problema encontrado em `ansible/roles/`, `ansible/inventory/`).
2. `ansible-playbook --syntax-check` para cada playbook em
   `ansible/playbooks/*.yml` — tentado, mas com detecção específica da
   falha conhecida: no Python 3.10 nativo do Windows, o próprio
   `ansible-core` não inicializa (`AttributeError: module 'os' has no
   attribute 'get_blocking'`, chamada POSIX-only usada em
   `ansible/cli/__init__.py`). O script detecta essa mensagem e reporta
   `SKIP` com explicação em vez de um traceback cru.

Isso confirma e reforça a decisão já registrada em `PROJECT_LOG.md`:
`ansible-lint`/Ansible completo não rodam de forma confiável no Windows
local — rodam de verdade no GitHub Actions (runner Ubuntu) ou via WSL.
`ansible/playbooks/` também ainda estava vazio nesta sessão (outra
trilha em andamento), então não havia playbook para checar de qualquer
forma.

## Arquivos criados/alterados por esta trilha

- `dashboard/css/style.css` (novo)
- `dashboard/js/app.js` (novo)
- `dashboard/README.md` (novo)
- `dashboard/index.html` (editado — adicionada tag `<script>` do jQuery)
- `tests/terraform/test-terraform.sh` (novo)
- `tests/terraform/test-terraform.ps1` (novo)
- `tests/terraform/README.md` (novo)
- `tests/ansible/test-ansible.sh` (novo)
- `tests/ansible/README.md` (novo)
- `docs/logs/dashboard-tests.md` (este arquivo)
- `PROJECT_LOG.md` (seção "Histórico de Sessões", Sessão 2, atualizada)

## Pendências / próximos passos sugeridos

- Corrigir `terraform/modules/database/main.tf` (`storage_encrypted`
  duplicado) e rodar `terraform fmt -recursive terraform/` para os
  problemas de alinhamento — não feito aqui por não ser o escopo desta
  trilha, mas bloqueia `validate`/`plan` reais daquele módulo.
- Quando `ansible/playbooks/` for preenchido pela outra trilha, rodar
  `tests/ansible/test-ansible.sh` de novo (localmente fica `SKIP` no
  `--syntax-check`, mas via WSL/CI validará de verdade).
- `dashboard/README.md` menciona servir a pasta com `python -m
  http.server` caso o navegador bloqueie `fetch` em `file://` por CORS —
  vale testar ao abrir `index.html` direto no navegador.
