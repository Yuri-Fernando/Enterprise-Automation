# Log da trilha Terraform / IaC

> Log detalhado desta trilha. Resumo consolidado em `PROJECT_LOG.md` (seção
> "Histórico de Sessões", Sessão 2).

## Contexto

Continuação da trilha Terraform após o reset de sessão da API. O que já
existia (`terraform/providers.tf`, `terraform/variables.tf`,
`terraform/backend.tf` como arquivos de referência, e os módulos
`networking`, `compute`, `iam`, `security` completos) **não foi reescrito** —
apenas os gaps identificados na auditoria da Sessão 2 foram completados.

## Gaps fechados nesta sessão

1. **`terraform/modules/database/outputs.tf`** (faltava) — outputs
   `db_instance_id`, `db_instance_arn`, `endpoint`, `address`, `port`,
   `db_name`, `username`, `master_user_secret_arn` (ARN do segredo no Secrets
   Manager gerado por `manage_master_user_password`) e `db_subnet_group_name`.
   Consistente com os recursos já definidos em `main.tf`/`variables.tf`.

2. **`terraform/modules/monitoring/`** (módulo inteiro, não existia) —
   `main.tf`, `variables.tf`, `outputs.tf`:
   - Tópico SNS opcional (`create_sns_topic` + `alarm_email`), ou reaproveita
     um `sns_topic_arn` externo — ou nenhum dos dois (alarmes sem ação).
   - Alarmes de EC2/Auto Scaling Group: `CPUUtilization` alto (threshold
     parametrizável) e `StatusCheckFailed`.
   - Alarmes de ALB (opcionais via `enable_alb_alarms`): `HTTPCode_ELB_5XX_Count`
     e `UnHealthyHostCount`.
   - Alarmes de RDS (opcionais via `enable_rds_alarms`): `CPUUtilization` e
     `FreeStorageSpace` baixo.
   - Log groups genéricos via `for_each` sobre `log_group_names`, com
     retenção parametrizável (`log_retention_days`).
   - Tudo opt-in (`enable_*_alarms = false` por padrão no módulo) — quem liga
     é o `environments/<env>/variables.tf` que consome o módulo.

3. **`terraform/environments/{dev,staging,prod}/`** (vazios, agora
   populados) — cada um com `providers.tf`, `backend.tf`, `variables.tf`,
   `main.tf`, `outputs.tf`, `terraform.tfvars.example`:
   - `main.tf` é **idêntico nas 3 pastas** (module wiring 100% orientado por
     variáveis) — a diferença entre dev/staging/prod está inteiramente em
     `variables.tf`/`terraform.tfvars.example`, não em lógica duplicada.
   - **dev**: footprint mínimo — `t3.micro`/`db.t3.micro`, 1 instância
     (`min_size=1`, `desired_capacity=1`), sem NAT Gateway, sem Multi-AZ RDS,
     sem deletion protection, `skip_final_snapshot=true`. VPC `10.0.0.0/16`.
   - **staging**: intermediário — `t3.small`/`db.t3.small`, ASG com 2
     instâncias desejadas (`desired_capacity=2`, `max_size=4`) para exercitar
     o load balancing do ALB. VPC `10.1.0.0/16`. Redundância (NAT Gateway,
     Multi-AZ) continua **desligada por padrão** — `terraform.tfvars.example`
     documenta um bloco "opt-in" comentado para ligar sob demanda.
   - **prod**: maior redundância — `desired_capacity=2`, `max_size=6`,
     `single_nat_gateway=false` (um NAT por AZ quando ligado). VPC
     `10.2.0.0/16`. Todos os knobs de redundância real (NAT Gateway,
     `db_multi_az`, `db_deletion_protection`,
     `enable_alb_deletion_protection`, `enable_https_listener`,
     `create_sns_topic`) **seguem `false`/vazios por padrão em
     `variables.tf`** — nenhum ambiente força custo AWS só por rodar
     `terraform apply` com os defaults. `terraform.tfvars.example` do prod
     tem uma seção final comentada, variável por variável, com o que ligar
     para um rollout de produção real e o custo aproximado de cada uma.
   - `backend.tf` de cada ambiente é o mesmo template comentado do root
     (state S3 + lock DynamoDB), só muda a `key` (`.../dev/terraform.tfstate`,
     `.../staging/...`, `.../prod/...`) para nunca colidir.
   - IAM/OIDC do GitHub Actions: por convenção, **dev** cria o OIDC provider
     (`create_github_oidc_provider = true`), staging/prod reaproveitam via
     `existing_github_oidc_provider_arn` (AWS só permite 1 provider por URL
     por conta).

