# art of rally VR

A stylised top-down rally game inspired by the golden era of rally racing, by Funselektor Labs. Career mode across 78 stages from Finland to Sardinia, Norway, Japan, Germany, Kenya and Indonesia, with iconic cars from the 60s through Group B. Now playable in stereoscopic VR with an experimental first-person view.

**Mod**: ArtOfRally_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: art of rally (Steam App 550320) - by Funselektor Labs

## About this mod

A community VR mod by Astienth, distributed via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

This is a **depth-only mod** with an experimental first-person view toggle. Controls remain gamepad or keyboard. There is no ViGEmBus dependency.

The mod author labelled this one as **"quite barebone but playable"** - it's a quick experimental build, not a polished feature-complete mod. The third-person top-down view (the game's native camera) gets stereoscopic depth in VR and is comfortable to play. The first-person view is a bonus toggle that's a bit rough around the edges.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1306503565698662462/1306503565698662462

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Downloading the mod ZIP from the linked Discord post
4. Auto-locating your art of rally install (Steam libraries scanned)
5. Extracting the mod files into the game folder

## Controls

**Gamepad or keyboard only - no VR controller support.** Game controls are unchanged from the flat-screen version.

### VR-specific hotkeys

- **F1** — Toggle first-person / third-person view
- **F2** — Recenter VR view

(F2 is documented by Astienth as "press once or twice, same thing" — there's a known quirk from the older universal-mod build this is based on. Not a problem, just a behaviour to know about.)

### Hidden hotkeys: first-person camera tuning

The mod author shared these in a Discord follow-up — they aren't in the main mod post. While first-person view is active you can reposition the camera with these key combos:

- **Hold LEFT CTRL + arrow keys (up / down / left / right)** — move the camera on the horizontal plane
- **Hold LEFT CTRL + PageUp / PageDown** — move the camera on the vertical axis

Use these to find a first-person seat position that fits your headset and seating arrangement.

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1306503565698662462/1306503565698662462
- Mod download: https://discord.com/channels/1001138422972432597/1306503565698662462/1306504207012204585

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Gravel, snow, sun. Trust the co-driver.
