function Test-SecretVault {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$VaultName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $vaultName).VaultParameters
    )

    $VaultParameters = $AdditionalParameters
    $accountName = $VaultParameters.AccountName
    $emailAddress = $VaultParameters.EmailAddress
    $secretKey = $VaultParameters.SecretKey
    Write-Verbose "SecretManagement: Testing Vault ${VaultName} for Account ${accountName}"

    if (-not $VaultName) { throw '1Password: You must specify a Vault Name to test' }
    if (-not $VaultParameters.AccountName) { throw '1Password: You must specify a 1Password Account to test' }
    if (-not $VaultParameters.EmailAddress) { throw '1Password: You must specify an Email for your 1Password Account to test' }
    if (-not $VaultParameters.SecretKey) { throw '1Password: You must specify an SecretKey for your 1Password Account to test' }

    Write-Verbose "Test listing vaults"
    $vaults = & op list vaults 2>$null | ConvertFrom-Json

    if ($null -eq $vaults) {
        if ( $null -eq [System.Environment]::GetEnvironmentVariable("OP_SESSION_$accountName") ) {
            Write-Verbose "Attemp login with shorthand and grab session token"
            $token = & op signin $accountName --raw

            if ( $null -eq $token ) {
                Write-Verbose "Attemp login with all parameters"
                $token = & op signin $accountName $emailAddress $secretKey -raw
            }
        }
        else {
            Write-Verbose "Attemp login with shorthand and grab session token"
            & op signin $accountName
        }

        Write-Verbose "Cache session token to [OP_SESSION_$accountName] - $token"
        [System.Environment]::SetEnvironmentVariable("OP_SESSION_$accountName", $token)

        Write-Verbose "Test listing vaults final"
        $vaults = & op list vaults 2>$null | ConvertFrom-Json
    }

    $Vaults.name -contains $VaultName
}
