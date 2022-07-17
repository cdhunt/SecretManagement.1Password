# This assumes 1Password is already registered and unlocked

BeforeAll {
	$testDetails = @{
		Vault     = 'Personal'
		LoginName = 'TestLogin' + (Get-Random -Maximum 99999)
		UserName  = 'TestUserName'
		Password  = 'TestPassword'
	}
	
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

Describe 'It gets logins with vault specified' {
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
}

AfterAll {
	if ($createdLogin) {
		& op delete item $testDetails.LoginName
	}
}
