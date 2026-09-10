# ADR-002 — Entrega de workloads por GitOps (Argo CD)

**Status:** Aceito · **Data:** 2026-09

## Contexto

Além de provisionar infraestrutura, a plataforma hospeda workloads (o
próprio dashboard/controller, e workloads externos como o **Argus**). É
preciso um mecanismo de deploy auditável e com rollback trivial.

## Decisão

**Argo CD** reconcilia o cluster (EKS) para o estado declarado em Git
(`gitops/`). Deploy = merge de PR alterando a tag da imagem / values do
Helm; rollback = `git revert`. Infra (Terraform) e workloads (GitOps) ficam
em trilhas separadas mas complementares.

## Alternativas

- **`kubectl apply` no pipeline (push)** — o CI precisa de credencial de
  prod; sem reconciliação contínua nem drift detection.
- **Flux** — equivalente; Argo CD escolhido pela UI de sync/health (útil
  para operar e para portfólio).

## Consequências

- (+) Todo deploy é um commit; drift detectado e (opcionalmente) revertido;
  cluster e repo nunca divergem em silêncio.
- (−) Mais um componente de plataforma para instalar/operar.
