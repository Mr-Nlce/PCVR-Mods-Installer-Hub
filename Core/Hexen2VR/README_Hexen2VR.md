# Hexen II VR Installer

VHexen2 v0.1.5-pc-alpha by alexdnax brings Hexen II to OpenXR VR with motion controllers. The standalone port also supports keyboard and mouse in flat mode.

## About the Game
Hexen II is a fantasy action game built around four playable classes, weapons, artifacts and interconnected realms. VHexen2 adds VR interaction to its Hammer of Thyrion engine.

## What it installs
- **VHexen2 v0.1.5-pc-alpha** — full VR port via OpenXR
- Automatically copies pak0.pak and pak1.pak from your Hexen II installation (Steam or GOG)
- Installs the publisher's executable, SDL2 runtime and VR asset package together; the Hub checks these files before marking the port ready

## Requirements
- Hexen II owned on Steam or GOG
- SteamVR or Virtual Desktop installed (for VR mode — flat mode works without)

## Install layout
The installer creates a self-contained folder under `C:\Games` (or the first writable drive root — `D:\Games`, `E:\Games`), **not** inside the Steam library:

```
C:\Games\Hexen II VR\
  vhexen2-desktop.exe      <- launch executable
  SDL2.dll                <- publisher runtime
  data1\
    pak0.pak  pak1.pak     (copied from your Hexen II install)
    pak5.pak              (publisher VR assets)
```

Your original Hexen II install (Steam/GOG) is only read from to copy `pak0.pak` + `pak1.pak` — nothing is written there.

## How to use
Click **Install Mod** on the game tile or detail page and follow the prompts. Start SteamVR or Virtual Desktop first if you want VR; VHexen2 starts in flat mode if no OpenXR runtime is available. Use **Start in VR** in the Hub or the installed desktop shortcut to launch the standalone executable. If SteamVR presents the game as a non-VR application, turn off its Theatre Mode setting.

## Controls

### Right Controller
| Button | Action |
|---|---|
| [[Right Trigger]] | Primary attack: melee swing or projectile fire |
| [[Right Grip]] | Select or deselect weapon from holster |
| [[Right A]] | Next inventory artifact |
| [[Right B]] | Dash |
| [[Right Stick]] | Turn; snap or smooth according to the current setting |
| [[Right Stick Click]] | Height calibration |

### Left Controller
| Button | Action |
|---|---|
| [[Left Trigger]] | Use selected artifact |
| [[Left Grip]] | Necromancer: toggle two-handed scythe / spell book |
| [[Left X]] | Previous inventory artifact |
| [[Left Y]] | Show console |
| [[Left Stick]] | Move / strafe |
| [[Left Menu]] | Toggle game menu |

### VR tuning mode
Open Options or enter `vr_tuning_mode 1` through `vr_tuning_mode 6` in the console. Gameplay attack, holster and artifact controls are unavailable while tuning. Enter `vr_tuning_mode 0` to return to gameplay.

- Mode 1: weapon viewmodel
- Mode 2: left HUD panel
- Mode 3: right HUD panel
- Mode 4: holster zones
- Mode 5: off-hand model
- Mode 6: melee collision boxes

| Button | Action |
|---|---|
| [[Left Trigger]] | Rotate the weapon in mode 1 or right HUD panel in mode 3; offset the holster model in mode 4; rotate the right-hand box in mode 6 |
| [[Left Grip]] | Move the weapon in mode 1 or right HUD panel in mode 3; move the right-hand box in mode 6 |
| [[Right Trigger]] | Rotate HUD or models in modes 2, 4 and 5; rotate the left-hand box in mode 6 |
| [[Right Grip]] | Move HUD or models in modes 2, 4 and 5; move the left-hand box in mode 6 |
| [[Right A]] | Scale up in modes 1–5; cycle the right-hand sub-mode in mode 6 |
| [[Left X]] | Scale down in modes 1–5; cycle the left-hand sub-mode in mode 6 |
| [[Right B]] | Reset the current adjustment; reset both hands in mode 6 |
| [[Right Stick Click]] | Height calibration in every tuning mode |
| [[Left Y]] | Toggle console in every tuning mode |
| [[Left Menu]] | Toggle game menu in every tuning mode |

## Toggle VR / Flat mode
Open the console with [[Left Y]] or the keyboard `~` key and type:
```
vr_enabled 1    // VR on
vr_enabled 0    // flat mode
```
You can switch at any time, even mid-game.

## Turn settings
```
vr_snap_turn 1          // snap turn
vr_snap_turn 0          // smooth turn
vr_snap_turn_angle 30   // snap angle in degrees
vr_turn_speed 120       // smooth turn speed in degrees per second
```

## Class tips
- **Assassin** — Dash triggers invisibility at level 3+ (lasts 5–10s, breaks on damage)
- **Paladin W2 (Vorpal Sword)** — with Tome of Power, melee swings fire projectiles (costs 8+ green mana)
- **Crusader W1 (Warhammer)** — with Tome of Power, throw the hammer as a projectile
- **Paladin / Assassin** — off-hand weapon controlled automatically by left controller in VR
- **Flat-mode off-hand** — use the console command `bind q +alt_fire` to bind an off-hand attack key

## Troubleshooting
- **OpenXR runtime unavailable:** Start SteamVR or Virtual Desktop, then toggle `vr_enabled 1` again. The publisher says a game restart is unnecessary.
- **Gameplay buttons behave like model-adjustment controls:** Enter `vr_tuning_mode 0` to leave tuning mode.
- **Hub shows Game Installed instead of VR Ready:** Check that `vhexen2-desktop.exe`, `SDL2.dll`, `data1\pak5.pak`, `data1\pak0.pak` and `data1\pak1.pak` exist in the standalone folder, then run the installer again if files are missing.

## Limitations
- Alpha release — expect rough edges
- No vignette / comfort overlay yet
- Only tested with Virtual Desktop + Quest Touch controllers — Index/Vive bindings exist but are untested
- Single-player only (multiplayer untested in VR)

## More info
https://www.moddb.com/mods/hexen-ii-vr/downloads

>>> Step through the portal. The four realms are waiting.
