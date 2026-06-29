# Cruelty Squad VR

Full VR conversion with motion controls for the surreal immersive-sim
shooter Cruelty Squad, built on a Godot OpenXR modloader by teddybear082
(co-maintained by SpencerBinXia) — a fork of crustyrashky & disco0's
flatscreen modloader.

## Epilepsy / seizure warning

Cruelty Squad VR has very fast-moving textures, a disturbing visual
effect from psychos, and flashing images. **If you have epilepsy, you
should not play this VR mod.**

## What it installs

- **CrueltySquadVR Modloader v1.3-Stable** — Godot OpenXR loader + the VR
  mod files (`cs-vr-mod-vr-files`, `cs-vr-mod-xr-tools`)
- Optionally: **Stutter Fix** (DX) and **Text-to-Speech** (teddybear082)
  add-ons

## Requirements

- Cruelty Squad owned on Steam (only use a legitimately purchased copy)
- SteamVR installed
- **A VR headset is required** — do not install this without one
- Set your OpenXR runtime to **SteamVR** (WMR / Virtual Desktop / ALVR
  users: not WMR/Oculus; VD can also use VDXR). Turn **off** OpenXR Toolkit
  or the game will crash on load

## Before you install

**Back up your saves.** If you've used other mods, return to a clean
state first (verify game files in Steam), and run the game once unmodded
so its folders exist. The mod files live in
`%APPDATA%\Godot\app_userdata\Cruelty Squad\mods`.

## Features

- **Full 6DOF VR with motion controls** — aim and shoot with your hands,
  motion-controlled melee, grab/climb, throw items and weapons
- **Gesture controls** — swing both arms up to jump, radial weapon menu
  on the off-hand, hand-pointer menus
- **Vehicle support** — grab and turn a virtual steering wheel, trigger
  gas/brake
- **Left-handed mode** supported
- An **NPC Performance Hack** (on by default) deactivates distant NPCs for
  a 15-20 FPS boost; toggle it off in the main menu for vanilla behaviour

## Controls

### Left hand (off hand)
- **[[Trigger]]:** kick / jetpack toggle / BioThruster / throw held items;
  select menu items with the pointer
- **[[Y]]:** toggle floating pause menu and the stocks menu on the right hand
- **[[Grip]]:** climb, use items/doors near your hand
- **[[Stick]]:** move
- **[[Stick]] press:** go back a screen in menus

### Right hand (weapon hand)
- **[[Trigger]]:** shoot / skull gun; select menu items with the pointer
- **[[A]]:** throw weapon
- **[[B]]:** Grappendix
- **[[Grip]]:** use / climb / reload (point weapon down while holding grip)
- **[[Stick]]:** turn (up = jump, down = crouch)
- **[[Stick]] press (hold):** radial weapon menu

### Gestures
- Radial menu: hover a weapon and release the [[Stick]] press to select.
  Bottom = tertiary (grenades / health item), Up = suicide (select twice)
- Swing both arms upward together to jump
- Recenter view: in-game press the off-hand thumbstick; in menus press [[B]] or [[Y]]

## First launch & "Invalid app ID"

The mod swaps `crueltysquad.exe` for a Steam-enabled Godot build and does a
"handshake" with Steam. Because of that:

- It can take **up to four clicks/launches** for the game to actually start
  in VR the first time — a first launch showing `Invalid app ID or app not
  installed` and closing is normal. Keep launching. (More than four times,
  it's a real problem.)
- If Windows Defender blocked the replacement `crueltysquad.exe` during
  install (or blocked the install script), the Steam integration won't work
  and you'll keep getting `Invalid app ID`. Re-run the installer, choose
  Keep/Run on any Defender prompt, or temporarily disable the antivirus for
  the install step, then re-enable it.
- Use SteamVR's **OpenXR runtime** for ALVR / Virtual Desktop / WMR.
- If the mod loads **0 mods** or errors on
  `addons/godot-xr-tools/...user_settings.gd`, the game wasn't returned to a
  clean state. Uninstall any previous mod/modloader, verify the game files
  in Steam, then re-run this installer from scratch.

## Known issues

- **No teleport locomotion.** If you get motion sick, the VRocker app can
  help with stick-based walking (works with Quest + Virtual Desktop in
  "stick touch" mode; not with Link/Air Link)
- You have to **jump up stairs**
- **Valve Index:** use 90 Hz, not 144/120 (higher rates cause jitter)
- Performance can tank in places — lower headset resolution, enable
  ASW/SSW/Reprojection, and reduce the in-game "NPCs" and "Draw Distance"

## Recommended add-ons

The installer can add two mods the author recommends:
- **Stutter Fix** (DX) — smooths the shader-compile stutter when you turn
- **Text-to-Speech** (teddybear082) — reads NPC dialogue aloud instead of
  making you read it from the VR hand menu

Both are hosted on MediaFire, so the download may need a manual click.

## Returning to flatscreen

Remove the VR mod folders from the mods directory, then verify the game
files in Steam (right-click -> Properties -> Local Files -> Verify).

## More info

https://github.com/teddybear082/CrueltySquadVR-Modloader

>>> The drillustrator says: stocks are up, and so are you.
