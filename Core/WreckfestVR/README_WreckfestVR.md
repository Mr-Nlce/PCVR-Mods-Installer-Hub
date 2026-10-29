# Wreckfest VR

## About the Game

Demolition racing with native OpenXR stereo cameras, head tracking, cockpit positioning and a configurable HUD. The publisher launcher prepares the mod and exposes resolution, input and diagnostic options.

## What you need

- Steam Wreckfest x64, build 16986367 exactly. The publisher rejects other executable builds. GOG, Epic, Xbox and the 32-bit EXE are not supported by this integration.
- A connected PC VR headset and active OpenXR runtime. SteamVR is publisher-tested; other runtime combinations remain unverified.
- A wheel, gamepad or keyboard. Motion-controller driving is not implemented.

## Install and start

1. Choose [[Install]] in the Untested VR Mod Installers area. The Hub identifies your Steam game and records its existing files before any VR changes.
2. When prompted, open the publisher launcher. Click Open Mod and let it prepare the supported game. If needed use Game & diagnostics > Locate game and select Wreckfest_x64.exe. Close the launcher and return to the installer for verification.
3. Choose [[Start in VR]] in the Hub. Click Open Mod, set resolution and connect your headset, then click Launch in VR. The Wreckfest VR desktop shortcut opens the same launcher.
4. Test a short race. Use Provide feedback on the tile or detail page; it opens the GitHub template and the Hub report folder. Attach this game test-result.txt and describe what worked or failed.

## Controls

| Button | Action |
| --- | --- |
| [[Gamepad]] / [[Wheel]] / [[Keyboard]] | Original driving inputs are unchanged. |
| [[F3]] | Toggle race HUD; menus remain visible. |
| [[F6]] / [[F7]] | Smaller / larger HUD. |
| [[Shift]] + [[F6]] / [[Shift]] + [[F7]] | Closer / farther HUD. |
| [[F10]] | Default seated recenter binding. |
| [[W]] / [[A]] / [[S]] / [[D]] | Move manual camera offset. |
| [[+]] / [[-]] | Raise / lower manual camera offset. |
| [[Shift]] / [[Ctrl]] | Faster / slower camera movement. |
| [[F8]] | Reset manual camera offset. |

Controls > Change accepts a keyboard key or digital gamepad/wheel button for recenter, then Save. Analog axes and triggers are not captured. Keep the game focused. HUD visibility and recenter changes apply live; render-target and panel sizes need restart. Camera keys retain their original game actions.

## Help

This is an Untested installer, separate from regular search, Explore, banners and Similar Games until explicitly approved. The Hub records before/after game-folder files and the installer log in Core\Logs\Untested. The launcher preserves INI settings and bindings, refuses an unrelated version.dll, and retains its own backups in %LOCALAPPDATA%\WreckfestNativeVR\backups. A supported-build rejection cannot be fixed by selecting another store EXE. No invented Depot route is offered.

Unsigned VR files may trigger protection warnings. Missing files can also indicate a copy, path or permissions problem; inspect the log and protection history before assigning a cause. The installer provides Retry and manual-file recovery.

## VR files

[Game and VR folder](.) contains [Wreckfest_x64.exe](Wreckfest_x64.exe), the [publisher launcher](WreckfestVRLauncher.exe), [WreckfestNativeVR.asi](WreckfestNativeVR.asi), [version.dll](version.dll) and [WreckfestNativeVR.ini](WreckfestNativeVR.ini). The Hub uses [Start-VR.ps1](PCVR-Launcher/Start-VR.ps1) to open WreckfestVRLauncher.exe with this folder as working directory. The launcher offers Launch in VR and Launch flat. The Hub Flat / VR button opens these publisher choices; it does not silently change your running game. Launcher-owned backups and runtime caches remain separate under %LOCALAPPDATA%\WreckfestNativeVR.

The VR files folder and start app will appear here as links once the VR mod installation is present. If the Hub does not find your game, you can choose Locate Game to select it manually.

## Discord discussion & support

- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [This mod discussion](https://discord.com/channels/747967102895390741/1563524138864222328)

## Links

- [Publisher project](https://github.com/sqofer/WREACKFEST-VR)
- [Official releases](https://github.com/sqofer/WREACKFEST-VR/releases)
- [Creator game: CYBRID](https://store.steampowered.com/app/1636850/CYBRID/)
- [VR gameplay](https://www.youtube.com/watch?v=Yo-dVs2Dpnc)

>>> The racing line is whichever barrier gives way first.
