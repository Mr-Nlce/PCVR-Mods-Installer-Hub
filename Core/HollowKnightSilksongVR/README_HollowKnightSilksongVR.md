# Hollow Knight: Silksong VR

<!-- hub:keep-order -->

Silksong has two VR mods. They do completely different things, they cannot run at the same time, and nothing below is shared between them. This page covers the first one from start to finish, then the second one.

**Neither mod puts you inside a VR world.** Silksong stays a 2D game shown on a screen in front of you; what the mods add is depth to that picture. You do not walk around in Pharloom, you do not look around a room, and there are no motion controls - gamepad or keyboard, exactly like the flat game. If you are expecting to stand in the world, neither of these is that.

Both mods are BepInEx plugins and both live in `BepInEx\plugins`, so only one may be active at a time. The installer parks the inactive one as `<name>.dll.off`. Once **both** are on disk the Hub turns its Play button into a split button - pick a mod there and it flips the pair for you before the game starts.

Run the installer once per mod. It asks which one you want and tells you which ones are already there.

One thing worth knowing if you install both: the `openvr_api.dll` that Flat to VR needs stays where it is when you switch. It is a passive library - nothing loads it unless a mod asks for it - and it plays no part in deciding which mod runs. That decision is made purely by which of the two plugin files currently ends in `.dll` instead of `.dll.off`, and the switch launchers only ever rename those two.

## Mod Info - Astienth (depth between the sprite layers)

- **Author:** Astienth
- **Where it comes from:** the FarmerTrueVR Discord - a Discord login is required to reach the download
- **Plugin file:** `BepInEx\plugins\HollowKnightSilksong_VR.dll`
- **BepInEx:** included in the mod ZIP, nothing to fetch separately

This mod pushes the game's sprite layers apart in depth, so foreground, midground and background sit at real distances in VR. The world reads like a diorama instead of a flat screen. The 2D gameplay itself is untouched.

Mod info post:
https://discord.com/channels/1001138422972432597/1414940597579419679/1414940597579419679

## Requirements - Astienth

- Hollow Knight: Silksong, launched at least once so its first-run files exist
- A Discord account, and membership of the FarmerTrueVR server with the rules accepted
- A headset and your OpenXR / SteamVR runtime running before the game

## What the installer does - Astienth

1. Locates your Silksong install (all Steam libraries are scanned; you can also paste the folder)
2. Walks you through the Discord invite and the rules post, or skips straight to the download if you are already a member
3. Opens the download post so you can grab the ZIP
4. You drop the ZIP into the window
5. Reads the archive before unpacking, resolves the payload by the mod DLL itself, and merges it into the game folder
6. Verifies `HollowKnightSilksong_VR.dll` really arrived, then makes this mod the active one

If Flat to VR is already installed it is parked as `SilksongFlatToVR4.dll.off`, and both choices become available on the Hub page.

## Launching - Astienth

Start your runtime first, then launch with **Start in VR** in the Hub, or Silksong from Steam.

With both mods installed the Hub tile shows a split button. The **Astienth** side activates this plugin and starts the game through Steam. Close the game before switching: a loaded DLL is locked by Windows and the switch would fail.

## Controls - Astienth

Game controls are unchanged - gamepad or keyboard.

- **Recenter view:** your runtime's own recenter, or hold [[Up]] + [[QuickMap]] + [[Pause]] together (gamepad: [[Up]] + [[LB]] + [[Start]])
- **Vignette on/off:** hold [[Start]]. Some areas have a heavy vignette; this removes it without leaving the game.

## Settings - Astienth

