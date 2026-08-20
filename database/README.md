# Database — MySQL 8 (executions / incidents / inventory)

Schema MySQL 8 usado pelo Automation Controller (Python) e pelo Dashboard
para registrar execuções de ferramentas, incidentes de self-healing e o
inventário de recursos AWS. Ver [`../docs/architecture.md`](../docs/architecture.md)
e [`../docs/epics/epic-5-observability.md`](../docs/epics/epic-5-observability.md)
para o contexto completo.

## Arquivos

| Arquivo | Conteúdo |
|---------|----------|
| `schema.sql` | DDL: tabelas `executions`, `incidents`, `inventory` com índices e comentários |
| `seed_data.sql` | Dados de exemplo (modo demo), espelhados em `../dashboard/js/data.example.json` |
| `docker-compose.yml` | Serviço `mysql:8` de desenvolvimento local |
| `.env.example` | Template de variáveis de ambiente (copiar para `.env`, nunca commitar `.env`) |
| `migrations/` | Reservado para migrações incrementais futuras (hoje vazio — `schema.sql` é a fonte de verdade inicial) |

## Como subir

Pré-requisito: Docker Desktop instalado e **daemon rodando**.

```bash
cd database
cp .env.example .env
# edite .env e defina senhas reais (MYSQL_ROOT_PASSWORD, MYSQL_PASSWORD)

docker compose up -d
```

No primeiro start, o container roda automaticamente, em ordem:
1. `schema.sql` (cria o banco `caterpillar_automation` e as 3 tabelas)
2. `seed_data.sql` (insere as linhas de exemplo)

Isso só acontece quando o volume nomeado `caterpillar_mysql_data` está vazio
(primeiro start). Se você já subiu o container antes e quer repopular os
dados, veja "Como resetar" abaixo.

Verifique o healthcheck:

```bash
docker compose ps
# STATUS deve mostrar "healthy" após ~30s
```

## Como conectar

Via cliente `mysql` (se instalado no host):

```bash
mysql -h 127.0.0.1 -P 3306 -u automation_app -p caterpillar_automation
# senha = MYSQL_PASSWORD do seu .env
```

Ou como root:

```bash
mysql -h 127.0.0.1 -P 3306 -u root -p
# senha = MYSQL_ROOT_PASSWORD do seu .env
```

Via `docker exec` (não depende de cliente mysql instalado no host):

```bash
docker exec -it caterpillar-mysql-dev mysql -u automation_app -p caterpillar_automation
```

String de conexão típica para uma aplicação (Python `mysql-connector` /
`PyMySQL`, Node `mysql2`, etc.):

```
mysql://automation_app:<MYSQL_PASSWORD>@127.0.0.1:3306/caterpillar_automation
```

## Como resetar

Remove o container **e** o volume de dados (apaga tudo, próximo `up`
repopula do zero com `schema.sql` + `seed_data.sql`):

```bash
docker compose down -v
docker compose up -d
```

Sem `-v`, `docker compose down` preserva o volume — os dados persistem entre
`down`/`up`, e os scripts de `docker-entrypoint-initdb.d/` **não** rodam de
novo (só rodam quando o diretório de dados do MySQL está vazio).

## Decisões de schema

- **Tipos e índices**: `status`, `environment` e `created_at` são as colunas
  mais consultadas (filtros do dashboard e relatórios), por isso têm índice
  dedicado em cada tabela que as possui.
- **`inventory.tags` como `JSON`**: as tags AWS (Environment, Project,
  ManagedBy, Owner, CostCenter — ver `escopo.md`) têm chaves variáveis por
  recurso; JSON evita uma tabela de tags separada nesta fase do projeto.
- **`inventory.resource_id` com `UNIQUE`**: um recurso AWS não deve aparecer
  duplicado no inventário; upserts do `automation/inventory/` devem usar
  `INSERT ... ON DUPLICATE KEY UPDATE`.
- **Chaves de `incidents`** seguem literalmente o contrato de dados
  combinado com a trilha de automação Python: `host`, `environment`,
  `problem`, `root_cause`, `action`, `validation`,
  `recovery_time_seconds`, `status`, `created_at`.

## Status da validação

`schema.sql` e `seed_data.sql` foram validados sintaticamente (parser SQL,
sem MySQL client local disponível nesta máquina) e `docker-compose.yml` foi
validado como YAML válido. **O teste real de `docker compose up` (subida do
container, healthcheck, `docker-entrypoint-initdb.d/` populando o banco)
está pendente** porque o Docker Desktop está instalado mas o daemon estava
parado no momento da construção — rode a sequência "Como subir" acima
quando o Docker Desktop estiver ativo. Detalhes em
[`../docs/logs/database-dashboard.md`](../docs/logs/database-dashboard.md).
