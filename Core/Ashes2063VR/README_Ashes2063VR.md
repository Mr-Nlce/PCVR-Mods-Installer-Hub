# Ashes 2063 VR

Ashes 2063 is a free, post-apocalyptic **total conversion for GZDoom** by Vostyok (ASHES DEV GROUP) - build-style level design and fast Doom combat with a Stalker / Fallout flavour. This entry plays it in **VR with motion controls** by swapping the engine for **gzdoomvr** (hh79's OpenVR fork of GZDoom).

**Mod**: gzdoomvr (hh79) running Ashes Enriched 2.23 / Afterglow 1.16 / Hard Reset 1.05
**Game**: Ashes 2063 - free standalone (ModDB)

## About the VR layer

The Ashes weapons are 2D sprites, so aiming works like other classic-engine VR ports: one hand is tracked for the weapon and a built-in **laser sight** shows where you are pointing. Launch SteamVR (or Virtual Desktop's OpenVR) before the game to avoid it potentially starting sometimes out of focus. Works with any SteamVR-compatible headset, including Meta Quest via Virtual Desktop or Link.

## What this Hub installer does

1. You supply the free **Ashes Standalone ZIP** from ModDB (red DOWNLOAD NOW, ~665 MB).
2. Drag that ZIP onto the installer window.
3. It extracts Ashes into `C:\Games\Ashes 2063 VR`.
4. It downloads **gzdoomvr** (the VR engine) from GitHub and places it alongside.
5. It writes three VR launchers and three desktop shortcuts - one per episode. Launch with **Start in VR** in the Hub (main episode) or the per-episode shortcuts.

Nothing game-related is bundled in the Hub; the standalone is a manual download and gzdoomvr is fetched at install time.

## Episodes

- **Ashes 2063 VR** - Enriched edition (Episode 1 + Dead Man Walking)
- **Ashes Afterglow VR**
- **Ashes Hard Reset VR**

## Controls

Controller bindings are handled by SteamVR (per-game bindings for gzdoomvr) and adjusted in-game under **Options -> VR**. A typical motion-controls layout:

- [[Trigger]] Fire
- [[Grip]] Secondary mappings / alt actions
- [[Stick]] Move / snap-turn
- [[A]] Jump
- [[B]] Use / open
- [[Menu]] Main menu

Aim by pointing your tracked hand; the laser sight marks your shot.

## Switch / tweak VR

In-game **Options -> VR** covers weapon angle, snap-turn, comfort and handedness. If aiming feels off, adjust the weapon angle. If you do not enter VR on launch, confirm SteamVR is running and that VR mode is enabled in Options.

## Optional: 3D models addon

During setup the installer offers a community **3D models addon** (ModDB)
- answer **Y** at the "Optional: 3D models addon" step to add it, **N**
to skip. You can re-run the installer any time to add it later.

- It turns the **world objects** into 3D models: ammo, quest items,
  powerups, props, and weapons lying in the world (the ones you pick up).
- **Note:** the weapon in your hand (first-person view) stays 2D. The
  addon replaces world/pickup models, not the held-weapon sprites - that
  is a separate thing this pack does not cover.
- Covers **Ashes 2063** and **Afterglow** (Hard Reset is not included).
- The installer opens the ModDB page; click the red **Download Now**
  button (about 33 MB), then drag the downloaded ZIP onto the window.
  The addon loads automatically on top of the matching episodes.

## Notes

- This is a free, fan-made VR setup over a free total conversion - performance and polish vary; up-close textures are low-res by classic-engine nature.
- gzdoomvr is GPLv3 (a GZDoom fork). Ashes 2063 is freeware by its authors.
- Source: Ashes 2063 (https://www.moddb.com/mods/ashes-2063) - gzdoomvr (https://github.com/hh79/gzdoomvr)
