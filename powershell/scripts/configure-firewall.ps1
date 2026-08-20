#requires -Version 5.1
<#
    configure-firewall.ps1 — Enterprise Cloud Automation & Infrastructure Platform

    Aplica um conjunto de regras de firewall a partir de um arquivo JSON
    (ou de um array inline), usando Set-FirewallRule do módulo InfraOps.
    Espelha ansible/roles/base/tasks/firewall.yml (ufw) no lado Windows.

.PARAMETER RulesFile
    Caminho para um JSON no formato:
    [ { "DisplayName": "InfraOps-HTTP", "Port": 80, "Protocol": "TCP" }, ... ]
    Se omitido, aplica um default mínimo (RDP 3389/TCP + WinRM 5985/TCP).
.EXAMPLE
    .\configure-firewall.ps1 -RulesFile .\firewall-rules.json
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RulesFile
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\modules\InfraOps\InfraOps.psd1') -Force

if ($RulesFile) {
    if (-not (Test-Path $RulesFile)) {
        throw "RulesFile '$RulesFile' não encontrado."
    }
    $rules = Get-Content -Path $RulesFile -Raw | ConvertFrom-Json
} else {
    Write-Verbose 'Nenhum -RulesFile informado — aplicando regras default (RDP, WinRM).'
    $rules = @(
        [PSCustomObject]@{ DisplayName = 'InfraOps-RDP';   Port = 3389; Protocol = 'TCP' },
        [PSCustomObject]@{ DisplayName = 'InfraOps-WinRM'; Port = 5985; Protocol = 'TCP' }
    )
}

$results = foreach ($rule in $rules) {
    Set-FirewallRule -DisplayName $rule.DisplayName -Port $rule.Port -Protocol $rule.Protocol
}

$results | Format-Table -AutoSize
