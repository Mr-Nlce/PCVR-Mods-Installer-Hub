# Red Dead Redemption VR

## About the Game

Red Dead Redemption is an open-world Western action adventure about John Marston's pursuit of his former gang across the American frontier. RDRVR by Disonomouss adds native stereo OpenXR rendering, a first-person body, tracked hands, physical guns and holsters, manual reloading, and an in-headset settings menu. Menus, loading and videos appear on a cinema screen; gameplay uses the headset view.

## Current VR mod

The Hub offers RDRVR by Disonomouss and follows that publisher's current releases, including prereleases. The reviewed current archive is 0.8.12.2. RedHook v0.8 remains required separately. Optimumbox is no longer offered for a new download or an online update. Existing historical fork profiles, their saved versions and explicit legacy Start/Remove actions remain available; they are not deleted or replaced automatically.

Installing or updating keeps the active runtime. Choose Original under Start in VR to activate the updated original profile. The publisher's current main version now includes single-pass stereo, physical gun actions and a desktop settings launcher. Personal headset preferences stay in %LOCALAPPDATA%\RDRVR\RDRVR.user.ini; saves remain with the original game. On the first transition to 0.8.12 the publisher resets its own settings once and keeps RDRVR.user.ini.before-0.8.12.bak. The 0.8.12.1 and 0.8.12.2 hotfixes retain those settings.

## Requirements and installation

The publisher supports the 2024 PC game from Steam or Rockstar Games Launcher. Epic Games Store and Xbox-app copies are not confirmed by the publisher and are outside this Hub installer's automatic routes. A Windows 10/11 PC, DirectX 12 GPU, PC VR headset and active OpenXR runtime are required. Only Quest 3 with Touch controllers has been tested by the author in a real headset; the mod also offers bindings for Index, Vive, WMR and Pico controllers.

RedHook v0.8 by K3rhos is required and comes from Nexus, not from the RDRVR release. Nexus sign-in may be needed. If the Hub finds a RedHook ZIP in your configured Windows Downloads folder, it shows its filename and asks whether to use it. If you decline or no ZIP is found, drag a different ZIP into the installer or paste its path; Enter opens the Nexus page. The Hub copies the three runtime files and sets `[DirectXHook] Disabled=true` in the newly installed RedHook.ini. If RedHook already exists, the Hub requires all three files and this setting but does not alter that existing configuration. Download the RedHook main file, not the SDK.

1. Install and close the Steam or Rockstar PC game. On this page choose [[Get Installer]]. Read the initial notice before pressing Enter.
2. If RedHook is missing and its ZIP is already in Downloads, answer Yes to use the displayed file. Otherwise drag the main ZIP into the installer or paste its full path; press Enter to open Nexus if you still need to download it. If RedHook already exists with its DirectX hook enabled, set `Disabled=true` under `[DirectXHook]` in RedHook.ini and retry.
3. The Hub resolves the latest RDRVR GitHub Windows release, including prereleases, or accepts a publisher ZIP that you explicitly select. It checks the complete selected publisher payload, including its current launcher, models and converter, and keeps the two profiles under .pcvrhub_rdr_profiles in the game folder. Versions are recorded separately only after the required files survive the copy check. Start in VR deploys the chosen profile beside RDR.exe and protects same-name original files. The game must be closed throughout setup.
4. Start your OpenXR runtime and choose [[Start in VR]]. On Steam this uses the Steam game launch route. For a Rockstar copy, sign in to Rockstar Games Launcher as normal. If direct launch cannot establish its license session, open the game through that launcher.

On the first launch, the publisher may show a notice that unlocks after 30 seconds and asks you to type the displayed confirmation sentence. After continuing, the converter package may also wait at the title screen while preparing shaders.

The mod's initial RDRVR.ini ships with the game folder. Changes in the in-headset menu are saved in `%LOCALAPPDATA%\RDRVR\RDRVR.user.ini` and take precedence. This user file remains after an update or Hub removal. The original game and save files are never part of the mod payload.

Version 0.8.12.2 fixes a long gun drifting away from its carrying hand. Single-pass rendering is now the default; shaders convert from your own game files at the first start. The desktop RDRVR_Launcher opens as the game starts: choose Save & Play, or Close to cancel. Its default countdown continues after 30 seconds if untouched. Roomscale walking and physical crouch are optional in Comfort. Scope views, two-handed weapon handling and manual loading are configured in Guns and Reloading. These are publisher features; the Hub's isolated installation tests do not prove headset behavior.

## Controls - Original RDRVR

