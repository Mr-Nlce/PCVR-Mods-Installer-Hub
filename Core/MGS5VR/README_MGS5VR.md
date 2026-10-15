# Metal Gear Solid V: The Phantom Pain VR

MGS5VR is an experimental native OpenXR mod with true stereo rendering, tracked hands, motion-controlled aiming, a left-wrist HUD and VR-first field controls.

## About the Game

Return to Afghanistan and the Angola-Zaire borderlands as Venom Snake, building Diamond Dogs while infiltrating large open missions. This VR build targets the Steam edition of The Phantom Pain version 1.0.15.4.

## Before installation

- Close the game completely.
- The current publisher build requires The Phantom Pain 1.0.15.4, an active PC OpenXR runtime and the Microsoft Visual C++ x64 runtime.
- Quest 3 with Touch controllers is tested. Other headsets and controllers remain unverified.
- MGS5VR uses `dinput8.dll`. The Hub backs up an existing file, but another proxy mod using that filename cannot operate at the same time.

## How to play

1. Connect the headset and select its software as the active OpenXR runtime.
2. Launch MGSV normally through Steam and use the Action Type controller layout.
3. Load Continue → Resume Game before entering VR.
4. Tracked VR enters automatically. Optional presentation and recenter bindings
   can be changed in `mgs5vr-controls.ini`.

Title screens, loading screens and some cutscenes can remain on the large in-headset screen before tracked VR is entered.

The hospital-bed and character-creation display issue remains open. If the prompt is visible only as a shadow on the wall, press Enter; if character creation appears as a pale blue-white screen, use the desktop view through the Meta dashboard. Finishing the prologue in flat mode may help with a particular save, but the publisher does not consider it a proven universal fix.

## Controls

![MGS5VR Quest Touch field controls](metal-gear-controls.jpg)

| Button | Action |
|---|---|
| [[Left Stick]] / [[Right Stick]] | Move / turn |
| [[Left Stick Click]] | Sprint |
| [[Right Stick Click]] | Quick dive |
| [[Right Grip]] / [[Right Trigger]] | Ready weapon / fire |
| [[Right Grip]] + [[Left Stick Click]] | Binocular zoom |
| [[B]] | Reload |
| [[Right Stick Down]] tap / hold | Crouch or stand / prone |
| [[Y]] | Interact / pick up |
| [[Left Trigger]] + [[Right Stick]] | Hold trigger and select from the wrist picker |
| [[Menu]] tap / hold | iDroid / pause |
| [[Menu]] + [[A]] hold | Toggle complete native-button mode |
| [[Left Grip]] + [[Y]] | Equip binoculars |
| [[Left Stick Click]] while using binoculars | Change magnification |
| [[Right Stick Up]] while aiming a compatible scope | Change scope zoom |
| [[X]] | Open Commands |

## Current experimental-2026-10-11 update

The reviewed October 11 publisher ZIP targets The Phantom Pain 1.0.15.4. It
adds optional God mode, world markers for acquired enemies, a close-cover
firing toggle and revised handheld iDroid controls. It also fixes night-vision
obstruction, Rewards confirmation, helicopter movement and D-Dog visibility.
Existing personal settings stay with the publisher's Update / Keep My Settings
route. The `experimental` asset name is explicitly approved for this Current
route after opening the official ZIP; it is not a depot or legacy package.

### Earlier October 2.1 changes

The October 2.1 prerelease makes the right-hand handheld iDroid the default.
An existing explicit world-panel preference is preserved; set
`settings.handheld_menus = 0` to choose that mode. The update also changes
hand-pose retention during tracking interruptions, native iDroid menus and
the bounded GPU frame handoff. The publisher still reports unresolved OpenXR
submission stalls, intermittent weapon selection and incomplete physical
headset and full-game coverage. Existing personal controls and settings stay
in place when the Hub installer updates the mod.

### October 2 changes

The October 2 build enables Map control labels by default and corrects native
prompt destinations for Items, Commands, vehicles and Mother Base. Bound
controller touch sensors can acquire VR input ownership; unbound touches do
not. Support-hand guidance follows the authored palm contact on noncompact
firearms. Binocular material preparation was corrected, but its native housing
lighting remains experimental and defaults off. Existing personal bindings
are preserved during update. The publisher still lists continuous stereo,
physical headset acceptance, all weapon alignments and full-game completion
as open. Close MGSV before installing the complete prerelease package.

### October 1 changes

The October 1 experimental build repairs a completed ACC Rival-guide lock that could block Development and iDroid input. Steady scope glass and independent lens exposure are on by default for supported TPP. The launcher adds live 3D previews for 55 VR fit settings, including iDroid placement. One-hand weapon tilt defaults to -30 degrees. Optional VR prompts can reflect the player's saved bindings. These changes have publisher simulator and scoped native test evidence; full-campaign, every weapon/menu path, continuous flicker-free display and physical-headset acceptance remain open. The publisher's optional FieldKit and launcher use Edge WebView2; the Hub installs the tracked game hook and controls tools, not those standalone publisher UIs.

The importer now produces eight required assets from your own game files: binocular, CQC, radio and iDroid model/material pairs. The Hub checks all eight before it records installation and removes them through its ownership manifest.

### Earlier changes

The September 24 build adds a tilted world quad for iDroid and pause, optional
handheld presentation, aim alignment, more configurable controls and ergonomics,
and updated launcher settings tools. The earlier build changes sprint to left-stick click, adds right-grip plus left-click
binocular zoom, configurable smooth/snap/off turning and a native vehicle-camera
path. A complete native-button mode is available by holding [[Menu]] + [[A]].
The release also supplies an external `Edit-Controls.cmd` tool that validates
bindings before saving and keeps a backup of the previous controls file.
The September 20 build fixes Steam startup by supplying the game identity on
direct headset launch, restores the tap/hold iDroid and pause behavior, makes
right [[B]] return through iDroid categories and lets a held [[B]] escape the
FOB tutorial lock. Wrist/equipment interaction, binocular eyes, peripheral
world rendering, LOD behavior and default smooth turning were also refined.
Existing settings are preserved. Ground Zeroes, physical punches, binocular
zoom and every full-body command path remain unfinished.

## Recommended display settings

Start with Windowed mode, Post Processing High for anti-aliasing, Depth of Field disabled and Motion Blur off. Image quality and stable frame rate depend on the headset resolution and PC.

## Experimental status

Native binocular marking, powered arms, physical body grabs, enemy motion-hit reactions, sustained vehicle control and every gameplay state are not fully implemented or headset-tested. Motion melee and driving remain experimental. This release does not promise complete campaign coverage or a locked 90 FPS.

## Updates and removal

The installer follows the newest GitHub prerelease and deliberately selects the MGS5VR ZIP rather than the separately attached controls image or SVG. It runs the release's owned-game importer before changing the game folder, then installs the required binocular model/material, controls validator and editor. Updates preserve both `mgs5vr.ini` and `mgs5vr-controls.ini`. Use Uninstall now on this page to remove only unchanged MGS5VR-owned files and restore a prior `dinput8.dll`; settings, saves and unrelated files remain.

## Credits and support

- MGS5VR by [nikamigaming-create](https://github.com/nikamigaming-create/MGS5VR)
- [GitHub releases](https://github.com/nikamigaming-create/MGS5VR/releases)
- Community project, not affiliated with Konami.

The battlefield changes when every movement is your own.
