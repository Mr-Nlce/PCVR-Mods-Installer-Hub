# Mouse P.I. For Hire VR

A black-and-white, hand-drawn 1930s cartoon boomer shooter - play private eye Jack Pepper through the noir streets of Mouseburg. The VR mod brings this jazz-fueled detective FPS into VR with motion-controller support.

**Mod**: MousePI_VR v1.0.0 - by Astienth, distributed via Discord
**Game**: MOUSE: P.I. For Hire (Steam App 2416450)

## About this mod

A community VR mod for MOUSE: P.I. For Hire, distributed by Astienth via Discord. **Discord login is required** to access the download. This mod is **OpenXR ONLY**. bHaptics vests/arms and ProTube devices are supported.

Mod info post (manual instructions live here):
- https://discord.com/channels/1001138422972432597/1523984295633490031/1523984342077014069

## What this Hub installer does

1. Joining the Discord server (skip if already in)
2. Reading and accepting the server rules
3. Downloading MousePI_VR.zip from the mod channel
4. Auto-locating your MOUSE install (Steam libraries scanned)
5. Extracting the mod files into the game folder
6. Installing the bundled ViGEmBus driver - **required** for VR controllers as input

## Requirements

- **MOUSE: P.I. For Hire** on Steam (App 2416450)
- A VR headset with a working **OpenXR** runtime (this mod is OpenXR only)
- **ViGEmBus** driver (the Hub installer sets this up in step 6). If you have never installed it, run `BepInEx\redist\ViGEmBus_1.22.0_x64_x86_arm64.exe` from the game folder.

## Controls

Launch MOUSE normally via Steam - it starts in VR automatically.

- **Recenter**: click [[Left Stick]] + [[Right Stick]] at the same time, or press [[F1]]. The view also recenters on every scene load.
- **Weapon** is on your **dominant hand**. Aim with the dominant hand for shooting, interacting, the flashlight and taking pictures - almost everything except kicking.
- **Kicking** hits where the VR UI in front of you is facing.
- Your **non-dominant hand** shows the health indicator (no aiming with it).
- **Taking a picture**: the UI shows a static screen in front, but you still aim with the dominant hand.
- **No roomscale movement**: turn with [[Right Stick]].
- **Weapon wheel**: hold [[Y]] + [[Right Stick]], then release [[Y]].
- The [[Right Stick]] Y axis is neutralized the whole game **except when swimming**.

### Swimming

Once in the water (under or at the surface), [[Right Stick]] up/down tilts the original camera up/down (just like the flat game - you can't see it directly in VR). Push [[Left Stick]] forward to swim in the direction that camera points. It takes a little getting used to.

## First-run settings

Open the in-game settings first and adjust to taste. For the best VR feel you probably want to turn **off aim assist**, **head bobbing** and **vsync**.

## Mod configuration

Edit `BepInEx\config\MousePI_VR.cfg`:

```
leftHanded              = false   # swaps to left hand; also swaps LT/RT, bHaptics + ProTube adapt
useTransparentFixShader = true    # alternate UI shader; try false if you prefer
usePostProcessing       = true    # false can raise fps (loses the game's look, minor glitches)
mirrorView              = true    # false can raise fps (disables the desktop camera)
```

## Known issues

- UI does not show true black - best that could be managed.
- The pick-lock minigame tail is transparent.
- No on-screen feedback when taking damage (removed to avoid flashing for photosensitive players) - watch the health indicator on your non-dominant hand. The Nexus mod **RedBlood** can help: https://www.nexusmods.com/mousepiforhire/mods/9
- If a hand's UI starts glitching (weird weapon size, an image blocking your view), save and reload the last save to fix it.
- During cutscene videos the weapon sprite can get huge - just move your hand out of view; it fixes itself when the video ends.

## Uninstall / temporarily disable

Rename `winhttp.dll` in the game root folder to something else, e.g. `winhttp_bak.dll`. The mod stops loading but stays on disk so you can re-enable it later by renaming it back.

## Discord

- Mod info post: https://discord.com/channels/1001138422972432597/1523984295633490031/1523984342077014069
- Mod download: https://discord.com/channels/1001138422972432597/1523984295633490031/1523985169625911388

>>> The city's crooked and the jazz is hot, gumshoe. Go get 'em.
