<#
.SYNOPSIS
    Restores GameSir Connect's original app.asar, undoing the D-pad patch.
#>
$ErrorActionPreference = "Stop"

$root = Join-Path $env:LOCALAPPDATA "Programs\gamesir_connect\resources"
$asar = Join-Path $root "app.asar"
$bak  = Join-Path $root "app.asar.bak"

Write-Host "Closing GameSir Connect..."
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path -like "*gamesir_connect*" } |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path $bak) {
    Copy-Item $bak $asar -Force
    Write-Host "Restored original app.asar from app.asar.bak."
    Write-Host "(Backup kept. Delete app.asar.bak manually if you no longer need it.)"
} else {
    Write-Host "No app.asar.bak found; nothing to restore."
}
