# Teardown VR

## About the Game

Teardown is a physics sandbox about breakable voxel environments and creative heists. The Hub offers two separate motion-control VR mods on this tile. Their native proxies, Lua files, settings and version receipts are different. Installing an alternative keeps the active selection; its Start action selects the runtime before opening Steam.

## Choose your mod

| Choice | Requirements and status |
|---|---|
| 1. VR Games For All | Steam Teardown 2.0.x, OpenXR and Quest 3. The public Patreon download works without login. Supports Virtual Desktop, Meta Quest Link and SteamVR. |
| 2. Markos - markos12900-beep | Current Direct3D 12 Steam Teardown, SteamVR/OpenXR. Experimental, single-player only. The author tested Quest 3 through Steam Link; new body, solid hands, punching and legs in v0.22 remain headset-untested by the author. |

Markos offers alternating-eye stereo, mono with head tracking, and theater mode. Stereo needs a high frame rate and fast movement can look doubled. Mono can be smoother.

## Install and start - Markos

1. Close Teardown. Choose [[Install VR mod]] and select Markos. The Hub resolves the official stable Windows ZIP and installs its complete native and Lua payload into a separate retained profile. The installed version comes from the publisher DLL. No game files, saves or personal settings are bundled with it.
2. Start SteamVR and connect the headset. Choose [[Start Markos]] in the Hub. The Hub parks the known legacy dsound.dll, places dxgi.dll beside teardown.exe and deploys the Lua files into your actual Windows Documents folder under Teardown\mods\TeardownVR. Existing same-name files receive ownership backups. The game starts through Steam.
3. In Teardown open Mods > Local files > Teardown VR Mod and enable it, then load a level. Enable only one local or Workshop copy. Disable the old VR Lua mod while using Markos; do not enable both VR mods together.
4. Set barrel distortion, motion blur and depth of field off, render scale 100%, head bob 0 and tool sway off in Teardown's own options. Keep the game window visible and focused so the controller's keyboard and mouse inputs reach it.

Markos creates teardown_vr.ini beside the game at first start. The Hub preserves it when updating. Keep a backup before carrying old values into a newer publisher configuration. Use the publisher's comments to review new options; the Hub does not reset your choices. Logs are teardown_vr.log and, after a crash, teardown_vr_crash.log. A missing file alone does not establish antivirus involvement: inspect the installer log and Windows protection history first.

## Controls - Markos

| Button | Action |
|---|---|
| [[Right Trigger]] | Use the tool; point at a menu window and click. |
| [[Right Grip]] | Grab a nearby loose object; release while swinging to throw. Otherwise use the game's normal grab or menu right click. |
| [[Left Grip]] | Grab or throw with the left hand. |
| [[Left Stick]] | Walk where you look; move through menus. |
| [[Right Stick Left]] / [[Right Stick Right]] | Turn, with 30-degree snap turns by default. |
| [[Right Stick Down]] / [[Right Stick Up]] | Next or previous tool; scroll in menus. |
| [[A]] | Jump; confirm in menus. |
| [[B]] | Hold to crouch; back in menus. |
| [[X]] | Interact. |
| [[Y]] | Map. |
| [[Left Menu]] | Pause. Hold about half a second to cycle stereo, mono and theater. |
| [[Left Stick Click]] | Flashlight. Hold to switch hand/head aiming. |
| [[Right Stick Click]] | Recenter. |
| [[F6]] | Reload teardown_vr.ini. |
| [[F7]] | Recenter with the game window focused. |
| [[F8]] | Change VR mode. |
| [[F9]] | Change hand/head aiming. |
| [[F10]] | Toggle VR. |
| [[F11]] | Show debug values. |

Punching uses a physical hand movement, without a button. Solid hands need the gloves hand style. If the new features shake or obstruct the view, turn off the affected option in teardown_vr.ini and reload with [[F6]]: hand_collision, hand_punch, body_collision or show_body. The first-level self-test may disable unsafe solid hands or legs until the next level.

## Install and start - VR Games For All

1. Close Teardown and choose [[Install VR mod]]. Select choice 1, **VR Games For All**. The Hub downloads and runs the public Windows Setup with the selected Steam game folder. The publisher Setup installs the native proxy and Lua mod. It preserves TeardownVR.ini.
2. Connect your headset before starting. Use [[Start VRGFA]] in the Hub. On first launch, open Play > Mod manager > Built-in, select Teardown VR and click Disabled to enable it. Enable only the Lua mod for the VR choice you want to run.
3. Load a level. The game switches to VR. Select SteamVR in the mod's Infos tab if that is your runtime.

## Controls - VR Games For All

| Button | Action |
|---|---|
| [[Right Trigger]] | Use the held tool. |
| [[Right Grip]] | Grab with the right hand. |
| [[Left Grip]] | Grab with the left hand. |
| [[Right Stick Left]] / [[Right Stick Right]] | Turn. |
| [[Right Stick Up]] / [[Right Stick Down]] | Change tools. |
| [[Right Stick Click]] | Open the VR inventory. |
| [[Left Stick]] | Move. |
| [[Left Stick Click]] | Show or hide the left-hand laser. Hold to recenter. |
| [[Left Trigger]] | Crouch. |
| [[A]] | Jump. |
| [[B]] | Toggle the flashlight. |
| [[X]] | Open the 3D level map. |
| [[Y]] | Interact; enter or leave a vehicle. |
| [[Menu]] | Pause; long press opens VR settings. |
| [[F10]] | Open VR settings from the keyboard. |
| [[F8]] | Recenter from the keyboard. |

## Switching, updates and removal

The Markos publisher profile has a separate version B. It never completes the legacy version A or resets its preferences. The Hub parks only a positively identified legacy proxy; an unrelated or modified loader is preserved and requires review. Start VRGFA restores its loader and the earlier same-name DXGI file, if one existed. User files in Documents and both configuration files stay.

Use the matching removal action for the selected mod. Markos removal reverses the recorded native, Lua and retained-profile ownership plans. Unchanged owned files disappear, original collisions return and changed files remain for review. VR Games For All removal uses its retained publisher Setup, or downloads the current Setup if the cache is missing. The original game, saves, other mods and personal INI files remain. Steam login, real game launch, headset output and controller behavior are not proven by the Hub's isolated file fixtures.

## Links

- [Markos publisher and complete guide](https://github.com/markos12900-beep/teardown-vr-mod)
- [Markos releases](https://github.com/markos12900-beep/teardown-vr-mod/releases)
- [VR Games For All publisher guide](https://www.patreon.com/VRGamesForAll/posts/teardown-vr-v1-1-172191906)
- [VR Games For All Windows Setup](https://www.patreon.com/file?h=172191906&m=773303902)
- [Flat2VR community thread](https://discord.com/channels/747967102895390741/1560664691594756147)
- [VR Games For All gameplay](https://youtu.be/ZMj2zIeCAmw?t=488)

>>> The next wall is merely a suggestion.
