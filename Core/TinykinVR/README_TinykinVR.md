# Tinykin VR

A delightful third-person 3D platformer about Milo, a tiny human exploring a world of giant rooms, with a colourful cast of bug-people and the titular tinykin who carry, climb, and combine to solve puzzles. Now playable in stereoscopic VR for added depth.

**Mod**: TinykinVR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Tinykin (Steam App 1599020)

## About this mod

A community VR mod for Tinykin, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

This is a **depth-only mod** - it adds stereoscopic 3D rendering but no motion controls. Controls remain gamepad or keyboard+mouse. The mod author recommends gamepad in VR for comfort. There is no ViGEmBus dependency.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1276919154678693908/1276919154678693908

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading the mod ZIP from the linked Discord post
4. Auto-locating your Tinykin install (Steam libraries scanned)
5. Extracting the mod files into the game folder

## Heads-up about known quirks

The mod author flagged these on the Discord post:

- **A few UI issues**, but nothing game-breaking. The mod author finished the game with the mod installed, so it's fully playable.
- **The aiming reticle uses a shader that stays flat on the UI** - it can feel weird at first but you get used to it.

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
- Mod info post: https://discord.com/channels/1001138422972432597/1276919154678693908/1276919154678693908
- Mod download: https://discord.com/channels/1001138422972432597/1276919154678693908/1276921301163839642

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Small heroes, big house. Solve every room.
