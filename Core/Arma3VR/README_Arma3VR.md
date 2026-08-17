# Arma 3 VR - A3VR Hybrid

An experimental **OpenXR bridge** for 64-bit Arma 3 by **gborgogno**. It presents
the game's image in your headset, feeds head movement through Arma's own
FreeTrack input path, and maps OpenXR controllers to native Arma controls.
**No VorpX required.**

> **Early community alpha, and not a native VR port.** Unofficial - not
> affiliated with Bohemia Interactive.

## What "hybrid" means - read this before judging it

A3VR wraps OpenXR presentation, head tracking and controller input **around**
Arma's existing renderer. It does not replace it.

**Both eyes receive the same image.** That is called comfort-mono, and it is the
compatibility default: you get a stable binocular picture and head-tracked
spatial cues, but **no true stereo depth**. Native per-eye rendering needs
engine-level camera work that is still being investigated.

Moderate black borders are **intentional** - they reduce zoom and keep the image
clear.

## Two ways to install

The Hub's installer asks which you want:

1. **From GitHub** - it places `@A3VR_Hybrid` beside your game, and the Hub can
   then tell you when a newer alpha appears.
2. **From the Steam Workshop** - nothing is installed locally; you subscribe and
   Steam keeps it updated.

Both give you the same mod. **Do not use both at once**, and never enable two
A3VR variants in the same Launcher preset - two render bridges cannot share one
Arma process.

## Quick start - none of this is automatic

1. Start the headset and activate the OpenXR runtime you intend to use
2. In the official Arma 3 Launcher, enable **A3VR - Arma 3 Hybrid VR** (only this one)
3. **Disable BattlEye** - the bridge is unsigned
4. In Arma's controller/device settings, **enable FreeTrack** when it is listed
5. Start the game and press [[F8]] once to recenter
6. If the right controller does not move your aim, press [[F9]]

**No FreeTrack in the settings at all?** Close Arma, run
`START_A3VR_LAUNCHER.cmd` from the mod folder first, then launch. That starts the
runtime early enough for Arma to find it - the author's own answer to exactly
this report.

If FreeTrack is still missing, install **OpenTrack** and run one tracking
session. In OpenTrack, choose **Oculus Rift Runtime** or **SteamVR** under
**Input**, whichever matches your setup. Put on the headset, click **Start**,
and let tracking run for a few seconds. This should create the required
FreeTrack file and registration. You can then stop and close OpenTrack; A3VR
does not need it running while you play. FreeTrack should now appear in Arma's
controller settings, where you can enable it.

## The FOV profile is a separate step

Copying the files - or subscribing on the Workshop - does **not** apply the mod's
FOV and graphics profile. With Arma **closed**, run `START_A3VR_LAUNCHER.cmd`
once. It backs up `Arma3.cfg` and your player profile first. Without it the image
looks zoomed in. Re-run it if Arma or another mod later overwrites those values.

## Controls

| Input | Action |
|---|---|
| Headset | Head tracking |
| [[Right Controller]] motion | Aim in game / point at the UI cursor in menus |
| [[Right Trigger]] | Fire |
| [[Right Grip]] | Aim down sights, and magnified optics |
| [[A]] | Reload |
| [[B]] | Throw the selected grenade |
| [[Right Stick Click]] | Fire mode |
| [[Right Stick]] left / right | Smooth turn |
| [[Right Stick]] up / down | Stand / crouch - view pitch in vehicles |
| [[Left Stick]] | Move and strafe |
| [[Left Stick Click]] | Sprint |
| [[Left Trigger]] | Vault / step over |
| [[Left Grip]] | Action Menu radial wheel |
| [[X]] | Interact |
| [[Y]] | Switch primary and sidearm |
| [[F7]] | Toggle the left-hand calibration skeleton |
| [[F8]] | Recenter head tracking |
| [[F9]] | Toggle motion aiming |
| [[F10]] | Force or release the VR UI cursor |

Each deliberate flick of [[Right Stick]] up or down changes **one** stance level -
stand, crouch, prone. Return the stick to centre before the next step. In menus,
the map, inventory and Zeus you point with the right controller; a cyan cursor
marks the real click position, [[Right Trigger]] clicks and [[Right Stick]]
scrolls.

**No VR button sends Escape or opens the pause menu.**

**Keep keyboard and mouse within reach.** Arma has many contextual commands with
no VR binding yet, and no VR button sends Escape or opens the pause menu.

## Headset support

- **Validated:** Meta Quest over Air Link with the Meta OpenXR runtime
- **Reported working:** VDXR
- **Not validated:** Virtual Desktop through SteamVR, native SteamVR headsets, Pimax

Only one application can own the active OpenXR session. If the headset stays
black, make sure the intended runtime is active and close other VR apps first.

## Multiplayer

**Keep BattlEye off.** Play locally, or only on servers that explicitly allow
client-side native modifications. Do not join protected servers.

## Known limits in this alpha

- No true stereo, no independent hands, no manual reload or physical inventory
- Full stand / crouch / prone cycling is not reliable
- Vehicles, Zeus and the editor, scopes and the VR cursor are experimental
- The Action Menu radial wheel is discouraged - its input can fight VR controls

## Credits and legal

Mod by **gborgogno** - https://github.com/gborgogno/a3vr-arma3
Steam Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3782798344

An unofficial community project, not affiliated with Bohemia Interactive. The
project does not modify network traffic and does not overwrite base-game files.

**Stop immediately if the image causes eye strain, nausea or headache.**

>>> Someone already took the high ground. It is always the sniper.
