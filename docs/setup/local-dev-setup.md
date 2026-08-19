# Setup de desenvolvimento local

## Já verificado nesta máquina (sessão de bootstrap)

| Ferramenta | Status |
|---|---|
| Git | ✅ 2.54.0 |
| Python | ✅ 3.10.8 — usar sempre `C:\Users\Yuri_\AppData\Local\Programs\Python\Python310\python.exe` |
| Terraform | ✅ 1.15.8 (instalado via winget nesta sessão) |
| AWS CLI | ✅ 2.28.8, credenciais já configuradas (`sa-east-1`) |
| Docker Desktop | ⚠️ instalado, **daemon parado** — inicie manualmente antes de usar `database/docker-compose.yml` |
| gh CLI | ✅ 2.88.1, autenticado como Yuri-Fernando |
| PowerShell | ✅ 7.5.2 |
| Pester | ✅ 3.4.0 (versão antiga; considere atualizar: `Install-Module Pester -Force -SkipPublisherCheck`) |
| Jupyter | ✅ completo (lab, notebook, nbconvert) |
| boto3 / moto | ✅ instalados nesta sessão |
| ansible / ansible-lint | ❌ não funcionam nativamente no Windows (dependem do módulo `grp`, POSIX-only) |
| checkov (CLI) | ⚠️ pacote pip instalado, mas o entry point não ficou disponível nesta sessão — reinstalar ou rodar via CI |

## Ansible no Windows

`ansible-playbook` como *control node* não roda nativamente no Windows.
Duas opções:
1. **WSL** (recomendado): `wsl --install`, depois dentro do WSL
   `pip install ansible ansible-lint` e rodar os playbooks contra os hosts
   Linux normalmente.
2. **Só no CI**: não instalar nada local, confiar no
   `.github/workflows/ansible-lint.yml` (roda em Ubuntu) para validar a
   sintaxe. É a abordagem usada nesta primeira fase.

## MySQL local

```bash
# depois de iniciar o Docker Desktop
cd database
docker compose up -d
```

## Rodar os testes Python

```bash
python -m pytest tests/python -v
python -m pytest automation/tests -v
```

## Rodar os notebooks

```bash
jupyter lab notebooks/
```

Cada notebook em `notebooks/` corresponde a uma etapa do roadmap e roda de
ponta a ponta **sem precisar de AWS real** (usa `moto` para mockar boto3 e
dados locais/sqlite ou MySQL local para o resto).

## Terraform local (sem custo)

```bash
cd terraform/environments/dev
terraform init -backend=false
terraform validate
terraform fmt -check -recursive
```
