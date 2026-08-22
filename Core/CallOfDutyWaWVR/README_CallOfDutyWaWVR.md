# Call of Duty: World at War VR

Call of Duty: World at War is Treyarch's 2008 shooter set in the Pacific and on
the Eastern Front - and the game that started **Nazi Zombies**, the co-op survival
mode where four players hold a bunker against endless waves.

**World War VR** by **RyanCraighead** adds stereo OpenXR rendering, 6DOF head
tracking and motion controllers: your right hand aims the weapon you can see,
grenades are cooked in your fist and thrown, and a fast outward swing is a melee.
Menus float on a panel you point at.

## Zombies is the mode that works

| Mode | Status |
|---|---|
| **Zombies** | The author's primary supported mode - play this |
| Local / offline multiplayer | Experimental; some maps and modes are broken |
| Campaign | Experimental; progression can stall around the second mission |
| Online multiplayer | Not supported or tested |

## It does not touch your game

World War VR installs as **its own program** under
`%LOCALAPPDATA%\Programs\World War VR\`, with its own Start Menu entry and its own
uninstaller. Your Call of Duty folder is only *read* - nothing is written there,
and there is nothing to undo later.

**Always start through the launcher**, never the game executable. *Start in VR* in
the Hub opens it. It needs **Run as administrator** every time.

In the launcher: pick the launch target, pick a quality preset, then *Launch in
VR*. It remembers your choices, so this is a one-time setup. If it does not find
the game by itself, *Browse* to the folder holding `CoDWaW.exe`.

## Headsets and connection

| Route | Status |
|---|---|
| Quest 2 / 3 via **Virtual Desktop** | Working - the author's recommendation |
| Quest 2 via **Air Link** | Working, but needs the **SteamVR Beta** branch in Steam and the SteamVR compatibility option switched on in the launcher |
| Rift S via Meta Horizon Link | Working |
| Rift S via SteamVR | Working |
| Quest 2 via **Steam Link** | **Not working** |

Other OpenXR headsets may work but are unverified. If one fails, name the
connection method and the active OpenXR runtime in the bug report.

## Controls

| Input | Action |
|---|---|
| Right controller | aims the visible weapon |
| [[Right Trigger]] | fire |
| [[Left Trigger]] | reload |
| [[Right Grip]] hold | cook a frag grenade, release to throw |
| [[Left Grip]] hold | cook the tactical grenade, release to throw |
| [[Left Stick]] | move relative to where you are looking |
| [[Left Stick Click]] | sprint |
| [[Right Stick]] left/right | snap turn |
| [[A]] | jump / confirm |
| [[B]] | crouch / back |
| [[X]] | use, interact |
| [[Y]] | next weapon |
| [[Right Stick Click]] | melee - or swing the right controller outward |
| [[Left Menu]] short | pause menu |
| [[Left Menu]] hold 1s | recentre position and facing |

**There is no crosshair on purpose** - aim along the barrel of the weapon in your
hands.

Menus, cinematics and loading screens appear on a flat panel: point the right
controller at it and pull [[Right Trigger]] to click. Keyboard and mouse still
work on the desktop as a fallback.

### Campaign prompts

Some campaign moments need the game's original numbered choices. Rest your right
thumb on the thumbrest and push the left stick once - left is **6** (the rocket
designator in *Little Resistance*), up is **5**, down is **N**, right is **7**.
Movement pauses while you hold this. It is disabled in multiplayer.

## Optional bots for local multiplayer

The launcher can install and configure nine **PeZBOT** players for offline
matches. The bot package is not included and is fetched by you, once:

1. Download **PeZBOT 005p for World at War**
2. Leave `PeZBOTWAW_005p.zip` **unextracted** in your Downloads folder
3. In the launcher, choose Multiplayer and enable **Automatic Bots**
4. *Launch in VR*, then create a local game with **Dedicated: No**

Do not extract the archive or copy bot files into the game yourself - the launcher
verifies and imports it, and after that keeps its own copy.

## Credits

Mod by **RyanCraighead** - https://github.com/RyanCraighead/WorldWarVR-Releases

An independent fan-made modification, not affiliated with or endorsed by
Activision. It contains no Call of Duty executables or game assets - you supply a
lawfully obtained copy of the game.

>>> The war is loud in here. Duck anyway.
