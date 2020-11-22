Describe 'Handling Op output' {
    BeforeAll {
        . C:\source\github\SecretManagement.1Password\SecretManagement.1Password.Extension\Class-OP.ps1
    }
    Context 'Not signed in' {
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

        It 'Should return login error on List' {
            $results = $op.List([OpNouns]::items)

            $results.Messsage | Should -Be 'You are not currently signed in. Please run `op signin --help` for instructions'
            $results.Success | Should -BeFalse
        }

        It 'Add categories flag' {
            # Mock Invoke()
            $op | Add-Member -MemberType ScriptMethod -Name Invoke -Value {$this} -Force

            $results = $op.List([OpNouns]::items, @([OpItemsCategories]::Login, [OpItemsCategories]::Password))

            $results | Should -Contain 'list', 'items', '--categories', 'Login,Password'
        }
    }
}

