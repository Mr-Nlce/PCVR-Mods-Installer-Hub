# F.E.A.R. VR Installer

<!-- hub:keep-order -->

Two separate VR mods are available. TheFreeMike supports verified GOG and original Steam copies; DR-89 supports Steam:

| | Game edition | Source |
|---|---|---|
| **Mod 1: thefreemike** | GOG F.E.A.R. Platinum Collection or original Steam base game | current stable public release from GitHub, downloaded automatically |
| **Mod 2: DR-89** | Steam Ultimate Shooter Edition | latest open beta from GitHub, downloaded automatically |

Both may be tracked at the same time when they use separate clean game folders. Do not install the two publishers' files into the same Steam game root. When both real mod markers are present on separate roots, the Hub shows one launch button for each.

## Mod 1 — F.E.A.R. VR GOG and Steam build — by thefreemike

### About this mod

TheFreeMike's public VR mod adds tracked hands, physical weapon handling, stereo VR,
configurable controls and comfort options to the original F.E.A.R. campaign. Choose
**Grip & Holsters** for physical body draws or **Classic Sticky** for conventional weapon
switching. This is the maintained continuation of the former private release candidates.

### Supported game and runtime

- **Verified GOG F.E.A.R. Platinum Collection or original Steam F.E.A.R. base game.**
  Other retail executable variants, the expansions and multiplayer are unsupported.
- Windows 10 or 11 and a PC VR headset are required. Quest 3 with Touch controllers is
  the author's physically validated baseline; other hardware remains experimental.
- Virtual Desktop: select **VDXR**, connect first and keep SteamVR closed.
- Steam Link or another SteamVR headset: start SteamVR, connect first and use a build with
  Win32/32-bit OpenXR support.
- Meta Quest Link and Air Link are unsupported, including through SteamVR.

### Before installation

Start the unmodified GOG or Steam game once, reach its main menu, load a level and then quit. Fix
any flat-game launch problem before adding VR. The author's Setup checks the supported
game executable and should be pointed at the folder containing `FEAR.exe`. Use a clean
copy without DR-89 or another graphics/input loader; the two VR mods must not share one root.

The Hub checks a previously confirmed folder first and keeps that assignment in its durable
state across updates and replacement Hub folders. It asks again only when that folder or its
`FEAR.exe` no longer exists. Fresh discovery checks the GOG per-game registry path before the
standard Galaxy location `C:\Program Files (x86)\GOG Galaxy\Games\F.E.A.R. Platinum Collection`
and offline-installer location `C:\GOG Games\F.E.A.R. Platinum Collection`. Steam is detected at
`C:\Program Files (x86)\Steam\steamapps\common\FEAR Ultimate Shooter Edition` and through its
library manifest. The retail path `C:\Program Files (x86)\Sierra\FEAR` is recognized by the Hub
as a base-game location, but remains unsupported by thefreemike's publisher installer.

### Installing and updating

The Hub resolves the latest stable public GitHub release and opens the author's native
`F.E.A.R. VR Setup.exe`; its `setup-files` folder must remain beside it. Choose **Install
F.E.A.R. VR** for a new setup or **Upgrade F.E.A.R. VR** for RC6.2 or another earlier
private beta. A direct upgrade preserves the existing backup lineage, saves and profiles.
Do not uninstall an earlier thefreemike build first and do not manually mix release ZIPs.

The current public release is **v1.3.1**. The unified v1.1.0 installer and launcher add
support for verified Steam copies alongside GOG, pass Steam startup through Steam without
changing `FEAR.exe`, include the accepted Steam input-polling fix and improve aiming,
weapon transfers, pickup priority, jumping, ladders and several physical interactions.
v1.2.0 added a branded launcher with display-mode selection and further weapon, reload and
holster polish. v1.3.0 prepares the verified original Steam executable for up to 4 GB of
address space on its first VR start, keeping `FEAR.exe.fearvr-memory-original` beside it so
the updated uninstaller can restore the original. GOG already has large-address support and
is left unchanged. The release also keeps installed official languages, adds experimental
Cyrillic menu-font correction, accepts either trigger at the continue prompt and adds a
slow-motion tutorial card. Other languages and full-campaign localization coverage remain
experimental, and VR-specific text can remain English. Upgrade directly without
uninstalling; saves, settings and the established recovery backup remain in place.

v1.3.1 fixes the v1.3.0 loading-screen regression that could make the controller,
pointer and headset appear unresponsive at **Press any key to continue**. Use either
trigger to continue. The separate native cleanup crash that can occur only while
quitting the game is still an upstream limitation. Everyone on v1.3.0 should update
directly; no uninstall is needed and saves, profiles and settings are retained.

The release files are unsigned. Keep antivirus protection enabled and review a warning
normally. A SHA-256 match supplied by GitHub can be shown as a positive confirmation, but
a missing or changed digest never blocks a newer release. The Hub records success only
after the actual VR launcher, bridge DLL and generated uninstaller exist and survive the
antivirus recovery check.

### Controls

