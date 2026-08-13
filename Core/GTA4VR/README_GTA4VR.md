# GTA IV VR Installer

Automated installer for **gtaiv-dxvk-vr** by Hochgeschwindigkeitsrennfahrer -
head-tracked VR for **GTA IV Complete Edition**, built on stock DXVK 3.0.2
and OpenVR.

This is an early proof of concept, and it is honest about that: stereo depth
and head tracking work, head aiming while aiming down sights is experimental,
and there are **no motion controller hands**. You play it on a gamepad, Xbox
pads being the tested ones.

**SteamVR only.** There is no OpenXR path, so a standalone WMR or Meta
runtime without SteamVR will not work.

## What the installer does
1. Finds your GTA IV folder (the one holding `GTAIV.exe`) on Steam,
   Rockstar Games Launcher, or a retail install
2. Downloads the newest release from GitHub
3. Backs up `d3d9.dll` and `dinput8.dll` as `.vrbak`, then merges the mod
   files into the game folder - asking for administrator rights only if
   that folder needs them
4. Shows you the settings the pack shipped - it does **not** overwrite them

## Stereo mode
The pack ships **Mode 909** with its settings already tuned - eye resolution
2048, `fpfov` 90 90 90 and the rest. **The installer no longer writes any of
them.** Earlier builds needed a choice between stereo modes and the Hub wrote
the numbers for you; that is obsolete and would only overwrite better defaults.

Everything is plain text next to `GTAIV.exe`, so you can still change any of it
with Notepad. `gtaiv_dxvk_vr.stereo` is the mode itself - **`0` turns VR off**
and gives you the flat game through DXVK.

## Two things the pack expects
In the **FusionFix graphics options, choose DirectX 9** - not FusionFix's
own Vulkan path. The VR layer hooks the DirectX 9 device.

**`FirstPerson.asi` has to be off.** If you have it, rename it to
`FirstPerson.asi.off` - this mod owns the camera and field-of-view path, and
running both makes them fight.

## Starting it
The pack ships **`QUICK-START.bat`** next to `GTAIV.exe`: it starts SteamVR,
waits, then launches the game through Steam. Start SteamVR first if you prefer
to launch normally.

**`FULL-RESTART.bat`** is what the VR menu's *Full restart* now runs - a real
process restart. The menu's *Re-read settings files* only reloads the text
files beside the game and does **not** reload the mod itself, so a changed
setting that seems to do nothing usually needs the full restart.

## Controls
The game plays on a gamepad; these are the VR layer's own keys.

- [[F3]] or gamepad [[Back]] open / close the VR settings menu
- [[F9]] or [[R3]] recenter the view
- [[F5]] cycle the eye resolution (it saves the new value back)
- [[F6]] stereo scale, [[F8]] IPD / separation
- [[F10]] set the seated lean baseline
- Menu navigation: [[WASD]], arrows or the left stick; [[Enter]] applies

If the gun glitches while aiming, recenter - that is a known rough edge.

## Config files (next to GTAIV.exe)
Plain text, one value each. Edit with Notepad, then restart the game.

- `gtaiv_dxvk_vr.vres` - eye resolution; `F5` also cycles it and saves back
- `gtaiv_dxvk_vr.stereo` - stereo mode; **`0` turns VR off** and gives you
  the flat game on the monitor
- `gtaiv_dxvk_vr.ipd`, `.stereoscale`, `.fpfov` - scale and field of view
- `gtaiv_dxvk_vr.log` next to `GTAIV.exe` records the build id

The shipped `CONFIG-GUIDE.txt` lags behind the build - where it and the
files disagree, the files that came with your download are what is actually
running.

## Optional: square aspect
The package ships `commandline.txt.vr-square`. Renaming it to
`commandline.txt` (back up any existing one first) switches the game to a
square window, which some people prefer in the headset. Needs a full
process restart.

## Turning VR off again
Set `gtaiv_dxvk_vr.stereo` to `0` and restart, or rename
`gtaiv_dxvk_vr.asi` to `gtaiv_dxvk_vr.asi.off`. To go back to a clean game,
restore `d3d9.dll.vrbak` and `dinput8.dll.vrbak` over the mod's versions.

## If it crashes at boot
The package includes `aCompleteEditionHook.asi`, which is **optional** - the
VR layer does not need it. On some Complete Edition plus FusionFix setups it
crashes at startup. Rename it to `aCompleteEditionHook.asi.off` and try
again.

## Requirements
- GTA IV **Complete Edition** (32-bit `GTAIV.exe`)
- SteamVR with a tracked headset (developed on a Reverb G2)
- A gamepad

## Mod page
https://github.com/Hochgeschwindigkeitsrennfahrer/Grand-Theft-Auto-IV-VR-Mod

## Credits
The pack builds on DXVK, FusionFix, Ultimate ASI Loader, MinHook and Aru's
ScriptHook - each under its own license. GTA IV belongs to Rockstar Games;
no game files are redistributed.
