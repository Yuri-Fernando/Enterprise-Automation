# gitops/

Estado desejado do cluster reconciliado pelo **Argo CD** (ADR-002). Deploy =
merge de PR; rollback = `git revert`. Workloads externos (ex.: **Argus**)
declaram sua própria `Application` apontando para o repo deles — esta
plataforma provê o cluster e o Argo CD, não o código dos workloads.
