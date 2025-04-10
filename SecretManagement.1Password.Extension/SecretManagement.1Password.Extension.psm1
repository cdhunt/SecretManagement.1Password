using namespace Microsoft.PowerShell.SecretManagement

function Invoke-OpCommand{
<#
.SYNOPSIS
Calls the 1Password CLI console application and returns an object with three properties:
    StdOut: Text, excluding errors, returned by the application 
    StdErr: Error text returned by the application, if any.
    ExitCode: Exit code of the command. ExitCode=0 means "Success".

.DESCRIPTION
Calling the op.exe application directly from PowerShell (with the prefix "&") doesn't allow to
capture the text outputted in case of an error. This function solves the issue and suppress the
need to redirecting the error text to "$null", to prevent its display to the user.

.PARAMETER ArgumentList
Argument list to be passed to the 1Password CLI console application.
#>
    param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            HelpMessage="Argument list to be passed to the 1Password CLI console application.")]
        [String[]]$ArgumentList
    )
    
    $pinfo = [System.Diagnostics.ProcessStartInfo]::new();
    $pinfo.FileName = "op.exe";
    $pinfo.RedirectStandardError = $true;
    $pinfo.RedirectStandardOutput = $true;
    $pinfo.UseShellExecute = $false;
    $pinfo.Arguments = ($ArgumentList -join " ");
    $p = New-Object System.Diagnostics.Process;
    $p.StartInfo = $pinfo;
    $p.Start() | Out-Null;
    $stdout = $p.StandardOutput.ReadToEnd();
    $stderr = $p.StandardError.ReadToEnd();
    $p.WaitForExit();
    return [PSCustomObject]@{
        StdOut = $stdout;
        StdErr = $stderr;
        ExitCode = $p.ExitCode;
    }
}

function Test-SecretVault {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$VaultName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [hashtable]$AdditionalParameters
    )

    if (-not $VaultName) { 
        Write-Error 'The name SecretManagement vault must be provided.' 
        return $false
    }

    Write-Verbose "Validating the SecretManagement Vault '$($VaultName)'..."

    $secretVault = Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue
    if ($null -eq $secretVault){
        Write-Error "The SecretManagement vault '$($VaultName)' is not registered."
        return $false
    }
    if ($null -eq $AdditionalParameters){
        $VaultParameters = $secretVault.VaultParameters
    }else{
        $VaultParameters = $AdditionalParameters
    }

    Write-Verbose "Validating the 1Password Vault parameters> AccountName: '$($VaultParameters.AccountName)'; OPVault: '$($VaultParameters.OPVault)'"
   
    if (-not $VaultParameters.AccountName) { Write-Warning 'The 1Password account (AccountName) is missing in the SecretManagement vault parameters.' }
    if (-not $VaultParameters.OPVault) { Write-Warning 'The 1Password vault name (OPVault) is missing in the SecretManagement vault parameters.' }

    Write-Verbose "Trying to read the 1Password vaults ..."
    $commandArgs = [System.Collections.ArrayList]::new();
    $commandArgs.AddRange(@('vault', 'list'));
    if ($VaultParameters.AccountName) {
        $commandArgs.AddRange(@('--account', "$($VaultParameters.AccountName)"));
    }
    $commandArgs.AddRange(@('--format', 'json'));
    $result = Invoke-OpCommand $commandArgs;
    if ($result.ExitCode -ne 0){
        #Error on execution
        Write-Error "An arror occurred while accessing 1Password: $($result.StdErr)";
        return $false;
    }else{
        Write-Verbose "1Password vaults successfully read."
    }
    $vaults = $result.StdOut | ConvertFrom-Json;
    if (-not $vaults) {
        Write-Error "No vaults were found in 1Password."
        return false;
    }
    if ($VaultParameters.OPVault) {
        $targetVault = $vaults.Where({ $_.name -eq $VaultParameters.OPVault -or $_.id -eq $VaultParameters.OPVault })

        if ($targetVault){
            Write-Verbose "1Password vault '$($VaultParameters.OPVault)' successfully found."
            return $true
        }else{
            Write-Error "The vault '$($VaultParameters.OPVault)' was not found in 1Password."
            return $false
        }
    }else{
        Write-Verbose "1Password contains '$($vaults.Count)' vaults."
        return ($vaults.Count -gt 0)
    }
}

