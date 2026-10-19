# Journey VR

## About the Game

Journey is an atmospheric trek through a desert and its ruins. The same publisher DLL used for Flower now adds stereo rendering, head tracking and motion controls to the Steam version of Journey. Journey support is still alpha: the title, menus and most cutscenes appear on a virtual screen, while exploration plays in VR.

## What you need

- Your own Steam copy of Journey (Steam app 638230) on Windows. If only an Epic installation is found, the Hub can offer it as an explicitly unconfirmed experimental route; the publisher has documented and tested Steam only.
- SteamVR selected as the active OpenXR runtime, with the headset connected before starting. The publisher tested Steam Frame through Steam Link and PSVR2 through its PC adapter.
- On Steam Frame, connect Steam Link VR when launching. Without an active headset connection, Journey can wait on a black screen.

The Hub selects the current stable release of [flower_vr](https://github.com/jeffMeador/flower_vr/releases). Its `d3d11.dll` supports Journey even though Journey gameplay is labelled alpha. It also copies your own `C:\Windows\System32\d3d11.dll` into the game folder as `d3d11_orig.dll`, so the proxy can forward normal Direct3D calls. The two files belong beside `Journey.exe`.

## Install and start

1. Choose [[Install]] in the Hub. It locates the Steam game first, or offers the Epic folder only when no Steam copy is found. It downloads the publisher DLL and installs both required DLLs with a recoverable ownership record. Existing files under those names are backed up.
2. Start SteamVR with the headset connected. Choose [[Start in VR]] in the Hub. Journey's first launch creates `vrmod.ini` and `vrmod_Journey.cfg` beside the game. Normal Journey settings are left alone.
3. Future updates use the same source and preserve your generated VR settings. If Journey starts flat, check `vrmod.log` in the game folder for the active OpenXR runtime and confirm SteamVR is selected.

Some cutscene detection and distant lighting remain rough in this alpha. The publisher notes that a few story scenes can remain in the world rather than on the virtual screen.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Walk. |
| [[Right Stick]] | Turn the camera. |
| [[A]] / [[X]] / [[Trigger]] | Jump and fly. |
| [[B]] / [[Y]] / [[Grip]] | Sing; hold for a louder call. |
| [[Menu]] | Pause. |

## Removal and troubleshooting

Choose [[Uninstall now]] to remove the two Hub-owned DLLs and restore any files that occupied those names before installation. Journey, saves, normal settings and the generated VR settings remain. If you want to reset the VR settings, back up and then remove `vrmod.ini` and `vrmod_Journey.cfg` manually.

## Links

- [Official source and Journey alpha guide](https://github.com/jeffMeador/flower_vr#journey-alpha)
- [Current publisher releases](https://github.com/jeffMeador/flower_vr/releases)
- [Flat2VR community thread](https://discord.com/channels/747967102895390741/1556404029590863893)
- [VR gameplay](https://youtu.be/UZQxigNpp-I?t=509)

Every journey begins with a single step.
