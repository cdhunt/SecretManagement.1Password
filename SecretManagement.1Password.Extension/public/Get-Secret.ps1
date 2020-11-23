function Get-Secret {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [string]$Filter,
        [Parameter()]
        [string]$VaultName,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )
    $totp = -1
    $item = & op get item $Name --fields username,password,one-timepassword --vault $VaultName | ConvertFrom-Json -AsHashtable
    if (-not [string]::IsNullOrEmpty($item["one-timepassword"]) )
    {
        $totp = & op get totp $Name --vault $VaultName 2>$nul
    }

    if ( -not [string]::IsNullOrEmpty($item["password"]) ) {
        [securestring]$secureStringPassword = ConvertTo-SecureString $item.password -AsPlainText -Force
    }

    $output = $null

    if ([string]::IsNullOrEmpty($item["password"]) -and -not [string]::IsNullOrEmpty($item.username)) {
        $output = @{UserName = $item.username}
    } elseif
    ([string]::IsNullOrEmpty($item.username)) {
        $output = $secureStringPassword
    }
    else {
        $output = [PSCredential]::new(
            $item.username,
            $secureStringPassword
        )
    }

    if ($totp -gt -1) {
            $output | Add-Member -MemberType ScriptMethod -Name totp -Value {& op get totp $Name --vault $VaultName}.GetNewClosure() -PassThru
    } else {
        $output
    }
}
