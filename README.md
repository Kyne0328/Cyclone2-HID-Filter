# Cyclone2DpadFilter

Windows KMDF HID upper-filter driver scaffold for GameSir Cyclone 2 D-pad filtering.

## Current INF target

The INF is an Extension INF, not a primary HIDClass device INF. It adds the filter above the existing in-box HID function driver.

The model section is decorated as `NTamd64.10.0...18362` because:

- `DIRID 13` requires Windows 10 build 16299 or newer.
- `DDInstall.Filters` / `AddFilter` requires Windows 10 build 18362 or newer.

So the effective minimum install target is Windows 10 version 1903 / build 18362 or newer.

## Build

Use the GitHub Actions workflow or build locally with Visual Studio + WDK/EWDK.

Expected package files after a successful build:

- `Cyclone2DpadFilter.sys`
- `Cyclone2DpadFilter.inf`
- `Cyclone2DpadFilter.cat`
- optional `Cyclone2DpadFilter.pdb`

## Before install

Replace the placeholder hardware ID in `Cyclone2DpadFilter.inf`:

```inf
HID\VID_XXXX&PID_YYYY
```

with the actual Cyclone 2 HID hardware ID from Device Manager.

The default D-pad report settings are still guesses until the real controller HID report layout is known:

- `ReportId=0`
- `DpadByteOffset=2`
- `DpadMask=0x0F`
- `DpadNeutralValue=0x08`

## Install notes

This is a kernel driver. Test only on a machine where you can recover through Safe Mode, Device Manager, or driver removal.

For test-signed packages, Windows test-signing may be required:

```cmd
bcdedit /set testsigning on
shutdown /r /t 0
```

Install from an elevated command prompt in the package folder:

```cmd
pnputil /add-driver Cyclone2DpadFilter.inf /install
```

## Uninstall

Find the published INF:

```cmd
pnputil /enum-drivers
```

Then remove it:

```cmd
pnputil /delete-driver oemXX.inf /uninstall /force
```

Reboot afterward.
