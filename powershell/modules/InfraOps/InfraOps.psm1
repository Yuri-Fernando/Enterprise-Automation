#requires -Version 5.1
<#
    InfraOps.psm1 — Enterprise Cloud Automation & Infrastructure Platform

    Módulo PowerShell de automação/troubleshooting para instâncias Windows,
    espelhando (no que faz sentido no Windows) o que ansible/roles/base e
    ansible/roles/webserver fazem no Linux: health check, gestão de
    serviços, disco, usuários locais e firewall.

    Cada função é escrita para ser testável (Pester) sem depender de estado
    real do sistema sempre que possível — dependências externas (Get-Service,
    Get-CimInstance, etc.) ficam isoladas para permitir Mock nos testes.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SystemHealth {
    <#
    .SYNOPSIS
        Retorna um snapshot de saúde do sistema (CPU, memória, disco, uptime).
    .DESCRIPTION
        Espelha automation/troubleshooting/health_check.py no lado Windows.
        Retorna um objeto estruturado (não texto) para ser consumido por
        automation/orchestrator.py via wrapper ou salvo como JSON.
    .PARAMETER DiskThresholdPercent
        Percentual de uso de disco acima do qual o sistema é considerado
        UNHEALTHY (padrão 85%).
    .EXAMPLE
        Get-SystemHealth | ConvertTo-Json -Depth 4
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 100)]
        [int]$DiskThresholdPercent = 85
    )

    $cpuLoad = (Get-CimInstance -ClassName Win32_Processor |
        Measure-Object -Property LoadPercentage -Average).Average

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $memFreePercent = [math]::Round(($os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 2)
    $uptime = (Get-Date) - $os.LastBootUpTime

    $diskUsage = Get-DiskUsage
    $worstDisk = $diskUsage | Sort-Object -Property UsedPercent -Descending | Select-Object -First 1
    $diskOverThreshold = $worstDisk -and ($worstDisk.UsedPercent -gt $DiskThresholdPercent)

    $status = if ($diskOverThreshold) { 'UNHEALTHY' } else { 'HEALTHY' }

    [PSCustomObject]@{
        Timestamp       = (Get-Date).ToUniversalTime().ToString('o')
        Host            = $env:COMPUTERNAME
        CpuLoadPercent  = $cpuLoad
        MemoryFreePct   = $memFreePercent
        UptimeHours     = [math]::Round($uptime.TotalHours, 2)
        Disks           = $diskUsage
        DiskThresholdPc = $DiskThresholdPercent
        Status          = $status
    }
}

function Get-ServiceStatus {
    <#
    .SYNOPSIS
        Retorna o status de um serviço Windows (ou de vários, via -Name com curinga).
    .DESCRIPTION
        Espelha automation/troubleshooting/service_check.py. Não lança
        exceção quando o serviço não existe — retorna Status = 'NotFound'
        para que o orquestrador de self-healing possa tratar isso como um
        diagnóstico, não como falha de execução.
    .PARAMETER Name
        Nome (ou padrão) do serviço, ex.: 'W3SVC', 'Spooler'.
    .EXAMPLE
        Get-ServiceStatus -Name W3SVC
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) {
        return [PSCustomObject]@{
            Name    = $Name
            Status  = 'NotFound'
            Healthy = $false
        }
    }

    [PSCustomObject]@{
        Name    = $svc.Name
        Status  = $svc.Status.ToString()
        Healthy = ($svc.Status -eq 'Running')
    }
}

function Restart-ServiceSafe {
    <#
    .SYNOPSIS
        Reinicia um serviço Windows e valida se voltou a rodar (remediação).
    .DESCRIPTION
        Espelha automation/troubleshooting/remediation.py e
        ansible/playbooks/remediation.yml (lado Linux). Usado pelo fluxo de
        self-healing: health check UNHEALTHY -> Restart-ServiceSafe ->
        revalida -> incidente RESOLVED/FAILED.
    .PARAMETER Name
        Nome do serviço a reiniciar.
    .PARAMETER TimeoutSeconds
        Tempo máximo de espera até o serviço reportar 'Running' após o
        restart (padrão 30s).
    .EXAMPLE
        Restart-ServiceSafe -Name Spooler
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [ValidateRange(1, 300)]
        [int]$TimeoutSeconds = 30
    )

    $before = Get-ServiceStatus -Name $Name
    if ($before.Status -eq 'NotFound') {
        return [PSCustomObject]@{
            Name      = $Name
            Action    = 'restart'
            Restarted = $false
            Validated = $false
            Status    = 'FAILED'
            Reason    = 'Service not found'
        }
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Restart-Service')) {
        Restart-Service -Name $Name -Force -ErrorAction SilentlyContinue
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $validated = $false
    do {
        Start-Sleep -Milliseconds 500
        $after = Get-ServiceStatus -Name $Name
        if ($after.Healthy) { $validated = $true; break }
    } while ((Get-Date) -lt $deadline)

    [PSCustomObject]@{
        Name      = $Name
        Action    = 'restart'
        Restarted = $true
        Validated = $validated
        Status    = if ($validated) { 'RESOLVED' } else { 'FAILED' }
    }
}

