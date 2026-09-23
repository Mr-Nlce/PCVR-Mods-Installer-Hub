# Thief (2014) VR

## About the Game

Thief is a first-person stealth adventure built around shadows, infiltration and carefully planned escapes through the City. ThiefVR adds experimental native same-frame stereo OpenXR and 6DoF head tracking to the supported 64-bit release.

## Requirements and support status

- This is an early **WIP** release. Motion controls are not implemented; use a gamepad or keyboard and mouse.
- The supported executable is the **Steam 64-bit build 1.7 (4158.21)** at `Thief\Binaries2\Win64\Shipping-ThiefGame.exe`.
- Quest Link is confirmed. Virtual Desktop can work when **Center to Stage Tracking** is enabled.
- Always launch with **Start in VR** in the Hub. The normal game shortcut does not perform the required stereo preparation.
- **Start in VR** now keeps a visible recovery screen if the active OpenXR runtime cannot see the headset. Connect and wake the headset, retry the live query, reuse the last successful resolution, or choose a per-eye preset/manual value. The launcher no longer closes without showing why it stopped.
- Looking down can occasionally lock the view; toggle cinema mode with [[F6]] to recover. Keyholes are also easiest in cinema mode.
- Bow aiming is still rough in the current WIP release and is being worked on by the author.

## Controls

| Button | Action |
|---|---|
| [[F6]] | Toggle cinema and full VR |
| [[F7]] | Correct the HUD |
| [[F8]] | Toggle diagnostics |
| [[F9]] | Recenter the view |

## Installation and removal

The installer follows prereleases, verifies the supported game build, preserves an existing `ThiefVR.ini`, and tracks every Hub-owned file. **Uninstall now** removes unchanged Hub-owned files and restores pre-existing collisions without touching saves or unrelated files.

## Links

- [Project and instructions](https://github.com/farmerarmor/ThiefVR)
- [Releases](https://github.com/farmerarmor/ThiefVR/releases)
- [VR gameplay](https://youtu.be/gz7iiS6ItOw?si=I-QrlCXlecm-gYW5&t=211)
- [Flat2VR discussion thread](https://discord.com/channels/747967102895390741/1550396410967490570)
