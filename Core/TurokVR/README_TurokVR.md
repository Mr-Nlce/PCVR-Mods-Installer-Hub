# Turok VR

VR mod: [TurokVR by VinceCrusty](https://github.com/VinceCrusty/TurokVR)  
Current publisher release: [v0.94 beta](https://github.com/VinceCrusty/TurokVR/releases/tag/0.94.0-beta)  
VR gameplay: [Watch from 2:16](https://youtu.be/Y6nBq9IOfcg?t=136)  
Flat2VR discussion: [Turok VR thread](https://discord.com/channels/747967102895390741/1103720023379410974/threads/1552423429104345108)

## About the Game

Turok is Nightdive's remaster of the first dinosaur-hunting action game. The
mod converts the current KEX4 PC edition to stereoscopic 6DOF OpenXR VR with
tracked weapons, roomscale play and controller interactions. It is beta
software; climbing and unrestricted quicksaves still have known edge cases.

## Install and start

Use the Hub installer with the Steam Turok installation (App 405820). It
downloads the newest applicable publisher release, including betas, checks the
outer TurokVR release ZIP and embedded `turok.assets`, and installs the complete
publisher file set with a Hub ownership record. Your `TurokVRUser.ini` is not
replaced. A release update is offered automatically when GitHub publishes a
new applicable asset.

The Hub also searches the default Steam, GOG Galaxy and GOG offline Turok
folders. `sobek_Shipping_Steam_x64.exe`, `sobek_Shipping_Galaxy_x64.exe` and
legacy `sobek.exe` can identify an owned base game together with `game.kpf`.
The publisher currently documents this VR mod for the Steam KEX4 edition
and its normal Steam launch. A detected GOG or legacy copy is therefore shown
as a base game only; the Hub installer requires the Steam executable and does
not claim that the VR mod works with the other editions.

Vulkan is required. Direct3D mode cannot run this VR mod. If necessary,
switch the flat game's Video Options back to Vulkan first. Activate SteamVR or
VDXR as the OpenXR runtime before starting. The publisher recommends starting
through Steam, without custom launch parameters. On the first launch,
confirm the mod's installation prompt; the game closes once. Start through
Steam again for VR. The Hub Start in VR button also uses the Steam route.

The publisher suggests an optional HD texture pack, which is separate and is
neither installed nor removed by the Hub.

Version 0.94 opens a first-run setup window for handedness, turning,
movement direction, HUD, immersive bow, shoulder slots and vignette. You can
choose head-directed or off-hand-directed movement for either handedness mode.
Smooth-turn speed is available only with smooth turning; snap angle is available
only with snap turning. The mod detects existing HD texture packs and offers
an optional download without replacing an existing pack. Updating or reinstalling
preserves existing personal settings. Run Turok once after the four release
files have been copied so the publisher's first-run setup can finish.

The 0.94 beta adds a weapon-mounted ammo HUD, optional physical crouching for
crawl passages and a choice to show boss health and underwater air on the HUD.
The first-run installer offers immersive or original auto-crouch; auto-crouch
remains the default. Weapon-wheel graphics now live in `zzzz_VR_Assets.kpf`
instead of separate loose images. Updating through the Hub retires unchanged
old Hub-owned images and preserves edited files, settings, saves and other mods.

## Controls

Right-handed default:

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Reset position |
| [[Left Trigger]] | Previous weapon; grab a compatible weapon with the off hand |
| [[X]] | Map |
| [[Y]] | Menu |
| [[Left Grip]] | Next weapon; off-hand weapon grab |
| [[Right Stick]] | Turn |
| [[Right Stick Click]] | Crouch |
| [[Right Trigger]] | Fire; right shoulder slot while the weapon wheel is open |
| [[A]] | Weapon wheel |
| [[B]] | Alternate ammo or Back |
| [[Right Grip]] | Jump |

Left-handed mode swaps weapon, movement and turn hands. Its default layout is
also available inside `VR Options > Controls` in the game:

| Button | Action |
|---|---|
| [[Left Stick]] | Turn |
| [[Left Stick Click]] | Crouch |
| [[Left Trigger]] | Fire |
| [[X]] | Weapon wheel |
| [[Y]] | Alternate ammo or Back |
| [[Left Grip]] | Jump |
| [[Right Stick]] | Move |
| [[Right Stick Click]] | Reset position |
| [[Right Trigger]] | Previous weapon; off-hand weapon grab |
| [[A]] | Map |
| [[B]] | Menu |
| [[Right Grip]] | Next weapon; off-hand weapon grab |

While the weapon wheel is open, [[Left Trigger]] chooses the left shoulder slot
and [[Right Trigger]] chooses the right shoulder slot. All button assignments
can be changed in `TurokVRUser.ini`.

## Update and removal

The Hub preserves the personal `TurokVRUser.ini`. Use Uninstall now to
remove only unchanged Hub-owned publisher files and restore any original files
it backed up. The mod can also leave a publisher backup named
`kexengine.cfg.pre-turokvr.bak`; review that backup before restoring video
settings. The Hub never runs the publisher's broad cleanup script and never
deletes the base game, saves or unrelated texture packs.

>>> The Lost Land is much closer when the dinosaurs look back.
