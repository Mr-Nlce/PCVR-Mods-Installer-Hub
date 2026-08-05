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
4. Lets you pick the stereo mode and writes the matching settings for you

## Stereo mode
The author recommends **AER**: the other stereo modes look right standing
still but blur while you look around, and that is a known open issue.

| mode | what the installer writes |
|---|---|
| AER | `ipd` = 1 |
| other stereo | `ipd` = 6, `stereoscale` = 130, `fpfov` = 110 110 110 |

Those values come from the release notes. You can change them any time -
they are plain text files sitting next to `GTAIV.exe`.

## Required in-game setting
In the **FusionFix graphics options, choose DirectX 9** - not FusionFix's
own Vulkan path. The VR layer hooks the DirectX 9 device.

## Controls
The game plays on a gamepad; these are the VR layer's own keys.

- [[F3]] or gamepad [[Back]] open / close the VR settings menu
- [[F9]] or [[R3]] recenter the view
- [[F4]] cycle stereo / render profiles
- [[F5]] cycle the eye resolution
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
