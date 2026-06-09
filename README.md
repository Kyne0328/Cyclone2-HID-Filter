# Cyclone2 D-pad Kill — XInput1_4 proxy

Neutralizes the GameSir Cyclone 2 D-pad by replacing a bundled `XInput1_4.dll`
with a proxy that forwards every call to the original and strips the four D-pad
button bits from the returned controller state.

This replaces the earlier kernel-driver (HID/USB filter) approach. The proxy is
a plain user-mode DLL — no test signing, no kernel driver, no Safe Mode risk.

## How it works

GameSir Connect ships its own copy of `XInput1_4.dll`:

```
%LOCALAPPDATA%\Programs\gamesir_connect\resources\dfu\XInput1_4.dll
```

The proxy DLL takes that filename. On load it pulls in the renamed original
(`XInput1_4_real.dll`) from the same folder and re-exports every XInput entry
point. `XInputGetState` and `XInputGetStateEx` (ordinal 100) clear the D-pad
bits before returning:

```cpp
state->Gamepad.wButtons &= ~(XINPUT_GAMEPAD_DPAD_UP | XINPUT_GAMEPAD_DPAD_DOWN |
                             XINPUT_GAMEPAD_DPAD_LEFT | XINPUT_GAMEPAD_DPAD_RIGHT);
```

Everything else (sticks, triggers, face/shoulder buttons, rumble, guide button)
passes through unchanged.

## Files

- `dllmain.cpp` — proxy implementation (named + ordinal exports).
- `XInput1_4.def` — export table, including ordinals 100–103.
- `XInput1_4.vcxproj` — builds `XInput1_4.dll` for Win32 and x64.
- `tools/windows/install-proxy.ps1` / `uninstall-proxy.ps1` — backup/swap helpers.

## Build

CI (`.github/workflows/build-proxy.yml`) builds both platforms and uploads
`XInput1_4-proxy-Win32` and `XInput1_4-proxy-x64` artifacts. Each artifact also
includes the install/uninstall scripts.

Local build (VS 2022 Developer prompt):

```cmd
msbuild XInput1_4.vcxproj /t:Rebuild /p:Configuration=Release /p:Platform=Win32
msbuild XInput1_4.vcxproj /t:Rebuild /p:Configuration=Release /p:Platform=x64
```

Output: `Win32\Release\XInput1_4.dll` and `x64\Release\XInput1_4.dll`.

The CRT is linked statically (`/MT`) so the proxy carries no VC++ redistributable
dependency inside the host process.

## Which bitness?

Install the proxy whose bitness matches the **original** `XInput1_4.dll` you are
replacing (and the process that loads it). The presence of `XInputUtil_x86.dll`
in the dfu folder suggests the bundled DLL is 32-bit, so try **Win32** first. If
the D-pad still works, check the original DLL's bitness and use the x64 proxy.

## Install

Close GameSir Connect, then from the artifact folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-proxy.ps1
```

It backs up `XInput1_4.dll` → `XInput1_4_real.dll` (once), then drops the proxy
in place. Open GameSir Connect and test: D-pad should read neutral, all other
inputs normal.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall-proxy.ps1
```

Restores the original `XInput1_4.dll` and deletes the backup.

## Scope / limits

- Only affects consumers that load **this** `XInput1_4.dll`. It neutralizes the
  D-pad inside GameSir Connect's own input/test view if that view uses the
  bundled XInput path.
- Games that load the system `XInput1_4.dll` from `System32` are not affected by
  the copy in GameSir Connect's folder. To cover a specific game, drop the
  matching-bitness proxy (plus the renamed real DLL) next to that game's
  executable instead.
- If the D-pad still appears after install, GameSir Connect is reading the D-pad
  through a different path (HID or a vendor DLL such as `sapjoyuniapis_*.dll`),
  not this XInput DLL.
