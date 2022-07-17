# This assumes 1Password is already registered and unlocked
# TODO: Vault is manually specified for all tests to avoid https://github.com/cdhunt/SecretManagement.1Password/issues/16

BeforeDiscovery {
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
		Write-Warning "An item called $($testDetails.LoginName) already exists. Remove-Item test will be skipped."
		$createdLogin = $false
	}
}

Describe 'It removes items' {
	It 'It removes an item with vault specified' -Skip:($createdLogin -ne $true) {
		# Skip the test if we did not create the login item
		Remove-Secret -Vault $testDetails.Vault -Name $testDetails.LoginName
		# Confirm the item no longer exists
		& op get item $testDetails.LoginName --fields title --vault $testDetails.Vault 2>$null | Should -BeNullOrEmpty
	}
}
