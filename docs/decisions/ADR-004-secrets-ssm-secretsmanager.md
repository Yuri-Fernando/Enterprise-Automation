# ADR-004 — Segredos em AWS SSM Parameter Store / Secrets Manager (nunca no repo)

**Status:** Aceito · **Data:** 2026-08

## Decisão

- Segredos de aplicação → **Secrets Manager** (rotação automática quando
  aplicável).
- Config sensível não-secreta → **SSM Parameter Store** (SecureString).
- Acesso por **IAM role por serviço** (IRSA no EKS); nunca chave estática em
  imagem, env de repo ou `terraform.tfvars` versionado.
- CI usa OIDC federation com a AWS (sem `AWS_SECRET_ACCESS_KEY` em secret do
  GitHub de longa duração).

## Consequências

- (+) Nenhum segredo no Git; acesso auditável (CloudTrail); rotação.
- (−) Setup inicial de OIDC/roles é mais trabalhoso que colar uma chave
  (aceito — é a diferença entre demonstração e prática real).
