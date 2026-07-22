# Raft VR Installer

Automated installer for RaftVR v1.1.0 by DrBibop.

## What it installs
- **RMLLauncher.exe** (RaftModLoader 2.8.10) — mod launcher
- **ExtraSettingsAPI v1.10.4** — required dependency
- **RaftVR v1.1.0** — full VR mod with motion controls

## IMPORTANT — Required Steam branch

RaftVR only works on Raft version **1.09_precrossplayupdate** (an older branch).
The installer guides you through switching to it in Steam.

## How to use

Click **Install Mod** on the game tile or detail page and follow the prompts.

## First-time VR setup (after installation)

1. Launch with **Start in VR** in the Hub or the **'Raft VR'** desktop shortcut — never via Steam directly
2. In the main menu, open the **Mod Manager** tab
3. Find **ExtraSettingsAPI** and click **'Load Mod'** to activate it
   (RaftVR should already show as active)
4. A **VR setup dialog** appears — configure your VR runtime and preferences
5. Confirm the restart when prompted

From the second launch onwards, start SteamVR first, then open Raft VR.

## Controls

Oculus Touch / Reverb G2 / Vive Cosmos layout:

![Controller layout](ControllerLayout.jpg)

- **Left:** [[Stick]] = Move, [[Stick]] click = Sprint; Menu, Inventory/Hold to
  Drop, Notebook/Hold to Block Pick (bindings differ slightly between
  Oculus and SteamVR runtimes)
- **Right:** [[Stick]] Left/Right = Turn, Up/Down = Next/Previous item, [[Stick]]
  click = Repair / Hold to Remove; Rotate held object with the right stick
- Primary / Secondary Action, Interact, Crouch and Jump are on the
  right-hand face buttons and triggers

## Motion sickness

If certain games make you motion sick, this mod might too. It ships with
comfort settings like **snap turn** (more, such as teleport locomotion, are
on the way) and a **motion-sickness setting in the General tab** to calm
the waves.

## Multiplayer

The mod is fully **client-side** and isn't required by other players. You
can play with flatscreen friends, and VR players see each other's arm and
head movements. Friends who aren't in VR can install the separate
flatscreen version of the mod to see your arms:
https://www.raftmodding.com/mods/raftvr-for-flatscreen-players

## Changing the VR runtime later

If you picked the wrong runtime and can't get into VR or the settings, edit
`VRRUNTIME.txt` in your Raft install folder (Steam: right-click Raft ->
Manage -> Browse local files). Open it in a text editor and replace the
text with either `oculus` or `steamvr`, then save.

## Support

Best support is via the Flatscreen to VR Discord (grab the Raft role to
unlock the RaftVR channel): http://flat2vr.com/ — or ping @DrBibop in the
Raft Modding server: https://www.raftmodding.com/discord

## Source
RaftVR: https://www.raftmodding.com/mods/raftvr
RaftModding: https://www.raftmodding.com

>>> Build a sail. Watch the sharks. VR awaits!
