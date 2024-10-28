# This assumes 1Password is already registered and unlocked

BeforeAll {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
	$testDetails = @{
		Vault        = '1Password: Employee'
		LoginName    = 'TestLogin' + (Get-Random -Maximum 99999)
		PasswordName = 'TestPassword' + (Get-Random -Maximum 99999)
		UserName     = 'TestUserName'
		Password     = 'TestPassword'
		VaultParameters = @{
			OPVault = 'Employee'
		}
	}

	Get-Module SecretManagement.1Password | Remove-Module -Force
	Get-Module Microsoft.PowerShell.SecretManagement | Remove-Module -Force
	Register-SecretVault -ModuleName (Join-Path $PSScriptRoot '..\SecretManagement.1Password.psd1') -Name $testDetails.Vault -VaultParameters $testDetails.VaultParameters -AllowClobber
}

Describe 'It gets items' {
	BeforeAll {
		# Create the login, if it doesn't already exist.
		$item = & op item get "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -eq $item) {
			& op item create --category=Login --title="$($testDetails.LoginName)" "username=$($testDetails.UserName)" "password=$($testDetails.Password)"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdLogin = $true
		} else {
			Write-Warning "An item called $($testDetails.LoginName) already exists"
			$createdLogin = $false
		}
	}

	It 'returns all items' {
		$info = Get-SecretInfo -Vault "$($testDetails.Vault)"
		$info.Count | Should -BeGreaterOrEqual 1
	}

	it 'filters items' {
		$info = Get-SecretInfo -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)"
		$info | Should -HaveCount 1
	}

	AfterAll {
		if ($createdLogin) {& op item delete "$($testDetails.LoginName)"}
	}
}

Describe 'It gets login info with vault specified' {
	BeforeAll {
		# Create the login, if it doesn't already exist.
		$item = & op item get "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -eq $item) {
			& op item create --category=Login --title="$($testDetails.LoginName)" "username=$($testDetails.UserName)" "password=$($testDetails.Password)"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdLogin = $true
		} else {
			Write-Warning "An item called $($testDetails.LoginName) already exists"
			$createdLogin = $false
		}
	}

	It 'returns logins as PSCredentials' {
		$info = Get-SecretInfo -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)"
		$info | Should -BeOfType [Microsoft.PowerShell.SecretManagement.SecretInformation]
		$info.Type | Should -Be PSCredential
	}

	AfterAll {
		if ($createdLogin) {& op item delete "$($testDetails.LoginName)"}
	}
}

Describe 'It gets password info with vault specified' {
	BeforeAll {
		# Create the password, if it doesn't already exist.
		$item = & op item get "$($testDetails.PasswordName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -eq $item) {
			& op item create --category=Password --title="$($testDetails.PasswordName)" "password=$($testDetails.Password)"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdPassword = $true
		} else {
			Write-Warning "An item called $($testDetails.PasswordName) already exists"
			$createdPassword = $false
		}
	}

	It 'returns passwords as SecureStrings' {
		$info = Get-SecretInfo -Vault "$($testDetails.Vault)" -Name $testDetails.PasswordName
		$info | Should -BeOfType [Microsoft.PowerShell.SecretManagement.SecretInformation]
		$info.Type | Should -Be SecureString
	}

	AfterAll {
		if ($createdPassword) {& op item delete "$($testDetails.PasswordName)"}
	}
}
