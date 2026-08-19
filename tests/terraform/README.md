# tests/terraform — testes estáticos de Terraform (sem custo)

Scripts que rodam checagens estáticas em todo módulo/environment sob
[`terraform/`](../../terraform/), **sem** nunca chamar `terraform plan` ou
`terraform apply` (decisão registrada em `PROJECT_LOG.md`: nenhum apply
automático nesta fase, para não gerar custo AWS sem aprovação explícita).

## O que roda

Para cada diretório em `terraform/modules/*` e `terraform/environments/*`
que já tenha pelo menos um arquivo `*.tf`:

1. `terraform fmt -check -diff` — formatação (não precisa de rede nem de
   providers, sempre roda).
2. `terraform init -backend=false -input=false` seguido de
   `terraform validate` — sintaxe/tipos/referências. Precisa baixar o
   provider `hashicorp/aws` do Terraform Registry na primeira vez.

Diretórios sem nenhum `.tf` ainda (ex.: `environments/*` enquanto outra
trilha ainda os está preenchendo) são reportados como `SKIP`, não como
`FAIL` — o script foi desenhado para rodar em paralelo com a trilha de
Terraform sem quebrar.

## Uso

```bash
# Bash / Git Bash / WSL / CI (Ubuntu runner)
bash tests/terraform/test-terraform.sh

# PowerShell nativo no Windows
pwsh -File tests/terraform/test-terraform.ps1
```

Variável opcional `TF_TEST_INIT_TIMEOUT` (bash) / parâmetro
`-InitTimeoutSeconds` (PowerShell), padrão 60s — tempo máximo esperando o
`terraform init` baixar o provider antes de reportar `validate: SKIP` para
aquele diretório.

## Nota importante: rede no ambiente de desenvolvimento local

Neste ambiente de desenvolvimento (sandbox local do agente), o acesso de
saída ao Terraform Registry (`registry.terraform.io`) está presente mas é
**extremamente lento/bloqueado** — um `terraform init` chegou a passar de
2m30s sem concluir o download do provider `hashicorp/aws`. Por isso, ao
rodar este script localmente aqui, é esperado ver `validate: SKIP` na
maioria dos diretórios (o `fmt`, que não depende de rede, roda
normalmente e reporta PASS/FAIL de verdade).

Isso segue o mesmo padrão já documentado no `PROJECT_LOG.md` para
`ansible-lint`/`checkov` (não confiáveis localmente no Windows/sandbox,
rodam de verdade no GitHub Actions). No runner Ubuntu do CI, com rede
normal, o `terraform init` conclui em segundos e `validate` roda de
verdade (PASS/FAIL), não SKIP.

## Achados desta execução (2026-08-19)

Rodando os scripts localmente contra o estado atual do repositório:

- `terraform fmt` **encontrou problemas reais de formatação** em
  `terraform/environments/{dev,staging,prod}/main.tf` e em
  `terraform/modules/compute/main.tf` (alinhamento de `=` fora do padrão
  `terraform fmt`). Não corrigidos por esta trilha (pertencem à trilha
  Terraform) — reportado aqui para quem for revisar aquele código.
- `terraform fmt`/`validate` **encontrou um bug real** em
  `terraform/modules/database/main.tf`: o atributo `storage_encrypted` é
  definido duas vezes (linha 17 e linha 32) em `aws_db_instance.this`,
  o que é um erro de sintaxe HCL (`Attribute redefined`) e quebra
  qualquer `plan`/`apply` daquele módulo até ser corrigido.
- `modules/iam`, `modules/monitoring`, `modules/networking`,
  `modules/security` passaram no `fmt` (validate ficou `SKIP` por causa
  da rede lenta descrita acima).

## Saída

- Exit code `0` se nenhum `FAIL` foi registrado (SKIPs não contam como
  falha).
- Exit code `1` se algum `fmt` ou `validate` falhou de verdade.
- Exit code `2` se o executável `terraform` não foi encontrado no PATH.
