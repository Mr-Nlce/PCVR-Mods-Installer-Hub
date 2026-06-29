# Subnautica: Below Zero VR Installer

Automated installer for SubmersedVR BZ by jbusfield.

## What it installs
- **BepInEx for Subnautica** (toebeann's build)
- **SubmersedVR BZ 0.8.0** — full VR mod with motion controls

## Requirements
- Windows 10/11
- Steam with **Subnautica: Below Zero** installed on the **default branch** (not legacy/experimental)
- SteamVR installed
- No other Below Zero VR mods installed

## How to use

Click **Install Mod** on the game tile or detail page and follow the prompts.

## Oculus / Quest users

If using an Oculus headset (Rift, Quest via Link or AirLink), add `-vrmode openvr` to Steam Launch Options. The installer copies this to your clipboard and guides you through setting it. You must also start SteamVR manually before launching the game.

Virtual Desktop users do not need this option.

## Playing in VR

1. Start SteamVR
2. Launch Subnautica: Below Zero via Steam

## Troubleshooting

- VR not activating or controllers not working? Check `BepInEx\LogOutput.log` in your game folder
- Do **not** use mod managers like Vortex — they can skip required files in `SubnauticaZero_Data\`

## Source
SubmersedVR BZ: https://github.com/jbusfield/SubmersedVR_BZ

>>> Stay warm out there, and watch out for the Shadow Leviathan!
