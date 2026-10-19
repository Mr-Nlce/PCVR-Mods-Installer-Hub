# Fallout 3 VR

## About the Game

Fallout 3 is an open-world role-playing game set around Vault 101 and the Capital Wasteland. THEwill2002's experimental PC VR launcher adds stereo rendering, head tracking, controller movement and tracked weapons. The package is an alpha test candidate, with visible gaps and startup issues still under investigation.

## Requirements and installation

**Publisher-confirmed route: the Steam PC game at build 1.7.0.4 on Windows x64.** The Hub detects Steam GOTY and Standard folders with `Fallout3.exe` and `Data/Fallout3.esm`. The Epic, GOG, Xbox and retail paths supplied for the base game are not automatically offered because the publisher launcher rejects unconfirmed executables. Keep Steam signed in; first run the flat game once and close it. Connect the headset through Virtual Desktop or SteamVR and wake both controllers.

1. Choose [[Get Installer]], read the requirements, then press Enter to locate the Steam game. A second Enter checks the latest GitHub release **including prereleases**.
2. The Hub extracts the whole official ZIP into a separate writable launcher folder under `%LOCALAPPDATA%/Programs/Fallout3VR`. It sets the verified game path in `settings.json` and runs the publisher check. A missing `FalloutPrefs.ini` or OpenXR runtime is reported as a **start prerequisite** and does not discard an otherwise complete installation. Unsupported game builds or incomplete publisher files still stop setup with the publisher's specific error. No mod DLL is permanently copied into the game by the Hub; the publisher launcher uses a temporary session and recovery journal.
3. Choose [[Start in VR]]. The Hub opens the publisher launcher with its **HD** profile. The current publisher release says UHD startup is broken; do not use `Launch-UHD.cmd` or an UHD profile. Quit the game normally so the publisher launcher can restore its temporary files.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move relative to the headset. |
| [[Right Stick]] | Turn; in menus move the pointer. |
| [[Right Trigger]] | Fire or use the native attack; in menus confirm. |
| [[A]] | Interact with the gaze-targeted object; confirm in menus. |
| [[X]] | Reload or ready an item; in the Pip-Boy cycle Stats, Items and Data. |
| [[Y]] | Open the Pip-Boy; in menus go back or close. |
| [[B]] | Jump; with [[Right Grip]] pause or send Escape. |
| [[Both Grips]] hold for one second | Recenter. |
| [[Left Grip]] near a supported weapon | Attach and hold the support hand. |
| [[F10]] | Recenter from the keyboard. |
| [[Ctrl]] + [[T]] | Toggle smooth and snap turning. |
| [[Ctrl]] + [[U]] | Show or hide the gameplay HUD. |

During lockpicking, [[Right Stick]] positions the pin, [[A]] or [[Right Trigger]] turns the lock, and [[B]] or [[Y]] exits. The publisher's `CONTROLS.md` inside the installed launcher has more diagnostic keys.

## Limits and troubleshooting

The Pip-Boy can be misaligned, water reflection is simplified, fast rotation can expose missing edge pixels, and some geometry/shaders are still being fixed. The optional prologue fallback is a floating native view; it does not provide normal VR aiming. This alpha's UHD profile can hang; Hub Start in VR forces HD. The publisher launcher stores backups and logs under `%LOCALAPPDATA%/Fallout3VR` and supports `--recover` after an interrupted session. If startup fails, keep that journal and use the launcher recovery route before removing files. The Hub cannot certify headset image or game stability without a live Steam session.

If the headset image wavers, keep the publisher's HD profile and confirm that Virtual Desktop or SteamVR is the active OpenXR runtime with both controllers awake. The publisher documents alternating-eye rendering and limited reprojection; it does not provide a verified graphics setting that removes this effect. Do not switch to the broken UHD profile as a workaround. To report a visible defect, press [[F8]] once while it is on screen, then close the game and run `Collect-Diagnostics.cmd` in the publisher launcher folder. Send the resulting report privately because it can contain local paths and a Windows username.

## Updates and removal

The Hub checks prereleases, validates the complete payload and writes the selected version only after installation proof. [[Uninstall now]] removes unchanged Hub-owned launcher files; the Steam game, saves, modified settings and publisher recovery data remain. Close the game and launcher before updating or removing. Do not delete the publisher recovery journal during an interrupted game session.

## Links

[Publisher](https://github.com/THEwill2002/Fallout3VR) · [Releases](https://github.com/THEwill2002/Fallout3VR/releases) · Join [Flat2VR Modding](https://discord.gg/uAeQkYBM4n), then read the [Fallout 3 thread](https://discord.com/channels/747967102895390741/1556723560389677126) · [VR gameplay](https://www.youtube.com/watch?v=o7bqkWxE4GU)

>>> Step out of the Vault and look around.
