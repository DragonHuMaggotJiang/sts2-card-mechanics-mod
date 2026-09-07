[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

& (Join-Path $PSScriptRoot 'Test-Architecture.ps1')
if (-not $?) {
    exit 1
}

$dotnetCandidates = @(
    $(if ($env:STS2_DOTNET_ROOT) { Join-Path $env:STS2_DOTNET_ROOT 'dotnet.exe' }),
    (Join-Path (Split-Path -Parent $root) '.dotnet\dotnet.exe'),
    'dotnet'
) | Where-Object { $_ }

$dotnet = $dotnetCandidates | Where-Object {
    $_ -eq 'dotnet' -or (Test-Path -LiteralPath $_)
} | Select-Object -First 1

if (-not $dotnet) {
    throw 'No .NET SDK launcher found. Install .NET 9 or set STS2_DOTNET_ROOT.'
}

& $dotnet build (Join-Path $root 'Sts2CardMechanicsMod.csproj') --configuration $Configuration
exit $LASTEXITCODE
