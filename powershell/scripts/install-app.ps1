#requires -Version 5.1
<#
    install-app.ps1 — Enterprise Cloud Automation & Infrastructure Platform

    Instala/atualiza uma aplicação empacotada (zip) em um diretório alvo e
    garante que o serviço Windows correspondente está rodando após a
    instalação. Espelha ansible/playbooks/deploy.yml no lado Windows.

.PARAMETER PackagePath
    Caminho do .zip com o artefato da aplicação.
.PARAMETER InstallDir
    Diretório de destino (será criado se não existir).
.PARAMETER ServiceName
    Nome do serviço Windows a validar/reiniciar após a instalação.
.EXAMPLE
    .\install-app.ps1 -PackagePath .\dist\app-1.4.2.zip -InstallDir C:\Apps\MyApp -ServiceName MyAppSvc
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$PackagePath,

    [Parameter(Mandatory)]
    [string]$InstallDir,

    [string]$ServiceName
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\modules\InfraOps\InfraOps.psd1') -Force

if (-not (Test-Path $InstallDir)) {
    if ($PSCmdlet.ShouldProcess($InstallDir, 'New-Item -ItemType Directory')) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
}

Write-Verbose "Extraindo $PackagePath para $InstallDir"
if ($PSCmdlet.ShouldProcess($PackagePath, "Expand-Archive -> $InstallDir")) {
    Expand-Archive -Path $PackagePath -DestinationPath $InstallDir -Force
}

$versionMarker = Join-Path $InstallDir 'VERSION.txt'
Set-Content -Path $versionMarker -Value (Get-Item $PackagePath).BaseName

if ($ServiceName) {
    $status = Get-ServiceStatus -Name $ServiceName
    if ($status.Status -eq 'NotFound') {
        Write-Warning "Serviço '$ServiceName' não encontrado — pulei a validação/restart pós-instalação."
    } else {
        Write-Verbose "Reiniciando serviço '$ServiceName' para carregar a nova versão."
        $result = Restart-ServiceSafe -Name $ServiceName
        $result | Format-List
        if ($result.Status -ne 'RESOLVED') {
            Write-Error "Serviço '$ServiceName' não voltou a rodar após a instalação."
            exit 1
        }
    }
}

Write-Output "Instalação concluída em $InstallDir"
