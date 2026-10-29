# Valheim VR

## About the Game

Build a Viking homestead, sail into the unknown and discover why cutting down one more tree is sometimes the most dangerous part of the expedition.

## What you need

- Valheim for Steam or the Xbox app / Microsoft Store.
- A connected PC VR headset with SteamVR running. SteamVR is the headset runtime; an Xbox copy does not require a Steam game license.
- DirectX 11. Vulkan is not supported by VHVR.

## Install and start

1. Choose [[Install]] in the Hub. Setup checks remembered locations and Steam/Xbox libraries; you can also select valheim.exe manually.
2. Close Valheim and let setup install the complete VHVR runtime plus BepInExPack Valheim 5.4.2351.
3. Use [[Start in VR]] in the Hub with SteamVR running. The Valheim VR desktop shortcut is an alternative.

Steam copies enter through Steam; Xbox copies use their registered Windows application. Both start with DirectX 11 automatically. No Steam-properties step is required for Xbox copies.

The installer follows current stable VHVR releases. Game updates can still require a matching mod update. The publisher has included Game Pass fixes; current Xbox entitlement and headset behavior still require confirmation on an actual Xbox copy.

## Controls

Oculus Touch / Index layout. Bindings may be customized in SteamVR.

The publisher's [VHVR Compendium](https://docs.google.com/spreadsheets/d/1RbopWqDfDaw62prd3H6vFuqqfgme-qHKAug12iRxCZo/edit?usp=sharing) documents current bindings and motion gestures.

![Controller layout](ControllerLayout.jpg)

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Toggle map |
| [[Y]] | Hold for left-hand quick switch |
| [[Left Grip]] | Grab and holster weapons |
| [[Right Stick Left / Right]] | Turn |
| [[Right Stick Up]] | Sprint |
| [[Right Stick Down]] | Crouch |
| [[Right Stick Click]] | Toggle menu |
| [[A]] | Jump |
| [[Right Grip]] + [[A]] | Remove an object in build mode |
| [[B]] | Hold for right-hand quick switch |
| [[Right Grip]] + [[Right Stick]] | Rotate a building piece |
| [[Right Trigger]] | Use, place or primary pointer click |
| [[Left Trigger]] | Pointer modifier or split inventory stacks |
| [[Home]] | Recenter headset |

## Help

Start SteamVR before Valheim. The first loader start can take longer while configuration files are generated. If you see a flat theatre screen, disable SteamVR's theatre setting and use the Hub start button again.

If Windows cannot identify an Xbox installation, open Valheim once from the Xbox app, close it and retry. The Hub does not redirect that installation to Steam. Locate Game remains available for a moved or custom game folder.

Use [[Flat / VR]] in the Hub for temporary flat play. Existing settings, worlds, characters and unrelated mods are retained during updates.

## VR files

The VR mod folder and start app will appear here as links once the VR mod installation is present. If the Hub does not find your game, you can choose [[Locate Game]].

VHVR installs into the Valheim game folder: BepInEx/plugins/ValheimVRMod.dll, its full Valheim_Data runtime and the loader files. The Hub controller and desktop shortcut use PCVR-Valheim/Start-ValheimVR.ps1. It selects the owning store and passes -force-d3d11. The Windows app identity comes from public Windows registration; no hidden game file needs to be opened manually.

## Uninstall guide

Close Valheim, then use [[Uninstall now]]. Setup removes unchanged files it owns and restores earlier same-name files. If a previous VR mod existed before this installer, it is restored too. Edited settings, saved worlds, characters and unrelated mods remain.

## Discord discussion & support

- [Flat2VR Modding invite](https://discord.gg/uAeQkYBM4n)

## Links

- [VHVR mod page](https://github.com/brandonmousseau/vhvr-mod)
- [Source and releases](https://github.com/brandonmousseau/vhvr-mod/releases)
- [BepInExPack Valheim](https://thunderstore.io/c/valheim/p/denikson/BepInExPack_Valheim/)

>>> The trees still have the highest kill count.
