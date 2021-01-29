using namespace Microsoft.PowerShell.SecretManagement

$classes = Join-Path -Path $PSScriptRoot -ChildPath 'classes'
$public = Join-Path -Path $PSScriptRoot -ChildPath 'public'

'Op.ps1' | ForEach-Object {
    $path = Join-Path -Path $classes -ChildPath $_
    . $path
}

Get-ChildItem -Path $public | ForEach-Object {
    . $_.FullName
}
