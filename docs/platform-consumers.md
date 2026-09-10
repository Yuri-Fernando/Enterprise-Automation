# Consumidores da plataforma

Esta plataforma provê **infraestrutura e entrega**; os workloads são de
outros projetos.

```text
enterprise-cloud-automation-platform          (esta plataforma)
   terraform/  → VPC · EKS · RDS · IAM · observabilidade
   gitops/     → Argo CD
   policies/   → OPA (Terraform) + Kyverno (K8s)
        │
        ▼  provê cluster + entrega
   ┌────────────────────────────────────────┐
   │  Argus (Enterprise AI & Data Platform) │  ← workload principal
   │  outros serviços de aplicação          │
   └────────────────────────────────────────┘
```

O **Argus** (`services/`, `platform/`) declara sua própria
`argocd Application` apontando para o repositório dele; esta plataforma não
versiona o código do Argus, só o ambiente em que ele roda. Ver
`docs/decisions/ADR-002-gitops-argocd.md`.
