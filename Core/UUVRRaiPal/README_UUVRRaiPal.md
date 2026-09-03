# UUVR / Rai Pal

**Rai Pal v0.19.2** by Raicuparta — the easiest way to use **UUVR (Universal Unity VR)**, an experimental injector that turns flat Unity-engine PC games into VR. UUVR is the Unity counterpart to UEVR (which does the same for Unreal Engine 4/5).

This is an **external tool**: the Hub's button links you straight to the official `RaiPal.exe` download. There is no Hub installer — you run Rai Pal yourself, and it handles everything else.

## What you get
- **Rai Pal** — a mod manager for universal game mods
- Rai Pal then downloads and installs **UUVR + BepInEx** for you, per game, on demand (nothing is bundled)

## What Rai Pal does
Rai Pal is a tool that helps you use and make universal game mods — mods that aren't built for one specific game but work across many games of the same engine. Features:
- Auto-find installed games from supported providers (Steam, GOG, Epic, Xbox)
- Auto-find owned (but not necessarily installed) games
- Detect each game's engine (look for **Unity**)
- Install/run the correct version of universal mods like UUVR
- Keep universal mods updated

## Requirements
- A flat Unity-engine PC game you own
- SteamVR (UUVR uses the OpenVR runtime)

## How to use
1. Click the Hub button to download `RaiPal.exe`, then run it (it's a portable app — put it wherever you like).
2. Rai Pal auto-scans your libraries and lists games with their engine. Filter for **Unity**.
3. Select a Unity game and install/run **UUVR** from its mod list — Rai Pal fetches UUVR + BepInEx and keeps them current.
4. Start **SteamVR** first, then launch the game from Rai Pal.
5. **The game starts FLAT - press [[F3]] in-game to turn VR on.** UUVR does not
   switch itself on. [[F5]] toggles the in-game UI overlay.

> **If F3 does nothing**, the runtime was not running when the game started.
> Close the game, start SteamVR, launch again.

> **UUVR is a viewing mod.** Stereoscopic depth and head tracking - you still
> play with the gamepad. No motion controls, no free camera, and a third-person
> game stays third-person. That is by design, not a limitation of your setup.

> UUVR is experimental. Older Mono-based Unity games work best; modern IL2CPP titles may not be supported. Results vary per game — expect to tweak settings.

## Credits
- **UUVR** and **Rai Pal** by Raicuparta — https://raicuparta.com/
- Rai Pal: https://raicuparta.com/rai-pal/ — download: https://github.com/Raicuparta/rai-pal/releases/latest
- UUVR source: https://github.com/Raicuparta/uuvr
- Built on BepInEx (downloaded as a managed dependency by Rai Pal)

## Support the developer
Raicuparta develops UUVR and Rai Pal in the open. If you enjoy his work, consider supporting him:
- Patreon: https://www.patreon.com/c/raivr/membership

>>> Every Unity game is a door. Rai Pal hands you the key — step through in VR.
