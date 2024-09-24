# SecretManagement extension for 1Password

This powershell module is a
[SecretManagement](https://github.com/PowerShell/SecretManagement)
extension for
[1Password](https://1password.com/).
It leverages the [`1password-cli`](https://support.1password.com/command-line/)
to interact with 1Password.

The SecretManagment.1Password module requires that the 1Password CLI application is installed and configured to access 1Password.

## Prerequisites

* [PowerShell](https://github.com/PowerShell/PowerShell)
* The [`1password-cli`](https://support.1password.com/command-line/) and accessible from Path
* Enable access to 1Password through one of the following methods:
  * Activate the [1Password app integration](https://developer.1password.com/docs/cli/app-integration/)
  * [Add a new 1Password account to 1Password CLI manually](https://developer.1password.com/docs/cli/reference/management-commands/account#account-add) with your account password and Secret Key.
    ```pwsh
    op account add --address my.1password.com --email user@example.org
    ```
* The [SecretManagement PowerShell](https://github.com/PowerShell/SecretManagement) module

You can get the `SecretManagement` module from the PowerShell Gallery:

Using PowerShellGet v2:

```pwsh
Install-Module Microsoft.PowerShell.SecretManagement
```

Using PowerShellGet v3:

```pwsh
Install-PSResource Microsoft.PowerShell.SecretManagement -Prerelease
```
## Installation

This module can be installed from the PowerShell Gallery:

Using PowerShellGet v2:

```pwsh
Install-Module SecretManagement.1Password
```

Using PowerShellGet v3:

```pwsh
Install-PSResource SecretManagement.1Password
```

## Registration

Once the SecretManagement.1Password module is installed, a SecretManagement vault must be registered as follows:

```pwsh
Register-SecretVault -Name '1Password: MyVaultName' `
        -ModuleName 'SecretManagement.1Password' `
        -VaultParameters @{AccountName='myaccount.1password.com'; OPVault = 'MyVaultName'}
```
Next are the detials provided in the registration:
* **Name**: Name of the SecretManagement vault. This will be the name to use when managing secrets from the SecretManagement powershell cmdlets.
* **ModuleName**: Name of the PowerShell extension module that will be interacting with the underlyging secrets source. In this case, as the source will be "1Password" the extension module name must be "SecretManagement.1Password".
* **VaultParameters**: Optional. Details required by the extension module to access the source secrets. See the section [Vault parameters](#Vault-parameters) for details specific for the SecretManagement.1Password extension module (used to access 1Password).

**Note**: The name given to the SecretManagement vault (provided with the `Name` parameter) doesn't need to match the name of an existing vault in 1Password. Considering that the SecretManagement module supports multiple sources, it may be useful to prefix each of its vaults with a word that allows to know the source. For instance, in the case of 1Password vaults, the SecretManagement vaults can be named as "1Password: VaultName".

It is recommended to regiser one SecretManagement vault for each 1Password vault that need to be accessed.


### Vault parameters

The module also has the following vault parameter that must be provided at registration.

```pwsh
$vaultParameters = @{
    AccountName = 'myaccount.1password.com'
    OPVault = 'MyVaultName'
}
```

#### AccountName

Optional. Specifies what 1Password account to connect to when accessing secrets. It is common to have a corporate and a personal account. This parameter allows to select one of your accounts. If this parameter is not provided, then the default 1Password account will be used.

The 1Password account name can be found in the URL used to access 1Password as follows:

```
https://myaccountname.1password.com/
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
Corporate accounts are typically accessed through a URL like `https://myaccountname.1password.com/`. In this example, the account name is `myaccountname.1password.com`.

Personal accounts typically have `my.1password.com` as account name.

#### OPVault

Name or Id of the 1Password vault associated with the SecretManagement vault.

If this parameter is missing then the 1Password CLI will search on all vaults in the target account. 

WARNING: Not linking the SecretManagement vault with a unique 1Password vault may cause issues because there may be more than one secret, stored in different 1Password vaults, sharing the same name. In that case, retrieval and updates uperations will have issues.

## Dependencies

This module extension has been developed and tested with the following dependencies' version:
* **PowerShell**: 5.1
* **Microsoft.PowerShell.SecretManagement**: 1.1.2
* **1Password CLI**: 2.30.0

## Known issues

### Development issue: Reimporting the extension module (or the parent SecretManagement module) doesn't refresh changes made in the extension module after the later has been previusly loaded

**Note**: This issue affects only to developers of this module extension. Regular users are not affected.

The SecretManagement.1Password module is an extension for the main module Microsoft.PowerShell.SecretManagement.

The need to nest extension modules comes due to the fact that all extension modules for Microsoft.PowerShell.SecretManagement, contain the same public function names which would be overwritten if more than one extension module (vault type) were loaded on the same session.

While developing there is the need to make changes to the functions of the extension module and then run them to see the effect. This can be done by loading the extension module (*.psm1) as a main module and then calling directly its functions. However, this approach presents limitations:

- It doesn't allow to see the parameters being passed by the main module (Microsoft.PowerShell.SecretManagement).
- It doesn't allow to see the transformations made by the parent module before the output is being finally returned to the calling code.

To see all effects of running the extension module as a nested extension of its parent module (Microsoft.PowerShell.SecretManagement) it is needed to import the parent module and then call one of the cmdlets associated with a vault registered with Microsoft.PowerShell.SecretManagement. Let's see an example

```pwsh
# Import the main module.
Import-Module Microsoft.PowerShell.SecretManagement
# Make sure the target vault is registered with its associated extension module.
Register-SecretVault -Name "MyVaultName" `
        -ModuleName 'PathToModule\SecretManagement.1Password\SecretManagement.1Password.psd1' `
        -VaultParameters @{OPVault = 'Employee'} `
        -AllowClobber
# Call an extension cmdlet through the main module.
Get-Secret -Vault "MyVaultName" -Name "MySecretName"
```
Note that the extension module is referenced with the path to the main *.psd1 file of the extension module. This path is specific for each development environment.

The above code works well if the extension module is not changed. However, if changes are made, then re-importing the main module will not refresh the extension module in the PowerShell cache with the new changes. Even the following code, that uses the -Force parameter and explicitly unload both, the main and the extension modules, will not solve the issue:

```pwsh
Get-Module SecretManagement.1Password | Remove-Module -Force;
Get-Module Microsoft.PowerShell.SecretManagement | Remove-Module -Force;
Import-Module Microsoft.PowerShell.SecretManagement -Force;
Import-Module 'PathToModule\SecretManagement.1Password\SecretManagement.1Password.psd1' -Force;
Get-SecretVault "MyVaultName" | Unregister-SecretVault
Register-SecretVault -Name "MyVaultName" `
        -ModuleName 'SecretManagement.1Password' `
        -VaultParameters @{OPVault = 'Employee'} `
        -AllowClobber
```
This is a [known issue](https://github.com/PowerShell/PowerShell/issues/2505#issuecomment-263105859) discussed internally by the PowerShell team who reached to the conclusion that [it is by "design"](https://github.com/PowerShell/PowerShell/issues/2505#issuecomment-902325128).

Not being able to reload nested modules during development time also affects Pester tests which require the console session to be re-started every time a change is made in the functions of the extension (nested) module. The easiest way to restart the console, in VSCode, to avoid restarting the development environment, is as follows:
1. Click on the commands box, on the top of the main window
1. Select "Show and Run Commands >"
1. Run "PowerShell: Restart Session"

#### References

- [Reloading module does not reload submodules](https://github.com/PowerShell/PowerShell/issues/2505#issuecomment-263105859)
- [Conclusion from the PowerShell team about the issue](https://github.com/PowerShell/PowerShell/issues/2505#issuecomment-902325128)