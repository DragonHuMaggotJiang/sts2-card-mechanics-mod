[CmdletBinding()]
param(
    [string]$JarPath = 'D:\Program Files (x86)\Steam\steamapps\common\SlayTheSpire\desktop-1.0.jar',
    [string]$OutputRoot = (Join-Path $PSScriptRoot '..\Sts2CardMechanicsMod\sts1')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path -LiteralPath $JarPath -PathType Leaf)) {
    throw "Slay the Spire 1 JAR was not found: $JarPath"
}

# These are the complete visual inputs needed by the first two acts and their reward pools. Keeping
# the original internal paths makes it possible to audit every imported file against the owned game.
$prefixes = @(
    'bottomScene/',
    'cityScene/',
    'images/events/',
    'images/monsters/theBottom/',
    'images/monsters/theCity/',
    'images/1024Portraits/red/',
    'images/1024Portraits/green/',
    'images/1024Portraits/blue/',
    'images/1024Portraits/colorless/',
    'images/1024Portraits/curse/',
    'images/relics/',
    'images/largeRelics/'
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($JarPath)
$manifestEntries = [System.Collections.Generic.List[object]]::new()
try {
    $entries = @($archive.Entries | Where-Object {
        $candidate = $_
        -not [string]::IsNullOrEmpty($candidate.Name) -and
        @($prefixes | Where-Object { $candidate.FullName.StartsWith($_, [System.StringComparison]::Ordinal) }).Count -gt 0
    } | Sort-Object FullName)

    foreach ($entry in $entries) {
        $destination = Join-Path $OutputRoot $entry.FullName
        $destinationDirectory = Split-Path -Parent $destination
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null

        $sourceStream = $entry.Open()
        try {
            $destinationStream = [System.IO.File]::Create($destination)
            try { $sourceStream.CopyTo($destinationStream) }
            finally { $destinationStream.Dispose() }
        }
        finally { $sourceStream.Dispose() }

        $hash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
        $manifestEntries.Add([ordered]@{
            source = $entry.FullName
            size = $entry.Length
            sha256 = $hash
        })
    }
}
finally { $archive.Dispose() }

$manifest = [ordered]@{
    schema_version = 1
    source = 'Slay the Spire desktop-1.0.jar'
    file_count = $manifestEntries.Count
    files = @($manifestEntries)
}
$manifestPath = Join-Path $OutputRoot 'asset-manifest.json'
($manifest | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $manifestPath -Encoding utf8

$totalBytes = ($manifestEntries | ForEach-Object { [long]$_['size'] } | Measure-Object -Sum).Sum
Write-Host "Imported $($manifestEntries.Count) STS1 assets ($([math]::Round($totalBytes / 1MB, 2)) MiB) into $OutputRoot"
