Describe 'Handling Op output' {
    BeforeAll {
        . C:\source\github\SecretManagement.1Password\SecretManagement.1Password.Extension\classes\OP.ps1
    }
    Context 'Not signed in' -Tag 'Integration' {
        BeforeEach {
            $op = [Op]::new()
        }
        It 'Should parse error messages' {
            $message = '[ERROR] 2020/11/22 11:20:32 You are not currently signed in. Please run `op signin --help` for instructions'

            $results = [Op]::ParseError($message)

            $results | Should -Be 'You are not currently signed in. Please run `op signin --help` for instructions'
        }

        It 'Shoud not error on "-h"' {
            $op.AddArgument('-h')
            $results = $op.Invoke()

            $results.Message | Should -Be 'The command completed without error.'
            $results.Success | Should -BeTrue
        }

        It 'Shoud error on bad argument' {
            $op.AddArgument('-madeup')
            $results = $op.Invoke()

            $results.Message | Should -Be 'unknown shorthand flag: ''m'' in -madeup'
            $results.Success | Should -BeFalse
        }
    }

    Context 'Base' -Tag 'Unit' {
        BeforeEach {
            $op = [Op]::new()
        }

        It 'Sanitize arguments' {
            $op.AddAssignment('password', 'abc123')

            $results = $op.GetSanitizedArgumentString()

            $results | Should -Be 'password=*****'
        }
    }

    Context 'List' -Tag 'Unit' {
        BeforeEach {
            $opListItemsCommand = [OpListItemsCommand]::new()
        }

        It 'Simple' {
            $results = $opListItemsCommand.ProcessInfo.ArgumentList

            $results[0] | Should -Be 'list'
            $results[1] | Should -Be 'items'
        }

        It 'Add categories' {
            $opListItemsCommand.AddCategories(@('login','password'))
            $results = $opListItemsCommand.ProcessInfo.ArgumentList

            $results[0] | Should -Be 'list'
            $results[1] | Should -Be 'items'
            $results[2] | Should -Be '--categories'
            $results[3] | Should -Be 'Login,Password'
        }

        It 'With Vault' {
            $opListItemsCommand.SetVault('test')
            $opListItemsCommand.AddVaultFlag()
            $results = $opListItemsCommand.ProcessInfo.ArgumentList

            $results[0] | Should -Be 'list'
            $results[1] | Should -Be 'items'
            $results[2] | Should -Be '--vault'
            $results[3] | Should -Be 'test'
        }
    }
}

