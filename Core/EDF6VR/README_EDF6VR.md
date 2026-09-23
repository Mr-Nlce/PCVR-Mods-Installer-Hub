# EARTH DEFENSE FORCE 6 VR

**WIP.** EDF6VR adds native stereo rendering, roomscale 6DoF tracking, one- and two-hand weapon aiming, all four soldier classes and vehicles. Ranger can draw the second primary weapon from the left-temple holster and aim and fire both guns independently. Recent packages also add automatic headset-FOV fitting, resolution control and an optional locally generated HD-texture pack.

## About the Game

EARTH DEFENSE FORCE 6 is the large-scale cooperative action shooter from SANDLOT and D3PUBLISHER. The Hub recognizes Steam and `C:\Program Files\Epic Games\EarthDefenseForce6`; the publisher documentation and the Hub's external test evidence currently center on Steam, so Epic runtime compatibility remains unverified. Run the flat game normally once before installation so its first-run state exists.

Connect the headset and controllers and select a 64-bit OpenXR runtime before launch. For a Steam installation, **Start in VR launches through Steam instead of opening `EDF6.exe` directly**, allowing the required Epic Online Services initialization or update to run in the normal publisher context. The Epic Games Store fallback keeps its own direct executable route. Bigscreen Beyond 2 with SteamVR and Index controllers was tested by the author. Quest Touch bindings are included, but Quest/VDXR and Quest Link remain externally unverified by the Hub.

## Controls

EDF6VR emits normal Xbox-style gamepad input, so the game's own assignments still apply.

| Button | Action |
|---|---|
| [[Left Stick]] | Move relative to the headset's horizontal heading |
| [[Right Stick Left / Right]] | Turn |
| [[Right Stick Up]] | Y on foot; vertical vehicle input while seated |
| [[Right Stick Down]] | L3 on foot; vertical vehicle input while seated |
| [[Left Trigger]] | LT; fire the left gun while Ranger dual-wielding |
| [[Right Trigger]] | RT; fire the right-hand weapon |
| [[Left Grip]] | LB; beside the left temple, draw or holster Ranger's second primary weapon |
| [[Right Grip]] | RB |
| [[Right A]] | A / confirm; save weapon-placement adjustment |
| [[Right B]] | X |
| [[Left X]] | B / cancel on Quest; cancel weapon-placement adjustment |
| [[Left Y]] | Y on Quest |
| [[Left Stick Click]] | L3 |
| [[Right Stick Click]] | R3 |
| [[Quest Menu]] | Start / pause when exposed by the runtime |
| [[Both Stick Clicks]] | Reset weapon placement while editing |
| [[F1]] | Collect all dropped items after mission clear |
| [[F2]] | Toggle eight-player rooms |
| [[F3]] / [[Tab]] | Show squad members five through eight |
| [[F5]] | Toggle the FPS limiter |
| [[F11]] | Toggle VR for the current session |
| [[F12]] | Recenter head orientation and room reference |

Bring the support hand near the weapon's front support point for two-hand aim. For the secondary input layer, hold the right controller beside either temple: the right stick becomes the D-pad, left-stick click becomes Back/View and right-stick click becomes Start/Menu.

To adjust the weapon, hold the left controller beside a temple and hold left-stick down for three seconds. Sticks, triggers and grips then move and rotate the weapon; Right A saves and Left X cancels. Left-temple plus left-stick up for three seconds resets tracked view height.

## Current installable package: 1.7.4

The 1.2 and 1.3 series substantially improves the original package: spatial audio tearing is largely fixed, the held weapon remains visible while rolling, laser sights follow the gun again and rendering is reported as roughly 20–30% faster. The rendered field of view now fits the headset automatically from the previous launch; restart once after changing headsets if a black edge appears.

`Set_Resolution.bat` changes render sharpness without editing the INI. `HD_Texture_2x.bat` can generate sharper colour textures from your own game files without modifying the originals. The HD process takes about an hour, needs a Vulkan-capable GPU with 10 GB or more VRAM and can require roughly 40 GB of working/free space; the finished city-map textures occupy about 30 GB. The package deliberately no longer ships `ModLoader.ini`, so your existing loader settings remain intact.

Ranger dash direction follows your view rather than the pointing controller. Ranger dual wield provides independent left/right aiming and fire, distinct recoil recovery, holster feedback and native weapon-change sounds. The 1.7.4 package keeps the expanded Fencer controls, shoulder weapons, visible hands, controller-driven weapon riding, bundled Clear Loot and EDF6MultiSlot components, and adds the publisher's package manifest plus dedicated 1.7.4 release notes. Its runtime layout remains compatible with the Hub's owned-file transaction.

Eight-player co-op is available with [[F2]], with enemy-count scaling for extra players while enemy stats stay capped at the five-player level. A host who enables eight-player rooms cannot be joined by players without the 8P component; a guest's local toggle does not matter.

## Display, switching and known limits

The default source resolution is 3840x2160, but the current package can safely change its render scale with `Set_Resolution.bat` while the game is closed. Do not change resolution during VR play. Anti-aliasing is off by default because the optional filter softens the image. [[F11]] toggles VR only for the current session, [[F12]] recenters and [[F1]] collects remaining loot after mission clear.

Use the Hub Flat / VR switch or `VR_Play.bat` to persistently park or restore only `Mods\Plugins\EDF6VR.dll`. Fencer movement audio can crackle, Prominence can temporarily hide its weapon, and the Wing Diver shot origin may lag during fast flight. The tutorial at the start of a new game may need a normal game controller and a temporary F11 flat view. Multiplayer and every weapon/vehicle variant have not been comprehensively tested.

## Updates and removal

The installer follows the newest GitHub release, including prereleases, that actually contains one unambiguous `EDF6VR*.zip` publisher package. A notes-only release cannot create a false Update badge or send the installer to an HTML/source archive. The reviewed offline fallback is 1.7.4. The installer preserves `EDF6VR.ini`, `EDF6ClearLoot.ini` and an existing `ModLoader.ini`. **Uninstall now** removes unchanged EDF6VR package files—including the resolution and HD-texture tools—and the bundled Clear Loot plugin; it leaves generated HD textures, shared EDFModLoader components, personal settings, saves and unrelated plugins. Turn generated HD textures off with `HD_Texture_2x.bat` before uninstalling if you want those large generated files removed too.

- [EDF6VR project](https://github.com/momotori01/EARTH-DEFENSE-FORCE-6-VR-MOD)
- [GitHub releases](https://github.com/momotori01/EARTH-DEFENSE-FORCE-6-VR-MOD/releases)
