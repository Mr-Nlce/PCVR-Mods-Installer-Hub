# Slyders VR Installer

Automated installer for Slyders_VR v1.0.0 by Astienth — full VR with motion controls for Slyders (roguelite bullet-hell FPS).

The mod adds support for bHaptics and Provolver.

## What it installs
- **Slyders_VR mod** — VR rendering and motion-controller support
- **BepInEx** — mod loader
- **ViGEmBus driver** (optional) — required for VR controllers; emulates an Xbox controller

## Requirements
- Slyders owned on Steam (App ID 2607870)
- SteamVR or any OpenXR runtime installed
- Discord account — the mod is distributed through Astienth's Discord server

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `Slyders_VR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates Slyders, copies the mod files in, and offers to run the ViGEmBus installer if you don't have it yet.

## Controls
- Dominant hand has the **red laser** — aim and shoot with the controller trigger.
- Non-dominant hand has the **white laser** — aim perks/upgrades (turrets etc.).
- When using dual weapons, each weapon aims with its own hand but both shoot with the dominant trigger.
- **Recenter view**: click both joysticks at once.
- **Toggle laser pointer**: [[Right Stick]] click + left controller [[A]]
- **D-Pad gesture**: hold your left hand close to the left side of your head (controllers buzz). While buzzing, [[Left Stick]] becomes D-Pad, [[Left Stick]] click = Back, [[Right Stick]] click = Start. Used for menus and upgrade selection.

## Configuration
Edit `BepInEx\config\Slyders_VR.cfg`:

```
[General]
leftHanded = false
aimingPosition = 0.0,0.0,0.0
aimingRotation = 90.0,0.0,0.0
```

`leftHanded = true` swaps the left/right triggers only — all other controls stay the same.

To switch from OpenXR to OpenVR, edit `BepInEx\config\UnityVR_Bepinex.cfg`:

```
vrApi = OpenXR    # change to OpenVR
```

## Known issues
- Beam laser upgrade: aiming with the non-dominant hand still damages enemies, but the laser visual doesn't follow your aim.

## Uninstall
Rename `winhttp.dll` in the game root folder to `winhttp_bak.dll` to deactivate the mod (game runs flat). Delete the renamed file plus `BepInEx\` and `winhttp_bak.dll` for a full uninstall.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Now go save Sky World, Aryx. The fox rides at dawn.
