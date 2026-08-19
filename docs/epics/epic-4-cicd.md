# Epic 4 — CI/CD

**Release alvo:** v0.3 · **Trilha:** CI/CD + Segurança

## Objetivo
Pipeline que valida cada mudança antes de qualquer aplicação real de infra.

## Escopo
- [ ] `.github/workflows/terraform-ci.yml`: fmt, validate, tflint, plan
      (sem apply automático)
- [ ] `.github/workflows/security-scan.yml`: checkov (e/ou tfsec) bloqueando
      IAM permissivo (`Action: "*"`, `Resource: "*"`)
- [ ] `.github/workflows/ansible-lint.yml`
- [ ] `.github/workflows/python-tests.yml`: pytest + coverage
- [ ] `.github/workflows/powershell-tests.yml`: Pester + PSScriptAnalyzer
- [ ] `.pre-commit-config.yaml` (opcional, roda os mesmos checks localmente)

## Critérios de aceite
- Todos os workflows disparam em `pull_request` para `main`.
- Pipeline falha (bloqueia merge) se `checkov` encontrar IAM permissivo.
- `terraform apply` nunca roda automaticamente — apenas `plan`.
