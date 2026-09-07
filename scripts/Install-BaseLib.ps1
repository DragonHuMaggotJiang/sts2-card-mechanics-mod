[CmdletBinding()]
param(
    [string]$GamePath,
    [string]$Version = '3.4.5'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if (-not $GamePath -and $env:STS2_GAME_DIR) {
    $GamePath = $env:STS2_GAME_DIR
}

if (-not $GamePath) {
    $localProps = Join-Path $root 'local.props'
    if (Test-Path -LiteralPath $localProps) {
        [xml]$props = Get-Content -Raw -LiteralPath $localProps
        $GamePath = [string]$props.Project.PropertyGroup.Sts2Path
    }
}

if (-not $GamePath -or -not (Test-Path -LiteralPath $GamePath)) {
    throw 'Slay the Spire 2 path was not found. Pass -GamePath or configure local.props.'
}

$package = Join-Path $env:USERPROFILE ".nuget\packages\alchyr.sts2.baselib\$Version"
if (-not (Test-Path -LiteralPath $package)) {
    throw "BaseLib $Version is not restored. Run scripts/Build.ps1 once, then retry."
}

$destination = Join-Path $GamePath 'mods\BaseLib'
New-Item -ItemType Directory -Path $destination -Force | Out-Null

$files = @(
    @{ Source = Join-Path $package 'lib\net9.0\BaseLib.dll'; Name = 'BaseLib.dll' },
    @{ Source = Join-Path $package 'Content\BaseLib.json'; Name = 'BaseLib.json' },
    @{ Source = Join-Path $package 'Content\BaseLib.pck'; Name = 'BaseLib.pck' }
)

foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file.Source)) {
        throw "Missing BaseLib package file: $($file.Source)"
    }
    Copy-Item -LiteralPath $file.Source -Destination (Join-Path $destination $file.Name) -Force
}

Write-Host "Installed BaseLib $Version to $destination"

