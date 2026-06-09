<#
.SYNOPSIS
    Patches GameSir Connect to neutralize the Cyclone 2 D-pad.

.DESCRIPTION
    Always starts from a pristine backup of app.asar (taken on first run), so
    re-running never double-applies the patch. Steps:
      1. Stop GameSir Connect.
      2. Back up app.asar -> app.asar.bak (first run only).
      3. Restore app.asar from the backup (pristine base).
      4. Extract the asar.
      5. Append dpad-neutralizer.js to node-hid's main module.
      6. Repack the asar, keeping native (*.node) modules unpacked.

    Requires Node.js (npx) on PATH. Uses @electron/asar via npx.

.PARAMETER Log
    Patch with logging enabled (writes raw HID reports to
    <temp>\gamesir_hid_log.txt) to confirm the real D-pad offset.
#>
param(
    [switch]$Log
)

$ErrorActionPreference = "Stop"

$root = Join-Path $env:LOCALAPPDATA "Programs\gamesir_connect\resources"
$asar = Join-Path $root "app.asar"
$bak  = Join-Path $root "app.asar.bak"
$work = Join-Path $env:TEMP "gamesir_asar_work"
$snippetSrc = Join-Path $PSScriptRoot "dpad-neutralizer.js"

if (-not (Test-Path $asar)) { throw "app.asar not found: $asar" }
if (-not (Test-Path $snippetSrc)) { throw "Neutralizer not found: $snippetSrc" }
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw "npx (Node.js) not found on PATH. Install Node.js first."
}

Write-Host "Closing GameSir Connect..."
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path -like "*gamesir_connect*" } |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (-not (Test-Path $bak)) {
    Copy-Item $asar $bak -Force
    Write-Host "Backed up app.asar -> app.asar.bak"
} else {
    Write-Host "Backup exists; rebuilding from the pristine backup."
}

# Always patch from the pristine backup so the snippet is never appended twice.
Copy-Item $bak $asar -Force

Write-Host "Extracting app.asar..."
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
npx --yes @electron/asar extract "$asar" "$work"

$nodeHid = Join-Path $work "node_modules\node-hid"
if (-not (Test-Path $nodeHid)) {
    throw "node-hid not found in app.asar. The app may use a different HID path."
}

$pkg = Get-Content (Join-Path $nodeHid "package.json") -Raw | ConvertFrom-Json
$main = if ($pkg.main) { $pkg.main } else { "index.js" }
$mainPath = Join-Path $nodeHid $main
if (-not (Test-Path $mainPath)) { throw "node-hid main module not found: $mainPath" }

$snippet = Get-Content $snippetSrc -Raw
if ($Log) {
    $snippet = $snippet -replace "var LOG = false;", "var LOG = true;"
    Write-Host "Logging ENABLED -> $env:TEMP\gamesir_hid_log.txt (via app's temp dir)"
}

Add-Content -Path $mainPath -Value "`n// === Cyclone2 D-pad neutralizer (injected) ===`n$snippet"
Write-Host "Appended neutralizer to $($main) in node-hid."

Write-Host "Repacking app.asar (keeping *.node unpacked)..."
npx --yes @electron/asar pack "$work" "$asar" --unpack "*.node"

Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Done. Launch GameSir Connect and test the D-pad."
if ($Log) {
    Write-Host "Press the D-pad, then check the log for the real report bytes."
}
