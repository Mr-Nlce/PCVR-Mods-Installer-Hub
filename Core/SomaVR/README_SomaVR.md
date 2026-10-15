# SOMA VR

Native OpenXR and motion-control conversion by Bateau01. The Hub follows the publisher's Setup and verifies the game, launcher and VR runtime before recording the installed version.

## About the Game

SOMA is Frictional Games' underwater science-fiction horror story. Explore the ruined PATHOS-II facility, solve environmental problems and uncover what remains of its crew and its machines.

## Before you install

- Own and install SOMA. The mod does not include the game.
- Start SOMA flat once and complete its initial menu setup. This creates `user_settings.cfg`, which the publisher Setup needs.
- The publisher now supports the Steam, GOG and Epic Windows versions. If Setup or its compatibility check rejects your executable, do not bypass that result as a confirmed route.
- Close the game, connect a headset and set SteamVR OpenXR or VDXR as the active runtime. Publisher Setup may request administrator access.

## Install or update

1. Select [[Install]] on this page. The Hub locates `Soma.exe`, then downloads the latest stable [publisher release](https://github.com/Bateau01/SOMA-VR/releases).
2. Confirm the game folder and the folder containing `user_settings.cfg` in publisher Setup. Choose Install, Update or Repair and wait for its completion message.
3. Return to the Hub window. It checks `LAUNCH-SOMA-VR.cmd`, `hpl3vr.dll`, `hpl3vr_inject.exe` and `openxr_loader.dll` before writing the version receipt.
4. Select [[Start in VR]]. The publisher launch script runs with administrator approval. For flat play, start the original game normally, without injection.

Publisher Setup preserves existing `hpl3vr_vr_settings.ini` and hand calibration. Keep your own backup of the game folder before a major update. The Hub does not copy or delete the publisher's mod files itself.

The reviewed **v1.07.1** release fixes progression problems when the optional 120 FPS setting is enabled. v1.0.6 added VR Hints, contextual control prompts and manual
power-pump interaction. It improves CPU headroom and key-item pickup. v1.0.5
added GOG and Epic support, finger-tracking improvements and graphics options,
including NVIDIA eye-tracked foveated rendering. v1.04.1 fixed MSAA black screens
and one-eye save menus. The Hub resolves the current stable publisher installer
ZIP; publisher Setup still owns the game-file changes.

## In VR

The mod adds 6DOF stereo, physical hands and object interaction, body movement, spatial subtitles and configurable comfort settings. Menus, documents, terminals, the Omni-Tool and story interactions use VR-specific presentation. Optional Steam Audio HRTF and hardware-dependent eye/finger tracking are available. Features and hardware coverage vary by build; the publisher's Quest 3S and Steam Link setup does not prove every headset.

Open the game's VR SETTINGS for turn mode, movement reference, height, subtitles, grip/trigger bindings, finger tracking, comfort and presentation. The publisher allows bindings to be changed there, so use the in-game mapping as the exact controller reference.

| Button | Action |
|---|---|
| [[Left Thumbstick]] | Move. |
| [[Left Thumbstick Click]] | Toggle crouch. |
| [[Right Thumbstick]] | Turn; hold for one second with the stick centered to reset hand positions. |
| [[Y]] | Recenter view. |
| [[X]] | Pause or resume. |
| [[B]] | Hold to run; back in menus and special interactions. |
| [[A]] | Jump or accept in menus. |
| [[Left Grip]] / [[Right Grip]] | Hold to grab; release to let go. |
| [[Left Trigger]] / [[Right Trigger]] | Curl the index finger; right trigger also selects menu items. |
| [[Headset touch]] + [[Grip]] or [[Trigger]] | Touch beside your head to toggle the flashlight after it is unlocked. |

![SOMA VR default controls](Soma-controls-1.jpg)

The Omni-Tool belongs over your right shoulder and eligible key items over
your left. Bring a held item behind the matching shoulder and release grip
to stow it. To retrieve it, reach behind that shoulder, wait for the haptic
cue, then press and hold grip as you bring your hand forward. Loose props
and documents cannot be stored this way.

![SOMA VR storage and gestures](Soma-controls-2.jpg)

## Troubleshooting and removal

- An immediate injection crash can mean the active runtime is not OpenXR. Check the headset connection and SteamVR's OpenXR setting.
- If the menu cursor is absent, focus the SOMA window on the desktop; recenter if menus appear misplaced.
- For an unrecognized or changed executable, use the publisher's `Check-SOMA-VR-Compatibility.cmd` and its compatibility report. An experimental engine-equivalent result is not a verified store port.
- When reporting a failure, include `hpl3vr.log` from the game root and `hpl.log` from `Documents\My Games\Soma\Main`, along with the map, steps, headset and runtime. A crash log may also be in the game root.
- To remove the publisher mod, close SOMA and restore the original files from your pre-install backup or verify the store files. Store verification alone may leave added VR files; compare them with the publisher's `SOMA_VR_MANIFEST.json` and remove only positively identified additions. Preserve saves, settings and unrelated files. The Hub currently offers this guide rather than an automatic delete because publisher Setup owns the file set and its backups.

[Publisher installation and troubleshooting](https://github.com/Bateau01/SOMA-VR/blob/main/docs/INSTALLATION.md) · [Features and limitations](https://github.com/Bateau01/SOMA-VR/blob/main/docs/FEATURES.md)

The ocean is deep. The existential questions are deeper.
