# Saints Row: The Third VR Installer

This installer layers **zolika1351's ZMenu** (a trainer/menu mod) together
with its **VR build** onto an existing, user-owned copy of
**Saints Row: The Third**. No game files are shipped - you must already own
and have the game installed via Steam or GOG.

The VR support is part of zolika1351's SR3 menu. In VR you play with motion
controllers; the menu itself is opened in-game with the **F7** key.

## What it installs

- **ZMenu (SR3)** - the menu/trainer base files (`ZMenuSR3.asi`,
  `ZMenuSR3.ini`, `bass.dll`, `dinput8.dll`, `zmods_twitch.dll`, `ZMenuAssets\`)
- **VR build overlay** - the contents of the mod's `build with VR support`
  folder, copied on top: the VR-enabled `ZMenuSR3.asi`, `openvr_api.dll`, and
  the SteamVR action files (`vr_actions*.json`)

All of these go directly into the **Saints Row: The Third game folder**
(the folder that holds `SaintsRowTheThird_DX11.exe`).

## Requirements

- **Saints Row: The Third** installed via Steam or GOG (you own it)
- A SteamVR / OpenVR-compatible headset
- The game must be launched with the **DX11** executable
  (`SaintsRowTheThird_DX11.exe`)

## How to install (via the Hub)

1. The installer finds your Saints Row: The Third folder automatically
   (Steam library or GOG). If it can't, you drag the game folder (or
   `SaintsRowTheThird_DX11.exe`) onto the window.
2. The mod is hosted on **MEGA**, so the installer opens the download page
   and waits while you download the zip yourself.
3. You drag the downloaded zip onto the installer window. (You can also drag
   an already-extracted folder if you prefer to unzip it yourself.)
4. The installer copies the menu files into the game folder, then overlays
   the `build with VR support` contents on top, and creates a desktop
   shortcut to the DX11 exe.

## Install layout

```
<Saints Row: The Third folder>\
  SaintsRowTheThird_DX11.exe      (the game's own exe - launch this)
  dinput8.dll                     (ASI loader - loads ZMenu on launch)
  ZMenuSR3.asi                    (VR-enabled build, overlaid)
  ZMenuSR3.ini
  bass.dll
  zmods_twitch.dll
  openvr_api.dll                  (VR runtime - install marker)
  vr_actions.json                 (+ knuckles / oculus_touch / vive variants)
  ZMenuAssets\                    (menu sounds & images)
```

Only the **contents** of `build with VR support` are copied into the game
folder - the folder itself is not copied.

## How to play in VR

1. Launch with **Start in VR** in the Hub, or `SaintsRowTheThird_DX11.exe` (the desktop shortcut,
   the Hub's Start button, or the exe directly).
2. In-game, press **F7** to open the ZMenu trainer menu.
3. Scroll down to **VR** and press it.
4. Choose **Start VR**, then put on your headset.

You can **stop VR** again from the same menu at any time.

## Controls (VR motion controllers)

Default **Oculus Touch** bindings shipped with the mod (these are SteamVR
action sets, so they can be rebound in SteamVR's controller bindings):

- [Trigger] (right) - Fire weapon
- [Stick] (left) - Move
- [Stick] (right) - Snap turn left / right
- [X] (left) or [Grip] (left) - Switch weapon
- [Grip] (right) - Reload weapon
- [Y] (left) - Action / interact
- [B] (right) - Jump

Action files for **Valve Index (Knuckles)**, **Oculus Touch**, and
**Vive controllers** are all included. The trainer menu itself is opened with
the **F7** key.

## Known issues and tips

- For VR, disable **fake distant vehicles & peds** in **Misc - Game Tweaks**,
  as they will otherwise sometimes spawn nearby.
- If you're getting low FPS in VR, try enabling **Performance Mode** and
  adjusting its settings.

## Supported versions

- Tested and compatible with the **latest GOG version**. Otherwise untested,
  but likely also works on other versions as long as you run the **DX11 exe**.

## Credits

- **zolika1351** - ZMenu and its VR support for Saints Row: The Third
- Mod page: https://zolika1351.pages.dev/mods/sr3menu

## More info

https://zolika1351.pages.dev/mods/sr3menu
