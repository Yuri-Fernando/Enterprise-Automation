# Log da trilha — Configuration Automation (Ansible + PowerShell)

> Complemento a `docs/logs/terraform.md` e `docs/logs/automation-python.md`.
> Escopo: fechar os gaps de `ansible/` e `powershell/` identificados na
> Sessão 2 do `PROJECT_LOG.md`, sem reescrever `ansible/roles/base/*` nem
> `ansible/inventory/*` (já existentes e completos).

## O que foi feito

### Ansible — role `webserver`

Já existiam `tasks/main.yml` e `tasks/install.yml` (parcial), `handlers`,
`defaults` e `meta`. Completado:

- `tasks/configure.yml` — gera o vhost a partir do template, ativa o site
  (symlink `sites-available` → `sites-enabled`), publica um `index.html`
  mínimo de smoke test (`force: false`, não sobrescreve app real já
  deployada) e valida com `nginx -t`.
- `tasks/firewall.yml` — libera a porta HTTP no `ufw`, complementando a
  regra de SSH herdada da role `base`.
- `templates/vhost.conf.j2` — vhost nginx com endpoint de health check
  (`/healthz`, sem log) consumido por `automation/troubleshooting/health_check.py`
  e pelo Load Balancer do Terraform, cabeçalhos de segurança básicos
  (opt-in via `webserver_security_headers_enabled`).
- `handlers/main.yml` — adicionado `reload ufw` (faltava; `firewall.yml`
  já usava `notify: reload ufw`).

### Ansible — playbooks (`ansible/playbooks/`, estava vazio)

- `site.yml` — aplica `base` a todos os hosts Linux, depois `webserver` só
  ao grupo `linux_web`.
- `deploy.yml` — sincroniza um artefato de aplicação (`app_src_dir`) para o
  document root via `ansible.posix.synchronize`, grava um marcador de
  versão e recarrega o nginx. Não re-toca hardening/firewall.
- `healthcheck.yml` — espelha `automation/troubleshooting/health_check.py`
  no lado remoto: `service_facts` + `wait_for` na porta + uso de disco via
  `df`, resume em HEALTHY/UNHEALTHY.
- `remediation.yml` — reinicia o serviço-alvo e revalida a porta, reporta
  RESOLVED/FAILED. Chamado por `automation/orchestrator.py` (variante
  `ansible`) quando o healthcheck acusa problema em um host Linux.

### PowerShell — módulo `InfraOps` (`powershell/modules/InfraOps/`, vazio)

Módulo real (`InfraOps.psd1` + `InfraOps.psm1`) espelhando no Windows o que
os roles Ansible fazem no Linux:

| Função | Espelha (lado Linux) |
|---|---|
| `Get-SystemHealth` | `automation/troubleshooting/health_check.py` |
| `Get-ServiceStatus` | `automation/troubleshooting/service_check.py` |
| `Restart-ServiceSafe` | `automation/troubleshooting/remediation.py` / `playbooks/remediation.yml` |
| `Get-DiskUsage` | `automation/troubleshooting/disk_check.py` |
| `Set-LocalUserPresent` | `ansible/roles/base/tasks/users.yml` |
| `Set-FirewallRule` | `ansible/roles/base/tasks/firewall.yml` (ufw) |

### PowerShell — scripts (`powershell/scripts/`, vazio)

- `health-check.ps1` — roda `Get-SystemHealth`, imprime JSON, exit code
  0/1/2 (saudável/não saudável/erro) para ser chamado por
  `automation/orchestrator.py`.
- `install-app.ps1` — extrai um pacote `.zip` para um diretório, grava
  marcador de versão e reinicia+valida o serviço Windows associado.
- `configure-firewall.ps1` — aplica um conjunto de regras de firewall a
  partir de um JSON (ou default RDP/WinRM) via `Set-FirewallRule`.

### PowerShell — testes Pester (`powershell/tests/`, vazio)

`InfraOps.Tests.ps1` com 9 testes cobrindo as 6 funções do módulo, todos
com `Get-Service`/`Get-CimInstance`/`Restart-Service`/`Get-NetFirewallRule`/
`New-NetFirewallRule`/`Set-NetFirewallRule` mockados (nenhum teste toca
estado real do host).

**Rodado de verdade** neste ambiente (PowerShell 7.5, Pester instalado —
v6.1.0, `Install-Module Pester -MinimumVersion 5.0.0 -Scope CurrentUser`):

```
Tests Passed: 8, Failed: 0, Skipped: 1
```

O único teste pulado é `Set-LocalUserPresent` — o módulo nativo
`Microsoft.PowerShell.LocalAccounts` (que traz `Get-LocalUser`/
`New-LocalUser`) não está presente nesta instalação standalone de
PowerShell 7, então o `Mock` não consegue derivar os metadados do cmdlet.
O teste detecta isso via `Get-Command -ErrorAction SilentlyContinue` e usa
`-Skip` no `Describe`, documentado no próprio arquivo. Roda de verdade no
CI (`windows-latest`, que traz o módulo por padrão).

## Bugs reais encontrados e corrigidos no processo

1. **Shadowing de cmdlet**: a função `New-LocalUser` do módulo tinha o
   mesmo nome do cmdlet nativo `New-LocalUser` — isso quebrava o `Mock` do
   Pester (erro interno de "break/continue label", ver
   pester/pester#2669) porque o mock não conseguia distinguir a função do
   módulo do cmdlet real. Corrigido renomeando para `Set-LocalUserPresent`
   (também mais correto semanticamente — a função é idempotente/"ensure",
   não um "New" puro).
2. **Pipeline binding em `Set-FirewallRule`**: o código original fazia
   `$existing | Set-NetFirewallRule ...`; ao mockar `Set-NetFirewallRule`
   em teste, o binding via pipeline falhava
   (`ParameterBindingException`). Trocado para passar `-DisplayName`
   diretamente (sem pipeline) — mais simples e testável.

## Como rodar

```powershell
# Ansible (Linux runner / WSL / CI Ubuntu — não roda nativamente no Windows,
# decisão já registrada no PROJECT_LOG):
ansible-playbook -i inventory/hosts.example.ini playbooks/site.yml --check --diff

# PowerShell:
Import-Module .\powershell\modules\InfraOps\InfraOps.psd1 -Force
Get-SystemHealth | ConvertTo-Json -Depth 4
.\powershell\scripts\health-check.ps1

# Testes Pester:
Install-Module Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
Invoke-Pester -Path .\powershell\tests\InfraOps.Tests.ps1 -Output Detailed
```

## Pendências

- Rodar `ansible-playbook --syntax-check`/`ansible-lint` de verdade
  (precisa de Linux — CI já cobre isso).
- Testar `Set-LocalUserPresent` num Windows completo com o módulo
  `Microsoft.PowerShell.LocalAccounts` disponível (Windows Server real ou
  runner `windows-latest`).
