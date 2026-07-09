# Star Fox 64 VR

A full PCVR port of Star Fox 64, built on **Starship** (the HarbourMasters PC port) with an OpenXR layer on top. Put on a headset and you're flying the Arwing for real: the scene renders once per eye with full head tracking, and the motion controllers drive everything - flight, menus, all of it. No headset connected? The same exe runs as the normal flat game.

**Mod**: Starship VR - by RaYRoD (VR work), on HarbourMasters Starship
**Source**: https://github.com/RaYRoD-TV/StarFox64-VR

## About

Windows only for now, built against OpenXR 1.0, so any PCVR-capable headset should work (tested on Quest via Link and Virtual Desktop). This is a beta - plenty of flight time, but expect some rough edges.

**No copyrighted assets are included - you provide your own ROM dump.** Supported: US 1.0 and US 1.1. ROM in `.n64` format? Convert it to `.z64` first (hack64.net/tools/swapper.php).

## What this Hub installer does

1. Downloads the latest Star Fox 64 VR release from GitHub
2. Installs it to `C:\Games\Star Fox 64 VR` (or a folder you pick)
3. Creates a desktop shortcut

## Providing the ROM

Nothing to place during install. On **first launch a file picker opens** - select your own Star Fox 64 US `.z64` ROM there. The game builds its asset archive from it once, and you're in.

## Playing

Start your VR runtime first (Quest Link / Air Link, Virtual Desktop, or SteamVR), then launch the `Star Fox 64 VR` shortcut (or `Starship.exe`). With the headset on you spawn straight into VR; the desktop window mirrors what you see. Force a mode with `--vr` (headset required) or `--novr` (always flat); with no flag it auto-detects.

## VR controller layout

| Control | Action |
|---|---|
| [[Left Stick]] | Flight stick / menu navigation |
| [[Right Trigger]] or [[A]] | Fire laser (hold to charge) |
| [[Left Trigger]] or [[B]] | Smart bomb |
| [[Left Grip]] | Bank left (double-squeeze = barrel roll) |
| [[Right Grip]] | Bank right (double-squeeze = barrel roll) |
| [[Right Stick]] up/down | Boost / brake |
| [[Right Stick]] click | Cycle view mode |
| [[Left Stick]] click | Open/close the desktop settings menu |
| [[Menu]] | Pause |

A gamepad or keyboard keeps working alongside the controllers. In VR your head moves the view on top of whichever input you use.

## View modes

Click the right stick any time to cycle:

- **Third Person** - the classic chase cam, life-size and in stereo (default).
- **First Person** - the Arwing is hidden and your eye sits in the pilot's seat.
- **Cockpit** - the game's own cockpit camera (on-rails stages).
- **Diorama** - the level shrunk to a tabletop in front of you (Quest: can use passthrough mixed reality).
- **Theater** - the flat game on a big head-locked screen. Maximum comfort, zero stereo.

## VR options

All settings are in-game. In the headset: pause, then pull the right trigger for a scrollable list (view mode, world scale, stereo depth, HUD size/distance, hide HUD, sky dome, fog, draw distance, resolution scale, and more). On the desktop: click the left stick and use the pointer - everything is under **Enhancements -> VR**. Feeling queasy? Theater mode is one stick-click away, and Stereo Depth can be dialed down.

## Credits

HarbourMasters **Starship** - the PC port this is built on (lead devs SonicDcer and Lywx). **libultraship** - the renderer/platform layer (this port uses a fork with VR render hooks). VR work by RaYRoD. Star Fox 64 belongs to Nintendo - bring your own ROM.

>>> Do a barrel roll, Fox - the Lylat System is counting on you.
