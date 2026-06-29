# Moto Rush Reborn VR Installer

Automated installer for MotoRushReborn_VR v1.0.0 by Astienth — VR conversion of Moto Rush Reborn (arcade motorbike racer) with optional motion controls.

The mod adds support for bHaptics and a ViGEmBus-based gamepad emulation.

## What it installs
- **MotoRushReborn_VR mod** — VR rendering and motion-controller support
- **BepInEx** — mod loader
- **ViGEmBus driver** (optional) — required for VR controllers; emulates an Xbox controller

## Requirements
- Moto Rush Reborn owned on Steam (App ID 2990060)
- SteamVR or any OpenXR runtime installed
- Discord account — the mod is distributed through Astienth's Discord server

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Discord invite, rules channel, and download post in your browser one at a time.
3. Join the server, click the AK-47 emoji under the rules post to confirm, then download `Moto_Rush_Reborn_VR.zip`.
4. Drag the downloaded ZIP into the installer window.
5. The installer auto-locates Moto Rush Reborn, copies the mod files in, and offers to run the ViGEmBus installer if you don't have it yet.

## Controls
- **VR controllers map like an Xbox gamepad** — by default the bike steers with the analogue stick, no motion needed.
- **Recenter view**: click both joysticks at once.
- **Toggle motion controls**: [[Right Stick]] click + left controller [[X]]. The game starts with motion controls **OFF**.

### Motion controls (when enabled)
- Hold both grips to control the bike. VR hands won't stay glued to the handlebars.
- **Wheelie**: pull both hands **up**.
- **Slide**: pull both hands **down**.
- **Duck**: pull both hands **towards you**.
- **Steering** depends on `steeringPlane` in the config:
  - `horizontal` — hands forward/back
  - `vertical` — left hand up vs right hand up
  - `shoulder` — lean head left/right (default)
- Controllers vibrate while gripping (toggleable in the config).

## Configuration

### VR runtime — `BepInEx\config\UnityVR_Bepinex.cfg`
```
vrApi = OpenVR    # or OpenXR
```
Default is **OpenVR** because it has hand animations. **OpenXR** has no hand animations but may run better on some hardware. The hands aren't really used, so try whichever is smoother on your setup.

### Mod settings — `BepInEx\config\MotoRushRebornVR.cfg`
```
[General]
triggerControllerHaptics      = true        # haptics while gripping
steeringPlane                 = shoulder    # vertical | horizontal | shoulder
steeringDiffMin               = 0.015       # dead zone (lower = sooner)
steeringClampMax              = 0.15        # max distance considered
enhanceSpeedEffect            = false       # respawn-halo at high speed
enhanceSpeedEffectMinSpeed    = 250         # km/h threshold for the halo
flamesOnSliding               = false       # big flames while sliding
```

`steeringDiffMin` MUST be lower than `steeringClampMax`.

## Uninstall
Rename `winhttp.dll` in the game root folder to `winhttp_bak.dll` to deactivate the mod (game runs flat). Delete the renamed file plus `BepInEx\` and `winhttp_bak.dll` for a full uninstall.

## More info
https://discord.gg/G8zZBTGuhP

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Throttle wide open. Don't blink.
