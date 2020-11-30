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

    $item = & op get item $Name --fields title --vault $VaultName 2>$null
    $verb = if ($null -eq $item) { 'create' } else { 'edit' }
    Write-Verbose $verb
    $data = @{}
    $commandArgs = [Collections.ArrayList]::new()

    Write-Verbose "Secret type [$($Secret.GetType().Name)]"
    switch ($Secret.GetType()) {
        { $_.IsValueType -or $_.Name -eq 'String' } {
            $category = "Password"
            Write-Verbose "Processing [string] as $category"
            $commandArgs.Add($verb) | Out-Null
            $commandArgs.Add('item') | Out-Null

            if ('create' -eq $verb ) {
                Write-Verbose "Creating $Name"
                $data = op get template $category | ConvertFrom-Json -AsHashtable
                $data.password = $Secret
                $endcodedData = $data | ConvertTo-Json | op encode

                $commandArgs.Add($category) | Out-Null
                $commandArgs.Add($endcodedData) | Out-Null
                $commandArgs.Add("Title=$Name") | Out-Null
            }
            else {
                Write-Verbose "Updating $item"
                $commandArgs.Add($item) | Out-Null
                $commandArgs.Add("password=$Secret") | Out-Null
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
                $data = op get template $category | ConvertFrom-Json -AsHashtable
                $data.password = ConvertFrom-SecureString -SecureString $Secret -AsPlainText
                $endcodedData = $data | ConvertTo-Json | op encode

                $commandArgs.Add($category) | Out-Null
                $commandArgs.Add($endcodedData) | Out-Null
                $commandArgs.Add("Title=$Name") | Out-Null
            }
            else {
                Write-Verbose "Updating $item"
                $commandArgs.Add($item) | Out-Null
                $commandArgs.Add("password=$(ConvertFrom-SecureString -SecureString $Secret -AsPlainText)") | Out-Null
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
                $data = op get template $category | ConvertFrom-Json -AsHashtable
                $data.fields | ForEach-Object {
                    if ($_.name -eq 'username') { $_.value = $Secret.UserName }
                    if ($_.name -eq 'password') { $_.value = $Secret.GetNetworkCredential().Password }
                }
                $endcodedData = $data | ConvertTo-Json | op encode

                $commandArgs.Add($category) | Out-Null
                $commandArgs.Add($endcodedData) | Out-Null
                $commandArgs.Add("Title=$Name") | Out-Null
            }
            else {
                Write-Verbose "Updating $item"
                $commandArgs.Add($item) | Out-Null
                $commandArgs.Add("username=$($Secret.UserName)") | Out-Null
                $commandArgs.Add("password=$(ConvertFrom-SecureString -SecureString $Secret -AsPlainText)") | Out-Null
            }
            break
        }
        Default {}
    }

    $commandArgs.Add('--vault') | Out-Null
    $commandArgs.Add($VaultName) | Out-Null

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