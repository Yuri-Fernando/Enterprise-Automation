#requires -Modules Pester
<#
    InfraOps.Tests.ps1 — testes Pester do módulo InfraOps.

    Roda com: Invoke-Pester -Path .\powershell\tests\InfraOps.Tests.ps1

    Todas as funções que tocam estado real do sistema (Get-Service,
    Get-CimInstance, New-LocalUser, New-NetFirewallRule) são mockadas —
    estes testes não alteram nada no host onde rodam.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\modules\InfraOps\InfraOps.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-ServiceStatus' {
    Context 'quando o serviço existe e está rodando' {
        BeforeAll {
            Mock -ModuleName InfraOps Get-Service {
                [PSCustomObject]@{ Name = 'nginx'; Status = 'Running' }
            }
        }

        It 'retorna Healthy = $true e Status = Running' {
            $result = Get-ServiceStatus -Name 'nginx'
            $result.Status  | Should -Be 'Running'
            $result.Healthy | Should -BeTrue
        }
    }

    Context 'quando o serviço existe mas está parado' {
        BeforeAll {
            Mock -ModuleName InfraOps Get-Service {
                [PSCustomObject]@{ Name = 'nginx'; Status = 'Stopped' }
            }
        }

        It 'retorna Healthy = $false' {
            $result = Get-ServiceStatus -Name 'nginx'
            $result.Healthy | Should -BeFalse
        }
    }

    Context 'quando o serviço não existe' {
        BeforeAll {
            Mock -ModuleName InfraOps Get-Service { $null }
        }

        It 'retorna Status = NotFound sem lançar exceção' {
            { Get-ServiceStatus -Name 'inexistente' } | Should -Not -Throw
            (Get-ServiceStatus -Name 'inexistente').Status | Should -Be 'NotFound'
        }
    }
}

Describe 'Restart-ServiceSafe' {
    Context 'quando o restart e a validação têm sucesso' {
        BeforeAll {
            Mock -ModuleName InfraOps Get-ServiceStatus {
                [PSCustomObject]@{ Name = 'nginx'; Status = 'Running'; Healthy = $true }
            }
            Mock -ModuleName InfraOps Restart-Service { }
            Mock -ModuleName InfraOps Start-Sleep { }
        }

        It 'retorna Status = RESOLVED' {
            $result = Restart-ServiceSafe -Name 'nginx' -Confirm:$false
            $result.Status    | Should -Be 'RESOLVED'
            $result.Validated | Should -BeTrue
        }
    }

    Context 'quando o serviço não é encontrado' {
        BeforeAll {
            Mock -ModuleName InfraOps Get-ServiceStatus {
                [PSCustomObject]@{ Name = 'ghost'; Status = 'NotFound'; Healthy = $false }
            }
        }

        It 'retorna Status = FAILED sem tentar reiniciar' {
            Mock -ModuleName InfraOps Restart-Service { }
            $result = Restart-ServiceSafe -Name 'ghost' -Confirm:$false
            $result.Status | Should -Be 'FAILED'
            Should -Invoke -ModuleName InfraOps Restart-Service -Times 0
        }
    }
}

Describe 'Get-DiskUsage' {
    BeforeAll {
        Mock -ModuleName InfraOps Get-CimInstance {
            @(
                [PSCustomObject]@{ DeviceID = 'C:'; Size = 100GB; FreeSpace = 10GB },
                [PSCustomObject]@{ DeviceID = 'D:'; Size = 200GB; FreeSpace = 190GB }
            )
        } -ParameterFilter { $ClassName -eq 'Win32_LogicalDisk' }
    }

    It 'calcula UsedPercent corretamente' {
        $result = Get-DiskUsage
        ($result | Where-Object DeviceID -eq 'C:').UsedPercent | Should -Be 90
        ($result | Where-Object DeviceID -eq 'D:').UsedPercent | Should -Be 5
    }
}

# Get-LocalUser/New-LocalUser vêm do módulo Microsoft.PowerShell.LocalAccounts,
# incluído no Windows PowerShell 5.1 e no PowerShell 7 rodando em runners
# windows-latest do GitHub Actions — mas ausente em algumas instalações
# standalone do PowerShell 7 (como esta máquina de desenvolvimento). Sem o
# comando original carregado, o Mock do Pester não consegue derivar os
# metadados do cmdlet e o teste é pulado localmente com aviso; roda de
# verdade no CI (.github/workflows/powershell-tests.yml).
$script:HasLocalAccountsModule = [bool](Get-Command -Name Get-LocalUser -ErrorAction SilentlyContinue)

Describe 'Set-LocalUserPresent' -Skip:(-not $script:HasLocalAccountsModule) {
    Context 'quando o usuário já existe' {
        BeforeAll {
            Mock -ModuleName InfraOps Get-LocalUser { [PSCustomObject]@{ Name = 'deploy' } }
            Mock -ModuleName InfraOps New-LocalUser { throw 'não deveria ser chamado' }
        }

        It 'é idempotente e retorna Created = $false' {
            $securePwd = ConvertTo-SecureString 'unused' -AsPlainText -Force
            $result = Set-LocalUserPresent -Name 'deploy' -Password $securePwd -Confirm:$false
            $result.Created | Should -BeFalse
            Should -Invoke -ModuleName InfraOps New-LocalUser -Times 0
        }
    }
}

Describe 'Set-FirewallRule' {
    Context 'quando a regra ainda não existe' {
        BeforeAll {
            Mock -ModuleName InfraOps Get-NetFirewallRule { $null }
            Mock -ModuleName InfraOps New-NetFirewallRule { }
        }

        It 'cria a regra e retorna Created = $true' {
            $result = Set-FirewallRule -DisplayName 'InfraOps-HTTP' -Port 80 -Confirm:$false
            $result.Created | Should -BeTrue
            Should -Invoke -ModuleName InfraOps New-NetFirewallRule -Times 1
        }
    }

    Context 'quando a regra já existe' {
        BeforeAll {
            Mock -ModuleName InfraOps Get-NetFirewallRule {
                [PSCustomObject]@{ DisplayName = 'InfraOps-HTTP' }
            }
            Mock -ModuleName InfraOps Set-NetFirewallRule { }
            Mock -ModuleName InfraOps New-NetFirewallRule { throw 'não deveria ser chamado' }
        }

        It 'não recria a regra (idempotente) e retorna Created = $false' {
            $result = Set-FirewallRule -DisplayName 'InfraOps-HTTP' -Port 80 -Confirm:$false
            $result.Created | Should -BeFalse
            Should -Invoke -ModuleName InfraOps New-NetFirewallRule -Times 0
            Should -Invoke -ModuleName InfraOps Set-NetFirewallRule -Times 1
        }
    }
}
