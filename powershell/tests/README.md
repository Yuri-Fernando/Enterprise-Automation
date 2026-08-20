# Testes PowerShell (Pester)

Testes unitários do módulo `powershell/modules/InfraOps` usando
[Pester](https://pester.dev/) (v5+).

## Rodar localmente

```powershell
# instalar Pester se ainda não tiver (uma vez):
Install-Module -Name Pester -Force -SkipPublisherCheck -MinimumVersion 5.0.0

Invoke-Pester -Path .\powershell\tests\InfraOps.Tests.ps1 -Output Detailed
```

## Cobertura

Todas as chamadas que tocam estado real do sistema operacional
(`Get-Service`, `Get-CimInstance`, `New-LocalUser`, `Get-LocalUser`,
`Get-NetFirewallRule`, `New-NetFirewallRule`, `Restart-Service`) são
mockadas — os testes **não alteram nada** no host onde rodam e não
precisam de privilégios administrativos.

Rodam também no CI (`.github/workflows/powershell-tests.yml`, runner
`windows-latest`).
