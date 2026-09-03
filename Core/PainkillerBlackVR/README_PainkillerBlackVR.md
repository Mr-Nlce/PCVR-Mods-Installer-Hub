# Painkiller: Black Edition VR Installer

Automated installer for the **painkiller-vr-mod** by FluorescentHallucinogen - native OpenXR VR with motion-controller aiming for the original **Painkiller** (People Can Fly / DreamCatcher). Tested with **Painkiller: Black Edition** on Steam, a Quest 2, and Virtual Desktop; expected to work with other OpenXR headsets and runtimes.

## What it does
- Downloads the latest release from GitHub (the Hub flags the tile when a newer build ships).
- Locates your Painkiller install (Steam / GOG, with a manual paste fallback).
- **Backs up** the two original files the mod replaces (`Bin\PainKiller.exe`, `Bin\Engine.dll` -> `*.vrbak`), then copies the mod's four files into `Bin\` inside the game folder.
- Enables VR by adding `Cfg.VideoVR = true` to `Bin\config.ini`.

## Requirements
- **Painkiller 1.64** (Painkiller: Heaven's Got a Hitman and/or Battle Out of Hell). Black Edition on Steam is the tested build.
- A PCVR / OpenXR runtime. **Virtual Desktop with VDXR** is the tested setup; other OpenXR runtimes are expected to work.

## How to play
Set your OpenXR runtime, put your headset on, then launch with **Start in VR** in the Hub, or the desktop shortcut. Aiming is by motion controller.

> **Raise the resolution first.** Painkiller defaults to a very low resolution, which looks blurry in VR. In the main menu or in-game press **Y** for Options, open **Video**, and set the resolution (top row) higher.

## Controls

![Controls](Painkiller_controls.jpg)

- [[Right Trigger]] / [[Left Trigger]] primary fire
- [[Right Grip]] / [[Left Grip]] alternate fire
- [[Left Stick]] move, [[Right Stick]] turn left/right, click up to jump
- [[B]] next weapon / zoom in, [[A]] previous weapon / zoom out
- [[Y]] menu

## Notes
Compatible with other mods that do not modify the game's executable files (e.g. Painkiller Advanced Cheats).

## Back to flat
Restore `Bin\PainKiller.exe.vrbak` and `Bin\Engine.dll.vrbak` (drop the `.vrbak`), or set `Cfg.VideoVR = false` in `Bin\config.ini`.

## Info
https://github.com/FluorescentHallucinogen/painkiller-vr-mod
