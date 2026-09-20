[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failed = $false

function Add-Failure([string]$Message) {
    $script:failed = $true
    Write-Error $Message -ErrorAction Continue
}

$jsonFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.json' |
    Where-Object { $_.FullName -notmatch '[\\/](bin|obj|\.godot)[\\/]' }

foreach ($file in $jsonFiles) {
    try {
        Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json | Out-Null
    }
    catch {
        Add-Failure "Invalid JSON: $($file.FullName): $($_.Exception.Message)"
    }
}

$restrictedRoots = @(
    (Join-Path $root 'src\Content'),
    (Join-Path $root 'src\Mechanics'),
    (Join-Path $root 'src\UI')
)

foreach ($restrictedRoot in $restrictedRoots) {
    $matches = Get-ChildItem -LiteralPath $restrictedRoot -Recurse -File -Filter '*.cs' |
        Select-String -Pattern 'using HarmonyLib|HarmonyPatch|\.Patch\('
    foreach ($match in $matches) {
        Add-Failure "Harmony usage is restricted to Bootstrap/Integration: $($match.Path):$($match.LineNumber)"
    }
}

$manifestPath = Join-Path $root 'Sts2CardMechanicsMod.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.id -ne 'Sts2CardMechanicsMod') {
    Add-Failure 'Manifest id must stay synchronized with ModConstants.Id and the assembly name.'
}

$sts1PoolCards = @(
    'src\Content\Cards\Ironclad\LimitBreak.cs',
    'src\Content\Cards\Ironclad\SpotWeakness.cs'
)
foreach ($relativePath in $sts1PoolCards) {
    $path = Join-Path $root $relativePath
    $source = Get-Content -Raw -LiteralPath $path
    if ($source -notmatch '\[Pool\(typeof\(Sts1IroncladCardPool\)\)\]') {
        Add-Failure "$relativePath must stay in the isolated STS1 Ironclad reward pool."
    }
    if ($source -match '\[Pool\(typeof\(IroncladCardPool\)\)\]') {
        Add-Failure "$relativePath must not leak into the STS2 Ironclad reward pool."
    }
}

$deathReapingPath = Join-Path $root 'src\Content\Cards\Ironclad\DeathReaping.cs'
$deathReapingSource = Get-Content -Raw -LiteralPath $deathReapingPath
if ($deathReapingSource -notmatch 'CardRarity\.Ancient') {
    Add-Failure 'Death Reaping must remain an Ancient card.'
}

if ($failed) {
    exit 1
}

Write-Host "Architecture and JSON validation passed ($($jsonFiles.Count) JSON files)."