## Bugs pré-existentes corrigidos (bloqueavam `terraform validate`)

Esses dois já existiam nos módulos entregues antes desta sessão — corrigidos
porque impediam qualquer `validate`, mas sem tocar em mais nada nos arquivos:

- **`terraform/modules/database/main.tf`**: atributo `storage_encrypted`
  estava definido duas vezes em `aws_db_instance.this` (linha 17 e linha 32).
  Terraform rejeita "Attribute redefined". Removida a segunda ocorrência
  (redundante — o valor já vinha de `var.storage_encrypted` na primeira).
- **`terraform/modules/iam/main.tf`**: `thumbprint_list` do
  `aws_iam_openid_connect_provider.github` tinha 39 caracteres hex (faltava
  1 caractere) — o provider AWS exige exatamente 40. Como o comentário já
  presente no código explica, a AWS ignora esse thumbprint desde 2023
  (valida contra sua própria CA trust store), então só precisa ser
  sintaticamente válido. Substituído por
  `1c58a3a8518e8759bf075b76b750d4f2df264fcd` (40 hex chars válidos).

## Comandos rodados

```bash
# Formatação (aplicada em terraform/ inteiro)
cd terraform
terraform fmt -recursive
terraform fmt -recursive -check   # confirma: sem diffs

# Validação por ambiente (init sem backend remoto — bucket de state ainda
# não existe, ver docs/setup/aws-setup.md)
cd environments/dev     && terraform init -backend=false -input=false && terraform validate
cd environments/staging && terraform init -backend=false -input=false && terraform validate
cd environments/prod    && terraform init -backend=false -input=false && terraform validate
```

Resultado: `terraform fmt -check` limpo e `terraform validate` = `Success!
The configuration is valid.` nos 3 ambientes. Terraform CLI usado: v1.15.8
(Windows), provider `hashicorp/aws` resolvido em `~> 5.0` → `5.100.0`.

**Não executados nesta sessão** (por decisão explícita — evitar custo/
depender de credenciais reais aplicadas): `terraform plan` e
`terraform apply`. Cada ambiente ainda usa state local até o bucket S3 +
tabela DynamoDB de lock existirem (ver `docs/setup/aws-setup.md`); os
arquivos `.terraform/`, `.terraform.lock.hcl` e `terraform.tfstate*` gerados
pelo `init` local ficam de fora do commit (`.gitignore` já cobre).

## Decisões desta sessão

| Decisão | Motivo |
|---|---|
| `main.tf` idêntico nos 3 ambientes, toda diferença em variables/tfvars | Evita duplicar lógica de módulo 3x; um reviewer só precisa diffar `variables.tf` para entender dev vs staging vs prod |
| Defaults de redundância (NAT Gateway, Multi-AZ RDS, deletion protection) sempre `false` mesmo em prod | Nenhum ambiente deve gerar custo real só por existir — redundância é opt-in explícito via `terraform.tfvars`, documentado no `.tfvars.example` |
| dev cria o GitHub OIDC provider, staging/prod reaproveitam | AWS permite só 1 OIDC provider por URL por conta — evita erro de duplicidade se os 3 ambientes forem aplicados |
| Thumbprint do OIDC corrigido para um valor sintaticamente válido, não recalculado do zero | AWS não valida mais esse campo desde 2023 (comentário already no código); só precisa passar na validação de schema (40 hex chars) |

## Próximos passos (fora do escopo desta trilha)

- Criar o bucket S3 + tabela DynamoDB de state (`docs/setup/aws-setup.md`) e
  então descomentar os 3 `backend.tf` + `terraform init -migrate-state`.
- Rodar `terraform plan` com credenciais reais e revisar antes de qualquer
  `apply` (pendência do usuário, ver `PROJECT_LOG.md`).
- `tflint`/`checkov` (trilha CI/CD já tem `.tflint.hcl`/`.checkov.yaml` no
  repo) — não rodados aqui, ficam para a trilha de CI/CD/segurança validar
  no GitHub Actions.
