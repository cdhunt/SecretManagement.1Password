# This assumes 1Password is already registered and unlocked
# TODO: Vault is manually specified for all tests to avoid https://github.com/cdhunt/SecretManagement.1Password/issues/16

BeforeAll {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
	$testDetails = @{
		Vault     = 'Personal'
		LoginName = 'TestLogin' + (Get-Random -Maximum 99999)
		UserName  = 'TestUserName'
		Password  = 'TestPassword'
	}

	Get-Module SecretManagement.1Password | Remove-Module -Force
	Get-Module Microsoft.PowerShell.SecretManagement | Remove-Module -Force
	Register-SecretVault -ModuleName (Join-Path $PSScriptRoot '..\SecretManagement.1Password.psd1') -Name $testDetails.Values -AllowClobber
}

Describe 'It updates items that already exist' {
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

	It 'Sets the password from an int value type with vault specified' {
		$testvalue = 123456
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $testvalue
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}

	It 'Sets the password from a char value type with vault specified' {
		$testvalue = [char]'a'
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $testvalue
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}

	It 'Sets the password from a string with vault specified' {
		$testvalue = 'String Password!'
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $testvalue
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}
	
	It 'Sets the password from a SecureString with vault specified' {
		$testvalue = 'SecureString Password!'
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret ($testvalue | ConvertTo-SecureString -AsPlainText -Force)
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}
	
	It 'Sets the password from a PSCredential with vault specified' {
		$testvalue = 'PSCredential Password!'
		$testusername = 'PSCredential Username'
		$cred = [pscredential]::new($testusername, ($testvalue | ConvertTo-SecureString -AsPlainText -Force))
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $cred
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
		& op get item $testDetails.LoginName --fields username --vault $testDetails.Vault | Should -Be $testusername
	}
	
	AfterAll {
		if ($createdLogin) {
			& op delete item $testDetails.LoginName
		}
	}
}

Describe 'It creates items' {
	BeforeEach {
		# TODO: currently also creates if >1 exists
		$item = & op get item $testDetails.LoginName --fields title --vault $testDetails.Vault 2>$null
		if ($null -eq $item) {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdLogin = $true
		} else {
			Write-Warning "An item called $($testDetails.LoginName) already exists"
		}
	}

	It 'Sets the password from an int value type with vault specified' -Skip {
		# TODO: does not work, appears to be an issue in op: json: cannot unmarshal number into Go struct field _passwordItemDetails.password of type string
		$testvalue = 123456
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $testvalue
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}

	It 'Sets the password from a char value type with vault specified' {
		$testvalue = [char]'a'
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $testvalue
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}

	It 'Sets the password from a string with vault specified' {
		$testvalue = 'String Password!'
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $testvalue
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}
	
	It 'Sets the password from a SecureString with vault specified' {
		$testvalue = 'SecureString Password!'
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret ($testvalue | ConvertTo-SecureString -AsPlainText -Force)
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}
	
	It 'Sets the username and password from a PSCredential with vault specified' {
		# TODO: Updating an existing item using a PSCredential does not currently work
		$testvalue = 'PSCredential Password!'
		$testusername = 'PSCredential Username'
		$cred = [pscredential]::new($testusername, ($testvalue | ConvertTo-SecureString -AsPlainText -Force))
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $cred
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
		& op get item $testDetails.LoginName --fields username --vault $testDetails.Vault | Should -Be $testusername
	}
	
	AfterEach {
		if ($createdLogin) {
			& op delete item $testDetails.LoginName
		}
	}
}
