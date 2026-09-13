# How to Fish XR

**HowToFishXR** by **J_axon** adds true stereo OpenXR, tracked hands, roomscale interaction and motion-controlled fishing, melee and firearms. Flat players can join the same multiplayer session.

## Setup and launch

The Hub installer downloads the current Thunderstore releases of HowToFishXR and its exact BepInEx 5 dependency. Start the game from **Start in VR** in the Hub or through Steam.

On first launch BepInEx creates `BepInEx/config/com.jaxon.howtofishvr.cfg`. Open the VR settings with [[F1]] or by clicking both thumbsticks. Use [[F2]] to recenter and [[F3]] to recalibrate your body.

## Playing flat

Use the **Flat / VR switch** on this detail page. It changes the documented `Disable VR` value in the HowToFishXR config; it does not rename shared BepInEx files or remove the mod.

You can also launch once with `--disable-vr`.

## Controls

| Input | Action |
|---|---|
| [[Left Stick]] | Move or drive |
| [[Left Stick Click]] | Sprint |
| [[Right Stick]] left/right | Turn |
| [[Right Stick]] up/down | Change inventory slot |
| [[Right Stick Click]] | Crouch |
| [[Right Trigger]] | Use, fire, punch, reel or confirm |
| [[Left Trigger]] | Secondary action, cast or reel out |
| [[Right Grip]] | Pick up, interact or control the boat |
| [[Left Grip]] | Inspect, two-hand a gun or work the reel |
| [[A]] | Jump |
| [[B]] | Bait |
| [[Left Grip]] + [[B]] | Drop or throw |
| [[X]] | Reload |
| [[Y]] | Pause |
| [[F1]] / [[Both Stick Clicks]] | VR settings |
| [[F2]] | Recenter |
| [[F3]] | Calibrate |

## Update and deprecated status

The Hub compares the exact version installed under `BepInEx/.ts_versions` with Thunderstore. If Thunderstore marks the package deprecated, the installer shows that prominently instead of presenting the build as known-compatible. A future game update can then be covered with the archived depot command documented in the Hub test archive.

## Uninstall

**Uninstall now** removes only files listed in the HowToFishXR ownership manifest. Changed files are preserved, shared BepInEx stays, and your generated config remains for a later reinstall.

## Credits

- HowToFishXR by J_axon: https://thunderstore.io/c/how-to-fish/p/J_axon/HowToFishXR/
- BepInEx 5: https://thunderstore.io/c/how-to-fish/p/BepInEx/BepInExPack/
