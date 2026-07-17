# World of Warcraft VR

World of Warcraft is a massive online role-playing game where players explore the world of Azeroth, complete quests, and develop their own hero. You can choose from different races and classes, fight monsters, collect gear, and team up with other players in dungeons, raids, and PvP battles.

WoVR by Marulu adds native VR support with motion controls to the **3.3.5a (WotLK, build 12340) client** - the 2010 version of the game, not the current retail / live-server version.

![WoW](../Assets/WorldOfWarcraft_screenshot.jpg)

**Mod:** WoVR v7
**Author:** Marulu (XIVR / WoVR dev)
**Target client:** WoW 3.3.5a build 12340 (US / EU)
**Source / info:** https://github.com/ProjectMimer/WoVR
**Precompiled builds:** Flat2VR Discord (the installer opens it for you)

## Requirements

- A working **3.3.5a build 12340** WoW client (US or EU), unedited, 4 GB-patched, or LUA-unlocked - all three are fine
- **7-Zip** installed (the installer needs it to extract the .7z)
- A working **Discord account** to download the precompiled mod files
- A **SteamVR-compatible headset** (or any OpenVR runtime)

The mod is **not** compatible with the current retail / live-server WoW client. If you do not already have a 3.3.5a client, this installer cannot help with that part.

## The three WoVR variants

WoVR ships in three flavours. Pick one in the installer:

| Variant | Use this if you... |
|---|---|
| **VR UI** (recommended) | want the dedicated VR interface and you are NOT on AMD graphics |
| **Flat UI** | are on an AMD graphics card (VR UI is incompatible with AMD) |
| **KB & M** | want keyboard + mouse only; no motion controls, no head-tracked locomotion |

To switch variants later, re-run the installer in **Update / Switch** mode and pick a different one - the cleaner only needs to run once.

## What the installer does

1. Locates your WoW folder (or asks for the path)
2. Runs `WoVR-Cleaner.bat` in the WoW folder to delete the launcher / patcher / cache / addons / WTF so only the bare game files remain (Full Install only)
3. Opens the Flat2VR Discord and the WoVR download channel (the only place precompiled builds are distributed)
4. Accepts the .7z via drag-and-drop and extracts it into the WoW folder
5. Offers to apply the **NTCore 4 GB RAM patch** to `Wow.exe` (Full Install only) - unlocks 4 GB of address space and fixes the "half the world is black" symptom

## Controls

![Controls](WorldOfWarcraft_controls.jpg)

- **[[Left Stick]]:** character movement; click for random mount
- **[[Right Stick]]:** snap turning; click toggles 1st/3rd person + camera recenter
- **[[Left Grip]] + [[Right Stick]]:** camera zoom
- **Left hand angle:** controls direction of movement, flying, swimming
- **Right hand angle:** target, interact with world & UI, AoE aiming
- **Y:** Esc menu | **X:** Toggle map | **A:** Jump | **B:** Next target
- **Triggers:** Left = Left Click | Right = Right Click
- **[[Grip]] + face buttons:** action set hotkeys (1/2/3/0/8/9 keys etc.)
- **[[Left Trigger]] + [[Left Grip]]:** previous / next action set

## After install - first login

1. Launch SteamVR (or your headset's runtime) first
2. Launch `Wow.exe` from the WoW folder
3. Log into a character. On the first login the UI and controls will look wrong - press **Y on the left controller** (or Esc) to open the menu and choose **Exit Game**
4. Next login is fully set up - have fun!

## Config: mounts, snap turning, etc.

Edit `<WoW folder>\vr\config.txt`:

- **Mount shortcut:** set `groundMountID` and `flyingMountID` to a Wowhead **spell ID** (NOT item ID). Example for Sea Turtle: `groundMountID: 64731` (from `wowhead.com/wotlk/spell=64731/sea-turtle`)
- **Snap turning:** `snapRotateX` / `snapRotateY` = 0 disables, 1 enables. Adjust `snapRotateAmountX` / `snapRotateAmountY` for the degrees per step.
- **UI scaling:** `uiMultiplier` - 1 = no scale, higher = bigger UI on low-res displays.

## Troubleshooting

- **Half the world or menu is black** -> you are out of RAM. Run the installer in Update mode and apply the 4 GB patch, or lower `uiMultiplier` to 1 or 2, or lower SteamVR supersampling.
- **Game shows only the minimap** -> chosen resolution is too big for your display. Pick a lower one.
- **Floating keyboard does not work** -> needs admin rights, and is not supported on Windows 11.
- **Text is low res** -> Nvidia users can enable DSR Factors, set the monitor to the highest resolution, and set DPI to 100%.
- **VR UI graphics menu missing in-game** -> it is only hidden from the in-game Esc menu, still accessible from the login screen.
- **VR UI displays broken** -> AMD graphics card. Switch to the Flat UI variant via Update mode.

## Should I supersample?

The game already renders at 2x headset resolution. Further supersampling is **not** recommended.

## Support the developer

WoVR is a labour of love by Marulu. If you enjoy the mod, consider tipping:

https://ko-fi.com/projectmimer

>>> Azeroth, life-size. For the Horde - or the Alliance.
