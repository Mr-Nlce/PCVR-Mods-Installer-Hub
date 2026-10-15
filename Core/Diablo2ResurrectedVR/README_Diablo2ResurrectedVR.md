# Diablo II: Resurrected VR

D2R VR by natpoh and BodyWalkVR offers four views: the original overhead view in stereo, a free third-person camera, a tabletop-like view on the floor of your room, and an experimental first-person view with tracked arms. The Hub downloads the latest publisher Setup from BodyWalkVR and records the version it actually installs. The publisher currently distributes the installer on its website rather than through GitHub releases.

## About the Game

Diablo II: Resurrected is an action RPG about pursuing the Prime Evils through Sanctuary. It combines character builds, randomized loot, dungeons and the original Diablo II campaign with remastered visuals.

## Before you install

- Offline single-player only. The publisher warns that injecting code while online can put your Blizzard account at risk. Keep this mod out of online play.
- Install Diablo II: Resurrected. If D2RLoader is missing, the Hub first offers an existing ZIP from your registered Downloads folder. Otherwise it downloads the [official D2RLoader ZIP](https://d2rloader.net/downloads/latest) automatically after your Enter confirmation and installs its complete file set beside D2R.exe. If the automatic download fails, the Hub opens the [publisher download page](https://d2rloader.net/download.html) after a separate Enter confirmation, then checks Downloads again. The mod is a D2RLoader plugin.
- The publisher tested game version 3.3.93787. Other builds may need an address scan; D2R VR Settings has a Status tab and Scan button.
- Have an active headset runtime. The publisher Setup offers BodyWalk Lite when BodyWalk is absent and installs the bridge and ReShade components for headset mode.
- Setup requests Windows administrator approval (UAC). Choose the VR headset mode in its wizard and check the selected game folder.

## Install and update

1. Select [[Install]] in the Hub. It locates a Battle.net, Steam or Xbox game folder or lets you locate D2R.exe manually.
2. After a separate Enter confirmation, it downloads the latest [publisher Setup](https://bodywalkvr.com/api/download/latest?product=d2r_vr). This is the publisher's current installer, including any newer build offered there.
3. Select VR headset mode in Setup. The Hub records an installed version only when the game-side plugin, ReShade and BodyWalk bridge exist after Setup finishes.
4. Select [[Start in VR]] in the Hub. This opens D2R VR Settings. On its Home tab, select [[Start BodyWalk]], then [[Launch Diablo II (D2RLoader)]] for offline play.

## Game video settings

In Options > Video, turn Vertical Sync and NVIDIA DLSS off. Set the frame cap to 180 for a 90 Hz headset. Use FXAA or MSAA rather than TAA, and set Ambient Occlusion Quality to Medium. For a square headset image, use a square game window or a square FlatVR virtual monitor.

## Views and controls

| Button | Action |
| --- | --- |
| [[F1]] | Original overhead stereo view. |
| [[F2]] | Free third-person view. |
| [[F3]] | Place the game on the floor in a room-scale view. |
| [[F4]] | Experimental first-person view with tracked arms. |
| [[F12]] | Cycle through views. |
| [[Left Stick]] | Move in the first three views. |
| [[Left Grip]] + [[Left Stick]] | D-pad directions in BodyWalk's controller mapping. |
| [[Left Stick Click]] | Open the map. |
| [[Left Stick Down]] | Open the menu or inventory. |
| [[Right Stick Down]] | Reset the forward direction. |
| [[Right Trigger]] | Fire a bow, crossbow or spell toward the hand in first-person mode. |
| [[Right Stick Click]] | Swap weapon sets in first-person mode. |

First-person hand and weapon alignment is still a preview. Adjust it in D2R VR Settings. Melee swings and belt potions use BodyWalk gesture mappings. Other actions follow Diablo II's gamepad layout.

## Troubleshooting

- If the game does not enter VR, check that Setup was run in VR headset mode, BodyWalk and the headset runtime are active, and the BodyWalk D2R bridge exists.
- If D2R VR Settings reports missing game addresses after a game update, use its Status and Scan controls and consult the publisher's compatibility notes.
- If a required file disappears, inspect the Hub log and security history. A missing file alone does not establish an antivirus cause.

## Links

[Publisher and source](https://github.com/natpoh/diablo2-vr-port) · [Latest publisher Setup](https://bodywalkvr.com/api/download/latest?product=d2r_vr) · Join [Flat2VR Modding](https://discord.gg/flat2vr) first, then open the [Diablo II VR discussion](https://discord.com/channels/747967102895390741/1557022511294586892) · [VR gameplay](https://www.youtube.com/watch?v=8ae9Q3E0nls)

Even Deckard Cain never identified a drop this immersive.
