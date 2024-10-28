# This assumes 1Password is already registered and unlocked

BeforeAll {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
	$testDetails = @{
		Vault     = '1Password: Employee'
		LoginName = 'TestLogin' + (Get-Random -Maximum 99999)
		UserName  = 'TestUserName'
		Password  = 'TestPassword'
		VaultParameters = @{
			OPVault = 'Employee'
		}
	}

	Get-Module SecretManagement.1Password | Remove-Module -Force
	Get-Module Microsoft.PowerShell.SecretManagement | Remove-Module -Force
	Register-SecretVault -ModuleName (Join-Path $PSScriptRoot '..\SecretManagement.1Password.psd1') -Name $testDetails.Vault -VaultParameters $testDetails.VaultParameters -AllowClobber
}

Describe 'It updates items that already exist' {
	BeforeAll {
		# Create the login, if it doesn't already exist.
		$item = & op item get "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -eq $item) {
			& op item create --category=Login --title="$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" "username=$($testDetails.UserName)" "password=$($testDetails.Password)"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdLogin = $true
		} else {
			Write-Warning "An item called $($testDetails.LoginName) already exists"
			$createdLogin = $false
		}
	}

	It 'Sets the password from an int value type with vault specified' {
		$testvalue = 123456
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret $testvalue
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
	}

	It 'Sets the password from a char value type with vault specified' {
		$testvalue = [char]'a'
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret $testvalue
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
	}

	It 'Sets the password from a string with vault specified' {
		$testvalue = 'String Password!'
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret "$($testvalue)"
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
	}
	
	It 'Sets the password from a SecureString with vault specified' {
		$testvalue = 'SecureString Password!'
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret ($testvalue | ConvertTo-SecureString -AsPlainText -Force)
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
	}
	
	It 'Sets the password from a PSCredential with vault specified' {
		$testvalue = 'PSCredential Password!'
		$testusername = 'PSCredential Username'
		$cred = [pscredential]::new($testusername, ($testvalue | ConvertTo-SecureString -AsPlainText -Force))
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret $cred
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
		& op item get "$($testDetails.LoginName)" --fields username --vault "$($testDetails.VaultParameters.OPVault)" | Should -Be $testusername
	}
	
	AfterAll {
		if ($createdLogin) {
			& op item delete "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)"
		}
	}
}

Describe 'It creates items' {
	BeforeEach {
		$item = & op item get "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -ne $item) {
			& op item delete "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)"
			Write-Verbose "Item '$($testDetails.LoginName)' detected and deleted before the test."
		}
	}

	It 'Sets the password from an int value type with vault specified' {
		$testvalue = 123456
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret $testvalue
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
	}

	It 'Sets the password from a char value type with vault specified' {
		$testvalue = [char]'a'
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret $testvalue
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
	}

	It 'Sets the password from a string with vault specified' {
		$testvalue = 'String Password!'
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret $testvalue
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
	}
	
	It 'Sets the password from a SecureString with vault specified' {
		$testvalue = 'SecureString Password!'
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret ($testvalue | ConvertTo-SecureString -AsPlainText -Force)
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
	}
	
	It 'Sets the username and password from a PSCredential with vault specified' {
		$testvalue = 'PSCredential Password!'
		$testusername = 'PSCredential Username'
		$cred = [pscredential]::new($testusername, ($testvalue | ConvertTo-SecureString -AsPlainText -Force))
		Set-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" -Secret $cred
		& op item get "$($testDetails.LoginName)" --fields password --vault "$($testDetails.VaultParameters.OPVault)" --reveal | Should -Be $testvalue
		& op item get "$($testDetails.LoginName)" --fields username --vault "$($testDetails.VaultParameters.OPVault)" | Should -Be $testusername
	}
	
	AfterEach {
		$item = & op item get "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -ne $item) {
			& op item delete "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)"
			Write-Verbose "Item '$($testDetails.LoginName)' detected and deleted after the test."
		}
	}
}
