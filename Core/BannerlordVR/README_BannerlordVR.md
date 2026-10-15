# Mount & Blade II: Bannerlord VR

## About the Game

Mount & Blade II: Bannerlord combines medieval battles, a campaign map, kingdom politics and army command. BannerlordVR v0.2.0-alpha.1 adds tracked hands, physical combat, body holsters, manual bows and crossbows, room-scale movement and OpenXR stereo. It remains an unfinished single-player alpha.

## Before installing

- The **v0.2.0-alpha.1 ZIP's included README and release notes identify Bannerlord v1.5.5** as the tested game build. The GitHub release page also names v1.4.8, but that conflicts with the archive's own notes. The Hub therefore checks for v1.5.5 before changing game files. If Steam still has the default v1.4.8, the installer explains the beta switch, opens Steam Properties only after Enter, waits for Steam to finish, then checks the version again in the same window.
- If Harmony is missing, the installer first offers a completed Harmony ZIP or 7z already in Downloads. Press [Enter] to check that archive, or [N] to open the [Nexus Files tab](https://www.nexusmods.com/mountandblade2bannerlord/mods/2006?tab=files) for a new one. Sign in, choose the Harmony main file and click **Manual download**. Nexus may suggest **Bannerlord Software Extender (BLSE)**; it is optional for this Steam route and is not declared by the BannerlordVR module. The Harmony Manual download is enough for this dependency. After a new download finishes, press [Enter]; the Hub searches Downloads for that new ZIP or 7z. If it is not found, drag the archive onto the installer window. The Hub checks `SubModule.xml` and every declared DLL, then copies the complete Harmony folder into the game's `Modules` folder automatically and checks it again. If a shared Harmony folder already exists but is incomplete, the Hub leaves it untouched and offers manual review. Harmony remains a shared dependency that the Hub does not remove. Enable Harmony above Bannerlord VR in the official game launcher. A greyed-out Bannerlord VR checkbox usually means Harmony is missing or disabled.
- Start Virtual Desktop with **VDXR** or **SteamVR OpenXR** before launching. Meta/Oculus OpenXR is not supported in this release. Other headsets/runtimes are not confirmed.
- Single-player only. Menus and physical interactions are unfinished; crashes and performance dips remain possible. The game is CPU-heavy even before VR.
- **Known earlier scene-loading defect:** the v0.1.0 build could hang or crash in scenes. The publisher reports a successful VDXR headset run for the new build on one machine; your headset and game remain unverified until you test them.
- Personal settings live in `Documents\Mount and Blade II Bannerlord\Configs\BannerlordVR.cfg`. Back up and rename this file while the game is closed if you want to test the new release defaults; the Hub does not replace it.

## Installation and launch

Select Install/Update in the Hub. The installer locates your Steam game, guides the manual Harmony download if needed, checks its installed module, downloads the newest installable GitHub release, and installs both mod DLLs, `SubModule.xml` and `BannerlordVR.default.cfg` into `Modules\BannerlordVR\`. It preserves pre-existing file collisions and records only files it owns. The new asset is named `BannerlordVR-0.2.0-alpha.1.zip`; the module XML deliberately reports `v0.2.0`, because Bannerlord's launcher cannot parse an alpha suffix there. The Hub tracks the full asset version. There is no historical SHA gate.

Use **Start in VR** on the Hub tile. This invokes the official Steam launcher. Open its **Mods** tab and tick the boxes beside **Harmony** and **Bannerlord VR**. Keep Harmony above Bannerlord VR with the required base modules enabled, then click **Play**. The Hub cannot automatically tick these launcher checkboxes. Start a small single-player Custom Battle to learn the physical controls.

If a DLL is missing after the copy, the installer checks the files and shows its antivirus/retry guidance without claiming antivirus caused it. Do not add a Windows Security exclusion unless you trust the publisher and deliberately choose one. The Hub never adds one silently.

The native DLL contains the OpenXR loader; this release needs no separate `openxr_loader.dll`.

## Controls

The shipped layout uses `controls_swap_trigger_grip = 1`. Grip means the squeeze control; trigger means the index-finger control. Context actions follow the game's gamepad bindings.

| Button | Action |
| --- | --- |
| [[Left Stick]] | Move; conventional riding and climbing input |
| [[Right Stick]] | Turn or move the camera |
| [[Left Grip]] / [[Right Grip]] | Reach for and hold a weapon or body holster item; release at its holster to stow, elsewhere to drop or throw |
| [[Off-hand Grip]] | Hold a second point on a two-handed weapon; grip behind a shoulder for an arrow or bolt while holding a bow/crossbow |
| [[Weapon-hand Stick Click]] | Slide that hand along a two-handed weapon shaft while held |
| [[Left Grip]] + [[Right Grip]] | Hold for two seconds with empty hands to toggle VR settings |
| [[Right Trigger]] | Gamepad RB when no physical action owns it; fire a loaded crossbow |
| [[Left Trigger]] | Gamepad LB when no physical action owns it |
| [[A]] / [[Cross]] | Click a pointed-at menu item; jump or confirm elsewhere |
| [[B]] / [[Circle]] | Back or cancel |
| [[X]] / [[Square]] | Kick or context action |
| [[Y]] / [[Triangle]] | Interact or use |
| [[Left Menu]] | Gamepad Start/menu where supplied by the runtime |
| [[Left Stick Click]] + [[Right Stick]] | D-pad direction for orders and battle actions |
| [[Left Stick Click]] | Hold three seconds with [[Right Stick]] centered to recenter |
| [[End]] | In-VR settings panel |
| [[F10]] | Recenter |

Swing or thrust the held weapon to attack; position a shield or weapon to block. For a bow, grab an arrow behind a shoulder, nock it, pull and release the grip. For a crossbow, seat a bolt, grip and pull the string to latch it, then fire with [[Right Trigger]]. On horseback, hold a rein with [[Grip]] and steer with the holding hand; [[Left Stick]] overrides rein input. Grip and pull ladder rungs to climb. On the campaign map, point with the right controller and press [[A]] / [[Cross]].

## Rendering and troubleshooting

Native stereo at 1.00 resolution scale is the release default. AFR can reduce rendering cost but may show timing differences between eyes; depth reprojection is experimental and can leave artifacts near occluded edges. Switch modes in the [[End]] panel. For performance, reduce army size, shadows or resolution scale; DLSS may help.

The two overwritten-per-launch logs are `Documents\Mount and Blade II Bannerlord\Logs\BannerlordVR.log` and `BannerlordVR.Native.log`. Copy both before relaunching when reporting a failure.

If a scene hangs or crashes, close the game, open the official launcher **Mods** tab, untick **Bannerlord VR** and launch the unmodded game. Leave Harmony installed; other mods may use it. Before relaunching for another VR attempt, copy both BannerlordVR logs because they are overwritten on each launch. Send the logs, game version, headset, active OpenXR runtime and render mode to the mod author in the [Flat2VR thread](https://discord.com/channels/747967102895390741/1550654814617075823). A handled view-restoration error may appear during shutdown.

The publisher reports a VDXR headset run and live AFR-to-native-stereo switch on one system for v0.2.0-alpha.1. That does not establish compatibility with other game builds or headsets. BLSE is not a declared module dependency; do not install it solely because Nexus lists it as a suggestion.

## Update and removal

The Hub downloads the latest installable GitHub release asset, including prereleases, and tracks the version encoded in its ZIP filename. The initial publisher tag is a fixed `BannerlordVR` label, so its tag alone is **not** a useful version; the asset version is used instead. The module XML's shorter numeric version is checked against the asset's numeric version. A publisher replacement of an asset under the same versioned filename cannot be distinguished automatically by a version comparison.

Use **Uninstall now** to remove only unchanged Hub-owned BannerlordVR files, including the default configuration, and restore any originals that were present before installation. Harmony, personal settings, other modules, the base game and saves remain untouched.

Publisher: [BannerlordVR on GitHub](https://github.com/NotLooky/BannerlordVR) · [v0.2.0-alpha.1 release](https://github.com/NotLooky/BannerlordVR/releases/tag/v0.2.0-alpha.1) · [Flat2VR Discord thread](https://discord.com/channels/747967102895390741/1550654814617075823) (join [Flat2VR Modding](https://discord.gg/flat2vr) first) · [Gameplay trailer — not VR footage](https://youtu.be/6YZVZ1uzF3o?t=22)

>>> Raise your banner, then hold the line in VR.
