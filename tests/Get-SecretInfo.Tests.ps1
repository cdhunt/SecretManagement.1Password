# This assumes 1Password is already registered and unlocked
# TODO: Vault is manually specified for all tests to avoid https://github.com/cdhunt/SecretManagement.1Password/issues/16

BeforeAll {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
	$testDetails = @{
		Vault        = 'Personal'
		LoginName    = 'TestLogin' + (Get-Random -Maximum 99999)
		PasswordName = 'TestPassword' + (Get-Random -Maximum 99999)
		UserName     = 'TestUserName'
		Password     = 'TestPassword'
	}

	Get-Module SecretManagement.1Password | Remove-Module -Force
	Get-Module Microsoft.PowerShell.SecretManagement | Remove-Module -Force
	Register-SecretVault -ModuleName (Join-Path $PSScriptRoot '..\SecretManagement.1Password.psd1') -Name $testDetails.Values -AllowClobber
}

Describe 'It gets login info with vault specified' {
	BeforeAll {
		# Create the login, if it doesn't already exist.
		# TODO: currently also creates if >1 exists
		$item = & op get item $testDetails.LoginName --fields title --vault $testDetails.Vault 2>$null
		if ($null -eq $item) {
			& op create item login --title $testDetails.LoginName "username=$($testDetails.UserName)" "password=$($testDetails.Password)"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdLogin = $true
		} else {
			Write-Warning "An item called $($testDetails.LoginName) already exists"
		}
	}

	It 'returns logins as PSCredentials' -Skip {
		# TODO: https://github.com/cdhunt/SecretManagement.1Password/issues/8
		$info = Get-SecretInfo -Vault $testDetails.Vault -Name $testDetails.LoginName
		$info | Should -BeOfType [Microsoft.PowerShell.SecretManagement.SecretInformation]
		$info.Type | Should -Be PSCredential
	}

	AfterAll {
		if ($createdLogin) {& op delete item $testDetails.LoginName}
	}
}

Describe 'It gets password info with vault specified' {
	BeforeAll {
		# Create the password, if it doesn't already exist.
		# TODO: currently also creates if >1 exists
		$item = & op get item $testDetails.PasswordName --fields title --vault $testDetails.Vault 2>$null
		if ($null -eq $item) {
			& op create item password --title $testDetails.PasswordName "password=$($testDetails.Password)"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdPassword = $true
		} else {
			Write-Warning "An item called $($testDetails.PasswordName) already exists"
		}
	}

	It 'returns passwords as SecureStrings' -Skip {
		# TODO: https://github.com/cdhunt/SecretManagement.1Password/issues/8
		$info = Get-SecretInfo -Vault $testDetails.Vault -Name $testDetails.PasswordName
		$info | Should -BeOfType [Microsoft.PowerShell.SecretManagement.SecretInformation]
		$info.Type | Should -Be SecureString
	}

	AfterAll {
		if ($createdPassword) {& op delete item $testDetails.PasswordName}
	}
}
