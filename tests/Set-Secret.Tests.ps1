# This assumes 1Password is already registered and unlocked

BeforeAll {
	$testDetails = @{
		Vault     = 'Personal'
		LoginName = 'TestLogin' + (Get-Random -Maximum 99999)
		UserName  = 'TestUserName'
		Password  = 'TestPassword'
	}
}

Describe 'It updates items that already exist' {
	BeforeAll {
		# Create the login, if it doesn't already exist.
		# TODO: currently also creates if >1 exists
		$item = & op get item $testDetails.LoginName --fields title --vault $testDetails.Vault 2>$null
		if ($null -eq $item) {
			& op create item login --title $testDetails.LoginName "username=$($testDetails.UserName)" "password=$($testDetails.Password)"
			$createdLogin = $true
		} else {
			Write-Warning "An item called $($testDetails.LoginName) already exists"
		}
	}

	It 'Sets the password from a value type with vault specified' {
		$testvalue = 123456
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $testvalue
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}

	It 'Sets the password from a string with vault specified' -Skip {
		# TODO: Using a string with Set-Secret does not currently work https://github.com/cdhunt/SecretManagement.1Password/issues/17
		$testvalue = 'String Password!'
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $testvalue
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}
	
	It 'Sets the password from a SecureString with vault specified' {
		$testvalue = 'SecureString Password!'
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret ($testvalue | ConvertTo-SecureString -AsPlainText -Force)
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}
	
	It 'Sets the password from a PSCredential with vault specified' -Skip {
		# TODO: Updating an existing item using a PSCredential does not currently work
		$testvalue = 'PSCredential Password!'
		$cred = [pscredential]::new('PSCredential Username', ($testvalue | ConvertTo-SecureString -AsPlainText -Force))
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $cred
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
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
			$createdLogin = $true
		} else {
			Write-Warning "An item called $($testDetails.LoginName) already exists"
		}
	}

	It 'Sets the password from a value type with vault specified' -Skip {
		# TODO: does not work, appears to be an issue in op: json: cannot unmarshal number into Go struct field _passwordItemDetails.password of type string
		$testvalue = 123456
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $testvalue
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}

	It 'Sets the password from a string with vault specified' -Skip {
		# TODO: Using a string with Set-Secret does not currently work https://github.com/cdhunt/SecretManagement.1Password/issues/17
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
		# TODO: Updating an existing item using a PSCredential does not currently work
		$testvalue = 'PSCredential Password!'
		$cred = [pscredential]::new('PSCredential Username', ($testvalue | ConvertTo-SecureString -AsPlainText -Force))
		Set-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName -Secret $cred
		& op get item $testDetails.LoginName --fields password --vault $testDetails.Vault | Should -Be $testvalue
	}
	
	AfterEach {
		if ($createdLogin) {
			& op delete item $testDetails.LoginName
		}
	}
}
