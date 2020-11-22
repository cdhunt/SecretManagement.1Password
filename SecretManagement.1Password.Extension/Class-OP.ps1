enum OpNouns {
    vaults
    items
}

enum OpItemsCategories {
    Login = 1
    Password = 5
}

class Op {
    hidden [string]$SanitizedOutput
    hidden [string]$Bin
    hidden [Diagnostics.ProcessStartInfo]$ProcessInfo

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

    [void] AddArgument ([string]$Argument) {
        $this.ProcessInfo.ArgumentList.Add($Argument)
    }

    [Op] List ([OpNouns]$Noun)
    {
        $this.AddArgument('list')
        $this.AddArgument($Noun.ToString())

        return $this.Invoke()
    }

    [Op] List ([OpNouns]$Noun, [OpItemsCategories[]]$Categories)
    {
        $this.AddArgument('list')
        $this.AddArgument($Noun.ToString())
        $this.AddArgument('--categories')
        $this.AddArgument($Categories.ForEach({$_.ToString()}) -join(','))

        return $this.Invoke()
    }

    [object] Invoke() {

        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $this.ProcessInfo
        $process.Start() | Out-Null
        $process.WaitForExit()

        $StdOut = $process.StandardOutput.ReadToEnd()
        $StdErr = $process.StandardError.ReadToEnd()

        if (-not [string]::IsNullOrEmpty($StdErr) ) {
            $this.Success = $false
            $this.Message = [Op]::ParseError($StdErr)
        }

        return $this
    }

    static [string] ParseError([string]$Message) {
        $matches = Select-String -InputObject $Message -Pattern '\[ERROR\] (?<date>\d{4}\W\d{1,2}\W\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<message>.*)'

        return $matches.Matches.Groups.Where({$_.Name -eq 'message'}).Value
    }
}
