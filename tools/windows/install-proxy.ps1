<#
.SYNOPSIS
    Installs the XInput1_4 proxy DLL into GameSir Connect's dfu folder.

.DESCRIPTION
    Backs up the original XInput1_4.dll to XInput1_4_real.dll (only the first
    time, so re-running never clobbers the genuine DLL), then drops the proxy in
    its place. The proxy forwards every call to XInput1_4_real.dll and strips the
    D-pad bits from the controller state.

.PARAMETER DllPath
    Path to the built proxy XInput1_4.dll. Defaults to the copy next to this
    script (as laid out in the CI artifact).
#>
param(
    [string]$DllPath = (Join-Path $PSScriptRoot "XInput1_4.dll")
)

$ErrorActionPreference = "Stop"

$dfu = Join-Path $env:LOCALAPPDATA "Programs\gamesir_connect\resources\dfu"
if (-not (Test-Path $dfu)) {
    throw "GameSir Connect dfu folder not found: $dfu"
}
if (-not (Test-Path $DllPath)) {
    throw "Proxy DLL not found: $DllPath"
}

$target = Join-Path $dfu "XInput1_4.dll"
$backup = Join-Path $dfu "XInput1_4_real.dll"

Write-Host "Closing GameSir Connect..."
Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path.StartsWith((Join-Path $env:LOCALAPPDATA "Programs\gamesir_connect"), [System.StringComparison]::OrdinalIgnoreCase) } |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path $target) {
    attrib -R $target 2>$null
}

if (-not (Test-Path $backup)) {
    if (-not (Test-Path $target)) {
        throw "No existing XInput1_4.dll to back up at $target"
    }
    Copy-Item $target $backup -Force
    Write-Host "Backed up original -> XInput1_4_real.dll"
} else {
    Write-Host "Backup already exists; leaving XInput1_4_real.dll untouched."
}

Copy-Item $DllPath $target -Force
Write-Host "Proxy installed to $target"
Write-Host "Open GameSir Connect and test the D-pad. It should read neutral."
