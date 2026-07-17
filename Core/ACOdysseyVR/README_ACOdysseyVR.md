# Assassin's Creed Odyssey VR Installer

Automated installer for AnvilEngine2VR by mutars (the same modder
as Starfield VR in this Hub) - a VR mod for Assassin's Creed games
on the AnvilNext 2.0 engine. Full 6DOF head tracking, head aim and
HUD scale adjustment, across Kassandra's Greece.

## What it does
1. Finds your Odyssey install on ANY store - Steam, Ubisoft
   Connect, Ubisoft+ / PC Game Pass (those use ACOdyssey_plus.exe;
   handled automatically) or Epic
2. Has you set the in-game settings FIRST (see below) - the game
   still starts flat at that point, so the menu cannot freeze
3. Lets you pick the runtime build:
   - OpenXR (recommended) - runs on any OpenXR runtime: SteamVR,
     Virtual Desktop VDXR, Meta, Pimax
   - OpenVR - the classic SteamVR path, if OpenXR misbehaves
4. Downloads the latest release from GitHub (auto-updates; falls
   back to the pinned v2.0.0.Public build) and drops the files into
   the game folder - dxgi.dll next to the exe, plus openvr_api.dll
   for the OpenVR build. DXGI hooking: the game loads the mod itself.
5. Records the release tag so the Hub's tile flips to Update when a
   new release lands

## Requirements
- Assassin's Creed Odyssey (any store version)
- A VR headset with an OpenXR-compatible runtime (or SteamVR for
  the OpenVR build)

## In-game settings (the installer asks for these FIRST)
The installer front-loads this as its second step - before the mod
files go in. Reason: once the mod is installed the game boots
straight into VR, and the settings menu can freeze in the headset.
Before the install the game still starts flat, so the installer
offers to launch it for you, you set these, quit, and only then does
the actual installation begin:
- Windowed Mode: ON
- Vsync: OFF
- Frame Cap: OFF
- HDR: OFF
- Depth of Field: OFF
A game update or a settings reset can undo these - if VR starts
acting up later, recheck them (delete dxgi.dll from the game folder
first if the menu freezes in VR, set them flat, then reinstall).

## How to play
1. Start your VR runtime
2. Launch the game normally from your store, or "Start in VR" in
   the Hub - the mod loads with the game
3. Head aim is active; HUD scale is adjustable in the mod settings

## Known limitations
- Dialogs are rendered in stereo but displayed in letterbox format
- Water and some visual effects are not visible when looking in the
  opposite direction to the character

## About the -symbols download
The Releases page also lists a -symbols zip. Those are debug
symbols for crash analysis - useful when reporting a crash to the
developer, not needed to play. This installer skips them on purpose.

## Uninstall
Delete dxgi.dll (and openvr_api.dll, if present) from the game
folder. Nothing else is touched.

## Updates
The Hub checks the GitHub latest release in the background and
flips the game tile to Update when a new build lands. Rerun this
installer and pick your runtime again.

## Mod page
https://github.com/mutars/anvilengine2vr

The same mod also supports Assassin's Creed Valhalla and Mirage
(Origins is in development).

## Support mutars

mutars develops the anvilengine2vr mod. If you enjoy their work, consider supporting them:
- Patreon: https://www.patreon.com/c/NoMoreFlat

>>> Malaka! From Kephallonia to Olympus, the eagle soars.
