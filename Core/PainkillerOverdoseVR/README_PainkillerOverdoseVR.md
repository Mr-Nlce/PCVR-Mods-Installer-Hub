# Painkiller: Overdose VR

## About the Game

Painkiller: Overdose is a fast, gothic first-person shooter built around large enemy waves, aggressive movement and an arsenal of supernatural weapons. This conversion adapts the original Painkiller VR project specifically for Overdose.

## What this mod adds

- Stereoscopic OpenXR rendering
- Headset tracking and motion-controlled weapons
- A standalone VR launcher that leaves `Bin\Overdose.exe` available for Flat play
- Support tested by the publisher on Quest 2 and Quest 3, with other OpenXR headsets expected to work

The Hub follows the newest stable release from [STR_Paragor's GitHub repository](https://github.com/STRParagor/painkiller-overdose-vr). The project is also presented on [ModDB](https://www.moddb.com/mods/painkiller-overdose-vr).

## Before installing

The VR launcher is incompatible with other Painkiller: Overdose modifications. When it starts, it deliberately deletes `Data\LScripts` and `Data\Textures` if those folders exist. This is required by the publisher's runtime. Back up custom files in those folders before the first VR launch.

The launcher is not digitally signed, so security software may inspect it. The installer checks whether its required files remain present, but a missing file is not automatically blamed on antivirus software.

## Installation and launch

Install Painkiller: Overdose through Steam or GOG, then run the Hub installer. It places the official publisher files in the game root beside `Bin` and `Data` and creates a stable Hub launcher.

1. Connect the headset through Virtual Desktop, Steam Link or Meta Horizon Link.
2. Use **Start in VR** on this page.
3. The first launch can take from 30 seconds to 5 minutes while the publisher launcher prepares game files. Later launches should be much faster.

For Flat play, start `Bin\Overdose.exe` directly or use the normal store route.

## Controls

This build is adapted from Painkiller VR 0.1.9 and inherits its motion-control layout. Headset runtimes may label buttons slightly differently.

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Right Stick]] | Turn |
| [[Right Stick Up Click]] | Jump |
| [[Right Trigger]] or [[Left Trigger]] | Primary fire |
| [[Right Grip]] or [[Left Grip]] | Alternate fire |
| [[A]] | Previous weapon / zoom out |
| [[B]] | Next weapon / zoom in |
| [[Y]] | Menu |

## Troubleshooting and community

- [Painkiller Club Discord](https://discord.gg/cQXyuZEkHC)
- [Painkiller Club on VK](https://vk.ru/painkillerclub)
- [STR_Paragor on VK](https://vk.ru/str_paragor)
- [Painkiller Russian Community on ModDB](https://www.moddb.com/company/painkiller-russian-community)

If Meta Horizon Link no longer starts the game, use Virtual Desktop or Steam Link first. The publisher also documents a legacy Meta PC runtime workaround in the packaged English readme; follow that external workaround only if you understand that it replaces Meta software files.

## Uninstall

Use **Uninstall now** on this page. It removes only unchanged Hub-owned launcher and readme files, restores any pre-existing file collisions and preserves the game, saves, settings and unrelated files. It cannot reconstruct `Data\LScripts` or `Data\Textures` if the publisher launcher already deleted them.
