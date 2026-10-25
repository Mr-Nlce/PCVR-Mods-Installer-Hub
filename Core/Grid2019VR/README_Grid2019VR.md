# GRID (2019) VR

## About the Game
Compete in wheel-to-wheel motorsport across street circuits and permanent tracks. GRID (2019) mixes touring cars, GT racers and muscle cars with rivals who remember your racing line. CodiesVR brings a head-tracked cockpit to its DirectX 12 version.

## What you need
- Windows Steam edition of GRID (2019), using DirectX 12. The original GRID, GRID 2 and GRID Autosport are different games.
- A connected PC VR headset and active OpenXR runtime supporting the game's graphics API. Virtual Desktop's VDXR is preferred where supported; starting a Steam game does not require using SteamVR as the OpenXR runtime.
- A gamepad or steering wheel. These mods add head tracking, without motion-controller driving.
- Run the game to its main menu once and exit before VR setup. The Hub offers a guided normal start if its graphics settings are missing.

## Install and start
1. Choose [[Install]]. The Hub shows your game folder, checks its first-run settings and downloads the current ZIP specifically for this game. Other CodiesVR games can have a different newest version.
2. Continue to install. Existing files are backed up; saves, mod INIs and other user configuration are preserved. A separate ownership manifest supports safe update and removal.
3. Use [[Start in VR]] in the Hub with the headset connected and OpenXR ready. Alternatively start normally through Steam.
4. Choose DirectX 12 whenever Steam offers the launch-mode choice. Only Grid_dx12.exe loads this mod. The DirectX 11 Grid.exe cannot enter VR.
5. This is an Untested Hub installer. File inventories before and after installation, differences and the installer log are saved in Core\Logs\Untested. Play a few minutes, choose Provide feedback above the installed tile or on this page, then drag the selected grid-2019-vr-test-result.txt into Installer log on GitHub. Review private details before sharing; numbered retries preserve older reports.

## Controls
Defaults can be rebound in the mod's Hotkeys tab. The game window must have focus.

| Button | Action |
| --- | --- |
| [[Insert]] | Open or close the VR menu |
| [[Home]] | Release to recenter; hold for one second to capture the home position |
| [[End]] | Capture the driving position |
| [[Page Down]] | Reset the driving-position offset |
| [[Page Up]] | Hide or restore the race HUD |
| [[Left Stick Click]] + [[Right Stick Click]] | Open or close the VR menu |
| [[Left Stick Click]] | Release to recenter; hold for one second to capture the home position |
| [[LB]] / [[RB]] | Switch between VR-menu tabs |
| [[Mouse Wheel]] | Adjust the hovered slider |
| [[Ctrl]] + [[Mouse Wheel]] | Adjust the hovered slider in smaller steps |
| [[Esc]] | Cancel a key rebinding |

[[Left Stick Click]] + [[Right Stick Click]] gestures can be disabled. Optional [[Right Stick Click]] HUD toggling is off by default, so it does not compete with game controls. Capturing a home position prompts you to sit back and release to recenter. Save settings after changing bindings.

## Picture and performance
Menus appear on a virtual screen; driving uses the cockpit view. Alternate-eye stereo updates each eye at half the game frame rate and can shimmer in fast movement. Lower render resolution or graphics detail if needed. Mono mode is smoother but has no stereo depth.

Prefer VDXR where supported if SteamVR movement produces ghosting or double images. If motion still looks wrong, try disabling the runtime's own motion smoothing/reprojection. Leave ordinary desktop frame generation off in alternate-eye stereo. Choose render resolution in the mod menu, then accept its restart prompt; do not resize the desktop mirror to set headset resolution.

The mod saves its own settings beside the game and backs up the original graphics XML before editing it. Existing Documents paths, including redirected folders, are respected. The Hub preserves those files and backups on removal so your tuning is not lost.

## VR files and updates
[Game and VR mod folder](.) contains [Grid_dx12.exe](Grid_dx12.exe) and [d3d12.dll](d3d12.dll). Steam copies use the store bootstrap when you choose Start in VR; Grid_dx12.exe is the game executable, not an extra manual step.

[Publisher package and guides](_vrmods/CodiesVR) retains the full downloaded package. [Publisher Setup](_vrmods/CodiesVR/Grid2019VR-Setup.bat) is available there for its separate optional tools; routine Hub update and Uninstall now use the Hub ownership manifest. Avoid mixing the publisher uninstaller with a Hub-managed deployment.

[Mod settings](gridvr12.ini) and [Mod log](codiesVR.log) appear after the first mod run. The saved recenter origin is gridvr_origin.ini. The game's original graphics settings backup is hardware_settings_config.xml.gridvr-backup in Documents\My Games\GRID (2019)\hardwaresettings. These links activate only for existing installed targets; Locate Game can help if automatic discovery misses your copy.

## Discord discussion & support
- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [This game's CodiesVR discussion](https://discord.com/channels/747967102895390741/1560414504293109892)

## Support drowhunter
- [Support the modder on Ko-fi](https://ko-fi.com/drowhunter)

## Links
- [CodiesVR project](https://github.com/drowhunter/CodiesVR)
- [Current game-specific downloads](https://github.com/drowhunter/CodiesVR/releases)
- [Watch gameplay](https://youtu.be/aMSJbJNCI8s?t=64)

Your nemesis has requested a less personal racing line.