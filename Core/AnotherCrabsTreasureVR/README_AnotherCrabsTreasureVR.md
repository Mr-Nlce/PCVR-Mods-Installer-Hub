# Another Crab's Treasure VR

A soulslike adventure set in a crumbling underwater world, by Aggro Crab. As Kril the hermit crab, scrounge through trash to find shells that protect you from enemies many times your size, learn umami techniques from the denizens of the deep, and uncover the mystery of the polluted ocean. Now playable in stereoscopic VR.

**Mod**: AnotherCrabsTreasureVRMOD v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Another Crab's Treasure (Steam App 1887840)

## About this mod

A community VR mod by Astienth, distributed via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

This is a **depth-only mod** - it adds stereoscopic 3D rendering but no motion controls. Controls remain gamepad or keyboard+mouse. A gamepad is recommended in VR for comfort. There is no ViGEmBus dependency.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1262749418981949483/1262749418981949483

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading the mod ZIP from the linked Discord post
4. Auto-locating your Another Crab's Treasure install (Steam libraries scanned)
5. Extracting the mod files into the game folder

The locator probes a few folder-name variants because Steam may keep the apostrophe ("Another Crab's Treasure") or strip it on some installs. Either is detected.

## Heads-up: this is a Souls-like

Another Crab's Treasure has Souls-like combat - precise dodge timing and learning enemy attack patterns are central to playing it. If your VR rig has noticeable motion-to-photon latency, that may add to the difficulty. The game also offers built-in assist options if you want a less punishing experience; those work in VR too.

## Controls

Game controls are unchanged. Use a **gamepad** (recommended for VR) or **keyboard+mouse**. There is no motion-controller support and no VR-specific hotkeys; the mod just renders the game in stereoscopic 3D.

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1262749418981949483/1262749418981949483
- Mod download: https://discord.com/channels/1001138422972432597/1262749418981949483/1271091506446598154

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Snail your way home, Kril. The shell is calling.