| Button | Action |
|---|---|
| [[Left Stick]] | Move; steer the horse when stick steering is selected. |
| [[Right Stick]] | Smooth or snap turn, including on horseback; while [[Menu]] is held, act as the D-pad. |
| [[Left Stick Click]] | Brake while riding a horse. |
| [[Right Trigger]] | Fire the gun in hand; point at a menu item and select it while the settings laser is active. |
| [[Either Trigger]] with a hand at your mouth | Whistle for the horse; if the other hand aims a gun, the mod briefly releases aim before whistling. |
| [[Either Grip]] | Grab a gun from a holster, hold a round at the chest for manual reloading, or use an item in hand. |
| [[Either Grip]] release | Return the held item to its holster; with the other hand on a long gun foregrip, carry it in that hand instead. |
| [[Menu]] tap | Send the game's [[Start]] input. |
| [[Menu]] hold | Open the RDRVR in-headset settings menu. |
| [[Y]] hold while viewing the wrist HUD | Open the in-headset settings menu. |
| [[Y]] twice with the off-hand wrist HUD visible | Open the satchel when the optional wrist-satchel setting is enabled; [[B]] closes it. |
| [[A]] while [[Menu]] is held | Send the game's [[Back]]/map input. |
| [[Both Stick Clicks]] hold for one second | Recenter the VR view. |
| [[Scroll Lock]] | Recenter while the desktop game window has focus. |
| [[F7]] | Open the in-headset settings menu from the keyboard. |

Current default mappings are [[B]] to the game's [[X]], [[X]] to its [[B]], with grips used only for grabbing and [[Gun-hand Stick Up]] for [[RB]]/cover. The Controls tab can remap them. Other controller buttons remain remappable: [[A]], [[B]], [[X]], [[Y]], [[Left Trigger]] as [[LT]] and [[Right Trigger]] as [[RT]]. The game's rumble reaches the controllers. To reload physically, use [[Grip]] to take a round at your chest and bring it to the gun's loading point. The menu laser, [[Trigger]] and [[Right Stick]] operate its tabs and rows. An optional weapon-wheel mode holds [[Grip]] to show the wheel, moves the hand toward a weapon and releases to select it. Optional hand throwing releases [[Grip]] after readying a throwable with [[Trigger]].

## Current gun inputs

| Button | Action |
|---|---|
| [[Right Stick Down]] flick | Cock a revolver; on a pistol, drop the magazine or clip. |
| [[Right Stick Down]] hold + [[Right Stick Click]] | Open a revolver or double-barrel shotgun. |
| [[Right Stick Down]] hold | Work a lever rifle by lowering and raising the gun hand. |
| [[Other-hand Trigger]] at a bolt or slide | Take hold to work it physically. |
| [[Either Grip]] at the chest | Take a round for the gun in the other hand. |
| [[Left Trigger]] then [[Right Trigger]] | Lock on and throw the lasso with the default gesture mode. |

## Controls - Optimumbox (legacy installed profiles)

This section documents an already installed historical fork. It is not a new download offer; its controls differ from the current original above.

The common movement, menu and recenter inputs above also apply. The following replaces the Original weapon-wheel, cover, brake and gun handling where stated. The two-handed steady rifle mode was designed for a physical controller gun stock; the author warns that using it without one can cause problems. The new models and handling can be disabled in the Guns and Reloading tabs.

