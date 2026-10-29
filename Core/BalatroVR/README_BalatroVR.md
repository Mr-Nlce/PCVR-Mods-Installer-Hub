# Balatro VR

## About the Game

Build impossible poker hands with Jokers, upgrades and increasingly unreasonable multipliers. Balatro in VR brings the cards, shop and table into a separate VR room connected to the running Windows Steam game.

## What you need

- The Windows Steam version of Balatro, an active PC VR runtime and tracked controllers.
- Lovely and Steamodded 26.1002.0 or newer. The Hub installs the current Lovely x64 release and the author-documented Steamodded library when absent. An existing older library needs updating before installation can continue.
- Both Balatro and the separate VR client must run. No public network connection or firewall exception is needed for their local bridge on port 27801.

## Install and start

1. Close Balatro and its VR client, then choose [[Install]] in the Hub. The installer shows your game folder and installs all three parts: Lovely beside Balatro.exe, Steamodded and BalatroVRBridge under %APPDATA%\Balatro\Mods, and the client under %LOCALAPPDATA%\PCVR Mods Installer Hub\BalatroVR.
2. Connect the headset and choose [[Start in VR]] in the Hub. It opens the VR client and starts Balatro through Steam. Alternatively, use the Balatro VR desktop shortcut, which does the same.
3. If the room says Waiting for Balatro, check that the game is running, open its Mods menu and enable Balatro in VR. A pre-existing version.dll loader must be resolved before installing current Lovely; the Hub does not delete it automatically.

## Controls

| Button | Action |
|---|---|
| [[Right Trigger]] | Point and click with the beam. |
| [[Right Grip]] | Grab selected cards. Drop over the golden chip or flick them to play; toss over your shoulder to discard. |
| [[A]] | Play selected cards. |
| [[B]] | Discard selected cards. |
| [[Left Stick Click]] | Switch sorting between rank and suit; use [[Right Stick Click]] in left-handed mode. |
| [[Left Grip]] / [[Right Grip]] | Grab Jokers to reorder, shop items, levers and coins; put a coin in the slot to sell. |
| [[Left Grip]] + [[Right Grip]] | Grab and tear open a pack. |
| [[X]] / [[Menu]] | Open VR settings. In left-handed mode use [[A]] on the right controller. |
| [[Grip]] + [[Stick Up]] / [[Stick Down]] | Move and resize the selected item in layout adjustment. |
| [[Y]] | Reset a layout item; [[B]] in left-handed mode. |

## Help

- Low frame rate: enable Performance Mode in the VR menu, or choose Background > Black. The latest client reduces resolution, shadows and bloom in Performance Mode.
- A flat Steam window is expected: the separate client provides the headset view. Starting only the Steam game does not open the VR room.
- Layout and client achievements are stored separately under %APPDATA%\Godot\app_userdata\Balatro in VR. Photos can be stored beside the client or under Pictures\Balatro in VR. The Hub leaves these files and Balatro saves alone.
- Other installed mods keep their own folders. The Hub retains an existing compatible Steamodded installation; it does not silently replace personal mod libraries.

## VR files

Lovely is winmm.dll beside Balatro.exe. The bridge is %APPDATA%\Balatro\Mods\BalatroVRBridge\BalatroVRBridge.lua; Steamodded is in the same Mods folder. The client and its durable Start-BalatroVR.ps1 controller are under %LOCALAPPDATA%\PCVR Mods Installer Hub\BalatroVR. The controller starts Balatro in VR.exe and steam://rungameid/2379780. Verified folder and start links appear here after the VR mod installation. If the Hub misses the game, you can choose [[Locate Game]].

## Discord discussion & support

- [Join Flat2VR](https://discord.gg/uAeQkYBM4n)
- [Balatro VR discussion](https://discord.com/channels/747967102895390741/1563690320183689226)

## Links

- [Official Balatro VR mod](https://github.com/alextreumer/BalatroVRMod)
- [Publisher releases](https://github.com/alextreumer/BalatroVRMod/releases)
- [Lovely](https://github.com/ethangreen-dev/lovely-injector)
- [Steamodded](https://github.com/Steamodded/smods)
- [VR gameplay](https://youtu.be/RgkfDyy8bQs?t=114)

## Uninstall guide

Close both programs and choose [[Uninstall now]]. The Hub removes its unchanged bridge and client files and its matching desktop shortcut, restoring earlier files when applicable. Lovely and Hub-installed Steamodded are kept if other mods still use them. Saves, settings, edited files, photos and other mods remain.

Surely the next Wheel of Fortune will hit.
