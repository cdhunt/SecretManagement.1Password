@{
    ModuleVersion     = '2.0.0.0'
    RootModule = 'SecretManagement.1Password.Extension.psm1'
    FunctionsToExport = @('Get-Secret','Get-SecretInfo','Test-SecretVault','Set-Secret','Remove-Secret')
}