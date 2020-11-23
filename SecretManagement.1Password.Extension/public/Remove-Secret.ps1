function Remove-Secret {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [string]$VaultName,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )


    $verb = 'delete'
    $commandArgs = [Collections.ArrayList]::new()
    $commandArgs.Add($verb) | Out-Null
    $commandArgs.Add("item") | Out-Null
    $commandArgs.Add($Name) | Out-Null
    $commandArgs.Add('--vault') | Out-Null
    $commandArgs.Add($VaultName) | Out-Null

    Write-Verbose ($commandArgs -join ' ')
    & op @commandArgs

    return $LASTEXITCODE -eq 0
}
