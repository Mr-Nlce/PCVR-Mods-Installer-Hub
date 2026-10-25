# Project Zomboid VR

## About the Game

Project Zomboid is an open-world survival game. PZVR adds experimental OpenXR support through Project Viewpoint and ZombieBuddy. This setup is currently for the Steam Build 42.21 game and its Steam Workshop packages.

## What you need

- Your own Steam copy of Project Zomboid, Build 42.21.
- [PZVR](https://steamcommunity.com/sharedfiles/filedetails/?id=3816830877), [ZombieBuddy](https://steamcommunity.com/sharedfiles/filedetails/?id=3619862853) and [Project Viewpoint](https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528) subscribed in Steam Workshop. On the PZVR page, Steam offers **Subscribe to all** for its two requirements.
- The separate [ZombieBuddy Windows installer](https://github.com/zed-0xff/ZombieBuddy/releases/tag/windows_installer_4.3). Its prompts are **1 — Install ZombieBuddy**, **1 — Both** launch modes, then **y — Continue**. Only this external publisher setup may ask you to exit Steam fully. The Hub opens Steam again if it ran that setup.
- A connected headset and an active OpenXR runtime such as SteamVR or Meta Link.

## Install and start

1. Choose [[Install]] in the Hub. Its guided setup checks the Steam game, all three Workshop packages, the ZombieBuddy files and both patched launchers. On the PZVR Workshop page, click the blue **Subscribe to all** button to get the three items. The Hub offers the official pages if something is missing.
2. If the separate ZombieBuddy setup ran, press [[Enter]] in the Hub to reopen Steam. Then press [[Enter]] to launch Project Zomboid through Steam. In the game's **Mods** menu, enable ZombieBuddy, Project Viewpoint and PZVR; confirm the activation dialog with **OK**. Restart the game if requested.
3. ZombieBuddy asks you to approve the two Java mods. Choose **Allow** for Viewpoint and PZVR, then **OK**. **Save decisions to disk** keeps these approvals for later starts. These mods appear as unsigned, so **Trust author** cannot be selected; it is not required.
4. Stay in flat mode for the first configuration. Start a **new single-player game** on the desktop; do **not** press **Start VR** yet. When the first-person configuration window appears, click its **Restart** button. Then start a flat single-player game again and finish the Viewpoint setup. The upper left should list ZombieBuddy and the two active Java mods. Only now use **Start VR** at the top right. The Hub checks the files, saved approvals and positive game log before recording VR Ready.
5. For later starts, choose [[Start in VR]] in the Hub. It launches Project Zomboid through Steam; then select **Start VR** in the game's main menu. The mod has no verified external command that skips this in-game step. If it does not enter VR, load a world and press [[O]] for Project Viewpoint in VR.

Add PZVR to an existing save or multiplayer server's mod list before loading that world. A first-person Viewpoint start may restart the game. The ordinary tutorial does not teach the VR controls. This is an experimental Build 42 mod, so use a backed-up save while trying it.

## Controls

| Button | Action |
|---|---|
| [[O]] | Toggle first person or VR through Project Viewpoint. |
| [[Left Stick]] | Walk or control vehicle movement. |
| [[Left Stick Click]] | Jog. |
| [[Left Stick Click]] twice | Sprint. |
| [[Right Stick]] left/right | Turn. |
| [[Right Stick]] up/down | Cycle hotbar slot, scroll menus or zoom the map. |
| [[Right Stick Click]] | Shove or stomp. |
| [[A]] | Interact, open a pointed context menu or loot; hold to loot all. |
| [[B]] | Toggle HUD; hold for radial menu. |
| [[X]] | Reload; hold for firearm radial menu. |
| [[Y]] | Cycle palm menu; hold to show or hide it. |
| [[Left Grip]] / [[Right Grip]] | Equip a selected hotbar item to that hand. |
| [[Left Grip]] + [[Right Grip]] | Equip a selected item to both hands. |
| [[Left Trigger]] / [[Right Trigger]] | Use an item, shoot or click pointed UI. |
| [[Right Trigger]] while placing | Place at the pointer; hold and aim to rotate. |
| [[Right Trigger]] while fishing | Cast toward water; hold to reel in. |
| [[Left Trigger]] while fishing | Hold to reduce line tension. |
| [[Left Menu]] / [[Left Touchpad]] on Index | Pause; hold to recenter. |
| [[D-Pad]] on Steam Frame | Navigate the UI. |
| [[Left Bumper]] on Steam Frame | Cycle inventory containers. |
| [[Right Bumper]] on Steam Frame | Cycle loot containers. |

You can also swing a held melee weapon, push with an empty hand, physically crouch, and face your palm or wrist to reveal the palm menu, moodles or watch. These bindings assume a right-dominant hand; left-dominant mode reverses the controller layout except for the menu button. Project Viewpoint's [[Delete]] settings include its shader and terrain controls; if the sky or terrain looks wrong, check those settings before changing the game installation.

## Removal and updates

[[Uninstall now]] removes the Hub's verified setup record so the tile no longer claims VR Ready. It does not unsubscribe Steam Workshop items, delete saves or remove the shared ZombieBuddy installation. To remove ZombieBuddy itself, run its publisher installer and choose **Uninstall**. Steam updates the three Workshop items. If a newer PZVR JAR replaces one that the Hub previously verified, the tile shows an update until ZombieBuddy approves the new JAR. Choose [[Update Mod]] and read the short update instructions. Press [[Enter]] to start the game; in the ZombieBuddy approval window choose **Allow** for the changed mods, select **Save decisions to disk**, then click **OK**. The Hub checks the new approval and game log before refreshing its receipt. If you already approved and loaded the updated mod during an earlier game start, the Hub recognizes that and completes without another launch. A Workshop-only update does not require closing or restarting Steam; that step belongs only to the separate ZombieBuddy Windows installer.

## Links

- [PZVR and controller guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3816830877)
- [ZombieBuddy installation guide](https://github.com/zed-0xff/ZombieBuddy/blob/master/doc/Installation.md)
- [Project Viewpoint](https://steamcommunity.com/sharedfiles/filedetails/?id=3809306528)
- [Flat2VR community thread](https://discord.com/channels/747967102895390741/1559077454125989908)
- [VR gameplay](https://youtu.be/uW8gyMKnSIU?t=2459)

Survive another day, this time from inside the world.
