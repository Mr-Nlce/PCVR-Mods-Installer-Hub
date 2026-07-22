# Quake 3 VR

**Quake 3 VR v1.0** (q3vr) by **RippeR37** — a PCVR port of *Quake III Arena* built on **ioquake3** and **Quake3Quest** (Team Beef), with full 6DoF motion controls, the single-player campaign, and crossplay multiplayer with PC and Quest players.

## Launching
1. Start **SteamVR** first.
2. Launch with **Start in VR** in the Hub, or the **Quake 3 VR** desktop shortcut (runs `q3vr.exe`).
3. Open the in-game **Setup** menu first to set controls, turning, and comfort options to your liking.

> Bindings can be rebound in **SteamVR → Controller Bindings**, or by creating an `autoexec.cfg` in `baseq3` and setting `vr_button_map_<key> "<action>"`.

## Controls (default motion-control layout)

### Right Controller (primary / active hand)
| Button | Action |
|--------|--------|
| [[Trigger]] | Fire weapon |
| [[Grip]] | Weapon selection wheel |
| [[A]] | Jump |
| [[B]] | Crouch |
| [[Stick]] left/right | Snap / smooth turn |

### Left Controller (off hand)
| Button | Action |
|--------|--------|
| [[Trigger]] | Jump |
| [[Grip]] | Weapon stabilization |
| [[X]] | Use item |
| [[Y]] | Menu / back |
| [[Stick]] | Move (locomotion) |
| [[Stick]] click | Scoreboard / player list |

### In menus
| Button | Action |
|--------|--------|
| [[B]] (left) | Menu — open/close or go up one level (like ESC) |
| [[B]] (right) | Reset position of the Virtual Screen |
| [[Trigger]] (active hand) | Cursor click |
| [[Trigger]] (other hand) | Make that hand the active one |

## What it installs
- **Quake 3 VR v1.0** — downloaded fresh from the official GitHub release (never bundled)
- Copies **pak0.pk3** (and any **pak1.pk3 – pak8.pk3** you own) from your *Quake III Arena* install into the q3vr `baseq3` folder

## Requirements
- *Quake III Arena* owned and installed — Steam **AppID 2200** (folder `Quake 3 Arena`), or GOG
- SteamVR (the game uses the OpenVR runtime)
- Motion controllers

## Troubleshooting
- Make sure `baseq3` contains `pak0.pk3` (and `pakQ3VR.pk3`). The installer copies `pak0.pk3` for you.
- To reset settings, remove the user config in `%appdata%\Quake3\` (this also removes downloaded mods/maps — back it up first).
- q3vr has built-in update notifications and will tell you on startup when a newer version is out.

## Credits & sources
- **Quake 3 VR (q3vr)** by RippeR37 — built on ioquake3 and Quake3Quest (Team Beef); *Quake III Arena* by id Software
- Project page: https://ripper37.github.io/q3vr/
- Download: https://github.com/RippeR37/q3vr/releases/download/v1.0/q3vr_v1.0_windows_portable.zip
- Launch executable `q3vr.exe`; base data `baseq3\pak0.pk3`; Quake III Arena Steam AppID **2200** (official Steam store, SteamDB, PCGamingWiki)

## Support RippeR37
If you want to show some support to RippeR37, you can buy them a coffee:
- https://buymeacoffee.com/ripper37

>>> Welcome to the Arena. Rail the shots, stack the frags, climb to Xaero.
