<#
.SYNOPSIS
    Restores GameSir Connect's original XInput1_4.dll, removing the proxy.
#>
$ErrorActionPreference = "Stop"

$dfu = Join-Path $env:LOCALAPPDATA "Programs\gamesir_connect\resources\dfu"
if (-not (Test-Path $dfu)) {
    throw "GameSir Connect dfu folder not found: $dfu"
}

$target = Join-Path $dfu "XInput1_4.dll"
$backup = Join-Path $dfu "XInput1_4_real.dll"

Write-Host "Closing GameSir Connect..."
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path.StartsWith((Join-Path $env:LOCALAPPDATA "Programs\gamesir_connect"), [System.StringComparison]::OrdinalIgnoreCase) } |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path $backup) {
    if (Test-Path $target) {
        attrib -R $target 2>$null
    }
    Copy-Item $backup $target -Force
    Remove-Item $backup -Force
    Write-Host "Restored original XInput1_4.dll and removed the backup."
} else {
    Write-Host "No XInput1_4_real.dll backup found; nothing to restore."
}
