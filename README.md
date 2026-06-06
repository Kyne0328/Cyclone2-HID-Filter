# Cyclone2DpadFilter

Kernel-mode HID upper-filter driver scaffold for Windows.

The goal is to sit below normal apps, including GameSir Connect, and rewrite the physical controller's HID input reports before apps receive them. It keeps the real device identity because the physical Cyclone 2 is still the device being opened; this driver only edits input report bytes in the device stack.

## Reality Check

This is the correct class of solution for "disable D-pad even in GameSir Connect while still reading as Cyclone 2", but it is not a one-click app:

- You need Visual Studio 2022 plus the Windows Driver Kit.
- You need Windows test-signing or a properly signed driver.
- The exact D-pad byte/mask can vary by firmware, USB/Bluetooth mode, and controller mode.
- A wrong byte/mask can disable the wrong control until the filter is removed or reconfigured.

The default config assumes the D-pad is a HID hat switch nibble:

- `ReportId = 0`
- `DpadByteOffset = 2`
- `DpadMask = 0x0F`
- `DpadNeutralValue = 0x08`

If your controller reports the D-pad as four button bits, use a mask that covers those bits and set `DpadNeutralValue = 0`.

## Files

- `Cyclone2DpadFilter.c`: KMDF filter driver source.
- `Cyclone2DpadFilter.h`: shared driver declarations.
- `Cyclone2DpadFilter.inf`: install file. You must edit the hardware ID.
- `Cyclone2DpadFilter.vcxproj`: Visual Studio/WDK project file.

## Build

1. Install Visual Studio 2022 with C++ desktop development.
2. Install the Windows Driver Kit matching your Windows version.
3. Open `Cyclone2DpadFilter.vcxproj`.
4. Build `Debug|x64` or `Release|x64`.

## Build with GitHub Actions

You can also build this in GitHub Actions. Put these files at the root of a GitHub repository, including:

```text
.github/workflows/build-driver.yml
Cyclone2DpadFilter.c
Cyclone2DpadFilter.h
Cyclone2DpadFilter.inf
Cyclone2DpadFilter.vcxproj
```

Then open the repository's **Actions** tab and run **Build Cyclone2DpadFilter** manually.

The workflow installs the Windows SDK and WDK, builds Debug and Release x64, and uploads the build output as artifacts.

GitHub Actions is useful for producing the `.sys`, `.inf`, and `.cat` files, but it does not install or test the driver on your PC. You still need to download the artifact, enable test-signing if needed, and install it locally.

## Find the Cyclone 2 Hardware ID

1. Open Device Manager.
2. Find the GameSir Cyclone 2 HID device.
3. Open **Properties**.
4. Go to **Details**.
5. Choose **Hardware Ids**.
6. Copy the most specific `HID\VID_....&PID_....` value.
7. In `Cyclone2DpadFilter.inf`, replace:

```text
HID\VID_XXXX&PID_YYYY
```

with your actual hardware ID.

## Install for Testing

Open an elevated Developer Command Prompt:

```cmd
bcdedit /set testsigning on
shutdown /r /t 0
```

After reboot, from the build output folder:

```cmd
pnputil /add-driver Cyclone2DpadFilter.inf /install
```

Unplug/replug the controller, or disable/enable it in Device Manager.

## Configure the D-pad Mask

The filter reads these per-device registry values:

The filter rewrites D-pad bytes on both `IRP_MJ_READ` (normal `ReadFile` polling) and `IOCTL_HID_GET_INPUT_REPORT` (`HidD_GetInputReport`), so apps using either path see the neutral D-pad.

- `ReportId`: only modify reports with this report ID. `0` means modify every report.
- `DpadByteOffset`: zero-based byte offset in the HID input report.
- `DpadMask`: bits to overwrite.
- `DpadNeutralValue`: neutral value written into the masked bits.

These are set by the INF defaults. If the D-pad is not disabled or another control is affected, change these values in the device instance registry, then replug the controller.

## Remove

In Device Manager:

1. Open the GameSir controller device.
2. Remove/uninstall the driver package.
3. Reboot if Windows asks.

You can turn off test-signing afterward:

```cmd
bcdedit /set testsigning off
shutdown /r /t 0
```

## Microsoft References

- KMDF HID filter sample: https://learn.microsoft.com/en-us/samples/microsoft/windows-driver-samples/kmdf-filter-driver-for-a-hid-device/
- HID reports are normally obtained through `IRP_MJ_READ`: https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/obtaining-hid-reports
- Microsoft recommends framework-based filter drivers for HID stacks: https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/keyboard-and-mouse-hid-client-drivers