function Get-DiskUsage {
    <#
    .SYNOPSIS
        Retorna o uso de disco de todas as unidades locais fixas.
    .DESCRIPTION
        Espelha automation/troubleshooting/disk_check.py. Cada entrada traz
        DeviceID, tamanho total/livre em GB e percentual usado.
    .EXAMPLE
        Get-DiskUsage | Where-Object UsedPercent -gt 85
    #>
    [CmdletBinding()]
    param()

    Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' |
        ForEach-Object {
            $totalGb = [math]::Round($_.Size / 1GB, 2)
            $freeGb = [math]::Round($_.FreeSpace / 1GB, 2)
            $usedPercent = if ($_.Size -gt 0) {
                [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
            } else { 0 }

            [PSCustomObject]@{
                DeviceID    = $_.DeviceID
                TotalGB     = $totalGb
                FreeGB      = $freeGb
                UsedPercent = $usedPercent
            }
        }
}

function Set-LocalUserPresent {
    <#
    .SYNOPSIS
        Garante (idempotente) a existência de um usuário local Windows.
    .DESCRIPTION
        Espelha ansible/roles/base/tasks/users.yml no lado Windows. Se o
        usuário já existir, não faz nada (idempotente) e retorna
        Created = $false.

        NOTA: o nome desta função evita propositalmente o verbo/substantivo
        do cmdlet nativo `New-LocalUser` — usar o mesmo nome causaria
        shadowing do cmdlet real dentro do módulo (e quebra o Mock em
        testes Pester, que resolve o nome para a função local em vez do
        cmdlet do sistema).
    .PARAMETER Name
        Nome do usuário local.
    .PARAMETER Password
        SecureString com a senha inicial. Nunca hardcode a senha em texto
        puro — gere via Read-Host -AsSecureString ou a partir de um
        secret manager.
    .PARAMETER AddToGroup
        Grupo local adicional a incluir o usuário (ex.: 'Administrators').
    .EXAMPLE
        Set-LocalUserPresent -Name 'deploy' -Password (Read-Host -AsSecureString) -AddToGroup 'Administrators'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [System.Security.SecureString]$Password,

        [string]$AddToGroup
    )

    $existing = Get-LocalUser -Name $Name -ErrorAction SilentlyContinue
    if ($existing) {
        return [PSCustomObject]@{ Name = $Name; Created = $false; AddedToGroup = $false }
    }

    if ($PSCmdlet.ShouldProcess($Name, 'New-LocalUser')) {
        New-LocalUser -Name $Name -Password $Password -PasswordNeverExpires:$false -AccountNeverExpires | Out-Null
    }

    $addedToGroup = $false
    if ($AddToGroup) {
        if ($PSCmdlet.ShouldProcess("$Name -> $AddToGroup", 'Add-LocalGroupMember')) {
            Add-LocalGroupMember -Group $AddToGroup -Member $Name -ErrorAction SilentlyContinue
            $addedToGroup = $true
        }
    }

    [PSCustomObject]@{ Name = $Name; Created = $true; AddedToGroup = $addedToGroup }
}

function Set-FirewallRule {
    <#
    .SYNOPSIS
        Garante (idempotente) uma regra de firewall Windows liberando uma porta.
    .DESCRIPTION
        Espelha ansible/roles/base/tasks/firewall.yml e
        ansible/roles/webserver/tasks/firewall.yml (ufw) no lado Windows,
        usando New-NetFirewallRule. Se uma regra com o mesmo DisplayName já
        existir, é atualizada em vez de duplicada.
    .PARAMETER DisplayName
        Nome de exibição único da regra (ex.: 'InfraOps-HTTP').
    .PARAMETER Port
        Porta TCP/UDP a liberar.
    .PARAMETER Protocol
        Protocolo ('TCP' ou 'UDP'). Padrão 'TCP'.
    .EXAMPLE
        Set-FirewallRule -DisplayName 'InfraOps-HTTP' -Port 80
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DisplayName,

        [Parameter(Mandatory)]
        [ValidateRange(1, 65535)]
        [int]$Port,

        [ValidateSet('TCP', 'UDP')]
        [string]$Protocol = 'TCP'
    )

    $existing = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
    if ($existing) {
        if ($PSCmdlet.ShouldProcess($DisplayName, 'Set-NetFirewallRule')) {
            # Passado por -DisplayName em vez de via pipeline: evita depender do
            # binding de propriedades do objeto retornado por Get-NetFirewallRule
            # (e é mais fácil de mockar em testes Pester).
            Set-NetFirewallRule -DisplayName $DisplayName -Enabled True -Action Allow -Direction Inbound
        }
        return [PSCustomObject]@{ DisplayName = $DisplayName; Port = $Port; Protocol = $Protocol; Created = $false }
    }

    if ($PSCmdlet.ShouldProcess($DisplayName, 'New-NetFirewallRule')) {
        New-NetFirewallRule -DisplayName $DisplayName -Direction Inbound -Action Allow `
            -Protocol $Protocol -LocalPort $Port | Out-Null
    }

    [PSCustomObject]@{ DisplayName = $DisplayName; Port = $Port; Protocol = $Protocol; Created = $true }
}

Export-ModuleMember -Function Get-SystemHealth, Get-ServiceStatus, Restart-ServiceSafe, Get-DiskUsage, Set-LocalUserPresent, Set-FirewallRule
