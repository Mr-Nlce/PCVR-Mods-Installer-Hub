# GRID Legends VR

## About the Game
Join Seneca Racing in a dramatic motorsport campaign, then build custom race events across city streets and circuits. GRID Legends combines varied racing classes with a live-action story. CodiesVR adds an immersive cockpit, adjustable HUD and OpenXR head tracking.

## What you need
- Windows Steam or EA app edition. The Steam edition also needs its EA account and EA app.
- A connected PC VR headset and active OpenXR runtime supporting the game's graphics API. Virtual Desktop's VDXR is preferred where supported; starting a Steam game does not require using SteamVR as the OpenXR runtime.
- A gamepad or steering wheel. These mods add head tracking, without motion-controller driving.
- Run the game to its main menu once and exit before VR setup. The Hub offers a guided normal start if its graphics settings are missing.

## Install and start
1. Choose [[Install]]. The Hub shows your game folder, checks its first-run settings and downloads the current ZIP specifically for this game. Other CodiesVR games can have a different newest version.
2. Continue to install. Existing files are backed up; saves, mod INIs and other user configuration are preserved. A separate ownership manifest supports safe update and removal.
3. Use [[Start in VR]] in the Hub with the headset connected and OpenXR ready. Alternatively start normally through Steam or the EA app.
4. Optional upscaling: Settings > Install Optiscaler downloads the publisher custom package. Select XeSS as the game input, then choose the supported output in OptiScaler. Finish or skip the manual DLSS ZIP prompt, wait for completion and close/restart when asked. AFW is optional, off by default and still experimental; ordinary upscaling does not require it. The optional installer can overwrite matching optional-component INIs and keeps separate publisher backups.
5. This is an Untested Hub installer. File inventories before and after installation, differences and the installer log are saved in Core\Logs\Untested. Play a few minutes, choose Provide feedback above the installed tile or on this page, then drag the selected grid-legends-vr-test-result.txt into Installer log on GitHub. Review private details before sharing; numbered retries preserve older reports.

## Controls
Defaults can be rebound in the mod's Hotkeys tab. The game window must have focus.

| Button | Action |
| --- | --- |
| [[F10]] | Open or close the VR menu |
| [[F5]] | Release to recenter; hold for one second to capture the home position |
| [[F6]] | Capture the driving position |
| [[F7]] | Reset the driving-position offset |
| [[F8]] | Hide or restore the race HUD |
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
[Game and VR mod folder](.) contains [GridLegends.exe](GridLegends.exe) and [d3d12.dll](d3d12.dll). Steam copies use the store bootstrap when you choose Start in VR; GridLegends.exe is the game executable, not an extra manual step.

[Publisher package and guides](_vrmods/CodiesVR) retains the full downloaded package. [Publisher Setup](_vrmods/CodiesVR/GridLegendsVR-Setup.bat) is available there for its separate optional tools; routine Hub update and Uninstall now use the Hub ownership manifest. Avoid mixing the publisher uninstaller with a Hub-managed deployment.

[Mod settings](gridvr12.ini) and [Mod log](codiesVR.log) appear after the first mod run. The saved recenter origin is gridvr_origin.ini. The game's original graphics settings backup is hardware_settings_config.xml.gridvr-backup in Documents\My Games\GRID Legends\hardwaresettings. These links activate only for existing installed targets; Locate Game can help if automatic discovery misses your copy.

## Discord discussion & support
- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [This game's CodiesVR discussion](https://discord.com/channels/747967102895390741/1556898585646334052)

## Support drowhunter
- [Support the modder on Ko-fi](https://ko-fi.com/drowhunter)

## Links
- [CodiesVR project](https://github.com/drowhunter/CodiesVR)
- [Current game-specific downloads](https://github.com/drowhunter/CodiesVR/releases)
- [Watch VR gameplay](https://youtu.be/0qrRPZz_6jI?t=89)

Seneca hired a driver. The barriers got a demolition crew.