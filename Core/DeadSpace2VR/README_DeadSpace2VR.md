# Dead Space 2 VR

## About the Game

Isaac Clarke escapes a Necromorph outbreak aboard the Sprawl. Chortdev's experimental mod adds stereo VR, tracked weapons, physical melee, manual reloads and motion controls to the Steam and EA app versions.

## What you need

- Windows 10/11 x64, the Steam or EA app game, a Vulkan-capable GPU and two tracked controllers through SteamVR.
- Close the game and SteamVR before installing or updating. Start SteamVR again before playing.
- This is WIP and CPU-bound: even strong PCs can run around 40–50 FPS. Lowering headset resolution cannot remove a CPU bottleneck.

## Install and start

1. Choose [[Install]] in the Hub. The installer shows the game folder and selects the matching Steam or EA package. For an unrecognized custom folder, choose the store explicitly.
2. On Windows 11, the Hub also installs MarkerPatch. It disables FixSuitChangeTiming, FixHazardSuitIcon, RawMouseInput, AutoHideMouseCursor, ImprovedAntiAliasingMode and AchievementSupport for VR compatibility. Other existing MarkerPatch options and personal VR INIs are preserved. Existing MarkerPatch installations on Windows 10 receive the same compatibility settings.
3. Connect the headset, start SteamVR, then choose [[Start in VR]] in the Hub. Steam copies launch through Steam; EA copies start deadspace2.exe. Starting through the matching store is an alternative.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move. |
| [[Left Stick Click]] | Sprint; boost in zero gravity. |
| [[Right Stick]] | Turn. |
| [[Left Stick Click]] + [[Right Stick Click]] | Open a centered pause menu. |
| [[Right Grip]] | Aim; reach over the shoulder or to the hip to change weapons. |
| [[Right Trigger]] | Fire. |
| [[B]] | Alternate fire while aiming. |
| [[Right Stick Click]] | Reload. |
| [[Left Grip]] | Kinesis grab; grab the glowing weapon component for supported manual reloads. |
| [[Left Trigger]] | Throw a kinesis object; activate the held health or stasis pack. |
| [[Y]] | Stasis. |
| [[Left Grip]] | Reach to the hip for a pack; reach to the temple for inventory. |
| [[A]] | Use; confirm a menu choice. |
| [[B]] | Back in menus. |
| [[X]] | Hold for the locator; [[Left Trigger]] or [[Left Grip]] changes the destination. |
| [[Left Trigger]] | Point and click in menus. Either stick also navigates. |
| [[Left Trigger]] + [[Right Trigger]] | Take off or land in zero gravity. Move with [[Left Stick]] and steer with your head. |

Swing your arm for melee. Non-Quest controller layouts can be remapped in Settings > VR Settings > Controller buttons; hold the prompted button for five seconds.

## Help

- Use Settings > VR Settings for comfort, controller and rendering options. The publisher's ds2stereo.log also lists available settings.
- Zero-gravity stations need station_vr=1. Setting it to 0 disables stations and some related features.
- If the Vulkan path crashes, the publisher suggests clearing real_d3d9 and trying vr_transport=cpu in ds2stereo.ini.
- Oversized menus: set Window.Width=1920 and Window.Height=1080 in the game's settings.txt under %LOCALAPPDATA%\EA Games\Dead Space 2.
- MarkerPatch startup problems may require Microsoft's Visual C++ x86 runtime. Missing files alone do not establish antivirus involvement; use the installer log and Windows Protection History first.
- If the original game crashes before its menu, MarkerPatch also includes the fix for CPUs with more than ten cores. The VR installer installs it on Windows 11. Keep HighCoreCPUFix enabled in MarkerPatch.ini; a flat startup crash must be resolved before testing VR.

## VR files

The VR files are beside deadspace2.exe: d3d9.dll, openvr_api.dll, dxvk_d3d9.dll, the ds2 data/helper files and configuration INIs. MarkerPatch adds dinput8.dll, MarkerPatch.ini and its support files in the same folder. Steam launches via steam://rungameid/47780; EA uses deadspace2.exe. The Hub shows verified folder and start links after the VR mod installation. If a scan misses your game, you can choose [[Locate Game]].

## Discord discussion & support

- [Join Flat2VR](https://discord.gg/uAeQkYBM4n)
- [Dead Space 2 VR discussion](https://discord.com/channels/747967102895390741/1546924467832225863)

## Donations

- [Support chortdev on Patreon](https://www.patreon.com/chortdev/)
- [Support chortdev on Boosty](https://boosty.to/chortdev)
- [Author's USDT ERC20 address](https://etherscan.io/address/0xB1C5A0da905a198026c813d1FE7C93A08DcEb2e1)

## Links

- [Official VR mod and troubleshooting](https://github.com/chortdev/DeadSpace2VR)
- [Publisher releases](https://github.com/chortdev/DeadSpace2VR/releases)
- [MarkerPatch](https://github.com/Wemino/MarkerPatch)
- [Microsoft Visual C++ x86 runtime](https://aka.ms/vs/17/release/vc_redist.x86.exe)
- [VR gameplay](https://www.youtube.com/watch?v=dK3brwnZN0o)

## Uninstall guide

Close the game and SteamVR, then choose [[Uninstall now]]. The Hub removes unchanged files it installed and restores earlier same-name files. Edited INIs, saves, generated logs and unrelated files remain. An edited MarkerPatch.ini is retained rather than overwritten during removal.

Cut off their limbs. The rest is just paperwork.
