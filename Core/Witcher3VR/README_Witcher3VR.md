# The Witcher 3 VR Installer

## About this mod
**Witcher3VR** by tig3rmast3r brings native stereo VR to the **DirectX 12** build of The Witcher 3: Wild Hunt. Same-tick geometry stereo, 6DoF head look synchronised with OpenXR, crossbow aiming that follows the headset, a resizable HUD and menus, and an adjustable render window inside the headset. DLSS, DLAA and TAAU all work; there is also an optional 5:4 cinema framing and an experimental first-person exploration view.

This is a work in progress and under active development. The **Alpha** label refers to validation, not to the state of the game: it has been tested on a limited number of headset and OpenXR combinations, and on that tested hardware the author describes the core game as fully playable.

https://github.com/tig3rmast3r/witcher3-vr

## Controls
You play with a **gamepad or mouse and keyboard**. VR motion controllers are not supported and the author states they are not planned. The headset handles looking around and crossbow aiming; everything else stays on the pad.

The launcher has an optional **Gamepad Snap Turn + Head Follow** mode that adds 30-degree snap turning and headset-directed movement - it only applies while the experimental first-person view is active, and it is off by default.

## Hotkeys
- [[F7]] Switch the HUD between the VR and Cinema3D banks
- [[F8]] Toggle between Standard and Near view
- [[F9]] Recenter the VR view
- [[F10]] Toggle cinema mode - mono or stereoscopic, following your render mode
- [[F11]] Toggle first person (experimental)

After a loading-screen video ends, the view recentres by itself two seconds
later, along the same path as [[F9]].

## New in v0.9.5 Alpha 1

**Two new render modes: AER + AFW**, as TAAU or DLSS. AER draws one whole eye at
a time and PureDark's AFW generates the other - a high-performance alternative to
classic stereo, which renders both eyes independently. These are also the **only**
routes that can use ray tracing.

**Ray tracing**, experimental: the game's ray-traced ambient occlusion, shadows
and reflections in VR. Considerable GPU and VRAM cost, and it can flicker or leave
artefacts around cutscenes.

**Asymmetric projection now works in every mode**, not just Stereo without AA.
Each eye uses its real off-axis OpenXR view instead of rendering a larger
symmetric area whose outer pixels you never see. The gain depends on the headset -
on a Quest 3 the author reckons asymmetric at Virtual Desktop **HIGH** looks like
symmetric at **GODLIKE**, so you can drop two resolution steps.

**The first-person view was overhauled** ([[F11]]): better camera placement,
Geralt turns to your view while standing, optional strafe and backpedal, snap turn
at 30/45/60 degrees, headset-directed movement, less head bobbing, and face and
hair hidden so they cannot clip into the camera. It can hand over to third person
during combat and come back afterwards.

**The launcher detects your headset resolution itself** - AUTO asks the OpenXR
runtime right before launch and writes that exact value. Cinema mode gained a
**4:3** option beside 5:4.

**Subtitles and dialogue can be moved and resized** in the HUD editor, separately
for the VR and Cinema3D profiles, with preview text so you can adjust them without
being in a conversation. **If you had tuned your HUD before, check those two after
updating** - they now control the real cutscene text.

**Optional: hide the static HUD outside combat** (off by default). Minimap, quest
tracker, buffs, health, equipment and the rest disappear while exploring and come
back by themselves in combat, with Witcher Sense, or during a horse race.

> **Pimax owners:** Pimax's own OpenXR can cap **Stereo** mode at half your
> headset refresh - 45 fps on a 90 Hz display. AER is not affected. Use SteamVR's
> OpenXR for proper stereo.

## What you need first
- The Witcher 3: Wild Hunt **Next-Gen**, at **Patch 4.04** or newer. Older versions and rollback branches are not supported.
- The game started as **DirectX 12** - the mod only exists in the `x64_dx12` branch.
- **The game started once, as DirectX 12, before you touch the VR launcher.** That first start is what creates your DirectX 12 profile, `Documents\The Witcher 3\dx12user.settings`. The launcher edits that file; it never creates it.
- A working OpenXR runtime.
- An NVIDIA RTX card if you want DLSS or DLAA.

Headsets with canted displays (Pimax and similar) need the manufacturer's **Parallel Projection** mode; native canted support is not implemented yet.

## How the installer works
The Hub finds your game folder across Steam, Steam GOTY, GOG and Epic by probing for `bin\x64_dx12\witcher3.exe`, downloads the newest release from GitHub and merges it into the game root. The package mirrors the game's own layout, so the files land in `bin\x64_dx12`, `mods` and `Witcher3VR` where the game expects them. The bundled `modWitcher3VRStateBridge` script is part of the mod and supplies the movement and combat state the first-person view needs.

## Launching
Launch with **Start in VR** in the Hub, or from the **The Witcher 3 VR** desktop shortcut. Both open the mod's own launcher, where you choose the rendering mode and resolution and then start the game from there. The launcher exists because each mode needs different hooks, and some have to be active before the game starts.

## Start the game once first
The VR launcher works on the game's own DirectX 12 profile:

