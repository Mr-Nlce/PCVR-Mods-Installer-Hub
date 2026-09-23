# Road to Vostok VR Installer

Automated installer for the latest Road to Vostok VR Mod by Blah64 — full VR support with motion controls, physical weapon handling, and a holster system.

## Requirements
- Road to Vostok owned on Steam
- **Metro Mod Loader** (the installer downloads its current `modloader.gd`
  and `override.cfg` files when they are missing or outdated)
- SteamVR or Meta PC app running before launch

## What it installs
- **vr-mod.vmz** — main VR mod (loaded by Metro Mod Loader)
- **modloader.gd + override.cfg** — Metro Mod Loader's current two-file release
- **Road to Vostok VR desktop shortcut** — your launch route into VR
- **VR runtime DLLs** and injector

## How to use
Click **Install Mod** on the game tile or detail page and follow the prompts.

**Always launch via the Road to Vostok VR desktop shortcut** (or **Start in VR** in the Hub) — do not use Steam's Play button directly, it starts the unmodded game.

## First launch
1. Start the game via the **Road to Vostok VR** desktop shortcut
2. The headset shows a black screen — switch to your desktop viewer
3. Click **"Launch with mods (Restart)"** in the Metro Mod Loader window
4. The game restarts and the main menu appears in VR
5. Press **F8** in-game to open VR settings (weapon grip, wrist watch, comfort options)

## Controls

### Movement
| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Right Stick]] | Turn |
| [[A]] | Jump / click UI |
| [[Y]] | Open/close inventory |
| [[Left Stick]] click | Sprint |
| [[Right Stick]] click | Crouch |
| [[Menu]] | Pause |

### Holster System
Weapons are drawn by reaching to body locations and gripping. Your controller buzzes when entering a holster zone.

| Location | Slot |
|----------|------|
| Right shoulder | Primary weapon |
| Right hip | Sidearm |
| Left hip | Knife |
| Chest | Grenades |

Releasing grip away from body: primary weapon goes to **sling position** (hangs at chest, follows your turn). Sidearm/knife/grenade auto-holster.

### Weapon
| Button | Action |
|---|---|
| [[Weapon hand trigger]] | Fire |
| [[Support hand trigger (quick)]] | Reload |
| [[Support hand trigger (hold 0.5s)]] | Ammo check |
| [[Support hand grip]] | Two-hand grip (stabilised aim) |
| [[Right Stick]] up/down | Zoom (variable scopes) |
| [[B]] | Cycle fire mode / cycle bolt action |
| [[B (weapon lowered)]] | Interact with objects |

All weapon inputs follow the weapon hand — draw with left hand, left trigger fires.

### Laser colors
- Red — nothing in range
- Green — grabbable item
- Yellow — interactable (trader, loot)
- Blue — menu open (5m range)
- Orange — movable furniture (decor mode)

### Wrist Watch HUD
Health and status effects shown on your non-dominant wrist. Raise toward your face to reveal it. Configurable in F8 settings.

## Tips
- **Weapon sway** can be disabled in F8 → VR settings
- **Grip adjust mode**: draw weapon, press [[X]] to fine-tune grip position live
- **Foregrip adjust**: grab with off-hand, press [[X]] to calibrate two-hand grip point
- To update later, run the Hub installer again. It resolves the newest VR-mod
  release and refreshes Metro Mod Loader when its two files have changed.

## Troubleshooting
- **Black screen after launch** — make sure SteamVR/Meta PC app is running before starting
- **Stale mod version** — delete `Road to Vostok\vr_mod_init.gd` if present
- **Can't click menu buttons** — use A button, not trigger
- **Weapon at wrong position** — enable Gun Config in F8, use X to enter grip adjust mode

## More info
https://github.com/Blah64/Vostok-VR-Mod

>>> Dead reckoning never felt this real.
