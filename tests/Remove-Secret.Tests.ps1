# This assumes 1Password is already registered and unlocked
# TODO: Vault is manually specified for all tests to avoid https://github.com/cdhunt/SecretManagement.1Password/issues/16

BeforeDiscovery {
	$testDetails = @{
		Vault     = 'Personal'
		LoginName = 'TestLogin' + (Get-Random -Maximum 99999)
		UserName  = 'TestUserName'
		Password  = 'TestPassword'
	}

	Get-Module SecretManagement.1Password | Remove-Module -Force
	Get-Module Microsoft.PowerShell.SecretManagement | Remove-Module -Force
	Register-SecretVault -ModuleName (Join-Path $PSScriptRoot '..\SecretManagement.1Password.psd1') -Name $testDetails.Values -AllowClobber

	# Create the login, if it doesn't already exist.
	# TODO: currently also creates if >1 exists
	$item = & op get item $testDetails.LoginName --fields title --vault $testDetails.Vault 2>$null
	if ($null -eq $item) {
		& op create item login --title $testDetails.LoginName "username=$($testDetails.UserName)" "password=$($testDetails.Password)"
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
		$createdLogin = $true
	} else {
		Write-Warning "An item called $($testDetails.LoginName) already exists. Remove-Item test will be skipped."
		$createdLogin = $false
	}
}

Describe 'It removes items' {
	It 'It removes an item with vault specified' -Skip:($createdLogin -ne $true) -ForEach @($testDetails) {
		# Skip the test if we did not create the login item
		# Use -ForEach to get the same $LoginName value as in BeforeDiscovery
		Remove-Secret -Vault $Vault -Name $LoginName
		# Confirm the item no longer exists
		& op get item $LoginName --fields title --vault $Vault 2>$null | Should -BeNullOrEmpty
	}
}