`C:\Users\<You>\Documents\The Witcher 3\dx12user.settings`

**The game writes that file, the mod does not.** On a fresh install it does not exist yet, and neither does it exist if you have only ever played the DirectX 11 version - DX11 and DX12 keep separate profiles (`user.settings` and `dx12user.settings`).

So: start The Witcher 3 the normal way, choose **DirectX 12**, wait until the main menu is up, then quit. After that the launcher has something to read.

Until it exists, every button in the VR launcher - **Configure Settings for VR**, **Restore Defaults**, **Save & Launch** - ends with:

`Could not open: C:\Users\<You>\Documents\The Witcher 3\dx12user.settings`

That message means the profile is missing. It does not mean the mod installed wrong.

## Required game settings
The launcher's **Configure Settings for VR** button applies the settings the mod was developed against and backs up your profile first; **Restore Original Settings** puts it back. By hand:

| Setting | Value |
|---|---|
| Ray tracing | **Only** with AER + AFW (TAAU or DLSS). The launcher forces it off in every other mode |
| Screen Space Reflections | Off or Low |
| Motion blur | Off |
| VSync | Off |
| Maximum FPS | Unlimited |
| NVIDIA Reflex | Off |
| Windows HDR | Off (Windows setting, not in the game) |

**Windows HDR must be off.** With it enabled the headset shows a black screen. The game has no HDR toggle of its own, so switch it off under Windows Settings > System > Display > HDR.

Resolution and anti-aliasing are controlled by the launcher, not the game menu. Texture quality also drives LOD distance: Medium suits No AA and FXAA, Medium or High suits TAAU and DLSS.

## If the game language changed
The launcher's **Configure Settings for VR** rewrites your whole DirectX 12 profile, and the language entries live in that same file - so the game can come back up in a language you never picked. It is fixed in the file itself, no reinstall needed.

Close the game, open

`C:\Users\<You>\Documents\The Witcher 3\dx12user.settings`

in Notepad, find the `[Localization]` section and set all four lines to the language you want:

```
[Localization]
RequestedSpeechLanguage=EN
SpeechLanguage=EN
RequestedTextLanguage=EN
TextLanguage=EN
```

The codes are two letters: `EN` English, `DE` German, `FR` French, `IT` Italian, `ES` Spanish, `PL` Polish, `RU` Russian. Text and speech can differ - English voices with German subtitles is `SpeechLanguage=EN` plus `TextLanguage=DE`. A spoken language only works if its audio pack is installed: in Steam, right-click the game > Properties > Language.

Since the next-gen update this is the DirectX 12 profile; the DirectX 11 build reads the same section in `user.settings` instead.

## Known limitations
- **High Screen Space Reflections** and the **far/distant camera modes** are not implemented. SSR must be Low or Off.
- **Ray tracing is experimental** and works only on the AER + AFW routes. It can flicker, and can leave artefacts when a cutscene starts or ends.
- Native canted displays ARE supported - each OpenXR eye pose is used directly, so no parallel-projection workaround is needed.
- Loading screens are not yet presented correctly in VR - they may change size, appear blank or show duplicated images.
- Some shadows can flicker in stereo.
- Third-party mods **and ASI loaders** are unsupported at this stage. Before reporting a bug to the author, reproduce it with all other mods disabled.
- The first-person view is meant for exploration. Third person is the recommended view for combat, and the launcher can switch back automatically when a fight starts.
- Do not open feature requests for motion controllers. The author has stated they are not part of the development plan.

## Reporting a bug to the author
The launcher has a **Diagnostic Logging** option. Turn it on, reproduce the problem, close the game normally, and attach the generated `witcher3vr.log` together with your `witcher3vr.ini`, headset model, OpenXR runtime, GPU and the rendering mode you used.

https://github.com/tig3rmast3r/witcher3-vr/issues

## Supporting the mod
The mod is free. Donations are optional and never unlock exclusive builds, features or support.

https://ko-fi.com/tig3rmast3r

## Credits
- **Witcher3VR** by tig3rmast3r - https://github.com/tig3rmast3r/witcher3-vr
- The DX12 and VR architecture was informed by praydog's REFramework and UEVR; the resolution-override approach is adapted from emoose's DLSSTweaks.
## Key points from updates
- **Cutscenes and Cinema Mode render in stereo** when a stereo rendering mode
  is selected, and there is an experimental option to keep automatic cutscenes
  in full VR. Manual Cinema Mode on F10 stays independent of it.
- Menus, inventory and Cinema Mode are no longer head-locked - you can look
  around freely.
- Snap turn is selectable at 30, 45 or 60 degrees, defaulting to 45.
- TAAU works during gameplay and cutscene transitions now, and the launcher
  survives Windows display scaling.
- Your `witcher3vr.ini` is migrated on the first launcher start: rendering
  mode, resolution, the full-VR preference and your own settings are kept.
- Known and not yet fixed: black borders at the image edges on some headsets,
  loading screens changing size or appearing blank, and severe culling during
  VR cutscenes - that last one is how the game itself is built. Ray tracing
  and screen space reflections on High are not supported, and canted displays
  need parallel projection.
