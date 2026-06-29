# Subnautica VR Installer

Automated installer for **SubmersedVR 0.2.0** by Okabintaro — a mod that
modernizes and enhances Subnautica's VR support, adding full motion-control
support and common VR mechanics to the underwater survival game.

## What it installs

- **BepInEx for Subnautica** (toebeann's build) — the mod framework
- **SubmersedVR 0.2.0** — the VR mod

## Requirements

- Subnautica installed on Steam, on the **default branch** (legacy and
  experimental beta branches are NOT supported)
- SteamVR installed
- No conflicting VR mods: remove **Subnautica VR Enhancements** and **SN1MC**
  beforehand
- Note: the Microsoft Store version is outdated and incompatible

## Features

- **Full motion controls** — interact with your tools and the world by hand
  instead of the old head-aimed cursor
- **Modernized VR mechanics** — proper hand presence and a more immersive
  experience than Subnautica's original built-in VR mode
- Works with the Seaglide, PDA, vehicles and the rest of the survival loop
  in VR

## Heads-up: work in progress

SubmersedVR is actively developed and not a fully polished, bug-free
experience — expect some rough edges. If you'd rather play with a gamepad
in the original VR mode, the Subnautica VR Enhancements mod is the
alternative (but don't run both at once).

## Oculus / Quest users

If using an Oculus headset (Rift, Quest via Link or Air Link), add
`-vrmode openvr` to Steam Launch Options (the installer copies this to your
clipboard and guides you). Start SteamVR manually before launching.
Virtual Desktop users do not need this option.

## Launch tip

It can take a couple of tries to land in "VR with motion controls" rather
than flat-in-VR or VR-without-motion-controls. Starting SteamVR first and
launching from the SteamVR dashboard (or, on Air Link, from the Meta Air
Link menu) is the most reliable route.

## Troubleshooting

- Controllers not working? Check `BepInEx\LogOutput.log` in your game folder
- Do **not** use mod managers like Vortex — they can skip required files in
  `Subnautica_Data\`

## Source

SubmersedVR: https://github.com/Okabintaro/SubmersedVR

>>> Dive safe, and watch out for the Leviathans!
