# SiN Episodes: Emergence

**SiN VR (auto-update)** by **RototRobot** adds native stereo rendering, 6DoF head tracking, roomscale walking and motion-controlled weapons to *SiN Episodes: Emergence*. The mod author documents and supports the Steam version. The Hub can prepare a best-effort direct route for another legitimate copy containing `SinEpisodes.exe`, but cannot certify that build as compatible.

## Before setup

Run the unmodded game once, let it reach the main menu, then quit. The Hub installer checks for the generated configuration before it changes the game folder.

SteamVR and a Vulkan-capable GPU are required. The mod uses OpenVR and was tested on Vive Cosmos and HP Reverb G2; other SteamVR-compatible headsets should work.

## Install

1. Select **Install VR mod** in the Hub.
2. Choose the optional readable GUI scaling and Arcade Reload files inside setup.
3. The installer downloads the current official GitHub release, verifies its structure, backs up every overwritten file and copies the mod beside `SinEpisodes.exe`.
4. For Steam, paste the visibly printed launch option into the Steam Properties window. The installer verifies its clipboard copy, but the complete line remains on screen for manual copying. Do not add `-w` or `-h`.
5. For a non-Steam copy, no Steam option is used. Setup creates **SiN Episodes VR** on the desktop and configures **Start in VR** in the Hub to call `sinvr_launcher.exe` directly with `--exe`. This is a best-effort Hub route, not an upstream-confirmed game build.
6. Start SteamVR, then launch through the route prepared for your installation.

On first VR launch, `sinvr.cfg` and `sinvr.log` appear beside the game executable. The Hub begins at a conservative 0.75 render scale, disables the two expensive experimental rendering switches and sets `vr_allow_oversize_window = 0` to avoid oversized headset-window failures. An existing explicit value is preserved when the installation has no matching failure evidence. SteamVR's resolution slider also controls render resolution. Raise quality only after a stable launch.

## Controls

| Input | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Right Stick]] | Smooth or snap turn |
| [[Right Stick Down]] | Crouch |
| [[Right Trigger]] | Fire |
| [[Left Trigger]] | Alternate fire |
| [[A]] | Jump |
| [[B]] | Use |
| [[X]] | Reload |
| [[Y]] | Flashlight |
| [[Weapon-hand Grip]] | Draw from a shoulder or hip holster |
| [[Off-hand Grip]] | Hold a grenade or use a two-handed foregrip |
| [[Left Stick Click]] | Open or close the menu |
| [[Right Stick Click]] | Recenter |

Shots leave the tracked muzzle rather than your face. A downward weapon-hand swing performs melee; physical crouching and roomscale movement use the game's collision.

## Optional improvements

**GUI scaling** enlarges fixed-size Load, Save and New Game screens at headset resolutions. **Arcade Reload** stops automatic empty reload and enables the waist reload gesture; install its files and setting together. The installer offers both and records exact originals for Uninstall now.

## Current limitations

- The current upstream build has a reported start/new-game crash on some systems. If **New Game** stops the music or leaves you at the menu, test **New Game** once with the mod disabled through **Flat / VR**. If flat mode works, the failure is in the current VR path; if flat mode also fails, repair or replace the base-game copy first. The game's age or a non-Steam executable alone does not prove which side failed.
- Save before entering either car. The current build can eject the player and soft-lock those two sequences.
- SiN has no separate hand model, so its viewmodel arms are hidden and the tracked weapon floats.
- Windows 11 Smart App Control can block unsigned binaries without an allow-once exception. Ordinary antivirus exclusions do not override Smart App Control.
- Opening all engine portals can prevent eye-to-eye geometry disagreement but costs substantial performance; sample-rate shading is also expensive. The Hub leaves both off initially. If the mod records a DXVK `VK_ERROR_DEVICE_LOST` render stall, reinstalling backs up `sinvr.cfg` under `.pcvrhub_sinvr_user_backup` and reapplies the conservative values instead of overwriting the only copy of your settings.

## Flat play and removal

Use **Flat / VR** on this page to park or restore the VR proxy without deleting files. **Uninstall now** removes only manifest-owned files, restores replaced originals and the vanilla crosshair, and retains `sinvr.cfg`, saves and unrelated mods. Steam Properties opens only for a Steam installation; a Hub-created standalone shortcut is removed only when its target still matches this game folder.

## Credits

- **SiN VR:** RototRobot — [project and support](https://github.com/RototRobot/Sin-Episodes-VR-Port)
- **SiN Episodes: Emergence:** Ritual Entertainment
- Source-engine VR reference work credited by the author: L4D2VR, Portal 2 VR, OpenVR and DXVK contributors

Blade is back — Freeport never learned to stay quiet.