| Button | Action |
|---|---|
| [[Controller Pointer]] + [[Trigger]] | Point at and select menu items |
| [[Right A]] + [[Left X]] | Pause with the SteamVR Touch layout |
| [[Right A]] + [[Left A]] | Pause with the suggested Index layout |
| [[Movement Stick]] | Move; with Tap to Walk enabled, tap the stick to toggle walking |
| [[Utility Control]] | Hold for a medkit; tapping and holding are separate actions |
| [[Grip]] | In Grip & Holsters, reach to a body slot and draw physically; the weapon wheel is disabled in this mode |
| [[Weapon Button]] | In Classic Sticky, tap to switch or hold to open the weapon selector |
| [[Reload / Pouch]] | Follow the weapon-specific magazine, pouch and chambering prompts |
| [[Grip]] | Hold at a ladder and move the hand; release to let go |
| [[Either Trigger]] | Continue after loading when the continue prompt appears |
| [[Options]] > [[VR Settings]] > [[Controls & Layout]] | Reconfigure controls |

The installed `FEAR-VR-Install` folder contains the full controls, calibration,
troubleshooting, limitations and controller-layout guides. Layouts are saved per reported
controller profile and weapon hand.

### Launching, removal and support

Use the **thefreemike** launch button in the Hub or `F.E.A.R. VR.exe` in the selected game
folder. On Steam, stay signed into the owning account and leave the VR launcher open while
it hands startup to Steam. On the first v1.3.x Steam VR start, press **Play in VR** once and
allow the one-time 4 GB preparation to finish; keep `FEAR.exe.fearvr-memory-original`.
Steam level loads can take several minutes, so GOG remains the
recommended route. To remove it, use **Uninstall thefreemike** on the detail page; the author's
`FEAR-VR-Install\Uninstall F.E.A.R. VR.exe` restores managed originals while retaining
saves, profiles and deliberately preserved changed files.

Project and stable releases: https://github.com/thefreemike31/fear-vr

GitHub issues: https://github.com/thefreemike31/fear-vr/issues

Discord discussion and support: https://discord.gg/NtAnbK6z9B

## Mod 2 — F.E.A.R. VR Steam build — by DR-89

### About this mod

An open-source OpenXR mod for the single-player base game of F.E.A.R. 1.08. It renders
true stereo from the LithTech camera and adds motion controls, a stereo HUD and VR menus.
This is an early open beta; issues are expected.

### Highlights

- Native per-eye stereo rendering, toggleable with [[F8]].
- Relative head tracking with recenter and optional HMD translation.
- Full motion controls for movement, turning, jumping, crouching, sprinting, weapons,
  grenades, slow motion, aiming, firing and interaction.
- Right-hand weapon, aim laser, hand flashlight and shot haptics.
- World-locked VR panel for menus, loading screens and mission briefings.
- A VR settings page inside the Escape menu.

### Requirements

- F.E.A.R. 1.08 Ultimate Shooter Edition on Steam.
- F.E.A.R. Public Tools 1.08. The Hub locates or installs it and performs the required
  Monolith registry step through a visible UAC prompt.
- An OpenXR runtime and headset. SteamVR and VirtualDesktopXR are confirmed.

The installer validates the expected executable build. Unsupported game builds stay
unhooked and run flat instead of being patched blindly.

### HD textures

The author recommends **HD Textures for F.E.A.R. & Extraction Point v2.0.2** by Rivarez.
It is a separate 5.06 GB ModDB download. The Hub can unpack
`HDTextures4FEAR_XP_v2.0.2.rar` and run the texture pack's own installer. Its **Steam
option is on the right and is not preselected**. Select it before clicking Install.

### What the installer does

The newest GitHub release is selected with prereleases included. Current overlay releases
are prepared inside the game; older staged releases remain supported. The real
`fearvr-host.exe` marker is checked in both layouts, and the selected install root is
recorded separately from the GOG mod so neither installation hides the other.

If GitHub cannot be reached, the installer offers a deliberate manual ZIP choice. It does
not silently take an arbitrary archive from Downloads.

### Controls and launching

| Button | Action |
|---|---|
| [[Left stick]] / [[Left grip]] | Move / sprint |
| [[Right stick]]; up jumps and down crouches | Turn / jump / crouch |
| [[Right stick click]] | Recenter |
| [[A]] / [[B]] | Weapon / reload or grenade |
| [[X]] / [[Y]] | Slow motion / pause |
| [[Right grip]] / [[Right trigger]] | Use / aim and fire |
| [[Left trigger click]] | Hand flashlight |

Start SteamVR or Virtual Desktop first, then use the **DR-89** launch button in the Hub or
the F.E.A.R. VR desktop shortcut. If the VR host crashes, the game may continue flat.
Mouse, keyboard and gamepad remain available.

### Known limitations and source

The D3D9 stereo path and stereo HUD use CPU readback. HMD translation has no world
collision and remains opt-in. The left system button cannot be bound because SteamVR
captures it.

Project and prereleases: https://github.com/DR-89/fear-vr

>>> Slow time. Check the shadows. Alma is already here.
