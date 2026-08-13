# Yooka-Laylee VR

**Mod:** VookaRaylee v0.3
**Author:** Eusth (also the author of IPA and VRGIN)
**GitHub:** https://github.com/Eusth/VookaRaylee

## Two install paths

The installer opens with a choice:

### Option A - Patch the current Steam version (default)

Fast and simple. Locates your Steam install of Yooka-Laylee, installs the VookaRaylee files, runs the IPA patch. You keep launching from Steam as usual. This works for most people.

### Option B - Downgrade to v1.1.0 "64-Bit Tonic"

Only needed if Option A gives you bad VR performance. Downloads v1.1.0 (April 2019) via the Steam Console, moves it to a stable folder, patches it, and creates a **Yooka-Laylee VR** desktop shortcut. You launch through the shortcut, not Steam.

If you are not sure, pick A. You can always re-run the installer and switch later.

## How to play

1. Start SteamVR
2. Launch the game (e.g. **Start in VR** in the Hub)
   - Option A: from Steam as usual
   - Option B: via the **Yooka-Laylee VR** desktop shortcut (do NOT launch from Steam; Steam would update the game back to the latest build)
3. If a **"VR is not supported"** message appears, just click it away
4. VR activates automatically

## Why two paths

- The current Steam build of Yooka-Laylee may have performance issues with the VR mod on some setups
- v1.1.0 is the last build before 1.2.0, which introduced a potential VR performance regression (v1.2.0 "64-Bit Model" switched to the Switch version's geometry)
- v1.0.4 and earlier are 32-bit only and won't work with VookaRaylee

## Moving the game (Option B only)

If you want the game on another drive, move the whole `Yooka-Laylee VR` folder to your target location and update the desktop shortcut's target to the new path.

## Optional launch flags

- `--novr` - forces flat-screen mode
- `--vr` - forces VR mode

Set via Steam -> Yooka-Laylee -> Properties -> Launch Options (Option A), or by editing the desktop shortcut's Target field (Option B).

## VR settings

Edit `vr_settings.xml` in the game folder:

- **scale** - world size relative to the player
- **vignetting** - on/off for the comfort vignette during movement

## Requirements

- Yooka-Laylee owned on Steam (AppID 360830)
- SteamVR
- Gamepad or keyboard & mouse (no motion controls)
