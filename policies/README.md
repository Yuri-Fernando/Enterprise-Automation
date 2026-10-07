# policies/ — Policy as Code

| Camada | Ferramenta | O que valida |
|---|---|---|
| Terraform (pré-apply, no CI) | **OPA / Conftest** (`opa/`) | tags obrigatórias (`Environment`/`Project`/`ManagedBy`, via `tags_all`) |
| Kubernetes (admission) | **Kyverno** (`kyverno/`) | `runAsNonRoot`, limites de recurso obrigatórios |

## Status: wired no CI (✅, não é mais só referência)

`.github/workflows/policy-gate.yml` executa as duas policies de verdade em
todo PR que toca `policies/**` ou `terraform/**`:

- **OPA/conftest** (`tests/terraform/test-opa-policies.sh`): roda `conftest
  test` contra dois fixtures reais em `opa/testdata/` — um `plan.json`
  gerado de verdade (via LocalStack, sem custo AWS) para
  `terraform/environments/dev` com tagging correto (deve passar), e o
  mesmo plano com uma tag obrigatória removida de um recurso (deve falhar).
  Quando `AWS_ROLE_TO_ASSUME` estiver configurado (ver
  `docs/setup/github-setup.md`), um segundo job roda conftest contra o
  `terraform plan` real de dev/staging/prod automaticamente — sem precisar
  editar o workflow.
- **Kyverno** (`tests/terraform/test-kyverno-policies.sh`): roda
  `kyverno test` contra dois Pods fixture em `kyverno/testdata/` — um
  espelhando o Pod real que `helm/automation-controller/` produziria
  (deve passar as 2 regras) e um sem `securityContext`/`resources` (deve
  falhar as 2 regras).

### Bug real encontrado e corrigido

`opa/terraform_tags.rego` exigia chaves de tag minúsculas
(`project`/`environment`/`managed_by`), que nunca batem com as tags reais
deste projeto — capitalizadas em `terraform/providers.tf`'s `default_tags`
(`Environment`/`Project`/`ManagedBy`/...). Resultado: a policy "passava"
sempre, mas só porque nunca conseguia comparar nada — não validava
absolutamente nada. Corrigido para usar as chaves reais e o atributo
`tags_all` (tags efetivamente aplicadas pelo provider, não só as
declaradas localmente no recurso). Ver `CHANGELOG.md` / `PROJECT_LOG.md`.

### O que ficou de fora (não inventado)

As regras adicionais mencionadas numa versão anterior deste README
("sem SG `0.0.0.0/0` em porta sensível", "RDS não público", "S3 sem ACL
pública", "imagem não-`latest`", "`PodDisruptionBudget` presente") não
existem como regras `.rego`/Kyverno neste repositório — foram removidas
desta tabela porque descreviam políticas que nunca foram escritas. Escopo
real desta sessão: consolidar e *testar* as 2 regras que já existiam
(tags + non-root/limits), não escrever políticas novas sem pedido
explícito.
