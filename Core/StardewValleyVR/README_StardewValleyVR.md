# Stardew Valley VR Installer

Automated installer for **Stardew3D** by GingasVR - it rebuilds Stardew Valley as a first-person 3D world you can play flat on your monitor or in VR, and you switch between 2D, 3D and VR with a hotkey at any time.

It's a work in progress and things will look odd here and there, but it's fully playable, **your save is never altered**, and you can remove it whenever you like.

## What it installs
- **Stardew3D** - the VR mod itself
- **SMAPI** - the mod loader Stardew Valley needs (its own installer runs)
- **Generic Mod Config Menu** - required, this is where all the mod's settings live

All three are free downloads from Nexus Mods. Nothing is bundled with the Hub.

## Requirements
- Stardew Valley on **Steam**, GOG, or the Xbox app / Microsoft Store
- A free **Nexus Mods** account
- For VR: a **SteamVR** or **OpenXR** headset. You do **not** need a headset - flat 3D works on its own.

## How to use
1. Click **Install Mod**. The installer finds your game, then walks through the three downloads.
2. For each one it opens the Nexus page, then picks the file up from your Downloads folder or takes a drag-and-drop.
3. SMAPI installs itself automatically into the folder that was found - no menu to click through.
4. Launch through **StardewModdingAPI.exe**, not the normal Stardew shortcut. The Hub's **Start in VR** does this for you.

## Quest headsets - one setting first
On Quest (Virtual Desktop or Link) open the mod's settings menu, turn on **Use OpenXR runtime** in the top section, then restart the game. Set Virtual Desktop's OpenXR runtime to **VDXR**.

SteamVR headsets (Index, Vive) need no change - just have SteamVR running.

**SteamVR with a Quest (e.g. Steam Link) does not work** - use the OpenXR route above.

## Hotkeys
- [[F5]] flat 3D mode - first person, normal Stardew controls
- [[F8]] VR mode - the headset has to be connected first
- [[F9]] recenter the VR view
- [[F10]] toggle the wrist HUD on the left controller
- [[F7]] dump debug info to the SMAPI console for bug reports

All of them can be rebound in the mod's settings menu.

## VR controls
- [[Left Stick]] walk, [[Right Stick]] turn (smooth by default, snap can be set in the menu)
- [[Right Trigger]] use tool or attack - hold to charge
- [[Left Trigger]] interact, talk, open doors
- [[A]] next toolbar slot, [[B]] shift toolbar row (right hand) - [[B]] on the left hand opens the menu
- Swing your right hand for a melee swing or a gesture-controlled tool
- Menus float in front of you: point with the right controller, trigger clicks, grip is right-click
- Fishing is motion-controlled - jerk the rod up to hook, then raise and lower your hand to keep the fish in the bar

## Worth knowing
- **True 3D** turns objects and buildings into voxel models and is GPU-heavy. Turn it off for a better frame rate; culling effects help too.
- **Cutscene view** can be first person, third person or a flat theater screen. Third person tends to look best.
- Building and placing objects works, but it's easier in normal 2D mode.
- Map edges, heavily modded maps and some decorations can render oddly - that's the nature of turning sprite data into 3D.
- The mod works on top of modded setups and expansions. The only known incompatibility is **Clear Glasses**.

## Removing it
Delete the `Stardew3D` folder from your `Mods` folder and the game is plain 2D Stardew again. SMAPI and Generic Mod Config Menu can stay - other mods need them.

## Credits & support
**Stardew3D** is made by **GingasVR**. Bug reports go to the mod's Nexus page - press [[F7]] and attach your SMAPI log via smapi.io/log.

The mod is free. If you enjoy it and want to help GingasVR keep developing it, you can support them here:
- https://www.patreon.com/c/gingasvr/membership
