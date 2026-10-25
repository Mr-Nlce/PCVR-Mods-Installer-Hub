# Alan Wake VR

## About the Game

Alan Wake is a story-driven action thriller set around Bright Falls. fholger's mod brings the original PC game into seated, third-person VR with six-degree-of-freedom head tracking and synchronized stereo rendering. Gameplay and the game's usual gamepad or keyboard-and-mouse controls remain unchanged. Motion controls are not part of this first release.

## What you need

- The **original Alan Wake** from Steam, GOG or Epic Games on Windows. The publisher does not support Alan Wake Remastered, Xbox/Microsoft Store, DVD or other editions.
- A connected PC VR headset and the correct active OpenXR runtime. **Meta Horizon Link currently does not work** with this mod. Quest owners should use Steam Link or Virtual Desktop.
- Close Alan Wake before installing, updating or removing the mod.

The Hub uses the current stable [Alan Wake VR GitHub release](https://github.com/fholger/alanwake_vr/releases). The publisher Setup contains `d3d9.dll`, a large-address-aware patcher, its README and a game-folder uninstaller. The Hub runs that Setup, verifies its required output and only then records the installed version. Windows may ask for administrator approval. Existing files that the Setup may replace are backed up before it opens.

## Install and start

1. Choose [[Install]] on the Alan Wake tile. The Hub locates the original Steam, GOG or Epic game, downloads the current publisher Setup and shows its selected folder. In the publisher Setup, point to that **same folder containing `AlanWake.exe`** and complete installation.
2. Connect your headset and select its OpenXR runtime. Quest owners should use Steam Link or Virtual Desktop.
3. Choose [[Start in VR]] in the Hub. A Steam installation starts through Steam; GOG and Epic installations start the selected `AlanWake.exe`. The mod should enter VR when the game launches.

The linked video is **ordinary Alan Wake gameplay**, because a VR gameplay video has not yet been supplied for this mod.

## Controls

The publisher says the game's existing gamepad and keyboard-and-mouse controls are unchanged. Play seated; motion controllers are not supported in this release.

## Removal and troubleshooting

Choose [[Uninstall now]] to run the publisher's uninstaller and restore the original files recorded before Hub installation. The Hub pauses removal if one of its recorded files was changed later, so it cannot overwrite that change without review. Your game, saves, settings and unrelated files remain.

If the game starts flat, check that `d3d9.dll` exists beside `AlanWake.exe`, the headset is connected, and the selected OpenXR runtime is active. A missing file does not by itself prove antivirus quarantine; check the installer log and Windows protection history before changing security settings.

## Links

- [Publisher's Alan Wake VR page](https://alanwake.vrmods.eu/)
- [Official source and releases](https://github.com/fholger/alanwake_vr)
- [Flat2VR community thread](https://discord.com/channels/747967102895390741/1561105393508294797)
- [Patreon support for fholger](https://www.patreon.com/cw/fholger)
- [Ko-fi support for fholger](https://ko-fi.com/fholger)
- [Alan Wake VR gameplay](https://www.youtube.com/watch?v=Lx8D8wnEiyE)

The darkness has a new dimension.