function Get-SecretInfo {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)]
        [string]$VaultName,
        [Parameter()]
        [string]$Filter,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )

    Write-Verbose "'Get-SecretInfo' invoked ..."

    if ($null -ne $AdditionalParameters){
        $VaultParameters = $AdditionalParameters
    }else{
        if ($null -eq $VaultName){$VaultName = ""}
        $secretVault = Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue
        if ($null -eq $secretVault){
            Write-Error "The SecretManagement vault '$($VaultName)' is not registered."
            return $null
        }
        $VaultParameters = $secretVault.VaultParameters
    }

    $commandArgs = [System.Collections.ArrayList]::new();
    $commandArgs.AddRange(@('item', 'list'));
    if ($VaultParameters.AccountName) {
        $commandArgs.AddRange(@('--account', """$($VaultParameters.AccountName)"""));
    }
    if ($VaultParameters.OPVault) {
        $commandArgs.AddRange(@('--vault', """$($VaultParameters.OPVault)"""));
    }
    $commandArgs.AddRange(@('--categories', '"LOGIN,PASSWORD"', '--format', 'json'));
    $result = Invoke-OpCommand $commandArgs;
    if ($result.ExitCode -eq 0){
        $items = $result.StdOut -replace 'b5UserUUID', 'B5UserUUID' | ConvertFrom-Json;

        if (-not [string]::IsNullOrEmpty($Name)){
            $items = $items | Where-Object { $_.title -eq $Name };
        }else{
            if ([string]::IsNullOrEmpty($Filter)){
                $Filter = "*"
            }
            $items = $items | Where-Object { $_.title -like $Filter };
        }
    }else{
        $items = $null;
    }

    $keyList = [System.Collections.Generic.Dictionary[[string],[SecretInformation]]]::new();

    foreach ($item in $items) {
        if ( $keyList.ContainsKey(($item.title).ToLower()) ) {
            Write-Verbose "Get-SecretInfo: An item with the same key has already been added. Key: [$($item.title)]"
        }
        else {
            $type = switch ($item.category) {
                'LOGIN' { [SecretType]::PSCredential }
                'PASSWORD' { [SecretType]::SecureString }
                Default { [SecretType]::Unknown }
            }
            
            $metadata = @{
                id = $item.id
                version = $item.version
                created_at = Get-Date $item.created_at
                updated_at = Get-Date $item.updated_at
                additional_information = $item.additional_information
                urls = $item.urls
            }

            Write-Verbose $item.title
            
            # The vault name to be returned within the SecretInformation object must be the name of the SecretManagement
            # vault because the SecretInformation object can be passed to the Get-Secret cmdlet to query secrets, which 
            # will require to have the name of the SecretManagement vault.
            # See: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/get-secret?view=ps-modules#-inputobject
            $keyList.Add( `
                $(($item.title).ToLower()), `
                [SecretInformation]::new($item.title, $type, $($VaultName), $metadata) `
            );
        }
    }

    return [SecretInformation[]]$keyList.Values
}

function Get-Secret {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [string]$Filter,
        [Parameter()]
        [string]$VaultName,
        [Parameter()]
        [switch]$AsPlainText,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )

    Write-Verbose "'Get-Secret' invoked ..."

    if ($null -ne $AdditionalParameters){
        $VaultParameters = $AdditionalParameters
    }else{
        if ($null -eq $VaultName){$VaultName = ""}
        $secretVault = Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue
        if ($null -eq $secretVault){
            Write-Error "The SecretManagement vault '$($VaultName)' is not registered."
            return $null
        }
        $VaultParameters = $secretVault.VaultParameters
    }

    $commandArgs = [System.Collections.ArrayList]::new();
    $commandArgs.AddRange(@('item', 'get', """$($Name)"""));
    if ($VaultParameters.AccountName) {
        $commandArgs.AddRange(@('--account', """$($VaultParameters.AccountName)"""));
    }
    if ($VaultParameters.OPVault) {
        $commandArgs.AddRange(@('--vault', """$($VaultParameters.OPVault)"""));
    }
    $commandArgs.AddRange(@('--format', 'json'));
    $result = Invoke-OpCommand $commandArgs;
    if ($result.ExitCode -ne 0){
        Write-Verbose $result.StdErr;
        return $null; # Not found
    }
    $item = $result.StdOut | ConvertFrom-Json;

    # Check existence of Time-based One Time Password (TOTP)
    $totp = -1
    if ($item.fields.type -contains "OTP") {
        $totp = $item.fields.Where({ $_.type -eq 'OTP' }) | Select-Object -ExpandProperty totp
    }

    $password = $item.fields.Where({ $_.id -eq 'password' })
    $username = $item.fields.Where({ $_.id -eq 'username' })

    if ( -not [string]::IsNullOrEmpty($password.value) -and -not $AsPlainText) {
        [securestring]$secureStringPassword = ConvertTo-SecureString $password.value -AsPlainText -Force
    }

    $output = $null

    if ([string]::IsNullOrEmpty($password.value) -and -not [string]::IsNullOrEmpty($username.value)) {
        $output = @{UserName = $username.value }
    } elseif ([string]::IsNullOrEmpty($username.value)) {
        if ($AsPlainText) {
            if($totp -gt -1){
                $output = @{Password = $username.value; totp = $totp }
            } else {
                $output = $username.value
            }
        } else {
            if($totp -gt -1){
                $output = @{Password = $secureStringPassword; totp = $totp }
            } else {
                $output = $secureStringPassword
            }
        }
    } else {
        if ($AsPlainText) {
            if($totp -gt -1){
                $output = @{UserName = $username.value; Password = $username.value; totp = $totp }
            } else {
                $output = $username.value
            }
        } else {
            if($totp -gt -1){
                $output = @{
                    Credentials = [PSCredential]::new(
                        $username.value,
                        $secureStringPassword
                    );
                    totp = $totp
                }
            } else {
                $output = [PSCredential]::new(
                    $username.value,
                    $secureStringPassword
                )
            }
        }

    }

    return $output

}

function Set-Secret {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
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

    Write-Verbose "'Set-Secret' invoked ..."

    if ($null -ne $AdditionalParameters){
        $VaultParameters = $AdditionalParameters
    }else{
        if ($null -eq $VaultName){$VaultName = ""}
        $secretVault = Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue
        if ($null -eq $secretVault){
            Write-Error "The SecretManagement vault '$($VaultName)' is not registered."
            return $null
        }
        $VaultParameters = $secretVault.VaultParameters
    }

    $commandArgs = [System.Collections.ArrayList]::new();
    $commandArgs.AddRange(@('item', 'get', """$($Name)"""));
    if ($VaultParameters.AccountName) {
        $commandArgs.AddRange(@('--account', """$($VaultParameters.AccountName)"""));
    }
    if ($VaultParameters.OPVault) {
        $commandArgs.AddRange(@('--vault', """$($VaultParameters.OPVault)"""));
    }
    $commandArgs.AddRange(@('--format', 'json'));
    $result = Invoke-OpCommand $commandArgs;

    if ($result.ExitCode -ne 0){
        if ($result.StdErr.Contains("More than one item matches")){
            throw [Exception]::new($result.StdErr);
            return $null;
        }
        # Not found
        $verb = 'create';
    }else{
        # Found and there is only one
        $verb = 'edit';
    }
    Write-Verbose $verb
    $commandArgs = [System.Collections.ArrayList]::new();
    $commandArgs.AddRange(@('item', $verb));
    if ($VaultParameters.AccountName) {
        $commandArgs.AddRange(@('--account', """$($VaultParameters.AccountName)"""));
    }
    if ($VaultParameters.OPVault) {
        $commandArgs.AddRange(@('--vault', """$($VaultParameters.OPVault)"""));
    }
    $commandArgs.AddRange(@('--format', 'json'));

    <#
    op item create --category=login --title='My Example Item' --vault='Test' `
    --url https://www.acme.com/login `
    --generate-password='letters,digits,symbols,32' `
    username=jane@acme.com `
    'Test Field 1=my test secret' `
    'Test Section 1.Test Field2[text]=Jane Doe' `
    'Test Section 1.Test Field3[date]=1995-02-23' `
    'Test Section 2.Test Field4[text]=Testing 1Password CLI'
    #>

    Write-Verbose "Secret type [$($Secret.GetType().Name)]"
    switch ($Secret.GetType()) {
        { $_.Name -eq 'String' -or $_.IsValueType } {
            $category = "Password"
            Write-Verbose "Processing [string] as '$category'"

            if ('create' -eq $verb ) {
                Write-Verbose "Creating '$Name'"

                $commandArgs.Add("--category=$category") | Out-Null
                $commandArgs.Add("--title=""$Name""") | Out-Null
                $commandArgs.Add("password=""$Secret""") | Out-Null
            }
            else {
                Write-Verbose "Updating '$Name'"

                $commandArgs.Add("""$Name""") | Out-Null
                $commandArgs.Add("password=""$Secret""") | Out-Null
            }
            break
        }
        { $_.Name -eq 'securestring' } {
            $category = "Password"
            Write-Verbose "Processing [securestring] as '$category'"

            if ('create' -eq $verb ) {
                Write-Verbose "Creating ""$Name"""
                $commandArgs.Add("--category=$category") | Out-Null
                $commandArgs.Add("--title=""$Name""") | Out-Null
                $commandArgs.Add("password=""$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret)))""") | Out-Null
            }
            else {
                Write-Verbose "Updating '$Name'"
                $commandArgs.Add("""$Name""") | Out-Null
                $commandArgs.Add("password=""$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret)))""") | Out-Null
            }
            break
        }
        { $_.Name -eq 'PSCredential' } {
            $category = "Login"
            Write-Verbose "Processing [PSCredential] as $category"

            if ('create' -eq $verb ) {
                Write-Verbose "Creating '$Name'"

                $commandArgs.Add("--category=$category") | Out-Null
                $commandArgs.Add("--title=""$Name""") | Out-Null
                $commandArgs.Add("username=""$($Secret.UserName)""") | Out-Null
                $commandArgs.Add("password=""$($Secret.GetNetworkCredential().Password)""") | Out-Null
            }
            else {
                Write-Verbose "Updating '$Name'"
                $commandArgs.Add("""$Name""") | Out-Null
                $commandArgs.Add("username=""$($Secret.UserName)""") | Out-Null
                $commandArgs.Add("password=""$($Secret.GetNetworkCredential().Password)""") | Out-Null
            }
            break
        }
        Default {}
    }

    $sanitizedArgs = $commandArgs | ForEach-Object {
        if ($_ -like 'password=*') {
            'password=*****'
        } else {
            $_
        }
    }
    Write-Verbose ($sanitizedArgs -join ' ')

    $result = Invoke-OpCommand $commandArgs;
    #$result.StdOut;
    #$result.StdErr;
    return ($result.ExitCode -eq 0);
}

function Remove-Secret {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [string]$VaultName,
        [Parameter()]
        [hashtable] $AdditionalParameters
    )

    Write-Verbose "'Remove-Secret' invoked ..."

    if ($null -ne $AdditionalParameters){
        $VaultParameters = $AdditionalParameters
    }else{
        if ($null -eq $VaultName){$VaultName = ""}
        $secretVault = Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue
        if ($null -eq $secretVault){
            Write-Error "The SecretManagement vault '$($VaultName)' is not registered."
            return $null
        }
        $VaultParameters = $secretVault.VaultParameters
    }

    $commandArgs = [System.Collections.ArrayList]::new();
    $commandArgs.AddRange(@('item', 'delete', """$($Name)"""));
    if ($VaultParameters.AccountName) {
        $commandArgs.AddRange(@('--account', """$($VaultParameters.AccountName)"""));
    }
    if ($VaultParameters.OPVault) {
        $commandArgs.AddRange(@('--vault', """$($VaultParameters.OPVault)"""));
    }
    $commandArgs.Add("--archive") | Out-Null
    Write-Verbose ($commandArgs -join ' ')

    $result = Invoke-OpCommand $commandArgs;
    #$result.StdOut;
    #$result.StdErr;
    if ($result.ExitCode -ne 0){
        Write-Error "An arror occurred while trying to delete the secret '$($Name)' in 1Password: $($result.StdErr)";
    }
    return ($result.ExitCode -eq 0);
}
