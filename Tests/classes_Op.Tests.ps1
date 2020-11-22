Describe 'Handling Op output' {
    BeforeAll {
        . C:\source\github\SecretManagement.1Password\SecretManagement.1Password.Extension\classes\OP.ps1
    }
    Context 'Not signed in'  -Tag 'Integration' {
        BeforeEach {
            $op = [Op]::new()
        }

        It 'Shoud not error on "-h"' {
            $op.AddArgument('-h')
            $results = $op.Invoke()

            $results | Should -Be 'The command completed without error.'
            $op.Success | Should -BeTrue
        }

        It 'Shoud error on bad argument' {
            $op.AddArgument('-madeup')
            $results = $op.Invoke()

            $results | Should -Be 'unknown shorthand flag: ''m'' in -madeup'
            $op.Success | Should -BeFalse
        }
    }

    Context 'Base' -Tag 'Unit' {
        BeforeEach {
            $op = [Op]::new()
        }

        It 'Should parse error messages' {
            $message = '[ERROR] 2020/11/22 11:20:32 You are not currently signed in. Please run `op signin --help` for instructions'

            $results = [Op]::ParseError($message)

            $results | Should -Be 'You are not currently signed in. Please run `op signin --help` for instructions'
        }

        It 'Sanitize arguments' {
            $op.AddAssignment('password', 'abc123')

            $results = $op.GetSanitizedArgumentString()

            $results | Should -Be 'password=*****'
        }
    }

    Context 'Get List' -Tag 'Unit' {
        BeforeEach {
            $opListItemsCommand = [OpListItemsCommand]::new()
        }

        It 'Simple' {
            $results = $opListItemsCommand.ProcessInfo.ArgumentList

            $results[0] | Should -Be 'list'
            $results[1] | Should -Be 'items'
        }

        It 'Add categories' {
            $opListItemsCommand.AddCategories(@('login', 'password'))
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

    Context 'Get Item' -Tag 'Unit' {
        BeforeEach {
            $opGetItemCommand = [OpGetItemCommand]::new('test_item')
        }

        It 'Simple' {
            $results = $opGetItemCommand.ProcessInfo.ArgumentList

            $results[0] | Should -Be 'get'
            $results[1] | Should -Be 'item'
            $results[2] | Should -Be 'test_item'
        }

        It 'Add fields' {
            $opGetItemCommand.AddFields(@('username', 'password'))
            $results = $opGetItemCommand.ProcessInfo.ArgumentList

            $results[0] | Should -Be 'get'
            $results[1] | Should -Be 'item'
            $results[2] | Should -Be 'test_item'
            $results[3] | Should -Be '--fields'
            $results[4] | Should -Be 'username,password'
        }

        It 'With Vault' {
            $opGetItemCommand.SetVault('test')
            $opGetItemCommand.AddVaultFlag()
            $results = $opGetItemCommand.ProcessInfo.ArgumentList

            $results[0] | Should -Be 'get'
            $results[1] | Should -Be 'item'
            $results[2] | Should -Be 'test_item'
            $results[3] | Should -Be '--vault'
            $results[4] | Should -Be 'test'
        }

        It 'With fields and vault' {
            $opGetItemCommand.AddFields(@('username', 'password'))
            $opGetItemCommand.SetVault('test')
            $opGetItemCommand.AddVaultFlag()
            $results = $opGetItemCommand.ProcessInfo.ArgumentList

            $results[0] | Should -Be 'get'
            $results[1] | Should -Be 'item'
            $results[2] | Should -Be 'test_item'
            $results[3] | Should -Be '--fields'
            $results[4] | Should -Be 'username,password'
            $results[5] | Should -Be '--vault'
            $results[6] | Should -Be 'test'
        }
    }
}

