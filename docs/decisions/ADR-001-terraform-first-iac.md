# ADR-001 — Terraform como núcleo de IaC (não CDK/Pulumi)

**Status:** Aceito · **Data:** 2026-08

## Contexto

A plataforma provisiona VPC, EC2/ASG, RDS, IAM, S3 e observabilidade em AWS
e precisa ser reproduzível, revisável em PR e portável para outros
provedores no futuro.

## Decisão

**Terraform** como ferramenta primária de IaC, com estado remoto (S3 +
DynamoDB lock), módulos versionados em `terraform/modules/` e composições
por ambiente em `terraform/environments/`. Configuração pós-provisionamento
fica com Ansible (Linux) e PowerShell DSC (Windows), não com Terraform.

## Alternativas

- **AWS CDK** — bom DX em TypeScript/Python, mas acopla a plataforma à AWS e
  ao runtime de linguagem; `cdk diff` é menos legível em review que
  `terraform plan`.
- **Pulumi** — semelhante ao CDK; menor ecossistema de módulos públicos.
- **CloudFormation puro** — verboso, sem módulos reutilizáveis de verdade,
  travado na AWS.

## Consequências

- (+) `plan` legível em PR; módulos reutilizáveis; estado versionado;
  caminho de portabilidade multi-cloud.
- (−) HCL não é uma linguagem completa (lógica complexa fica feia); drift
  entre `apply`s exige disciplina (mitigado por CI que roda `plan` em todo
  PR).
