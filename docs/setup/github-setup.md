# Setup GitHub (sua parte)

## 1. Repositório

Criado via `gh repo create` durante o bootstrap desta sessão (público, para
servir como peça de portfólio). Confirme a URL final em
[`../../PROJECT_LOG.md`](../../PROJECT_LOG.md).

## 2. Secrets necessários para o CI rodar `terraform plan` de verdade

`Settings → Secrets and variables → Actions`:

| Secret | Uso |
|--------|-----|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Simples, mas menos seguro (chave de longa duração) |
| ou `AWS_ROLE_TO_ASSUME` (+ OIDC) | Recomendado — sem chaves de longa duração no GitHub |

Sem esses secrets, os workflows de `terraform-ci.yml` que dependem de
credenciais reais (`plan`) falham graciosamente ou ficam limitados a
`fmt`/`validate` (que não precisam de credenciais).

## 3. Branch protection (recomendado)

Em `Settings → Branches → main`:
- Exigir PR antes de merge.
- Exigir que os checks de CI (`terraform-ci`, `security-scan`,
  `python-tests`) passem.

## 4. GitHub Projects (para reforçar a narrativa ágil)

Sugerido, mas manual: criar um Project (board) com os 6 epics em
[`../epics/`](../epics/) como colunas ou milestones, e transformar cada
checklist item em issue. Isso dá histórico real de "backlog, issues,
milestones e entregas incrementais" para citar em entrevista.

## 5. Releases

Ao fechar cada versão do roadmap (`CHANGELOG.md`), criar uma tag e release:

```bash
git tag -a v0.1.0 -m "v0.1.0 - Terraform Foundation"
git push origin v0.1.0
gh release create v0.1.0 --notes-file <(sed -n '/## \[0.1.0\]/,/## \[/p' CHANGELOG.md)
```
