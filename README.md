# SecretManagement extension for 1Password

This is a
[SecretManagement](https://github.com/PowerShell/SecretManagement)
extension for
[1Password](https://1password.com/).
It leverages the [`1password-cli`](https://support.1password.com/command-line/)
to interact with 1Password.

## Prerequisites

* [PowerShell](https://github.com/PowerShell/PowerShell)
* The [`1password-cli`](https://support.1password.com/command-line/)
* The [SecretManagement](https://github.com/PowerShell/SecretManagement) PowerShell module

You can get the `SecretManagement` module from the PowerShell Gallery:

Using PowerShellGet v2:

```pwsh
Install-Module Microsoft.PowerShell.SecretManagement -AllowPrerelease
```

Using PowerShellGet v3:

```pwsh
Install-PSResource Microsoft.PowerShell.SecretManagement -Prerelease
```
## Installation

You an install this module from the PowerShell Gallery:

Using PowerShellGet v2:

```pwsh
Install-Module SecretManagement.1Password
```

Using PowerShellGet v3:

```pwsh
Install-PSResource SecretManagement.1Password
```

## Registration

Once you have it installed,
you need to register the module as an extension:

```pwsh
Register-SecretVault -ModuleName SecretManagement.1Password -VaultParameters @{AccountName = 'myaccountname'; EmailAddress = 'user@youremail.com'; SecretKey = 'secretkey-for-your-account'}
```

### Vault parameters

The module also have the following vault parameter, that must be provided at registration.

#### AccountName

Your 1Password account name.

```
https://myaccountname.1password.com/
        ^^^^^^^^^^^^^
```

#### EmailAddress

The email address you use to log into 1Password.

#### SecretKey

The SecretKey for your 1Password vault.
[Find your Secret Key or Setup Code](https://support.1password.com/secret-key/)