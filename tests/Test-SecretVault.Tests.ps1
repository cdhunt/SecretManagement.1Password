# This assumes 1Password is already registered and unlocked

BeforeDiscovery {
	$testDetails = @{
		Vault        = '1Password: TestVault' + (Get-Random -Maximum 99999)
		SecretStoreVault = 'SecretManagement.1Password.Tests'
		VaultParameters = @{
			OPVault = 'Employee'
		}
	}
	
	if ([System.String]::IsNullOrEmpty($env:OP_TEST_ACCOUNT)){
		Write-Warning ("Some tests require the name of a 1Password account which is stablished through " + `
					"the environment variable `$env:OP_TEST_ACCOUNT. If you want all tests to be completed, " + `
					"please, set such environment variable. The following command can help:" + `
					"`r`n`r`n`t`$env:OP_TEST_ACCOUNT = ""mytestaccount.1password.com""`r`n");

		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
		$testAccountNotAvailable = $true;
	}else{
		$testDetails.VaultParameters.AccountName = "$($env:OP_TEST_ACCOUNT)";
		$testAccountNotAvailable = $false;
	}

}

Describe 'Unregistered SecretManagement vault for 1Password' -ForEach @{testDetails=$testDetails;} {
	BeforeAll {
		$secretVault = Get-SecretVault -Name "$($testDetails.Vault)" -ErrorAction SilentlyContinue
		if ($null -ne $secretVault) {
			Unregister-SecretVault "$($testDetails.Vault)";
			Write-Warning "The SecretManagement vault '$($testDetails.Vault)' was unexpectedly detected before the test. It has been removed.";
		}
	}
	BeforeEach{
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
		$er = $null;
		Test-SecretVault -Name "$($testDetails.Vault)" -ErrorVariable er -ErrorAction SilentlyContinue;
	}

	It 'Write an error' {
		$er.Count | Should -BeGreaterThan 0;
	}

	It 'Meaningful error message' {
		$er.Exception.Message | Should -BeLike "* does not exist in registry*"
	}

}

Describe 'Missing all vault paremeters' -ForEach @{testDetails=$testDetails;}{
	BeforeAll {
		# Register the vault without VaultParameters
		Register-SecretVault -ModuleName 'SecretManagement.1Password.psd1' -Name "$($testDetails.Vault)" -AllowClobber
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
		$testValue = Test-SecretVault -Name "$($testDetails.Vault)" -WarningVariable wa;
	}

	It 'Writes one warnings for each missing optional parameter.' {
		$wa.Count | Should -Be 2
	}

	It 'Meaningful warning for missing optional parameters' {
		$wa.Message | Should -BeLike "* is missing in the SecretManagement vault parameters*"
		#$wa.Message.Where({$_ -like "* is missing in the SecretManagement vault parameters*"})
	}

	It 'Returns $True if it can read vaults from 1Password using default settings.' {
		try{
			$vaults=$null;
			$vaults= (& op vault list --format json) | ConvertFrom-Json;
		}catch{}
		($null -ne $vaults -and $vaults.Count -gt 0) | Should -Be $testValue

	}

	AfterAll {
		# Clearing tests
		Unregister-SecretVault -Name "$($testDetails.Vault)"
	}
}

Describe 'Only the ''OPVault'' parameter (name of the 1Password vault) is configured in the VaultParemeters' -ForEach @{testDetails=$testDetails;} {
	BeforeAll {
		# Register the vault without VaultParameters
		Register-SecretVault -ModuleName 'SecretManagement.1Password.psd1' -Name "$($testDetails.Vault)" -VaultParameters @{OPVault="$($testDetails.VaultParameters.OPVault)"} -AllowClobber
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
		$testValue = Test-SecretVault -Name "$($testDetails.Vault)" -WarningVariable wa;
	}

	It 'Writes one warnings for each missing optional parameter.' {
		$wa.Count | Should -Be 1
	}

	It 'Meaningful warning for missing optional parameters' {
		$wa.Message | Should -BeLike "* is missing in the SecretManagement vault parameters*"
		#$wa.Message.Where({$_ -like "* is missing in the SecretManagement vault parameters*"})
	}

	It 'Returns $True if it can read vaults from the specified 1Password vault.' {
		try{
			# The 1Password CLI API doesn't allow to filter by vault through flags. Thus, the filter must be applied locally.
			$vaults=$null;
			$vaults= (& op vault list --format json) | ConvertFrom-Json;
			$opVault = $testDetails.VaultParameters.OPVault;
			$vaults = $vaults | Where-Object{$_.name -eq $opVault -or $_.id -eq $opVault };
			# $testDetails.VaultParameters.OPVault
			# $testDetails.VaultParameters.AccountName
			}catch{}
		($null -ne $vaults) | Should -Be $testValue

	}

	AfterAll {
		# Clearing tests
		Unregister-SecretVault -Name "$($testDetails.Vault)" #-ErrorAction SilentlyContinue
	}
}

Describe 'Only the ''AccountName'' parameter (1Password account) is configured in the VaultParemeters' -Skip:($testAccountNotAvailable -eq $true) -ForEach @{testDetails=$testDetails;} {
	BeforeAll {
		# Register the vault without VaultParameters
		Register-SecretVault -ModuleName 'SecretManagement.1Password.psd1' -Name "$($testDetails.Vault)" -VaultParameters @{AccountName="$($testDetails.VaultParameters.AccountName)"} -AllowClobber
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
		$testValue = Test-SecretVault -Name "$($testDetails.Vault)" -WarningVariable wa;
	}

	It 'Writes one warnings for each missing optional parameter.' {
		$wa.Count | Should -Be 1
	}

	It 'Meaningful warning for missing optional parameters' {
		$wa.Message | Should -BeLike "* is missing in the SecretManagement vault parameters*"
		#$wa.Message.Where({$_ -like "* is missing in the SecretManagement vault parameters*"})
	}

	It 'Returns $True if it can read vaults from the specified 1Password vault.' {
		try{
			# The 1Password CLI API doesn't allow to filter by vault through flags. Thus, the filter must be applied locally.
			$vaults=$null;
			$vaults= (& op vault list --account "$($testDetails.VaultParameters.AccountName)" --format json) | ConvertFrom-Json;
			}catch{}
		($null -ne $vaults -and $vaults.Count -gt 0) | Should -Be $testValue

	}

	AfterAll {
		# Clearing tests
		Unregister-SecretVault -Name "$($testDetails.Vault)"
	}
}

