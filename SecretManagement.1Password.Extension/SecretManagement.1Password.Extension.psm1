using namespace Microsoft.PowerShell.SecretManagement

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
    $vaults = & op vault list --format json | ConvertFrom-Json

    if ($null -eq $vaults) {
        if ( $null -eq [System.Environment]::GetEnvironmentVariable("OP_SESSION_$accountName") ) {
            Write-Verbose "Attempt login with shorthand and grab session token"
            $token = & op signin $accountName --raw

            if ( $null -eq $token ) {
                Write-Verbose "Attempt login with all parameters"
                $token = & op signin $accountName $emailAddress $secretKey --raw
            }
        }
        else {
            Write-Verbose "Attempt login with shorthand and grab session token"
            & op signin $accountName
        }

        Write-Verbose "Cache session token to [OP_SESSION_$accountName] - $token"
        [System.Environment]::SetEnvironmentVariable("OP_SESSION_$accountName", $token)

        Write-Verbose "Test listing vaults final"
        $vaults = & op vault list 2>$null | ConvertFrom-Json
    }

    $Vaults.name -contains $VaultName
}

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

    $json = & op item list --categories "LOGIN,PASSWORD" --format json
    $items = $json -replace 'b5UserUUID', 'B5UserUUID' | ConvertFrom-Json
    $items = $items | Where-Object { $_.overview.title -like $Filter }

    $keyList = [Collections.ArrayList]::new()

    foreach ($item in $items) {
        if ( $keyList.Contains(($item.title).ToLower()) ) {
            Write-Verbose "Get-SecretInfo: An item with the same key has already been added. Key: [$($item.title)]"
        }
        else {
            $type = switch ($item.category) {
                'LOGIN' { [SecretType]::PSCredential }
                'PASSWORD' { [SecretType]::SecureString }
                Default { [SecretType]::Unknown }
            }

            Write-Verbose $item.title
            [SecretInformation]::new(
                $item.title,
                $type,
                $VaultName
            )
            $keyList.Add(($item.title).ToLower())
        }
    }
}

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
    $item = & op item get $Name --format json | ConvertFrom-Json -AsHashtable
    if ($item.fields.Keys.Contains("totp")) {
        $totp = $item.fields.totp
    }

    $password = $item.fields.Where({ $_.id -eq 'password' })
    $username = $item.fields.Where({ $_.id -eq 'username' })
    if ( -not [string]::IsNullOrEmpty($password.value) ) {
        [securestring]$secureStringPassword = ConvertTo-SecureString $password.value -AsPlainText -Force
    }

    $output = $null

    if ([string]::IsNullOrEmpty($password.value) -and -not [string]::IsNullOrEmpty($username.value)) {
        $output = @{UserName = $username.value }
    }
    elseif
    ([string]::IsNullOrEmpty($username.value)) {
        $output = $secureStringPassword
    }
    else {
        $output = [PSCredential]::new(
            $username.value,
            $secureStringPassword
        )
    }

    if ($totp -gt -1) {
        $output | Add-Member -MemberType Property -Name totp -Value $totp -PassThru
    }
    else {
        $output
    }
}

function Set-Secret {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [object]$Secret,
        [Parameter()]
        [string]$VaultName,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )

    $item = &  op item get $Name --format json | ConvertFrom-Json | Select-Object -ExpandProperty Title
    $verb = if ($null -eq $item) { 'create' } else { 'edit' }
    Write-Verbose $verb
    $data = @{}
    $commandArgs = [Collections.ArrayList]::new()

    <#
    op item create --category=login --title='My Example Item' --vault='Test' `
    --url https://www.acme.com/login `
    --generate-password=20,letters,digits `
    username=jane@acme.com `
    'Test Field 1=my test secret' `
    'Test Section 1.Test Field2[text]=Jane Doe' `
    'Test Section 1.Test Field3[date]=1995-02-23' `
    'Test Section 2.Test Field4[text]='$myNotes
    #>

    Write-Verbose "Secret type [$($Secret.GetType().Name)]"
    switch ($Secret.GetType()) {
        { $_.Name -eq 'String' -or $_.IsValueType } {
            $category = "Password"
            Write-Verbose "Processing [string] as $category"
            $commandArgs.Add('item') | Out-Null
            $commandArgs.Add($verb) | Out-Null


            if ('create' -eq $verb ) {
                Write-Verbose "Creating $Name"

                $commandArgs.Add("--category=$category") | Out-Null
                $commandArgs.Add("--title='$Name'") | Out-Null
                $commandArgs.Add("'password=$Secret'") | Out-Null
            }
            else {
                Write-Verbose "Updating $item"

                $commandArgs.Add($item) | Out-Null
                $commandArgs.Add("'$Name'") | Out-Null
                $commandArgs.Add("'password=$Secret'") | Out-Null
            }
            break
        }
        { $_.Name -eq 'securestring' } {
            $category = "Password"
            Write-Verbose "Processing [securestring] as $category"
            $commandArgs.Add($verb) | Out-Null
            $commandArgs.Add('item') | Out-Null

            if ('create' -eq $verb ) {
                Write-Verbose "Creating $Name"
                $commandArgs.Add("--category=$category") | Out-Null
                $commandArgs.Add("--title='$Name'") | Out-Null
                $commandArgs.Add("'password=$(ConvertFrom-SecureString -SecureString $Secret -AsPlainText)'") | Out-Null
            }
            else {
                Write-Verbose "Updating $item"
                $commandArgs.Add($item) | Out-Null
                $commandArgs.Add("'$Name'") | Out-Null
                $commandArgs.Add("'password=$(ConvertFrom-SecureString -SecureString $Secret -AsPlainText)'") | Out-Null
            }
            break
        }
        { $_.Name -eq 'PSCredential' } {
            $category = "Login"
            Write-Verbose "Processing [PSCredential] as $category"
            $commandArgs.Add($verb) | Out-Null
            $commandArgs.Add('item') | Out-Null

            if ('create' -eq $verb ) {
                Write-Verbose "Creating $Name"

                $commandArgs.Add("--category=$category") | Out-Null
                $commandArgs.Add("--title='$Name'") | Out-Null
                $commandArgs.Add("'username=$($Secret.UserName)'") | Out-Null
                $commandArgs.Add("'password=$($Secret.GetNetworkCredential().Password)'") | Out-Null
            }
            else {
                Write-Verbose "Updating $item"
                $commandArgs.Add($item) | Out-Null
                $commandArgs.Add("'$Name'") | Out-Null
                $commandArgs.Add("'username=$($Secret.UserName)'") | Out-Null
                $commandArgs.Add("'password=$($Secret.GetNetworkCredential().Password)'") | Out-Null
            }
            break
        }
        Default {}
    }

    #$commandArgs.Add('--vault') | Out-Null
    #$commandArgs.Add($VaultName) | Out-Null

    $sanitizedArgs = $commandArgs | ForEach-Object {
        if ($_ -like 'password=*') {
            'password=*****'
        }
        else {

            $_
        }
    }
    Write-Verbose ($sanitizedArgs -join ' ')
    & op @commandArgs

    return $?
}

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
    $commandArgs.Add("item") | Out-Null
    $commandArgs.Add($verb) | Out-Null

    $commandArgs.Add("'$Name'") | Out-Null
    #$commandArgs.Add('--vault') | Out-Null
    #$commandArgs.Add($VaultName) | Out-Null
    $commandArgs.Add("--archive") | Out-Null
    Write-Verbose ($commandArgs -join ' ')
    & op @commandArgs

    return $LASTEXITCODE -eq 0
}
