# My Friendly Neighborhood VR (MFNVR)

Full 6DOF VR for My Friendly Neighborhood with motion controllers,
by LeviGaming1248.

## What it installs
- **Current MFNVR mod** - the VR mod itself, plus the BepInEx loader
  it needs (`winhttp.dll` proxy, `BepInEx\`, `openxr_loader.dll` and
  `MFNOpenXR.dll` in `My Friendly Neighborhood_Data\Plugins\`)

The installer pulls the current release straight from GitHub, so it
also serves as the update path - run it again whenever the Hub shows
an update on the tile.

## Requirements
- My Friendly Neighborhood (Steam, Epic or the Xbox app)
- SteamVR or the Oculus app as the **active OpenXR runtime**; other
  runtimes are untested by the author
- A Windows PC

## How to use
Click **Install Mod** on the game tile or detail page and follow the
prompts. The installer finds the game itself on Steam, Epic and the
Xbox app, and asks for the folder only if nothing is found.

## Settings that matter
| Where | Setting |
|---|---|
| Game options | **Field of View around 100** - the author's own recommendation |
| Windows / headset | SteamVR or Oculus must be the active OpenXR runtime |

## Playing
Start with **Start in VR** in the Hub or the **My Friendly Neighborhood VR**
desktop shortcut, then put the headset on once the game is running.

## What works
- The full game, start to finish
- 6DOF head tracking and room-scale movement
- Tracked motion controllers with independent floating hands
- Motion-controlled weapons, weapon-aligned shooting and crosshair
- Two-handed weapon gripping
- Physical wrench melee
- VR-compatible HUD and menus

## Known issues
- **The toolbox is broken.** Use the inventory instead - that works.
- This is an early alpha. Expect bugs, visual glitches, incomplete
  interactions and performance problems.

The author's own note: the mod was generated with AI and none of the
code has been written or reviewed by a human, so bugs and unintended
behaviour are possible. No source code is published yet.

## Your settings are kept
Your `BepInEx\config\MFNVR*.cfg` files - including the hand
calibration - are left alone when you run the installer again. The
config that ships with the mod is only written on a fresh install.

## Planned by the author
Better toolbox interaction, better hand poses, physical item
interactions, improved weapon handling, nicer menus, performance work
and more comfort options.

Mod page:

https://github.com/LeviGaming1248/MFNVR
