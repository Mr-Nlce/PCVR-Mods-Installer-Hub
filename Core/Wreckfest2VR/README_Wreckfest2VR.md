# Wreckfest 2 VR

## About the Game

Wreckfest 2 gains stereoscopic cockpit rendering and head tracking through a standalone OpenXR app. Menus and loading screens use a flat panel, while the cockpit becomes stereo once an offline race and headset are ready.

## What you need

- Your Steam copy of Wreckfest 2, supported game build released 2026-10-22. Both game and mod are early access.
- The publisher tested Meta Quest 3 through Virtual Desktop / VDXR. Other headset/runtime combinations are unverified.
- A wheel, gamepad or keyboard; this mod does not add motion-controller driving.

## Install and start

1. Choose [[Install]] in Untested VR Mod Installers. The Hub records the game-folder contents, installs the standalone VR app and saves the before/after inventory plus installer log.
2. Connect through Virtual Desktop with VDXR, then choose [[Start in VR]] in the Hub. The VR app opens first and the game starts normally through Steam. The Wreckfest 2 VR desktop shortcut performs the same actions.
3. Load an offline race, enter cockpit view and resume. With automatic start enabled, VR begins when ready; otherwise click Start VR. Sit forward and press [[F8]] to recenter.
4. After testing, use Provide feedback. Attach the matching test-result.txt from the Hub report folder to the opened GitHub template.

## Controls

| Button | Action |
| --- | --- |
| [[Gamepad]] / [[Wheel]] / [[Keyboard]] | Use the original game driving controls. |
| [[F6]] | Cycle All / HUD only / None. |
| [[F7]] | Switch flat panel / stereo manually. |
| [[F8]] / [[Brake Alt]] | Recenter; Brake Alt also performs its original game action. |
| [[F10]] | Toggle head tracking. |

For a steering-wheel recenter button, bind Brake Alt in the game and leave Brake Alt recenters view enabled in the VR app. In Settings > Gameplay, the publisher recommends 0% camera shake strength, 1st person horizon stability and cockpit g-effects. Raise game graphics resolution for sharper VR while watching performance. Track changes can still crash; restart the game after a game/GPU crash before retrying.

## Help

Keep the VR app running for VR play. Stop VR leaves the game open and suspends auto-start; click Start VR or toggle auto-start off/on to resume. The Hub Flat / VR switch changes the next launch: close the VR app before flat play. It never kills your running game. Game updates can invalidate this build-specific mod; a dated build requirement is not proof that a Steam Depot is currently available.

Unsigned VR files may trigger protection warnings. Missing files can also indicate a copy, path or permissions problem; inspect the log and protection history before assigning a cause. The installer provides Retry and manual-file recovery.

## VR files

[Game and VR folder](.) contains [Wreckfest2.exe](Wreckfest2.exe), [Wreckfest2VR.exe](Wreckfest2VR.exe) and the [Hub launch controller](PCVR-Launcher/Start-VR.ps1). [launch.json](PCVR-Launcher/launch.json) selects this Steam copy, started through steam://rungameid/1203190. The VR app injects while running; its presence does not imply game files were patched. Flat / VR is stored in [.pcvrhub_wreckfest2_mode.ini](.pcvrhub_wreckfest2_mode.ini). Publisher settings are separate at %LOCALAPPDATA%\WF2VR\settings.ini; Open settings and Open reports in the app expose those folders. Hub test reports are stored in Core\Logs\Untested.

The VR files folder and start app will appear here as links once the VR mod installation is present. If the Hub does not find your game, you can choose Locate Game to select it manually.

## Discord discussion & support

- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [This mod discussion](https://discord.com/channels/747967102895390741/1563456530467135529)

## Links

- [Publisher project](https://github.com/MatsKarlsson/Wreckfest2VR)
- [Official releases](https://github.com/MatsKarlsson/Wreckfest2VR/releases)
- [VR gameplay](https://youtu.be/B8o2Ad7T_yE?t=91)

>>> Your insurance premium has entered early access.
