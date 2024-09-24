# This assumes 1Password is already registered and unlocked

BeforeAll {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
	$testDetails = @{
		Vault        = '1Password: Employee'
		LoginName    = 'TestLogin' + (Get-Random -Maximum 99999)
		PasswordName = 'TestPassword' + (Get-Random -Maximum 99999)
		TOTPName	 = 'TestTime-boundOneTimePassword' + (Get-Random -Maximum 99999)
		UserName     = 'TestUserName'
		Password     = 'TestPassword'
		VaultParameters = @{
			OPVault = 'Employee'
		}
	}

	Get-Module SecretManagement.1Password | Remove-Module -Force
	Get-Module Microsoft.PowerShell.SecretManagement | Remove-Module -Force
	Register-SecretVault -ModuleName (Join-Path $PSScriptRoot '..\SecretManagement.1Password.psd1') -Name $testDetails.Vault -VaultParameters $testDetails.VaultParameters -AllowClobber
}

Describe 'It gets logins with vault specified' {
	BeforeAll {
		# Create the login, if it doesn't already exist.
		$item = & op item get "$($testDetails.LoginName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -eq $item) {
			& op item create --category=Login --title="$($testDetails.LoginName)" "username=$($testDetails.UserName)" "password=$($testDetails.Password)"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdLogin = $true
		} else {
			Write-Warning "An item called $($testDetails.LoginName) already exists"
		}
	}

	It 'Gets a login' {
		Get-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)" | Should -BeOfType PSCredential
	}

	It 'Gets the login username with vault specified' {
		$cred = Get-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)"
		$cred.UserName | Should -Be $testDetails.UserName
	}
	
	It 'Gets the login password with vault specified' {
		$cred = Get-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.LoginName)"
		$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto( `
			[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Password))) | Should -Be $testDetails.Password
	}

	AfterAll {
		if ($createdLogin) {& op item delete "$($testDetails.LoginName)"}
	}
}

Describe 'It gets passwords with vault specified' {
	BeforeAll {
		# Create the password, if it doesn't already exist.
		$item = & op item get "$($testDetails.PasswordName)"--vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -eq $item) {
			& op item create --category=Password --title="$($testDetails.PasswordName)" "password=$($testDetails.Password)"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdPassword = $true
		} else {
			Write-Warning "An item called $($testDetails.PasswordName) already exists"
		}
	}

	It 'Gets a password' {
		Get-Secret -Vault "$($testDetails.Vault)" -Name $testDetails.PasswordName | Should -BeOfType SecureString
	}

	It 'Gets the password with vault specified' {
		Get-Secret -Vault "$($testDetails.Vault)" -Name $testDetails.PasswordName -AsPlainText | 
		Should -Be $testDetails.Password
	}

	AfterAll {
		if ($createdPassword) {& op item delete "$($testDetails.PasswordName)"}
	}
}

Describe 'It gets one-time passwords with vault specified' {
	BeforeAll {
		# Relies on an item called TOTPTest with TOTP set up being present
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
		$item = & op item get "$($testDetails.TOTPName)" --vault "$($testDetails.VaultParameters.OPVault)" 2>$null
		if ($null -eq $item) {
			& op item create --category=Password --title="$($testDetails.TOTPName)" --vault "$($testDetails.VaultParameters.OPVault)" --generate-password=20,letters,digits "TotpField[otp]=otpauth://totp/<website>:<user>?secret=<secret>&issuer=<issuer>"
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
			$createdPassword = $true
			#Write-Verbose "An item called $($testDetails.TOTPName) created for the tests"
		} else {
			Write-Warning "An item called $($testDetails.TOTPName) already exists"
			$createdPassword = $false;
		}
	}

	It 'Gets a TOTP' {
		$secret=Get-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.TOTPName)"
		$members = switch ($secret) {
			{ $_ -is [System.Collections.Hashtable] } {
				$secret.Keys;
				break;
			}
			{ $_ -is [PSObject] } {
				Get-Member -InputObject $secret  -MemberType Property | Select-Object -ExpandProperty Name
				break;
			}
			{ $_ -is [PSCustomObject]} {
				Get-Member -InputObject $secret  -MemberType NoteProperty | Select-Object -ExpandProperty Name;
				break;
			}
			default {
				[String[]]@()
			}   
		}
		$members | Should -Contain 'totp'
	}

	It 'Gets the TOTP with vault specified' {
		$secret = Get-Secret -Vault "$($testDetails.Vault)" -Name "$($testDetails.TOTPName)"
		# Timing issues, test will be flaky
		$secret.totp | Should -BeGreaterThan -1
	}

	AfterAll {
		if ($createdPassword) {& op item delete "$($testDetails.TOTPName)"}
	}
}
