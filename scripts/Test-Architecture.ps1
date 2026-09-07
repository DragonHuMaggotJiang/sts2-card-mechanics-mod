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

if ($failed) {
    exit 1
}

Write-Host "Architecture and JSON validation passed ($($jsonFiles.Count) JSON files)."

