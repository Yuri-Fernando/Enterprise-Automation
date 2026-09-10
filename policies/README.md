# policies/ — Policy as Code

| Camada | Ferramenta | O que valida |
|---|---|---|
| Terraform (pré-apply, no CI) | **OPA / Conftest** (`opa/`) | tags obrigatórias, sem SG `0.0.0.0/0` em porta sensível, RDS não público, S3 sem ACL pública |
| Kubernetes (admission) | **Kyverno** (`kyverno/`) | imagem não-`latest`, `runAsNonRoot`, limites de recurso obrigatórios, `PodDisruptionBudget` presente |

> 🗺️ Referência. As políticas são válidas; a execução no CI/cluster é o
> próximo passo.
