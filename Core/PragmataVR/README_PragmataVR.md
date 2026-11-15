# Pragmata VR

## About the Game

Explore a deserted lunar research station as astronaut Hugh and android Diana. Combine shooting and real-time hacking to escape hostile robots and uncover what happened on the Moon.

## Choose Your Mod

Option 1: Pragmata VR by scubasteve2365. Third-person gamepad VR with an in-headset HUD editor and Native / Alternate Frame Warping (AFW). Requires Steam game 1.3.0.0.

Version 1.1 adds a Picture setting for the HUD and mod menu. Auto uses Steady on Virtual Desktop and Panel elsewhere. If the HUD distorts when you turn your head, try the other mode. The mod now remembers decoupled pitch and keeps the reticle aligned with the gun when looking up or down.

Option 2: Legacy REFramework by praydog. The original general RE Engine VR route remains separately available. It lacks the dedicated new HUD editor. Imported old AFW files are retained with their original framework. Updating legacy to a general nightly parks an old AFW plugin as PDAFWPlugin.dll.pcvrhub_off so incompatible versions cannot load together; removing the active Hub mod restores the original pair.

Installing or updating a mod prepares its separate package and does not activate it. Both can remain installed. Their Hub Play buttons select the matching runtime when you play.

## Install and Start

1. Use Start in VR in the Hub. Select Pragmata VR or Legacy REF.
2. Start your active OpenXR runtime before playing. Use Windowed display mode. Meta Quest: the publisher recommends Virtual Desktop with VDXR.
3. For Pragmata VR, click both sticks or press [[F1]] for its menu. Adjust HUD elements for your headset and choose Native or AFW.

The complete Pragmata VR package includes REFramework, PureDark's AFW plugin and the OpenXR loader. No separate AFW download is needed for option 1. Old HUD Controls / community HUD scripts conflict with the new HUD: their named files are moved to reframework/autorun/pragmatavr_disabled when you activate the new mod, and restored for legacy. Unknown scripts are left alone.

Keep per-headset settings in reframework/data. Updates and removal preserve them, your game settings and saves. Run the publisher's PragmataVR_collect_logs.bat from the active game folder to gather a bug report.

## Controls

Gamepad only; no motion controls.

| Button | Action |
| --- | --- |
| [[Left Stick Click]] + [[Right Stick Click]] / [[F1]] | Open or close the Pragmata VR menu. |
| [[LT]] / [[RT]] / [[Page Up]] / [[Page Down]] | Change menu tab. |
| [[D-Pad]] / [[Arrow Keys]] | Navigate. |
| [[A]] / [[Enter]] | Select, edit or finish. |
| [[RB]] / [[Shift]] (hold) | Larger editing steps. |
| [[B]] / [[Backspace]] | Back or close. |

## Performance

Start with low graphics settings, DLSS Balanced or Quality, and an appropriate headset resolution. Turn off ray/path tracing, frame generation and dynamic resolution. Native renders both eyes at the same moment; AFW reduces the rendering cost. Do not change display mode or resolution during VR play.

## Removal and Help

Use Uninstall now for the selected profile. The other mod, saves, per-headset settings and unrelated files remain. A changed user file is preserved; a conflicting existing HUD backup is reported rather than overwritten.

[Pragmata VR guide and releases](https://github.com/scubasteve2365/Pragmata-VR) · [Support scubasteve](https://buymeacoffee.com/scubasteve2365) · [Legacy REFramework](https://github.com/praydog/REFramework) · [Support PureDark](https://www.patreon.com/PureDark)

Hack the moon. Hold her hand. Step into the unknown.
