#requires -Version 5.1
<#
    health-check.ps1 — Enterprise Cloud Automation & Infrastructure Platform

    Roda Get-SystemHealth do módulo InfraOps e imprime como JSON (consumido
    por automation/orchestrator.py ao chamar hosts Windows). Exit code 0 =
    HEALTHY, 1 = UNHEALTHY, 2 = erro de execução.

.PARAMETER DiskThresholdPercent
    Percentual de disco acima do qual o host é considerado UNHEALTHY.
.EXAMPLE
    .\health-check.ps1 -DiskThresholdPercent 90
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 100)]
    [int]$DiskThresholdPercent = 85
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\modules\InfraOps\InfraOps.psd1') -Force

try {
    $health = Get-SystemHealth -DiskThresholdPercent $DiskThresholdPercent
    $health | ConvertTo-Json -Depth 4

    if ($health.Status -eq 'HEALTHY') {
        exit 0
    } else {
        exit 1
    }
} catch {
    Write-Error "health-check.ps1 falhou: $($_.Exception.Message)"
    exit 2
}
