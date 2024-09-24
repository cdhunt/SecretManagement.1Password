# This assumes 1Password is already registered and unlocked

BeforeAll {
	$testDetails = @{
		Vault        = '1Password: Employee'
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

Describe 'It removes items' {
	BeforeEach {
		# Create the login, if it doesn't already exist.
		$item = & op item get "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -eq $item) {
			& op item create --category=Login --title="$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" "username=$($testDetails.UserName)" "password=$($testDetails.Password)"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdLogin = $true
		} else {
			Write-Warning "An item called $($testDetails.LoginName) already exists. Remove-Item test will be skipped."
			$createdLogin = $false
		}
	}

	It 'It removes an item with vault specified' {
		# Skip the test if we did not create the login item
		# Use -ForEach to get the same $testDetails.LoginName value as in BeforeDiscovery
		Remove-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)"
		# Confirm the item no longer exists
		& op item get "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null | Should -Not -Contain "isn't an item in the ""$($testDetails.VaultParameters.OPVault)"" vault"
	}

	AfterEach {
		if ($createdLogin) {
			$item = & op item get "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
			if ($null -ne $item) {
				& op item delete "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)"
			}
	

		}
	}
}
