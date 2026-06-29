# Hexen II VR Installer

Automated installer for VHexen2 v0.1.5-pc-alpha by alexdnax — Hexen II: Hammer of Thyrion with full VR support via OpenXR. Play in VR with motion controllers or in flat mode with keyboard/mouse.

## What it installs
- **VHexen2 v0.1.5-pc-alpha** — full VR port via OpenXR
- Automatically copies pak0.pak and pak1.pak from your Hexen II installation (Steam or GOG)

## Requirements
- Hexen II owned on Steam or GOG
- SteamVR or Virtual Desktop installed (for VR mode — flat mode works without)

## Install layout
The installer creates a self-contained folder under `C:\Games` (or the first writable drive root — `D:\Games`, `E:\Games`), **not** inside the Steam library:

```
C:\Games\Hexen II VR\
  vhexen2-desktop.exe      <- launch executable
  data1\
    pak0.pak  pak1.pak     (copied from your Hexen II install)
```

Your original Hexen II install (Steam/GOG) is only read from to copy `pak0.pak` + `pak1.pak` — nothing is written there.

## How to use
Click **Install Mod** on the game tile or detail page and follow the prompts. The game launches automatically in VR if an OpenXR runtime is detected. If no runtime is found, it starts in flat mode.

## Controls

### Right Controller
| Button | Action |
|--------|--------|
| [[Trigger]] | Primary attack |
| [[Grip]] | Select weapon from holster |
| [[A]] | Next inventory artifact |
| [[B]] | Dash |
| [[Stick]] | Snap turn |
| [[Stick]] click | Height calibration |

### Left Controller
| Button | Action |
|--------|--------|
| [[Trigger]] | Use artifact |
| [[Grip]] | Necromancer: toggle scythe / spell book |
| [[X]] | Previous inventory artifact |
| [[Y]] | Show console |
| [[Stick]] | Move / strafe |
| Menu | Game menu |

## Toggle VR / Flat mode
Open the console (Y / ~) and type:
```
vr_enabled 1    // VR on
vr_enabled 0    // flat mode
```
You can switch at any time, even mid-game.

## Turn settings
```
vr_snap_turn 1          // snap turn (default)
vr_snap_turn 0          // smooth turn
vr_snap_turn_angle 30   // snap angle in degrees
vr_turn_speed 120       // smooth turn speed
```

## Class tips
- **Assassin** — Dash triggers invisibility at level 3+ (lasts 5–10s, breaks on damage)
- **Paladin W2 (Vorpal Sword)** — with Tome of Power, melee swings fire projectiles (costs 8+ green mana)
- **Crusader W1 (Warhammer)** — with Tome of Power, throw the hammer as a projectile
- **Paladin / Assassin** — off-hand weapon controlled automatically by left controller in VR

## Limitations
- Alpha release — expect rough edges
- No vignette / comfort overlay yet
- Only tested with Virtual Desktop + Quest Touch controllers — Index/Vive bindings exist but are untested
- Single-player only (multiplayer untested in VR)

## More info
https://www.moddb.com/mods/hexen-ii-vr/downloads

>>> Step through the portal. The four realms are waiting.
