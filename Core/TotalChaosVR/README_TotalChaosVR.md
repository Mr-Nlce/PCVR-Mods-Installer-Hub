# Total Chaos VR

Total Chaos is a free, survival-horror **total conversion for Doom II / GZDoom** by Sam Prebble (wadaholic) - set on the abandoned mining island of Fort Oasis, with improvised melee weapons, scarce ammo, and a heavy horror atmosphere. This entry plays it in **VR with motion controls** by swapping the bundled engine for **gzdoomvr** (hh79's OpenVR fork of GZDoom).

**Mod**: gzdoomvr (hh79) running Total Chaos Standalone 1.00.0
**Game**: Total Chaos - free standalone (ModDB)

## About the VR layer

The Total Chaos weapons are 2D sprites, so aiming works like other classic-engine VR ports: one hand is tracked for the weapon and firearms use a built-in **laser sight** to show where you are pointing. SteamVR (or Virtual Desktop's OpenVR) must be running before launch. Works with any SteamVR-compatible headset, including Meta Quest via Virtual Desktop or Link.

## What this Hub installer does

1. You supply the free **Total Chaos Standalone ZIP** from ModDB (red DOWNLOAD NOW, `totalchaos_standalone_1000b.zip`, ~1.42 GB).
2. Drag that ZIP onto the installer window.
3. It extracts Total Chaos into `C:\Games\Total Chaos VR`.
4. It downloads **gzdoomvr** (the VR engine) from GitHub and copies it over the bundled engine inside `gamedata\`, keeping all of Total Chaos's own content files.
5. It writes a VR launcher and a desktop shortcut.

Nothing game-related is bundled in the Hub; the standalone is a manual download and gzdoomvr is fetched at install time.

## Engine note

Total Chaos 1.00.0 bundles GZDoom 3.6.0, so the installer downloads the matching **gzdoomvr 3.6.x** build (hh79) and runs it from its own `gzdoomvr\` folder, pointed at Total Chaos's `doom.wad` + `totalchaos.pk3`. Total Chaos's own `gamedata` is left untouched.

## Controls

Controller bindings are handled by SteamVR (per-game bindings for gzdoomvr) and adjusted in-game under **Options -> VR**. A typical motion-controls layout:

- [[Trigger]] Fire / swing melee
- [[Grip]] Secondary mappings / alt actions
- [[Stick]] Move / snap-turn
- [[A]] Jump
- [[B]] Use / interact
- [[Menu]] Inventory / main menu

Aim by pointing your tracked hand; firearms show a laser sight for your shot.

## Performance

Total Chaos is demanding even on flatscreen (lots of dynamic lights, high-res textures, 3D models; can use 6 GB+ RAM). In VR it renders twice, so expect it to be heavy - a SOLID-tier machine or better is recommended.
