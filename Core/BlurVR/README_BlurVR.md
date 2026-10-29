# Blur VR

## About the Game

Blur combines licensed cars with arcade racing and power-up combat. BlurVR adds seated stereo racing, head tracking, a 3D rear-view mirror and floating menu screens while retaining the original driving controls.

## What you need

- Your own installed 32-bit Windows PC copy of Blur. Steam and retail copies are supported; the game is no longer sold.
- A SteamVR headset. OpenVR is the default; optional OpenXR requires an existing 32-bit runtime.
- A gamepad, wheel or keyboard. Motion-controller driving is not added.

## Install and start

Untested installer: installation and removal are checked with isolated files, but a working VR game session has not been confirmed. Use the feedback form after trying it on your own game.

1. Choose [[Install]]. The Hub searches Steam; otherwise select Blur.exe with Locate Game or drag its EXE/folder into the installer.
2. The complete publisher BlurVR folder is installed and its proxy is placed next to Blur.exe. Existing settings and replaced files are preserved.
3. Start SteamVR and choose [[Start in VR]] in the Hub. Genuine Steam copies start through Steam; retail copies start their own Blur.exe. The Blur VR desktop shortcut follows the same route.
4. In Options > Graphics > Resolution, choose an appropriate headset size. Start small, then raise it while performance stays smooth. VR begins as the first level loads.

## Controls

| Button | Action |
| --- | --- |
| [[Gamepad]] / [[Wheel]] / [[Keyboard]] | Original driving and menu controls remain unchanged. |
| [[F9]] | Recenter while seated and looking forward. |
| [[F10]] | Toggle head tracking. |
| [[F8]] | Cycle automatic / forced menu / forced race mode. |
| [[Num6]] | Toggle the 3D mirror. |
| [[Num7]] | Toggle timing diagnostics. |
| [[Num8]] | Save headset picture files for diagnostics. |
| [[Num9]] | Toggle FPS counter. |

The Hub Flat / VR switch uses the publisher Stereo option. Flat mode leaves SteamVR off and restores the normal game display size. On updates, your BlurVR.ini and resolution choices remain. On removal, unchanged Hub files are removed and earlier files restored; generated logs and display backups remain.

## Help

The desktop window may only say Playing in VR. Keep it focused for keyboard/gamepad input; closing it quits the game. Menus are intentionally shown on a flat panel. For optional OpenXR set Api=openxr under [VR] in BlurVR.ini and select a 32-bit runtime. VDXR has a separate virtualdesktop-openxr-32.json; a 64-bit runtime cannot load into Blur. Set Api=openvr to return to the default. A modder-reported VDXR showroom crash was resolved by a manual Large Address Aware / 4 GB patch; the Hub does not patch your game EXE.

Unsigned VR files may trigger protection warnings. Missing files can also indicate a copy, path or permissions problem; inspect the log and protection history before assigning a cause. The installer provides Retry and manual-file recovery.

## VR files

[Game and VR folder](.) contains [Blur.exe](Blur.exe) and the [VR files folder](BlurVR). The root [d3d9.dll](d3d9.dll) loads the mod; [BlurVR.ini](BlurVR/BlurVR.ini) holds its settings. The Hub uses [Start-VR.ps1](PCVR-Launcher/Start-VR.ps1) and [launch.json](PCVR-Launcher/launch.json), with the game folder as working directory. Steam uses steam://rungameid/42640; retail uses Blur.exe. Flat / VR changes General.Stereo (0 / 1) while retaining the installed mod. [BlurVR.log](BlurVR/BlurVR.log) appears only with General.Log=1.

The VR files folder and start app will appear here as links once the VR mod installation is present. If the Hub does not find your game, you can choose Locate Game to select it manually.

## Discord discussion & support

- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [This mod discussion](https://discord.com/channels/747967102895390741/1563206420143407255)

## Links

- [Publisher project](https://github.com/TwoAyEm/BlurVR)
- [Official releases](https://github.com/TwoAyEm/BlurVR/releases)
- [VR gameplay](https://youtu.be/-Gwqe6Wcjd8?t=41)

>>> Indicators are optional. Shunts are not.
