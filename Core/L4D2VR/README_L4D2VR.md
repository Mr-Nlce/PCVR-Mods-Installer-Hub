# Left 4 Dead 2 VR

**Mod:** L4D2VR (auto-updates to latest)
**Author:** keyou91
**More info:** https://github.com/keyou91/l4d2vr

## What this installer does

1. Guides you through the recommended in-game video settings
2. Copies the required Steam launch parameters to your clipboard
3. Opens Steam game properties so you can paste them in
4. Queries the GitHub API for the latest L4D2VR release and installs it directly into your game folder. The author sometimes replaces the ZIP under an existing tag without a version bump, so re-running the installer will always pick up the newest build.
5. Optionally opens the L4D2VR Config Tool for advanced VR settings

## Alternative: Steam Workshop (auto-updates)

The mod is now also on the Steam Workshop, which keeps it updated
automatically whenever the author publishes a new version:
https://steamcommunity.com/sharedfiles/filedetails/?id=3724995607

Note this is not fully automatic - after subscribing you still do a
one-time manual step:
1. Subscribe, then launch the game once (**Start in VR** in the Hub works) and let the download finish
2. Find the file at `left4dead2\addons\workshop\3724995607.vpk` in your
   game folder
3. Rename its extension from `.vpk` to `.zip`, open it, and extract all
   contents into your game root directory

This installer instead pulls the same build straight from the author's
GitHub and unpacks it for you, so you don't have to do the rename/extract
by hand - but the Workshop is the better choice if you want hands-off
updates. Either way it's the same mod by the same author.

## Recommended Video Settings

| Setting | Value |
|---|---|
| Film Grain Amount | All the way down (0) |
| Filtering Mode | Anisotropic 16x |
| Shader Detail | Very High |
| Effect Detail | High |
| Model / Texture Detail | High |
| PAGED Pool Memory | High (use Low if you have many mods) |

## Steam Launch Parameters

```
-heapsize 524288 -processheap -high -novid +crosshair 0 -w 1280 -h 720 +mat_queue_mode 0 +mat_vsync 0 +mat_antialias 0 +mat_grain_scale_override 0
```

## Controls

**Left controller:**
- **[[Left Stick]]:** Move
- **[[Left Stick]] click:** Recenter
- **[[Left Grip]]:** Reload
- **[[Left Trigger]]:** Bash
- **[[A]]:** Unused
- **[[B]]:** Open menu

**Right controller:**
- **[[Right Stick]]** up/down: Switch between weapons and medpacks
- **[[Right Stick]]** left/right: Rotate camera
- **[[Right Stick]] click:** Flashlight on / off
- **[[Right Grip]]:** Crouch
- **[[Right Trigger]]:** Shoot gun or strike with weapon
- **[[A]]:** Jump
- **[[B]]:** Grab objects, open / close doors

## Turning VR off
Two ways, and they are not equivalent:

- **Launch option `-nohmd`** - the game starts flat and **keeps DXVK**. This is
  the author's preferred route and the better one for a quick flat session.
- **Park `d3d9.dll`** (the Hub's Flat/VR button does this). It also turns VR off,
  but that file **is DXVK** - parking it drops the Vulkan translation layer with
  it, along with its shader-stutter and frame-pacing work. The author says he
  would keep the file for that reason alone.

Either way, the mod hides the crosshair, so type `crosshair 1` in the console to
get it back.

## New in v0.7.9 - v0.8.1
- **Manual throwing.** Press the trigger to enter throwing mode with a throwable,
  cola bottle or map item; release to throw by your controller's swing. **Use +
  trigger** throws weapons and consumables too, without arming a throwable.
- **Object pull.** Aim at an item in range, and when its outline lights up, hold
  grip and pull back. Keep holding, or press grip again, to take it into your hand.
- **First-person body and arm IK** - VR players can see each other's body and hand
  movement. Arms are rendered by default and the SteamVR gloves are off; if you
  would rather not see the arms, enable the cropped native viewmodel arms.
- **`vrconfig` in the console, or just [[F8]]**, opens the settings panel - you no
  longer have to go through the pause menu.
- **Separate grab / reload input.** With it on, grip only enters two-handed mode
  and reload grabbing goes on the trigger (which must be bound to Reload, Crouch,
  Jump or SecondaryAttack).
- **DXVK async pipeline and shader compilation** cut the stutter that shader
  compilation used to cause, plus a low-latency mode for input lag. Full ReShade
  support needs the **add-on version** of ReShade.
- **A HUD that stays hidden** if you want it, no longer triggered by an action.
- v0.8.1 fixes the first-person body not following the headset, arm IK distortion,
  and a reset-settings button that did nothing.

## Notes

- Start SteamVR **before** launching Left 4 Dead 2
- Aim controller **Up/Down** to show the HUD

## Framerate locked to half refresh?

If L4D2VR feels stuck at half your refresh rate (90Hz -> 45 FPS, 120Hz ->
60 FPS), your VR runtime or streaming app has probably enabled motion
smoothing / reprojection. Try turning it off:
- **SteamVR / Index / Vive:** Motion Smoothing
- **Meta Quest Link / Air Link:** ASW (Asynchronous SpaceWarp)
- **Virtual Desktop:** SSW (Synchronous Spacewarp)

The feature has a different name in each runtime, so check your own.

>>> No Mercy. Dead Center. Now in VR. Good luck, Survivor!
