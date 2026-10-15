# EARTH DEFENSE FORCE 6 VR

WIP. EDF6VR adds native stereo rendering, roomscale 6DoF tracking, one- and two-hand weapon aiming, all four soldier classes and vehicles. Ranger can draw the second primary weapon from the left-temple holster and aim and fire both guns independently. Recent packages also add automatic headset-FOV fitting, resolution control and an optional locally generated HD-texture pack.

## About the Game

EARTH DEFENSE FORCE 6 is the large-scale cooperative action shooter from SANDLOT and D3PUBLISHER. The Hub recognizes Steam and `C:\Program Files\Epic Games\EarthDefenseForce6`; the publisher documentation and the Hub's external test evidence currently center on Steam, so Epic runtime compatibility remains unverified. Run the flat game normally once before installation so its first-run state exists.

Connect the headset and controllers and select a 64-bit OpenXR runtime before launch. For a Steam installation, Start in VR launches through Steam instead of opening `EDF6.exe` directly, allowing the required Epic Online Services initialization or update to run in the normal publisher context. The Epic Games Store fallback keeps its own direct executable route. Bigscreen Beyond 2 with SteamVR and Index controllers was tested by the author. Quest Touch bindings are included, but Quest/VDXR and Quest Link remain externally unverified by the Hub.

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

## Current installable package: 3.2.9

Version 3.2.9 fixes the Fencer gatling feed belt on the back and still includes
EDF6MultiSlot 1.6.9. Version 3.1.12 improved frame rate by about 10% according to the publisher and
includes EDF6MultiSlot 1.6.9. The installer follows current releases, including
prereleases, and verifies the package manifest before changing game files. If
GitHub is unavailable, its reviewed direct fallback is 3.2.9.

The 1.2 and 1.3 series substantially improves the original package: spatial audio tearing is largely fixed, the held weapon remains visible while rolling, laser sights follow the gun again and rendering is reported as roughly 20–30% faster. The rendered field of view now fits the headset automatically from the previous launch; restart once after changing headsets if a black edge appears.

`EDF6 VR setting.exe` beside `EDF6.exe` now handles picture size, VR or Normal
mode, HD texture generation, gun hand, scope zoom, vehicle hand aim and extra
VR settings. It replaces the old `VR_Play.bat`, `Set_Resolution.bat` and
`HD_Texture_2x.bat`; opening the publisher program removes those obsolete files.
The Hub's own Flat / VR switch remains available on this page. HD generation
uses your game files and can need substantial disk space; the package does not
ship generated textures or `ModLoader.ini`, so existing loader settings remain.

Ranger dash direction follows your view rather than the pointing controller. Ranger dual wield provides independent left/right aiming and fire, distinct recoil recovery, holster feedback and native weapon-change sounds. Version 2.0.0 adds seated VR cockpits with armour, ammunition and radar displays for every vehicle, improves hand and weapon alignment, and updates the bundled EDF6MultiSlot to 1.5.6 for eight-player co-op. All players in an eight-player room should use the same current package.

Version 3.0.2 adds weapon-mounted scope views: Native is sharper but costs
frames while zoomed; Digital is softer without that extra cost; Off restores
whole-view zoom. Vehicle aim can follow the gun hand per vehicle type. Proteus
two-seater crew figures and lighter Kurul shots are made locally from game
assets through the settings program. Sight lines can be thinned separately.
The release also fixes white ground on 23 maps after HD generation: press
Make under HD textures once to rebuild the affected files. Fencer shield
direction, scope crosshair placement and several cockpit details are corrected.
The bundled EDF6MultiSlot is now 1.5.33.

Version 3.1.0 makes Fencer melee weapons other than spears follow their normal
game swing while held in VR. Radio subtitles move toward the middle of the HUD
panel; `SubtitleCentre=0` in `EDF6VR.ini` restores their old position. Quick
chat bubbles appear beside players in the world, with size controlled by
`WorldChatBubbleSize`. Fencer compact HUD gauges, lowered-shield position,
Power Blade sheath and the quick-chat window layout are corrected. The bundled
EDF6MultiSlot is 1.5.34; its change is logging for eight-player mission drops.
Existing personal settings are preserved when updating the complete package.

Version 3.1.8 gives Ranger's left-hand gun its own reticle when dual wielding
and aligns Fencer hand-cannon shots with the barrel. Vehicle hand aim starts
enabled for Nix, Gravis and Combat Wagon; enable other vehicles individually
in EDF6 VR setting.exe. Versions 3.1.5 through 3.1.7 also improve combat-frame
cockpit comfort, show shots from two independently aimed guns to other players,
and address online disconnects. Eight-player hosts and guests should use the
current package because rooms made with older 8P components cannot be joined.
The bundled EDF6MultiSlot is 1.6.7. Existing settings are preserved.

Eight-player co-op is available with [[F2]], with enemy-count scaling for extra players while enemy stats stay capped at the five-player level. A host who enables eight-player rooms cannot be joined by players without the 8P component; a guest's local toggle does not matter.

## Display, switching and known limits

Open `EDF6 VR setting.exe` with the game closed to change picture size and
other options; changes take effect on the next launch. Anti-aliasing is off by
default because the optional filter softens the image. [[F11]] toggles VR only
for the current session, [[F12]] recenters and [[F1]] collects remaining loot
after mission clear.

Use the Hub Flat / VR switch or the VR mode selection in `EDF6 VR setting.exe`
to persistently park or restore only `Mods\Plugins\EDF6VR.dll`. Fencer movement
audio can crackle, Prominence can temporarily hide its weapon, and the Wing Diver
shot origin may lag during fast flight. The tutorial at the start of a new game
may need a normal game controller and a temporary F11 flat view. Multiplayer
and every weapon/vehicle variant have not been comprehensively tested.

## Updates and removal

The installer follows the newest GitHub release, including prereleases, that
actually contains one unambiguous `EDF6VR*.zip` publisher package. A notes-only
release cannot create a false Update badge or send the installer to an HTML or
source archive. The reviewed offline fallback is 3.1.0. The installer preserves
an existing `EDF6VR.ini`, `EDF6ClearLoot.ini` and `ModLoader.ini`. On first
launch, the mod creates `EDF6VR.ini` if missing, or adds new defaults to an
existing copy. The shipped defaults are in `EDF6VR\EDF6VR.defaults.ini`.
The Hub updates a shared `winmm.dll` only if it can prove ownership or you
explicitly agree to back up a different older loader. A modified parked Flat
DLL is preserved and setup stops for review. Uninstall now keeps the shared
loader and its backup for other EDF6 mods.

Uninstall now removes unchanged Hub-owned EDF6VR package files and the
bundled Clear Loot plugin. It leaves generated HD textures, shared EDFModLoader
components, personal settings, saves and unrelated plugins. Delete generated
HD textures through `EDF6 VR setting.exe` before removal if desired.

- [EDF6VR project](https://github.com/momotori01/EARTH-DEFENSE-FORCE-6-VR-MOD)
- [GitHub releases](https://github.com/momotori01/EARTH-DEFENSE-FORCE-6-VR-MOD/releases)