Two config files, both under `BepInEx\config\`.

`HollowKnightSilksong_VR.cfg`

```
spaceBetweenMultiplier = 1.65    depth between the sprite layers - this is the effect
VRCamDistance          = 0,0,10  headset distance from the scene; change Z only
worldScale             = 1       relative world scale
UIScale                = 1       UI scale
```

`UnityVR_Bepinex.cfg`

```
canvasOffset = 0.0,0.0,1.4       UI distance from the headset; smaller Z = closer
```

A bigger world, as tested by the mod author: `worldScale = 20`, `UIScale = 10`, `canvasOffset = 0.0,0.0,12`. Tune `worldScale` first, then match the other two. Pushing `worldScale` up can cost the VR camera its 6DoF behaviour - restore the defaults if anything breaks.

## Known issues - Astienth

- The inventory map can look wrong when zoomed in
- Map pin placement is offset: the pin lands at the bottom right of the cursor instead of on it

## Good to know - Astienth

Compatible with other BepInEx mods, with no guarantee against conflicts.

To play flat without removing anything, use the **Flat / VR** switch on this
page. It parks the shared loader and one click restores VR later.

## Support Astienth

- Server invite: https://discord.gg/G8zZBTGuhP
- Buy them a coffee: https://www.buymeacoffee.com/astienth4

## Mod Info - Flat to VR by SadMonsterParty

Nothing above this line applies to this mod.

- **Author:** SadMonsterParty
- **Where it comes from:** Nexus Mods, file 942 - no direct download, you fetch it and hand it to the installer
- **Plugin file:** `BepInEx\plugins\SilksongFlatToVR4.dll`
- **BepInEx:** not included - the Hub fetches the pinned BepInEx 5 x64 build when the game folder has none

**This is a 3D screen, not a VR environment.** It draws Silksong on several floating planes in SteamVR through the OpenVR overlay API - the picture hangs in front of you at different distances, nothing more.

In detail: Each game element is sorted onto the plane that suits it, and because the planes sit at different physical distances, your IPD gives you stereo parallax and your head movements give you motion parallax. The result looks like a layered diorama, and it makes the action easier to follow when foreground and background sit at different depths. Because it works through overlays, it needs no VR support in the game at all.

Mod page:
https://www.nexusmods.com/hollowknightsilksong/mods/942

## Requirements - Flat to VR

- Hollow Knight: Silksong, launched at least once so its first-run files exist
- **SteamVR** - this mod uses the OpenVR overlay API, so SteamVR must be running
- A headset that runs through SteamVR
- BepInEx (the Hub installs it if it is missing)
- `openvr_api.dll` from your SteamVR install - the **win64** one. The Hub copies it into the game folder AND into `Hollow Knight Silksong_Data\Plugins\x86_64\`. That second folder is the one that actually matters: the mod calls into the library through Unity's Mono, and Mono looks for native libraries there. With the file only in the game folder the mod loads but reports *openvr_api.dll not found* and stays disconnected from OpenVR

## What the installer does - Flat to VR

1. Locates your Silksong install
2. Looks in your Downloads and Desktop for the file you may already have; if not, opens the Nexus Files tab and waits for you to drop the ZIP in
3. Installs BepInEx into the game folder - only if there is none there yet, so an existing setup is left alone
4. Copies `SilksongFlatToVR4.dll` into `BepInEx\plugins`
5. Copies `openvr_api.dll` out of `steamapps\common\SteamVR\bin\win64\` into the game folder. If SteamVR cannot be found you get the exact path and do that one copy yourself. **Take the win64 one, not win32.** The Nexus page says `win32`, but Silksong is a 64-bit game and cannot load a 32-bit DLL - and the mod then reports it as *openvr_api.dll not found*, which sends you hunting for a file that is already there in the wrong architecture
6. Verifies the plugin really arrived, then makes this mod the active one

One thing worth knowing: the instructions on the Nexus page say to copy `SilksongFlatToVR.dll`, but the file in the archive is named `SilksongFlatToVR4.dll`, with the 4. The installer handles either name.

If the Astienth mod is already installed it is parked as `HollowKnightSilksong_VR.dll.off`, and both choices become available on the Hub page.

## Launching - Flat to VR

Start SteamVR before the game to avoid it potentially starting sometimes out of focus. Then launch with **Start in VR** in the Hub, or Silksong from Steam.

With both mods installed the Hub tile shows a split button. The **Flat to VR** side activates this plugin and starts the game through Steam. Close the game before switching.

## Controls - Flat to VR

Game controls are unchanged - gamepad or keyboard. Everything below is on the keyboard and affects the overlay planes, not the game.

- [[F9]] Overlays on/off
- [[F10]] Settings GUI on/off, and re-centres the VR view
- [[F11]] VR on / off - the mod's own panel labels this one *VR Enabled (F11)*
- [[F12]] Reinitialise OpenVR. May need a VR restart, and may clash with screenshot hotkeys
- [[Numpad 7]] / [[Numpad 1]] Background plane further / closer
- [[Numpad 9]] / [[Numpad 3]] Foreground plane further / closer
- [[Numpad +]] / [[Numpad -]] Overlay wider / narrower
- [[Numpad 5]] Reset all distances to their defaults

## Settings - Flat to VR

Plane distances from your viewpoint:

```
Background   1 - 10 m    default 4 m
Midground    0.5 - 6 m   default 2.5 m
Gameplay     0.5 - 4 m   default 1.5 m
Foreground   0.3 - 2 m   default 0.8 m
Overlay width           default 3 m
```

Objects land on a plane by their name (keywords such as background, foreground, player, enemy), their Unity sorting layer, and their sorting order in the render pipeline. When something ends up on the wrong plane, the mod can sort the scene again - the re-analyse control sits in the settings panel ([[F10]]).

## Known issues - Flat to VR

- HUD and text overlays do not show up, cause unknown
- Some objects end up on the wrong plane
- The flat OpenVR API function names differ between OpenVR versions
- Some layers carry little or nothing visible, because the game builds its glow and bloom out of several layers

## Flat play and removal

The **Flat / VR** switch parks only the shared BepInEx loader. It does not
uninstall either mod and it does not change which of the two plugins is
selected.

**Uninstall now** shows Astienth and Flat to VR separately. It removes only
the selected plugin and activates the other one when present. Shared BepInEx
and Unity/OpenVR support files stay while either mod needs them. After the
final mod is removed, the loader is parked so Silksong starts flat; optional
Steam verification can return the folder to a pristine state without touching
saves.

>>> Climb high, Hornet. The Citadel waits.
