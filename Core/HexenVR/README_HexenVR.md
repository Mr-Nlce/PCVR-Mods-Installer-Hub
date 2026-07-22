# Hexen VR

VR port of Hexen via **GZDoomVR** - hh79's PC VR fork of GZDoom. Provides full 6DoF motion controls with laser-pointer aim, snap turn, and smooth locomotion through OpenVR / SteamVR.

## Where to get the game

The IWAD this installer copies comes from the official Steam release. Get it on Steam: https://store.steampowered.com/app/3286930/

That URL points at the **Heretic + Hexen bundle (2025 enhanced re-release)**. HEXEN.WAD ships inside this package. If you already own the older standalone Hexen: Beyond Heretic on Steam (app/2360), the new bundle is a free upgrade.

GOG owners are also supported - the installer will prompt for the WAD path if it can't find a Steam install.

## What this installer does

1. **Locates your WAD** - searches Steam for Hexen and copies `HEXEN.WAD` from there.
2. **Downloads the engine** - GZDoomVR v4.13.2.2 (~25 MB) from GitHub, on first install only.
3. **Pre-configures VR mode** - the launch settings are set up for the headset, nothing to configure.
4. **Adds a desktop shortcut** - one-click launch into VR (or use **Start in VR** in the Hub).

The engine is shared between all five Doom-family VR games (Doom, Doom 2, Heretic, Hexen, Strife) - if you install another later, the engine download is skipped and only the WAD is added.

## Requirements

- Hexen owned on Steam (the WAD source) **or** a local `HEXEN.WAD` you can point the installer at.
- Launch SteamVR before the game to avoid it potentially starting sometimes out of focus.
- SteamVR Theatre Mode disabled: `Settings -> Dashboard -> Present Non-VR Applications` set to OFF.

## Performance notes

Vanilla Hexen runs comfortably on basic VR-capable hardware. Heavy mods (Brutal Doom and the like) can cause framedrops - the engine's README suggests dropping supersampling to 0.9 if you hit performance trouble.

## Controls

Default mappings (right-handed):

- **[[A]]** - Open door / switch
- **[[B]]** - Jump
- **[[Y]]** - Toggle automap
- **[[Dominant Trigger]]** - Fire
- **[[Off-hand Trigger]]** - Run
- **[[Off-hand Grip]]** - Two-handed weapon grip / weapon stabilisation
- **[[Off-hand Stick]]** - Locomotion / teleport
- **[[Dominant Stick]]** - Snap turn (left/right) and weapon change (up/down)

Hold the dominant grip to access secondary mappings (alt-fire on the trigger etc). All bindings can be remapped from the in-game options menu.

## Credits

- **hh79** - GZDoomVR (PC VR fork of GZDoom)
- **Team Beef Studios / DrBeef** - Original QuestZDoom Quest port and 6DoF design
- **The ZDoom team** - GZDoom engine
- **m8f (mmaulwurff)** - Laser sight mod (bundled, helpful for VR aiming)

## Links

- GitHub: https://github.com/hh79/gzdoomvr
- Official site: https://www.questzdoom.com/

>>> Fighter, Cleric, Mage. Korax falls, or you do.
