# tests/ansible — lint/syntax checks (sem execução real de playbooks)

Verificação estática do conteúdo de [`ansible/`](../../ansible/): sintaxe
YAML e sintaxe de playbook, **nunca** execução real (`ansible-playbook`
sem `--syntax-check`, ou `--check` contra hosts reais).

## O que roda

```bash
bash tests/ansible/test-ansible.sh
```

1. **`yamllint`** em todo `*.yml`/`*.yaml` sob `ansible/` — funciona em
   qualquer SO (Windows/Linux/macOS), é puro Python sem dependência POSIX.
   Roda de verdade aqui e reporta PASS/FAIL real.
2. **`ansible-playbook --syntax-check`** para cada playbook em
   `ansible/playbooks/*.yml` — tentado, mas com uma ressalva importante
   documentada abaixo.

## Decisão registrada: `ansible-lint`/Ansible completo não roda no Windows

Já documentado em `PROJECT_LOG.md`:

> `ansible-lint`/`checkov` não rodam localmente (dependem de módulos POSIX
> no Windows) — rodam de verdade no GitHub Actions (Ubuntu runner).

Confirmado nesta sessão: no Python 3.10 nativo do Windows usado neste
projeto, o próprio `ansible`/`ansible-playbook` **não consegue nem
inicializar**:

```
File "...\ansible\cli\__init__.py", line 34, in check_blocking_io
    if not os.get_blocking(fd):
AttributeError: module 'os' has no attribute 'get_blocking'
```

`os.get_blocking` só existe em sistemas POSIX (Linux/macOS) — é uma
limitação da própria biblioteca `ansible-core`, não deste projeto. Por
isso, `test-ansible.sh` detecta essa falha específica e reporta
`--syntax-check` como `SKIP` (com explicação), em vez de um traceback
cru ou uma falha "vermelha" enganosa.

**Onde roda de verdade:**

- WSL (`wsl bash tests/ansible/test-ansible.sh`) ou qualquer Linux/macOS
  com Python 3.10+ padrão.
- GitHub Actions, runner `ubuntu-latest` (ver `.github/workflows/`) —
  aqui sim, `ansible-playbook --syntax-check` e `ansible-lint` rodam
  completos como parte do CI.

## Resultado desta execução local (Windows, 2026-08-19)

- `yamllint`: **PASS** — nenhum problema de formatação YAML encontrado em
  `ansible/roles/`, `ansible/inventory/`, `ansible/ansible.cfg`-adjacent
  files.
- `ansible-playbook --syntax-check`: **SKIP** (ansible-core não inicializa
  no Python nativo do Windows, ver acima). `ansible/playbooks/` também
  ainda está vazio nesta trilha em paralelo, então mesmo em Linux/CI não
  haveria playbook para checar até aquela trilha terminar.

## Saída

- Exit code `0`: nenhum FAIL real (SKIPs de ambiente não contam).
- Exit code `1`: `yamllint` ou `--syntax-check` encontrou erro real.
