function Get-SecretInfo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$VaultName,
        [Parameter()]
        [string]$Filter,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )

    $op = [OpListItemsCommand]::new($VaultName)
    $op.AddCategories(@('Login', 'Password'))

    # Use the parent scroped cmdlet to pull in the saved VaultParameters
    if (Microsoft.PowerShell.SecretManagement\Test-SecretVault -Name $VaultName) {
        $items = $op.Invoke()
    }

    if ($op.Success) {
        $keyList = [Collections.ArrayList]::new()

        foreach ($item in $items) {
            if ( $keyList.Contains(($item.overview.title).ToLower()) ) {
                Write-Verbose "Get-SecretInfo: An item with the same key has already been added. Key: [$($item.overview.title)]"
            }
            else {
                $type = switch ($item.templateUuid) {
                    '001' { [SecretType]::PSCredential }
                    '005' { [SecretType]::SecureString }
                    Default { [SecretType]::Unknown }
                }

                Write-Verbose $item.overview.title
                [SecretInformation]::new(
                    $item.overview.title,
                    $type,
                    $VaultName
                )
                $keyList.Add(($item.overview.title).ToLower())
            }
        }
    }
    else {
        Write-Error -Message $op.Message -TargetObject "Get-SecretInfo.ps1"
    }
}