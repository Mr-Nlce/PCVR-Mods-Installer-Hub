# F.E.A.R. VR Installer

<!-- hub:keep-order -->

Two separate VR mods are available. Pick the one that matches your game copy:

| | Game edition | Source |
|---|---|---|
| **Mod 1: DR-89** | Steam Ultimate Shooter Edition | latest beta from GitHub, downloaded automatically |
| **Mod 2: thefreemike** | GOG F.E.A.R. Platinum Collection | private beta supplied through the author's Discord |

Both may be installed at the same time because they use different game and mod folders.
When both real mod markers are present, the Hub shows one launch button for each.

## Mod 1 — F.E.A.R. VR — by DR-89

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
It is a separate 5.06 GB download from ModDB. The Hub can take
`HDTextures4FEAR_XP_v2.0.2.rar`, check for 7-Zip, unpack it to a temporary folder and then
run the texture pack's own `FEAR_HDTextures.exe`.

In that texture installer, the **Steam option is on the right and is not preselected**.
Select it before clicking Install. The wrong edition can produce
`application load error 3:0000065432`. To remove the pack later, run its installer again
and choose Uninstall. If textures disappear in-game, set texture resolution to minimum and
then back to maximum to reload them.

### What the installer does

The newest GitHub release is selected with prereleases included. Current overlay releases
are prepared inside the game; older staged releases remain supported. The mod's real
`fearvr-host.exe` marker is checked in both layouts, and the selected install root is
recorded separately from the GOG mod so neither installation hides the other.

If GitHub cannot be reached, the installer offers a deliberate manual ZIP choice. It does
not silently take an arbitrary archive from Downloads.

### Launching

Start SteamVR or Virtual Desktop first, then use the **DR-89** launch button in the Hub or
the F.E.A.R. VR desktop shortcut. If the VR host crashes, the game may continue flat.

### Controls

- [[Left stick]] move; [[Left grip]] sprint.
- [[Right stick]] turn; up jumps, down crouches; [[Right stick click]] recenters.
- [[A]] weapon switch; [[B]] reload or grenade; [[X]] slow motion; [[Y]] pause.
- [[Right grip]] use; [[Right trigger]] aim and fire.
- [[Left trigger click]] toggles the hand flashlight.
- Tilt the left hand to lean. Mouse, keyboard and gamepad remain available.

### Hotkeys and VR panel

- [[F8]] toggles stereo; [[F9]] recenters; [[F10]] toggles the comfort screen;
  [[F11]] recalibrates the body arm piece.
- Hold both grips and press [[B]] to open the floating Recoil, Weight, Collide, Weapon,
  IK, Move, Melee and VR panel. Settings are kept in `fearvr.ini`.
- To hide the weapon collision wireframe, open **Collide**, disable
  **Show collision box**, then leave that tab.

### Known limitations and source

The D3D9 stereo path and stereo HUD use CPU readback. HMD translation has no world
collision and remains opt-in. The left system button cannot be bound because SteamVR
captures it.

Project and releases: https://github.com/DR-89/fear-vr

## Mod 2 — F.E.A.R. VR GOG build — by thefreemike

### About this mod

A private GOG-only beta with working body holsters, a grenade socket, physical pickups and
weapon swapping with either hand, stable two-handed props, contact-confirmed melee,
two-handed ladder climbing and contextual tutorials.

### Supported game and runtime

- **GOG F.E.A.R. Platinum Collection only.** Do not point it at the Steam edition.
- **SteamVR Beta 2.17.2 or newer** for its 32-bit OpenXR runtime.
- Quest 3 is the author's validation device. Other headsets may work but are untested.
- Multiplayer is not included.

### How you get it

The author distributes the current release candidate through his Discord and asks that it
remain there. The Hub opens the invite and waits for you to choose the ZIP. It never scans
Downloads and accepts a file without confirmation, because the build-stamped filename
changes and an older archive must not overwrite a newer one by accident.

### Installing and updating

The author's installer asks for the game folder; use the folder containing `FEAR.exe`.
After it finishes, the Hub requires `fearvr_bridge.dll` in that exact game root before it
records the mod as installed.

For updates, the old build should be removed first. If the author's uninstaller is found,
the Hub offers to run it. Campaign saves and the player profile are retained.

### Launching and support

Start SteamVR, then use the **thefreemike** launch button in the Hub or
`Launch F.E.A.R. VR - SteamVR.cmd` in the GOG game folder.

For bug reports, include the headset model, connection method, runtime version, GPU and the
exact release-candidate filename in the author's Discord.

>>> Slow time. Check the shadows. Alma is already here.
