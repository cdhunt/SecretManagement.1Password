# This assumes 1Password is already registered and unlocked
# TODO: totp

BeforeAll {
	$testDetails = @{
		Vault        = 'Personal'
		LoginName    = 'TestLogin' + (Get-Random -Maximum 99999)
		PasswordName = 'TestPassword' + (Get-Random -Maximum 99999)
		UserName     = 'TestUserName'
		Password     = 'TestPassword'
	}
}

Describe 'It gets logins with vault specified' {
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

	It 'Gets a login' {
		Get-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName | Should -BeOfType PSCredential
	}

	It 'Gets the login username with vault specified' {
		$cred = Get-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName
		$cred.UserName | Should -Be $testDetails.UserName
	}
	
	It 'Gets the login password with vault specified' {
		$cred = Get-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName
		$cred.Password | ConvertFrom-SecureString -AsPlainText | Should -Be $testDetails.Password
	}

	AfterAll {
		if ($createdLogin) {& op delete item $testDetails.LoginName}
	}
}

Describe 'It gets passwords with vault specified' {
	BeforeAll {
		# Create the password, if it doesn't already exist.
		# TODO: currently also creates if >1 exists
		$item = & op get item $testDetails.PasswordName --fields title --vault $testDetails.Vault 2>$null
		if ($null -eq $item) {
			& op create item password --title $testDetails.PasswordName "password=$($testDetails.Password)"
			$createdPassword = $true
		} else {
			Write-Warning "An item called $($testDetails.PasswordName) already exists"
		}
	}

	It 'Gets a password' {
		Get-Secret -Vault $testDetails.Vault -Name $testDetails.PasswordName | Should -BeOfType SecureString
	}

	It 'Gets the password with vault specified' {
		Get-Secret -Vault $testDetails.Vault -Name $testDetails.PasswordName -AsPlainText | 
		Should -Be $testDetails.Password
	}

	AfterAll {
		if ($createdPassword) {& op delete item $testDetails.PasswordName}
	}
}

Describe 'It gets one-time passwords with vault specified' {
	BeforeAll {
		# Relies on an item called TOTPTest with TOTP set up being present
		# TODO: How to create TOTP using op?
		$TOTPName = 'TOTPTest'
	}

	It 'Gets a TOTP' {
		Get-Secret -Vault $testDetails.Vault -Name $TOTPName |
		Get-Member -MemberType ScriptMethod |
		Select-Object -ExpandProperty Name |
		Should -Contain 'totp'
	}

	It 'Gets the TOTP with vault specified' {
		$secret = Get-Secret -Vault $testDetails.Vault -Name $TOTPName
		# Timing issues, test will be flaky
		$secret.totp() | Should -Be (& op get totp $TOTPName --vault Personal 2>$nul)
	}
}
