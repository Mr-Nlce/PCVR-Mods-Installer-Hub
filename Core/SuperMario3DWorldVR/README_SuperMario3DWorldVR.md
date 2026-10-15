# Super Mario 3D World VR

## About the Game

Super Mario 3D World is Nintendo's cooperative 3D platform game: run through compact courses, collect stars and stamps, and use character abilities and power-ups to reach the goal. This unofficial PC VR layer by Destroyjevski renders the Wii U game stereoscopically through Cemu and OpenXR. Bring your own legally obtained Wii U game dump. Neither the game nor Cemu is supplied by the Hub or the mod.

## Requirements and setup

The [publisher's VR releases](https://github.com/Destroyjevski/SuperMario3DWorld-VR/releases) provide an installation ZIP, separate from GitHub's source-code ZIP. The Hub downloads the install ZIP, places the complete `Mario3DWorld-VR` folder beside `Cemu.exe`, and records the release only after its required layer, launcher, graphics packs and publisher VERSION file match the selected release. GitHub prereleases are included in update checks. The reviewed package is Alpha 1.6b. It includes the Alpha 1.41 fix for VR stopping after roughly ten minutes, Alpha 1.5's portable Cemu data-folder detection and Captain Toad headlamp improvement, and Alpha 1.6's touch and blowing interactions. The 1.6b hotfix extends touch, blowing and the head-directed Captain Toad lamp to USA v1 and keeps the microphone closed outside levels that ask for blowing. It remains an early build without a confirmed full playthrough.

Use Cemu 2.6 on Windows x64 with the Vulkan renderer and an active OpenXR runtime. The supported original game is European v0 (title ID `0005000010145D00`) or USA v1 (`0005000010145C00`). Other revisions are not covered. Before installing, start your own game once in Cemu with a gamepad and close Cemu normally. Choose the extracted game folder containing `code/RedCarpet.rpx` and `meta/meta.xml`, then choose the writable Cemu folder containing `Cemu.exe`. The Hub leaves the game dump, Cemu settings, saves and keys alone.

Start VR through the Hub's Play action, which runs the publisher's `Start-VR.cmd`. Keep its launcher window open, then select your game in Cemu. Quit Cemu normally when done. The launcher copies its graphics packs into Cemu's data folder for the session, enables Vulkan and restores the previous graphics API and debug-logging settings after a normal exit. It keeps settings backups in `Mario3DWorld-VR-backups` under Cemu's data folder. If Cemu or the launcher is forcibly closed, inspect enabled graphic packs before flat play. No system-wide Vulkan layer is installed.

## Camera modes and controls

The view starts in Diorama. One right-stick click changes to Close diorama, a second to First Person, and a third returns to Diorama. Each change also resets camera turning and recenters the headset position. Intro and world-map scenes use Diorama. In first person, movement follows horizontal head direction plus stick turning; looking up or tilting your head does not steer movement. Menus and the HUD stay room anchored.

### Gamepad

Keep your normal Cemu gamepad mapping. Ensure the physical right stick click maps to the emulated right stick click. The VR controller gesture below does not change your gamepad D-pad.

| Button | Action |
|---|---|
| [[Right Stick Click]] | Cycle Diorama, Close diorama and First Person; recenter. |
| [[Left Stick]] | Move with the game's normal mapping. |
| [[Right Stick]] | Turn the camera. |
| [[D-pad]] | The game's normal directional input. |

### VR controllers (Quest / Touch defaults)

Set emulated controller 1 to Wii U GamePad. The VR controllers use their own bindings and need no button mapping in Cemu. Other controller layouts have not been validated.

| Button | Action |
|---|---|
| [[Left Stick]] | Move. |
| [[Right Stick]] | Turn the camera. |
| [[Right Stick Click]] | Cycle camera modes and recenter. |
| [[Left X]] | Wii U X: run or action. |
| [[Left Y]] | Wii U Y: game action. |
| [[Right A]] | Wii U A: jump or confirm. |
| [[Right B]] | Wii U X: run or action. |
| [[Left Trigger]] | Wii U ZL. |
| [[Right Trigger]] | Wii U B: jump or menu back. |
| [[Left Grip]] | Wii U L. |
| [[Right Grip]] | Wii U R. |
| [[Right Grip]] hold | Aim the touch ring with the right controller on European v0 touch platforms. |
| [[Right Grip]] + [[Right Trigger]] | Touch the aimed point; without grip, trigger keeps its jump action. |
| [[Right Controller]] near [[Headset]] | Alternative blowing gesture; hold until the controller vibrates. |
| [[Left Menu]] | Wii U Plus: pause. |
| [[Left Stick Click]] | Wii U Minus. |
| [[Left Controller]] near your head + [[Right Stick]] | D-pad directions; a short vibration confirms the gesture. |

Alpha 1.6b supports touch and blowing on the European v0 and USA v1 games. For touch, hold
[[Right Grip]] and aim with the blue ring, then press [[Right Trigger]]. The
game's own 3D hand appears where the original game draws it. The mod listens
to the Windows default recording device for steady blowing; Cemu needs no
microphone setup. It processes audio in memory and does not save or send it.
Speech alone does not count. To disable microphone blowing, set
`CEMUVR_BLOW_MIC=0` in `Start-VR.cmd`; the near-head controller gesture remains
available. A physical gamepad can still be used alongside VR controllers. The
default camera-mode button can be changed in the VR graphic pack settings.

## Graphics, limits and help

The default FPS pack targets 120 rendered stereo pairs per second with gameplay updates near 60 Hz; set your headset to 120 Hz for that preset. The 60 FPS preset is a safer starting point when 120 is unstable. 90 and 144 FPS are experimental. A 3840×2160 resolution graphic pack can sharpen the image if your GPU can sustain it; that community pack is not bundled. Publisher headset testing used an RTX 4080 and Virtual Desktop/VDXR. SteamVR sRGB compatibility was improved in Alpha 1.4, but broad runtime and hardware coverage remains limited.

Known issues include misplaced shadows, geometry missing outside the original camera view, imperfect depth effects, awkward fixed-camera/cinematic framing, and a room-anchored HUD that may leave view in first person. The publisher has not validated every death, respawn or scene transition. If VR does not start, check Cemu 2.6, Vulkan, your active OpenXR runtime, the supported game title ID, and that you launched Start-VR.cmd. The [publisher's install guide](https://github.com/Destroyjevski/SuperMario3DWorld-VR/blob/main/INSTALL.md) and [known issues](https://github.com/Destroyjevski/SuperMario3DWorld-VR/blob/main/KNOWN-ISSUES.md) have further details. A bug report should include mode, level, game and Cemu versions, GPU, runtime and FPS preset; never attach game data or keys.

The detail page's Uninstall guide and Uninstall now remove the Hub-owned VR folder files and restore unchanged name collisions. Original game data, Cemu, saves and unrelated graphic packs remain. Files that you changed after installation are preserved for review.

>>> One more stamp, one more star, and now the whole level has depth.
