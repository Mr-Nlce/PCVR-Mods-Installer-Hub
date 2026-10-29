# Aliens versus Predator 2 VR

Bassquake's motion-controlled VR mod for the original 2001 PC game. Free game download available through the community Easy Installer.

## About the Game

Play through three distinct single-player storylines from the perspectives of a Colonial Marine, an Alien, and a Predator, each offering completely different gameplay mechanics and traversal styles.

## Important

Patch 1.0.9.6 is required. Use SteamVR and Steam Link; Meta Link does not support this 32-bit game. Virtual Desktop is untested by the publisher. Multiplayer is not currently supported. Some weapon models have missing faces when viewed from new angles.

## Install

Run the Hub installer. It finds both retail/Gold and Easy Installer locations, remembers Locate Game selections, and accepts AVP2.exe or a custom game folder.

Default locations:

- C:\Program Files (x86)\Fox\Aliens vs. Predator 2
- C:\Program Files (x86)\Aliens vs. Predator 2

Need the game? Choose D in the installer. On the [Easy Installer page](https://www.moddb.com/games/aliens-vs-predator-2/downloads/aliens-vs-predator-2-easy-installer), click Download Now, then supply its complete ZIP. After extraction, Enter opens the Easy Installer with Windows administrator approval. Select Aliens Vs Predators 2 installers > Alien Vs Predator 2 > Install AVP 2. Install the included 1.0.9.6 update and close all installer windows before continuing. Keep any chosen location; the VR setup does not require the Fox path.

Run the game once in flat, then close it. The VR installer downloads the current official stable Windows package. It installs all deploy runtime files and weapon models directly into your chosen game folder, with a launcher that supports custom locations. Windows may request administrator approval for protected folders.

Updates preserve avp2xr.ini and dgVoodoo.conf, including your custom settings. Backups protect earlier files replaced by the Hub. Saved games, profiles and unrelated mods are retained.

## Start and Flat / VR

1. Start SteamVR and connect your headset through Steam Link.
2. Use Start in VR in the Hub.

Alternative: the Aliens versus Predator 2 VR desktop shortcut. The Hub calls Core\AliensPredator2VR\Start-AvP2VR.ps1 with your game folder. Its retained copy is PCVR-Launcher\Start-AvP2VR.ps1 inside that folder. VR starts lithtech.exe with the existing resource list plus -rez vrrez and the configured GameResolution. xrres.exe prepares the headset resolution first; the process uses SteamVR's 32-bit OpenXR runtime.

Flat / VR parks DDraw.dll for flat play. The same start button then opens the original AVP2.exe launcher; press Play. Switch back to VR before playing in the headset. Updating a flat installation keeps it flat.

## Controls

![Controller layout](../Assets/AliensPredator2VR_controls.jpg)

Default Touch layout; controller bindings and weapon alignment can be adjusted in avp2xr.ini.

| Button | Action |
| --- | --- |
| [[Left Stick]] | Menu up/down; move and strafe in game |
| [[Left Stick Click]] | Crouch |
| [[Left SteamVR Button]] | SteamVR menu |
| [[X]] | Show objectives; hold for Escape, dismiss messages or pause |
| [[Y]] | Cycle vision modes; hold for Predator zoom or Marine shoulder lamp |
| [[Right Stick]] | Navigate menus; up/down selects previous/next weapon; left/right turns |
| [[Right Stick Click]] | Marine flare or Predator cloak |
| [[B]] | Menu back or jump; hold for Marine welding torch or Predator energy sift |
| [[A]] | Menu select; use or Alien pounce; hold to retrieve Predator disc |
| [[Right Menu Button]] | Hold to recenter |
| [[Right Trigger]] | Primary fire; hold for Predator medicomp |
| [[Left Trigger]] | Secondary fire |
| [[Left Grip]] | Alien wall walk; support Marine/Predator weapon |
| [[Left Controller]] | Move over left shoulder for Marine hacking device or Predator charge emitter |
| [[Left Controller]] | Move behind lower back, then to the weapon, to reload as Marine |

## Help

If the game stays on the monitor, check SteamVR and the 32-bit runtime first. The [publisher release notes](https://github.com/Bassquake/Aliens-Versus-Predator-2-VR/releases/tag/0.4) also recommend the DirectX End-User Runtime June 2010 and VC++ x86 runtimes (2015–2022 and 2008/2010). Install official Microsoft packages and restart Windows when requested.

VR logs are in %LocalAppData%\avp2xr. The launcher also reads the corresponding Windows VirtualStore copy of avp2cmds.txt when present. Game settings are in avp2xr.ini; edited configurations stay during updates and removal.

[Publisher](https://github.com/Bassquake/Aliens-Versus-Predator-2-VR) · [Flat2VR invite](https://discord.gg/uAeQkYBM4n) · [Discussion](https://discord.com/channels/747967102895390741/1554884770951864410) · [VR gameplay](https://youtu.be/4kNUM0h5kPE?t=64)

## Uninstall

Use Uninstall now below. Close the game first. The Hub removes unchanged files it installed and restores protected originals. Changed settings, saves, profiles and unrelated files stay. The base game is not removed.
