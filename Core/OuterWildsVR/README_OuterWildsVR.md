# Outer Wilds VR Installer

Automated installer for **NomaiVR 2.10.0** by Raicuparta & artumino — the
full game playable in VR with 6DOF tracking and motion controls. NomaiVR
was Raicuparta's first VR mod and one of the most popular Flat2VR mods.

## What it installs

- **OWML 2.15.5** — the Outer Wilds Mod Loader
- **NomaiVR 2.10.0** — the VR mod with full motion controls

## Requirements

- Outer Wilds owned on Steam or Epic Games Store
- SteamVR installed
- You must be on **Outer Wilds 1.10.0**, NOT the 1.0.7 beta branch (NomaiVR
  fails to initialise on the old beta)

## Features

- **Full 6DOF room-scale tracking** — lean, duck and look around your ship
  and the world naturally
- **Motion controls** — pilot the ship, use the translator, signalscope,
  and scout launcher with your hands
- **Multiple comfort options** to tune the experience to your tolerance
- **Built-in openvr_fsr** upscaler for extra performance (see below)

## Performance

- NomaiVR ships with **openvr_fsr** (FSR upscaling), **disabled by
  default**. To enable/tune it, open the NomaiVR directory (Mod Manager ->
  three dots next to NomaiVR -> "Show in explorer") and edit the config
  under `Raicuparta.NomaiVR\patcher\files\OuterWilds_Data\Plugins\x86_64`.
  These settings reset on every NomaiVR update or reinstall
- **RTX cards:** the optional Fixed Foveated Rendering addon gives a nice
  performance boost

## Troubleshooting

- **"Failed to initialize player" / "Failed to load PlayerSettings":**
  you're on the wrong game version — make sure you're on 1.10.0 and not the
  Steam beta branch, then verify the integrity of the game files (Steam:
  right-click Outer Wilds -> Properties -> Local Files -> Verify; Epic: the
  three dots -> Verify)

## How to use

Click **Install Mod** on the game tile or detail page and follow the prompts.

## More info

https://outerwildsmods.com/mods/nomaivr/

## Support Raicuparta

Raicuparta develops NomaiVR and many other VR mods. If you enjoy their
work, consider supporting them:
- https://www.patreon.com/c/raivr/home

>>> The Hatchling sets out. Twenty-two minutes is plenty of time.