| Button | Action |
|---|---|
| [[A]] + [[B]] on the right controller | Take cover. |
| [[Left Trackpad Click]] on Index | Open the weapon wheel; click again to pick. Quest uses drawing from holsters. |
| [[Either Grip]] on foot | Hold or draw weapons; no longer sends the game's [[LB]] / [[RB]] wheel or cover inputs. Index accepts a lighter squeeze. |
| [[Right Grip]] while riding | Brake the horse, wagon or coach. |
| [[Right Stick Down]] | Cock a revolver hammer; with [[Right Trigger]] held, fan another shot for each downward press. Revolvers are already cocked when drawn. |
| [[Right Stick Up]] | Flick to open a revolver or hold to keep it open. |
| [[Thumbrest]] on Quest / [[Trackpad]] on Index | Rest the thumb to keep a revolver open; release and flick the wrist to close it. With the Schofield open, tilt the muzzle upward by at least 30 degrees to empty casings. |
| [[Grip]] near the Springfield hammer | While held in two hands, pull the hammer hand back about 4 cm to cock it. One-handed: [[Right Stick Down]]. Grip the rear sight with the other hand to flip it up or flat. |
| [[Gun-hand Grip]] release with the Winchester held in two hands | Keep the front hand holding the rifle; move the gun hand down and back up inside the lever loop. Rest the thumb on [[Thumbrest]] / [[Trackpad]] to lock the hand to the lever. |
| [[Trigger]] at the chest with the Winchester gun hand outside the lever loop | Take a round and push it into the right-side loading gate. [[Grip]] at the gun grip holds the rifle again. After a shot, flick down then up to chamber the next round. |
| [[Gun-hand Grip]] release, then [[Trigger]] at the Bolt Action bolt knob | Keep the rifle in the front hand; raise the gun hand, pull back, push forward and lower to cycle the bolt. |
| [[Grip]] at the chest with the Bolt Action bolt back | Take a five-round clip, set it in the guide and push down. Moving the bolt forward ejects the clip. [[Grip]] at the rifle grip holds it again. |
| [[Right Stick Down]] with the High Power pistol | Flick to drop its magazine. [[Grip]] a fresh magazine at the chest and push it into the well. [[Grip]] the rear of the slide with the other hand, pull back and release to chamber. |
| [[Grip]] at the Mauser bolt ears with the other hand | Pull back to open. [[Grip]] a ten-round clip at the chest and push it down into the top guide; release to close the bolt and eject the clip. |

The Springfield's trapdoor must be opened physically and a round inserted before firing. The publisher's current complete gun-control diagram is included below and in the downloaded release as Controls.png.

![Optimumbox 0.8.11.11 controls](Optimumbox-Controls.png)

## Comfort, performance and limits

Before playing in VR, open the game graphics settings and set Depth of Field to Off. With it enabled, the headset image can be severely blurred.

The HUD can float in front of you or sit on your wrist. Choose body visibility, handedness, holster placement, turning mode, reticle and gesture options in the headset menu. Current publisher builds add headset-size render presets, a horse whistle, the optional weapon wheel and wrist satchel, and more holster and front-hand choices. Some newer features were tested by the author only in an OpenXR simulator, not yet in a headset. Use FXAA for eye-shaped rendering; changes to render resolution apply from the next start. The author recommends Windowed mode for the new resolution option because Fullscreen can override a smaller requested size. Keep the OpenXR runtime's own resolution scale at its default when using the mod's percentage setting, since the two scales multiply.

Current RDRVR uses single-pass rendering by default; two-pass remains available. A historical Optimumbox profile can also use one view-instanced pass when the GPU supports DirectX 12 view instancing; uncovered shaders can fall back to separate eye draws. Lowering headset refresh rate to 72 or 80 Hz may help maintain real frames; runtime frame generation can make guns lag behind the hands. Back holster long guns cost extra frame time. DLSS is experimental and may feel laggy; FXAA is the default, with TAA also available.

If the game launches flat, check the installed RDR.exe build, RedHook v0.8, `[DirectXHook] Disabled=true`, and active OpenXR runtime. The mod writes `RDRVR_build_report.txt` and `RDRVR.log` in the game folder; a build it cannot safely recognize causes its hooks to stand down rather than guessing. Send those reports to the publisher issue tracker when reporting a build problem. Rare freezes or very low frame rates have been reported by the author. Changing the game's graphics resolution while in the headset temporarily returns to the cinema screen until a restart. The game sends crash reports to Rockstar even when a mod is installed.

## Updates

The Hub watches Disonomouss/RDRVR, including its prereleases. The retired fork has no online update source. A main update never overwrites a historical fork's stored version. Close the game first. Personal RDRVR.ini changes are preserved when updating its stored profile. Other changed runtime files are retained before switching rather than discarded.

## Start in VR

Start in VR runs Core\RDRVR\Start-RDRVR.ps1 with the detected game folder and -Mod main or -Mod fork. Steam installations then use steam://rungameid/2668510 for the required Steam/Rockstar login route. A Rockstar installation starts its RDR.exe with that game folder as the working directory. The 2024 PC game is required for both; this is not a Red Dead Redemption 2 mod.

## Links

[RDRVR publisher and full documentation](https://github.com/Disonomouss/RDRVR) · [RDRVR releases](https://github.com/Disonomouss/RDRVR/releases) · [RedHook v0.8 on Nexus](https://www.nexusmods.com/reddeadredemption/mods/192?tab=files) · Join [Flat2VR Modding](https://discord.gg/uAeQkYBM4n) first, then open the [RDRVR discussion](https://discord.com/channels/747967102895390741/1557309171555369020) · [VR gameplay](https://youtu.be/s215LWkVHaw?t=53)

>>> The frontier is waiting. Ride into it.
