[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $Test,

    [Parameter()]
    [switch]
    $Package,

    [Parameter()]
    [switch]
    $Publish
)

Push-Location $PSScriptRoot

if ($Test) {
    Invoke-Pester tests
}

if ($Package) {
    $outDir = Join-Path 'release' 'SecretManagement.1Password'
    Remove-Item release -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

    @(
        'SecretManagement.1Password.Extension'
        'SecretManagement.1Password.psd1'
        'LICENSE.txt'
        'README.md'
    ) | ForEach-Object {
        Copy-Item -Path $_ -Destination (Join-Path $outDir $_) -Force -Recurse
    }
}

if ($Publish) {
    Write-Host -ForegroundColor Green "Publishing module... here are the details:"
    $moduleData = Import-Module -Force ./release/SecretManagement.1Password -PassThru
    Write-Host "Version: $($moduleData.Version)"
    Write-Host "Prerelease: $($moduleData.PrivateData.PSData.Prerelease)"
    Write-Host -ForegroundColor Green "Here we go..."

    Publish-Module -Path ./release/SecretManagement.1Password -NuGetApiKey $env:PSGALLERYAPIKEY
}

Pop-Location