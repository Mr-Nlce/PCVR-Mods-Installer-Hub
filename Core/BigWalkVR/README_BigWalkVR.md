# Big Walk VR

Full multiplayer-compatible SteamVR support for **Big Walk** by House
House, with 6DOF motion controls, grabbing and throwing. By CircuitLord.

## What it installs
- **The Big Walk VR app** (`BigWalkVRInstaller.exe`) into your Big Walk
  folder

This entry works differently from the rest of the Hub: the mod is not a
downloadable archive. CircuitLord ships a small companion app that finds
Big Walk, sets up **MelonLoader**, downloads the mod plus any optional
add-ons, keeps all of it up to date, and launches the game in VR or
flat. So the Hub installs that app and hands over.

The Hub verifies the download against the SHA-256 in the project's own
`manifest.json` before it writes anything into your game folder.

## Requirements
- Big Walk on Steam
- SteamVR

## How to use
Click **Install Mod** on the game tile or detail page. The installer puts
the app into your game folder and then opens it for you. Three presses in
the app:

1. **Find Big Walk** - usually already filled in. If not, press
   **Change** and pick the folder.
2. **Set up MelonLoader** - press its **Install**.
3. **Big Walk VR** - press its **Install**.

Optional: **Solo Launch** has its own **Install** - press that too if you
want to play without other players.

The Launch buttons stay greyed out until 1-3 are done. Back in the
installer, press Enter and it checks whether the mod really arrived.

From then on, **Start in VR** in the Hub and the *Big Walk VR* desktop
shortcut both open the app - press **Launch in VR** there, with SteamVR
already running.

**The first start takes longer than usual** while the mod is prepared.
Give it time, it is not stuck.

## Controls
Motion controllers, with a pointer for the menus. The mod ships its own
SteamVR binding sets for **Index Controllers** and **Oculus Touch**
(`bindings_knuckles.json`, `bindings_oculus_touch.json`), so those two are
mapped out of the box - anything else falls back to SteamVR's own
remapping under Controller Bindings.

Objects are grabbed and thrown with the controllers rather than a button
prompt, so reach out and take hold of things.

## Flat and VR together
Launching Big Walk from Steam, or pressing **Launch in Non-VR**, starts
the game flat with the mod still installed. Flat and VR players can play
together and see each other's tracked movement.

## Updates
The app updates itself and the mod. There is nothing to chase in the Hub
for this entry.

## Optional add-on
**Solo Launch** bypasses the initial player-count check, so you can walk
alone. It sits under the optional add-ons in the app with its own
**Install** button.

## Removing it again
The app's **Uninstall** takes out every installed mod, MelonLoader and the
`Mods`, `Plugins`, `UserLibs` and `UserData` folders. Your saves are kept.

## If something goes wrong
The app's **Logs** tab has its own history, and **Mod logs** opens
`MelonLoader\Latest.log` in your game folder - that is where the mod
itself reports errors.

Big Walk VR and its app are community projects, not affiliated with or
endorsed by House House.

Project page:

https://github.com/CircuitLord/BigWalkVRInstaller
