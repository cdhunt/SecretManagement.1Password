enum OpNouns {
    vaults
    items
}

enum OpItemsCategories {
    Login = 1
    Password = 5
}

class Op {
    hidden [string]$Bin
    hidden [Diagnostics.ProcessStartInfo]$ProcessInfo
    hidden [string]$StandardOuput

    [string]$Vault
    [string]$Message
    [bool] $Success

    Op () {
        $this.Bin = Get-Command -Name 'op' -CommandType Application | Select-Object -ExpandProperty Source
        $this.ProcessInfo = [Diagnostics.ProcessStartInfo]::new()
        $this.ProcessInfo.FileName = $this.Bin
        $this.ProcessInfo.RedirectStandardError = $true
        $this.ProcessInfo.RedirectStandardOutput = $true
        $this.ProcessInfo.UseShellExecute = $false

        $this.Message = 'The command completed without error.'
        $this.Success = $true
    }

    Op ([string]$VaultName) {
        $this.Bin = Get-Command -Name 'op' -CommandType Application | Select-Object -ExpandProperty Source
        $this.ProcessInfo = [Diagnostics.ProcessStartInfo]::new()
        $this.ProcessInfo.FileName = $this.Bin
        $this.ProcessInfo.RedirectStandardError = $true
        $this.ProcessInfo.RedirectStandardOutput = $true
        $this.ProcessInfo.UseShellExecute = $false

        $this.Message = 'The command completed without error.'
        $this.Success = $true
        $this.Vault = $VaultName
    }

    [void] SetVault ([string]$VaultName) {
        $this.Vault = $VaultName
    }

    [void] AddArgument ([string]$Argument) {
        $this.ProcessInfo.ArgumentList.Add($Argument)
    }

    [void] AddAssignment ([string]$Key, [object]$Value) {

        $assignment = $Key, $Value.ToString() -join '='

        $this.ProcessInfo.ArgumentList.Add($assignment)
    }

    [void] AddVaultFlag () {
        $this.AddArgument('--vault')
        $this.AddArgument($this.Vault)
    }

    [bool] InvokeOp() {
        Write-Verbose "(Invoke) ArgumentList=[$($this.GetSanitizedArgumentString())]"

        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $this.ProcessInfo
        $process.Start() | Out-Null
        $process.WaitForExit(5000)

        $this.StandardOuput = $process.StandardOutput.ReadToEnd()
        $StdErr = $process.StandardError.ReadToEnd()

        Write-Verbose "(Invoke) Message=[$($this.Message)]"

        if (-not [string]::IsNullOrEmpty($StdErr) ) {
            $this.Success = $false
            $this.Message = [Op]::ParseError($StdErr)
        } else {
            $this.Success = $true
        }

        return $this.Success
    }

    [string] Invoke() {

        $result = $this.InvokeOp()

        return $this.Message
    }

    static [string] ParseError([string]$Message) {
        $matches = Select-String -InputObject $Message -Pattern '\[ERROR\] (?<date>\d{4}\W\d{1,2}\W\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<message>.*)'

        return $matches.Matches.Groups.Where( { $_.Name -eq 'message' }).Value
    }

    [string] GetSanitizedArgumentString() {
        $sanitizedArgs = $this.ProcessInfo.ArgumentList | ForEach-Object {
            if ($_ -like 'password=*') {
                'password=*****'
            }
            else {

                $_
            }
        }

        return $sanitizedArgs -join ' '
    }
}

class OpListItemsCommand : Op {

    OpListItemsCommand() : base() {
        $this.AddArgument('list')
        $this.AddArgument('items')
    }

    [void] AddCategories([string[]]$Categories) {
        $this.AddArgument('--categories')
        $this.AddArgument($Categories -join ',')
    }

    [PSCustomObject[]] Invoke() {

        $this.AddVaultFlag()

        $result = $this.InvokeOp()

        if ($result) {
            return $result | ConvertFrom-Json
        } else {
            return $null
        }

    }
}

class OpGetItemCommand : Op {

    OpGetItemCommand() : base() {
        $this.AddArgument('get')
        $this.AddArgument('item')
    }

    OpGetItemCommand([string]$Name) : base() {
        $this.AddArgument('get')
        $this.AddArgument('item')
        $this.AddArgument($Name)
    }

    [void] AddFields([string[]]$Fields) {
        $this.AddArgument('--fields')
        $this.AddArgument($Fields -join ',')
    }
}