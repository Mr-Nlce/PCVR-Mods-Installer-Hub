# ELDERBORN VR

## About the Game

ELDERBORN is a first-person melee action game built around heavy weapons, parries and smashing undead enemies through hostile dungeons. This setup combines the ready-made UUVR profile with the first-party ElderbornVRMod bridge for tracked hands, physical weapon motion and roomscale movement.

The bridge maps the shipped SteamVR controller action set to ELDERBORN, tracks both controllers, aligns the weapon with the right hand and follows physical headset movement for leaning and crouching. Performance of the original UUVR profile was described as excellent.

## What this setup installs

The Flat2VR Discord package contains BepInEx 5.4.23.5, UUVR 0.4.0 and Jean-Francois' preconfigured `raicuparta.uuvr-modern.cfg`. Setup adds the Hub project's own clean user build `ElderbornVRMod.dll` 1.27.0 at `BepInEx\plugins\ElderbornVRMod.dll`. This smaller first-party bridge omits development logging and tools and is bundled with the Hub; third-party VR mods and dependencies remain external downloads.

The installer supports Steam/Humble and both common GOG locations, verifies `ELDERBORN.exe`, skips the publisher's old runtime log and cache files, preserves existing configuration during updates and tracks every installed file for recovery and removal. The bundled bridge is also covered by the same ownership manifest, rollback and uninstall path.

The download is a message attachment. Setup first opens the Flat2VR invite, waits for you to return, then opens the exact download post and searches Downloads only after a third confirmation. A renamed archive is accepted when its safe contents form a complete UUVR package; an old filename, size or checksum never blocks a valid newer upload.

## Starting VR

1. Start the OpenXR runtime before launching the game. The profile was tested with SteamVR acting as the OpenXR runtime.
2. Launch ELDERBORN normally through Steam or GOG.
3. Press [[F3]] to enable UUVR.
4. ElderbornVRMod loads automatically and enables its roomscale and motion-control features; no second injector or manual file copy is required.
5. Press [[F4]] to recenter the tracked head position.

[[F5]] is shared with UUVR's interface shortcut and the bridge's head-position toggle. Normally leave it alone so roomscale stays enabled. If you use it to show the UUVR interface, press it again after finishing so head-position tracking returns to its previous state.

## Recommended display settings

Use **Windowed** display mode, disable **VSync**, **Bloom**, **Ambient Occlusion** and **Motion Blur**, then choose the target frame rate that suits your headset. Leave anti-aliasing **Off**. If you want anti-aliasing, use **FXAA**, never **TAA**.

![Recommended ELDERBORN VR display settings](Elderborn_recommended_settings.jpg)

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Right Stick]] | Turn |
| [[Right Trigger]] | Attack |
| [[Left Trigger]] | Block |
| [[A]] | Submit or jump |
| [[B]] | Cancel or kick |
| [[X]] | Interact or claim a reward |
| [[Y]] | Use a phial |
| [[Left Stick Click]] | Dash |
| [[Right Stick Click]] | Select the next weapon |
| [[Start]] | Pause or escape |
| [[Select]] | Tab action |
| [[F3]] | Enable or disable UUVR |
| [[F4]] | Recenter roomscale head position |
| [[F5]] | Toggle head-position tracking and the UUVR interface shortcut |
| [[F6]] | Toggle head aim |
| [[F7]] | Toggle VR controller input |
| [[F8]] | Toggle camera-rotation correction |
| [[F9]] | Toggle physical motion attacks |

## Updates, flat play and removal

Run setup again when the Discord post supplies a newer package or the Hub ships a newer first-party bridge. Existing BepInEx and UUVR configuration files are retained. Use the Hub's **Flat / VR** switch to park or restore the UUVR loader without deleting anything.

Use **Uninstall now** for a full Hub-owned removal. The uninstaller removes unchanged files written by this setup, restores files that existed beforehand and retains UUVR/BepInEx configurations, ELDERBORN, saves and unrelated mods. Files generated inside `ELDERBORN_Data` by UUVR on first launch remain conservative game-side state and are not guessed or deleted.

Mod information and support: [Flat2VR ELDERBORN thread](https://discord.com/channels/747967102895390741/1542935421649027152). Download post: [ElderbornVR.zip](https://discord.com/channels/747967102895390741/1542935421649027152/1542935629313351770).
