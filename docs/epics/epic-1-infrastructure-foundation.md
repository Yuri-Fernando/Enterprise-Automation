# Epic 1 — Infrastructure Foundation

**Release alvo:** v0.1 · **Trilha:** Terraform / IaC

## Objetivo
Fundação de rede e identidade na AWS via Terraform, com backend remoto e
módulos reutilizáveis.

## Escopo
- [ ] `terraform/backend.tf` — backend remoto (S3 + DynamoDB para state
      locking), documentado mas não aplicado automaticamente
- [ ] `terraform/providers.tf`, `terraform/variables.tf`
- [ ] Módulo `networking`: VPC, subnets públicas/privadas, route tables,
      Internet Gateway, NAT Gateway (opcional/parametrizável)
- [ ] Módulo `iam`: roles/policies least-privilege (sem `Action: "*"`)
- [ ] Módulo `security`: Security Groups reutilizáveis
- [ ] Environments `dev/`, `staging/`, `prod/` consumindo os módulos
- [ ] Tags obrigatórias (`Environment`, `Project`, `ManagedBy`, `Owner`,
      `CostCenter`) com validação
- [ ] `terraform validate` e `terraform fmt -check` passando localmente

## Critérios de aceite
- `terraform init -backend=false && terraform validate` sem erros em cada
  environment.
- Nenhum secret hardcoded nos `.tf`.
- README por módulo explicando inputs/outputs.
