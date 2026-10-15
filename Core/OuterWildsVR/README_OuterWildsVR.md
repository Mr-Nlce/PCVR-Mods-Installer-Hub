# Outer Wilds VR Installer

## About the Game

Outer Wilds is a time-loop exploration mystery. You investigate a changing
solar system, translate ancient Nomai writing and piece together discoveries
across repeated expeditions. NomaiVR brings the existing game into VR.

Automated installer for **NomaiVR 2.10.0** by Raicuparta & artumino — the
full game playable in VR with 6DOF tracking and motion controls. NomaiVR
was Raicuparta's first VR mod and one of the most popular Flat2VR mods.

## What it installs

- **OWML 2.16.3** — the mod loader bundled by this Hub setup
- **NomaiVR 2.10.0** — the VR mod with full motion controls

## Requirements

- Outer Wilds **1.1.10 or newer**, on Steam or Epic. The publisher also
  supports Xbox/Game Pass, but that edition requires its separate Mod Manager
  preparation before installing; follow the [publisher's Xbox guide](https://outerwildsmods.com/mods/nomaivr/).
- Steam and SteamVR, a VR headset and VR controllers, including for non-Steam
  copies. A regular gamepad alone is not supported.
- Leave the old Steam 1.0.7 beta branch; it can fail during player initialization.
- The Echoes of the Eye DLC works but is optional.

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
  check the game version and make sure you're not on the
  Steam beta branch, then verify the integrity of the game files (Steam:
  right-click Outer Wilds -> Properties -> Local Files -> Verify; Epic: the
  three dots -> Verify)
- **Stuck at the first loading screen:** check that the store client and account
  are connected. Start through `OWML.Launcher.exe` once after every NomaiVR
  install or update. For Xbox, accept the first login prompt; if needed, start
  through the Xbox app without skipping its logos.
- **Flat screen / theatre:** in Steam game Properties, disable *Use Desktop
  Game Theatre*; also turn off SteamVR's desktop theatre presentation.
- **No controller icons or input:** some controllers lack published icons.
  Keep hand prompts enabled, and reset to default SteamVR bindings while the
  game is running if custom bindings stopped working after an update.
- **Poor performance:** reduce in-game shadows, antialiasing and ambient
  occlusion; lower SteamVR resolution (for example from 150% to 100%). The
  game's own resolution and V-sync settings do not control VR rendering.
- **Keyboard does not work:** stable NomaiVR disables it to avoid an end-sequence
  performance bug. Keyboard-dependent add-on mods may need the publisher's
  prerelease; changing branch is outside this pinned Hub setup.

## Controls

NomaiVR displays the active action prompts on your hands. Actual physical
buttons depend on the SteamVR binding for your controllers.

| Button | Action |
| --- | --- |
| [[Interact]] | Aim the dominant-hand laser and interact with most objects. |
| [[SteamVR Binding]] | Choose or reset the mapping for your controller. |

Left-hand mode requires a manual SteamVR binding change.

## How to use

Click **Install Mod** on the game tile or detail page and follow the prompts.
The Hub installs OWML under the game folder and NomaiVR under
`OWML\Mods\Raicuparta.NomaiVR`. After installation or update, start through
the OWML launcher once. The Hub's **Uninstall now** action removes only its
owned NomaiVR files; OWML, other mods and saves remain. It preserves an older
unowned NomaiVR folder in a separate legacy backup before replacing it.

## More info

https://outerwildsmods.com/mods/nomaivr/

## Support Raicuparta

Raicuparta develops NomaiVR and many other VR mods. If you enjoy their
work, consider supporting them:
- https://www.patreon.com/c/raivr/home

>>> The Hatchling sets out. Twenty-two minutes is plenty of time.
