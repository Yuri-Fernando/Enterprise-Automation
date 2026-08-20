@{
    RootModule        = 'InfraOps.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'b3f7f0a0-2c1e-4a6b-9d3f-7a1c2e4f5b6c'
    Author            = 'Yuri Fernando Dubbern'
    CompanyName       = 'Portfolio'
    Copyright         = '(c) Yuri Fernando Dubbern. MIT License.'
    Description       = 'Automação e troubleshooting de infraestrutura Windows para o Enterprise Cloud Automation & Infrastructure Platform (projeto de portfolio). Espelha, no Windows, o que os roles Ansible fazem no Linux.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-SystemHealth',
        'Get-ServiceStatus',
        'Restart-ServiceSafe',
        'Get-DiskUsage',
        'Set-LocalUserPresent',
        'Set-FirewallRule'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('infrastructure', 'automation', 'windows', 'troubleshooting')
            LicenseUri = 'https://opensource.org/licenses/MIT'
        }
    }
}
