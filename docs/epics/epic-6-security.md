# Epic 6 — Security

**Release alvo:** v1.0 · **Trilha:** Terraform / IaC + CI/CD

## Objetivo
Governança e segurança demonstráveis, não apenas mencionadas no currículo.

## Escopo
- [ ] IAM least-privilege em todos os módulos (nunca `Action: "*"`)
- [ ] Secrets via AWS Secrets Manager / SSM Parameter Store (nunca no Git)
- [ ] `checkov`/`tfsec` no CI bloqueando achados críticos
- [ ] Tags obrigatórias validadas (`Environment`, `Project`, `ManagedBy`,
      `Owner`, `CostCenter`)
- [ ] `docs/setup/aws-setup.md` — checklist de segurança antes do primeiro
      `apply` (MFA, least-privilege do usuário/role usado pelo CI, etc.)
- [ ] `SECURITY.md` — política simples de disclosure/uso do repositório

## Critérios de aceite
- Nenhuma credencial ou `.tfvars` real commitado (verificar `.gitignore`).
- `checkov` sem findings CRITICAL nos módulos principais.
