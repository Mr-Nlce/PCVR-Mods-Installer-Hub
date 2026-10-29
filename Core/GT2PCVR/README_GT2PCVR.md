# Gran Turismo 2 PCVR

Native Windows OpenXR port of Gran Turismo 2 by Yevhen Dubrovskiy. The reviewed v0.9.0 package contains the complete native Windows PCVR installer, runtime and OpenXR launchers alongside the other platforms.

## About the Game

Gran Turismo 2 combines Arcade racing with a Simulation career of licences, dealerships, garage management, tuning and championships. The native port prepares these modes from disc images you own and keeps their memory cards separate.

## What you need

- Your own supported complete 2352-byte-sector Arcade and/or Simulation disc image. BIN/CUE and supported archives work with the publisher importer. Select one image per disc. A 2048-byte ISO omits required XA audio and video sectors.
- A Windows x64 PC, Vulkan 1.3 capable graphics driver and active OpenXR runtime with the connected headset. Meta Link, SteamVR and Virtual Desktop VDXR have separate launchers.
- No BIOS is required for the game. An optional compatible BIOS only adds the original PlayStation startup; the Hub does not ask for or download one.
- No game files, disc data, BIOS or saves are bundled or downloaded by the Hub.

## Install and play

1. Select [[Install]] and provide your own disc image path or paths. The Hub downloads the reviewed [v0.9.0 release](https://github.com/dubrovskiy-yevhen-stakelogic/gt-2-pc/releases/tag/v0.9.0).
2. The publisher's precompiled `INSTALL-PCVR.bat` path verifies its package, imports your supported disc data and creates the runtime under `%LOCALAPPDATA%\GT2-VR\runtime`. Its backups retain earlier data. The Hub confirms the runtime, OpenXR loader, launchers and at least one prepared disc before recording the version.
3. Select [[Start in VR]] or the Gran Turismo 2 PCVR desktop shortcut to run `PLAY-PCVR.bat` for automatic runtime choice. In the runtime folder, use `PLAY-PCVR-META.bat` for Meta Link, `PLAY-PCVR-STEAMVR.bat` for SteamVR/Steam Link, or `PLAY-PCVR-VD.bat` for Virtual Desktop VDXR. `PLAY.bat` starts the same data on the monitor. These launchers do not change the Windows OpenXR default.

Release v0.9.0 includes Windows PCVR and fixes European Simulation career races and memory-card screens. The Hub uses the native PCVR installer from that package. Arcade and Simulation keep separate game cards while sharing graphics and controller settings; the publisher installer retains earlier runtime data in backup folders.

## Controls

Menus and movies appear on a theatre screen; races use head-tracked stereo. VR driving offers Stick, Virtual wheel and Motion modes, including tracked hands, grip-held steering and separate trigger pedals. A gamepad, DualSense or keyboard can also be used.

| Button | Action |
|---|---|
| [[Left Stick Click]] + [[Right Stick Click]] | Open VR settings. |
| [[Left Grip]] + [[Right Grip]] + [[Menu]] | Alternate VR-settings shortcut. |
| [[Menu]] | Pause the race. |
| [[F10]] | Open settings from the keyboard. |
| [[Left Stick]] / [[Right Stick]] | Navigate settings rows or steer according to the chosen mode. |
| [[Left Trigger]] / [[Right Trigger]] | Change a setting value; act as independent pedals in Motion driving. |
| [[A]] | Open or confirm a menu item. |
| [[B]] | Go back. |

Seat height and reach, cockpit wheel and mirror, HUD, eye resolution, refresh request, foveation and vibration are in the in-game menus. Eye-resolution changes need a restart. Set `GT2_XR_MIRROR=1` only if you want a headset mirror on the monitor; it adds GPU work. The most recently used controller supplies input, and keyboard input needs the game window focused. Other controller layouts may require OpenXR bindings.

## Saves and troubleshooting

- PC flat and PCVR share the installed save directory; Arcade and Simulation retain separate memory cards. Back up saves before changing devices. The publisher includes PC/Quest transfer scripts for supported versions.
- If the headset is unavailable, confirm the selected runtime is active and the headset is awake. The dedicated SteamVR launcher requires SteamVR running; the VDXR launcher requires Virtual Desktop connected. The game reports a startup error instead of silently falling back to flat mode.
- The publisher's installer validates each disc, extracts data into staging, runs course/media checks and keeps prior data in folders beginning with `backup-`. Preserve its error and staging output when reporting a failed import.
- To remove PCVR, close the game and review `%LOCALAPPDATA%\GT2-VR\runtime`. Back up the folder first. Remove only the generated player executable, OpenXR loader and launchers whose names begin with `PLAY-PCVR` and end in `.bat`; keep `arcade`, `simulation`, `saves`, settings and publisher `backup-` folders if you may reinstall. Remove the Gran Turismo 2 PCVR desktop shortcut only if it points to that runtime's `PLAY-PCVR.bat`. The Hub currently provides this guide because the publisher installer owns these files and no publisher uninstaller is shipped.

[Publisher PCVR guide](https://github.com/dubrovskiy-yevhen-stakelogic/gt-2-pc/blob/main/docs/PCVR.md) · [Supported disc requirements](https://github.com/dubrovskiy-yevhen-stakelogic/gt-2-pc/blob/main/docs/EUROPEAN-DISCS.md)

There are no shortcuts to the podium, only apexes.
