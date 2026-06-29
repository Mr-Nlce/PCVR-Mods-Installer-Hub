# Hollow Knight: Silksong VR

The legendary 2D Metroidvania, brought into VR with a parallax-style depth effect that adds dimension to the hand-drawn world. **This is a depth-enhancement mod, not a motion-control conversion** - you still play with a gamepad or keyboard, exactly like the base game.

**Mod**: HollowKnightSilksong_VR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Hollow Knight: Silksong (Steam App 1030300)

## About this mod

A community VR mod for the 2D side-scroller, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download.

The mod adds spatial depth between the game's sprite layers so the foreground, midground, and background occupy real depth in VR - the world feels like a diorama rather than a flat screen. The original 2D gameplay is unchanged.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1414940597579419679/1414940597579419679

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Confirming you've launched the base game at least once (required by the mod)
4. Downloading `HollowKnightSilksong_VR.zip` from the mod channel
5. Auto-locating your Silksong install (Steam libraries scanned)
6. Extracting the mod files into the game folder

**Pre-install requirement**: launch Hollow Knight: Silksong at least once and get past the initial settings before installing the mod. The installer asks you to confirm.

## Controls

Game controls are unchanged. Use a gamepad or keyboard. There is no motion-controller support - this mod only enhances visual depth, it doesn't remap input.

### Mod-specific hotkeys

- **Recenter view**: SteamVR recenter, OR hold the **Up + QuickMap + Pause** buttons at the same time (gamepad: Up + [[LB]] + Start)
- **Toggle vignette on/off**: hold the **Start** button. Useful when an area has too strong a vignette - you can disable it on the fly without leaving the game.

## Configuration

Two config files, both in `BepInEx\config\`:

### `HollowKnightSilksong_VR.cfg`

```
spaceBetweenMultiplier = 1.65   # depth between sprite layers (the effect)
VRCamDistance          = 0,0,10 # headset distance from scene (change Z only; increase = closer)
worldScale             = 1      # relative world scale
UIScale                = 1      # UI scale
```

### `UnityVR_Bepinex.cfg`

```
canvasOffset = 0.0,0.0,1.4   # UI distance from headset (smaller Z = closer, larger = further)
```

### World-scale tuning (mod author's tested config)

If you want a noticeably bigger world:

```
worldScale   = 20
UIScale      = 10
canvasOffset = 0.0,0.0,12
```

Tweak `worldScale` first, then dial in `UIScale` and `canvasOffset` to match. **Heads-up**: pumping `worldScale` can cause the VR camera to lose 6DoF behaviour. If anything breaks, restore the defaults from the comment block above each value in the config files and try again.

## Known issues

- Inventory map zoomed in can have visual quirks (it was tricky to fix in VR)
- Map pin placement is offset: the pin appears at the bottom-right of the cursor instead of on it. Reference: https://discord.com/channels/1001138422972432597/1414940597579419679/1415029563867529267

## Compatibility

Compatible with any other BepInEx mod, but no guarantee against conflicts.

## Uninstall / temporarily disable

Rename `winhttp.dll` in the game root folder to something else, for example `winhttp_bak.dll`. The mod stops loading but stays on disk so you can re-enable it later by renaming back.

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1414940597579419679/1414940597579419679
- Mod download: https://discord.com/channels/1001138422972432597/1414940597579419679/1440826936698998785

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Climb high, Hornet. The Citadel waits.
