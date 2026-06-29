# S.T.A.L.K.E.R. Anomaly VR

A motion-controlled VR overhaul for S.T.A.L.K.E.R. Anomaly - the free standalone fan-mod successor to the original S.T.A.L.K.E.R. trilogy. Runs on the 64-bit X-Ray engine and stitches the maps of Shadow of Chornobyl, Clear Sky, and Call of Pripyat into one interconnected Zone.

**Mod**: AoE VR (public alpha 0.4.5) - installed and updated through the mod team's own launcher.
**Base game**: Anomaly 1.5.3 (free, no Steam/GOG account needed) - the launcher can download it for you.

**This is a public alpha, not the final VR release.** Expect bugs and crashes - VR digs into the deepest parts of the renderer, plus AOE multithreading.

## What changed

The mod team now ships its **own launcher**, `AoeVrLauncher.exe`. It downloads the base game and the VR modpack from mod.db, enables the right modules in the right order, launches the game in VR, and - importantly - **updates itself and the modpack from then on**. JSGME is no longer needed.

So the Hub no longer hand-installs the modpack. Its only job now is to place that launcher into your Anomaly folder and start it once. Every update after that happens **inside the launcher**.

## What this Hub installer does

1. Asks for your Anomaly folder, or creates a fresh one (default `C:\games\Anomaly VR`).
2. Opens the mod's Discord post and tells you which link to take.
3. You drag the downloaded `AoeVrLauncher.exe` into the installer window; it is copied into the folder.
4. Starts the launcher (UAC prompt is expected).
5. Creates a desktop shortcut `Anomaly VR` pointing at the launcher.

The Hub's **Start in VR** button also runs `AoeVrLauncher.exe`.

## Getting the launcher (Discord-gated)

The launcher download lives behind the mod's Discord server, so the installer opens the exact post for you. In that post:

- Take the **FIRST** download link - the one with the rocket icon, labelled "Launcher (recommended)". That is `AoeVrLauncher.exe` on Google Drive.
- Do **NOT** take the second link - that is the manual full archive (unsupported).

## Using the launcher

1. Switch the language to **English** - the toggle is at the **top-right** (it starts in Russian).
2. Click **Install / Updates** - it downloads the base game and the VR modpack, then keeps both current.
3. Accept the **UAC / admin** prompt.

Because the launcher sits in the same folder as the install, it detects the game automatically.

## Requirements

- **Strong PC** - Anomaly is CPU-heavy, the VR mod even more so
- **Runtime** - pick Oculus OpenXR, SteamVR or VDXR in the launcher
- **Discord account** to reach the launcher download
- Plenty of free disk space (base game + VR modpack)
- A simple install path on a separate drive - avoid `C:\Program Files`, the desktop, or paths with unusual characters

## Updating

Open the launcher (or the Hub's Start in VR) and hit **Updates**. No re-install, no Hub round-trip - the launcher handles base + modpack + itself.

## Manual archive (unsupported)

The mod team still posts a full `.7z` archive for manual installation via JSGME. That path is **explicitly unsupported** by both the mod team and this Hub. Use the launcher.

## Credits

- **VR mod + launcher**: Anomaly VR Team (AoE VR)
- **Base game**: S.T.A.L.K.E.R. Anomaly team
