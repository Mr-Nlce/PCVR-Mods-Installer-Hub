# Outlast 2 VR

## About the Game

Outlast 2 is a first-person survival horror game. This unofficial WIP mod by StrikeZoneVR adds an OpenXR VR launcher and tracked controller support to the Steam game.

## What the VR mod adds

The public beta adds head tracking, Quest/Touch button mappings, hybrid tracked upper-body arms, VR-friendly menus and loading screens, and the original game's scripted interactions and animations. The camcorder retains night vision, zoom, batteries, recordings and microphone controls. A physical Xbox-style gamepad remains supported. The desktop mirror shows one eye for recording. An optional seven-second in-headset intro can be disabled in the launcher.

## Install and update

Own and install [Outlast 2 on Steam](https://store.steampowered.com/app/414700/). **Before adding the VR mod, start the unmodified game from Steam, reach the main menu, then close it.** This creates `OLGame.ini` and `OLEngine.ini` under `Documents\My Games\Outlast2\OLGame\Config`. The installer checks for both files before downloading or copying the VR mod; if they are missing, it waits for a flat first run or lets you cancel. If the VR mod is already present and these files are missing, remove the mod with **Uninstall now**, run the game flat, then reinstall. The Hub downloads the current Windows x64 asset from the [GitHub prerelease channel](https://github.com/StrikeZoneVR-hub/Outlast2VR/releases). It copies the complete publisher package beside `Binaries\Win64\Outlast2.exe`, keeps a file ownership record and writes the installed version only after the required files are present. Reopen the installer to update.

Start in VR opens `Binaries\Win64\Outlast2VR.exe`. Select **PLAY VR** in the publisher launcher. Running `Outlast2.exe` directly does not use those VR options. Quest 3 with Virtual Desktop and VDXR is the publisher-tested setup; other OpenXR configurations and game builds remain unverified. The publisher verified Outlast2.exe version `1.0.8767.0`; a different build receives a warning during setup.

The default **Compatibility / performance** renderer shows the same sharp image to both eyes, so it has **no binocular depth**. Optional depth stereo is experimental and substantially more demanding. For an initial test, use the default renderer, 72 Hz if needed, and the launcher's **VR-safe** graphics option; it disables motion blur and temporal antialiasing. Leave `PrimitiveDrawDistanceFix=0`: the publisher says its diagnostic object scan can cause a long startup hitch. This is a beta; headset gameplay has not been tested by the Hub.

For the first launch, face forward before pressing **PLAY VR**. With Quest 3 and Virtual Desktop, select VDXR and leave color vibrance and gamma neutral while checking the image. The optional headset intro is on by default; clear **Play StrikeZone VR headset intro** on the launch page to skip it.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move; move objects after pressing X |
| [[Left Stick Click]] | Sprint |
| [[Right Stick]] | Turn left/right; camcorder zoom up/down |
| [[A]] | Jump |
| [[B]] | Crouch or crawl |
| [[X]] | Interact, pick up objects or start moving objects |
| [[Y]] | Reload the camcorder battery |
| Hold [[Y]] | Apply a bandage |
| [[Right Grip]] | Raise or lower the camcorder |
| [[Right Stick Click]] | Toggle night vision |
| [[Y]] + [[Right Stick Click]] | Toggle microphone |
| [[X]] + [[Y]] | Open recordings and inventory |
| [[A]] + [[B]] | Look behind |
| [[Menu]] | Pause |
| [[Left Stick Click]] + [[Right Stick Click]] | VR settings and recenter controls |

## Beta limitations and troubleshooting

- Compatibility/performance mode has no binocular depth. Depth stereo may run much slower and remains experimental.
- Scripted scenes can temporarily use the original character animation instead of tracked arm movement; tracking returns afterward. Some prompts still use Xbox labels.
- Other OpenXR headsets and Outlast 2 builds may work but are not publisher-verified. Runtime hooks deliberately stop when executable signatures differ.
- Isolated level-specific visibility issues may remain. For a reproducible problem, record the location, VR runtime, game version, headset capture and `Binaries\Win64\outlast2_vr_p34.log`, then use [GitHub issues](https://github.com/StrikeZoneVR-hub/Outlast2VR/issues). The [Flat2VR thread](https://discord.com/channels/747967102895390741/1537851737728221284) is available for discussion.
- If the launcher cannot find the game, check that the complete release sits beside `Binaries\Win64\Outlast2.exe`. If OpenXR cannot start, select an active runtime and run the launcher's VR check.
- If menus work in VDXR but gameplay stays on the desktop, choose **Default OpenXR / Virtual Desktop** plus **Compatibility / performance** and wait several seconds for the full-view fallback. Include the log in a bug report if it still fails. For an immediate crash, verify the Steam game files and compare your executable with the publisher-supported build before reinstalling the complete VR package.
- Outlast 2 is intense horror. Use the launcher comfort options, take breaks and stop if you feel unwell.

[Watch VR gameplay](https://www.youtube.com/watch?v=ZMQF1Re5XVw)

>>> The camera sees the terror. The headset puts you inside it.
