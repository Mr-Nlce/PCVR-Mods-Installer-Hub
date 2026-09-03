# Outbound VR Installer

Automated installer for **OutboundVR v1.0** by Destroyjevski - a stereoscopic 6DOF VR conversion of Outbound, the cozy van-life survival/crafting road-trip game. Played on a **gamepad**, just like the flat game.

No original game files are modified; removing the mod restores the vanilla game.

## What it installs
- **OutboundVR mod** - stereo 3D rendering with full 6DOF head tracking
- **BepInEx 6.0.0-be.755** - mod loader (bundled with the mod; developed and tested against this exact version)
- Two mode-switch helpers - `Switch to flat.bat` and `Back to VR.bat`

The mod's `GameFiles` contents go into the **game root folder** (the folder that ends up with a `BepInEx` folder and `winhttp.dll` at its root).

## Requirements
- Outbound owned on **Steam** (App ID 2681030), **Epic Games Store**, or **Xbox / Microsoft Store / PC Game Pass**
- A free **Nexus Mods** account - the mod is distributed on Nexus
- An **OpenXR runtime**, set once (pick one):
  - **Virtual Desktop** -> choose **VDXR** in the Streamer app **(recommended, most-tested)**
  - **SteamVR** -> Settings -> OpenXR -> **Set SteamVR as OpenXR runtime**
  - **Quest Link** -> set the Oculus runtime as the active OpenXR runtime in the Meta PC app

> Hardware note: Outbound is **surprisingly demanding** in VR - treat it as a STRONG-tier title.

## How to use
1. Click **Install Mod** on the game tile or detail page.
2. The installer opens the Nexus Mods files page. Log in (free) and download the OutboundVR file.
3. Back in the installer, confirm the file it found in your Downloads folder, or drag the ZIP onto the window.
4. The installer auto-locates Outbound (Steam / Epic / Xbox) and merges the mod's `GameFiles` into the game root.
5. **Launch normally** - VR is active immediately, no batch file needed to start in VR.

> **First launch only:** expect a longer startup (up to several minutes; the window may stay black) while the mod generates helper files once. **Don't close it** - every later launch is fast.

## Controls (gamepad)
Interactions are aimed **with your head**, not the camera stick. A small bracket shows the current target: **cyan = usable**, **orange = blocked**.

- [[R-Stick]] turns you left/right only - look up/down with your head
- [[R3]] re-centers the view at any time
- [[L3]] + [[R3]] together toggles the entire HUD on/off
- Menus, HUD and grid menus (backpack, workbench, journal) float on a panel in front of you and behave exactly like flat; the selected element gets a pulsing yellow frame
- First-person arms appear only while you actually do something (grabbing, fire-starting, carrying); while a tool mode is active (building, painting, fishing) the tool stays visible

**VR keyboard** (text fields, e.g. naming your license plate): [[D-Pad]] selects, [[A]] types, [[X]] deletes, [[Y]] space, [[R-Stick]] moves the text cursor, [[Start]] confirms.

**Color pickers** (vehicle colors, customization) work fully in VR, including the hue/saturation/brightness selector.

## Switching between VR and flat
VR is active right after install. To play flat, run **`Switch to flat.bat`** in the game folder; run **`Back to VR.bat`** to return. **Quit the game before switching.** Saves are shared - it's the same game.

## Configuration
Arm position/size and other tweaks live in `BepInEx\config` inside the game folder.

## Removing the mod
Delete the mod files from the game folder - the vanilla game is restored. No original game files were changed.

## Credits & license
- **OutboundVR** by Destroyjevski (developed with the help of AI coding agents)
- BepInEx 6.0.0-be.755 (mod framework, LGPL-2.1); Unity OpenXR Plugin 1.14.1 (Unity Companion License)

**Free distribution:** OutboundVR is provided free of charge. The author will never charge for access, and no third party is authorized to sell it or include it in a paid package. This mod is not affiliated with the Outbound developers - please support the game!
