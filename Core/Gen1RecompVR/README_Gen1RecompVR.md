# Pokemon Dramatic Shape VR

This Hub setup installs the official standalone Windows build of
**Dramatic Shape VR** by prismaticShape. It is one OpenXR application with a
shared launcher for first-generation Pokemon, Pokemon Crystal and Pokemon
Pinball. It supports VR and mixed-reality play with motion controls.

## About the Game

Dramatic Shape turns classic handheld Pokemon adventures into interactive 3D
dioramas and first-person worlds. You can lean over the map, walk through it at
room scale, use a physical Pokedex and party or bag racks, throw Poke Balls,
fish with a physical rod, speak battle commands and move between full-VR and
mixed-reality views. Pokemon Pinball runs on a physical VR table.

## What is supported

| Launcher card | ROM you provide |
|---|---|
| Red | Canonical US Pokemon Red `.gb` ROM |
| Blue | Canonical US Pokemon Blue `.gb` ROM |
| Yellow | Canonical US Pokemon Yellow `.gb` ROM |
| Crystal | US Pokemon Crystal `.gbc` ROM, revision 1.0 or 1.1 |
| Pokemon Pinball | Pokemon Pinball (U) `.gbc` ROM |

**Gen 2 currently means Crystal only. Gold and Silver are present in parts of
the underlying code but are deliberately hidden by the publisher and are not
supported launcher choices.** Stadium, Stadium 2 and Cobblemon imports are
additional optional features; they are not substitutes for the supported
cartridge imports above.

No Nintendo ROM or commercial game data is included, downloaded or copied by
the Hub. The publisher archive was inspected and contains no ROM.

## Installation and updates

The installer's first choice selects one of two independent routes. Press
[[Enter]] on option 1 for the recommended current application, or choose
option 2 to install the classic legacy route again:

1. **Dramatic Shape VR 3.x** — the current standalone OpenXR application and
   default choice.
2. **Legacy Gen1Recomp VR** — pinned Gen1Recomp v0.2.56 plus either the full
   Dramatic Shape v1.8.5 profile or the leaner Dramaless Shape v1.6.4 profile.

The legacy versions are deliberately pinned because both manifests support
Gen1Recomp below 2.0.0, while later profile releases removed or materially
changed the old VR path. Both source repositories and all three exact release
assets were live-checked on 23 September 2026. The installer validates the
functional files and OpenXR loader after extraction; historical size and hash
records never block a future download.

The default install folder is `C:\Games\Pokemon Dramatic Shape VR`; the
installer lets you choose another complete folder. Keep the application out of
`Program Files`, because its built-in updater needs a writable folder.

The Hub downloads the newest stable Windows ZIP from the official GitHub
releases and checks the functional runtime after extraction. The installed
application also has its own **UPDATES** control in the launcher. Its updater
stages the complete official Windows package, restarts the executable and
writes the installed version into `VERSION`; the Hub reads that same proof so
an in-app update does not leave a stale Update badge.

The official PC launcher can crash on the ROM-selection screen when a VR
controller sends touch input. The Hub installer guards all three touch events
in the local executable automatically before installation. If a future
publisher build already handles them, the installer leaves it unchanged.
ROMs, settings and saves are not changed.

The legacy installer defaults to `C:\Games\Pokemon Gen 1 VR` but accepts a
different complete folder and remembers it separately. Its selected profile
lives under `%APPDATA%\pokemon-love2d\mods`; a conflicting profile is moved
without deletion to the adjacent `mods-disabled` folder. Scan installed games
recognizes an existing or newly installed legacy route only when
`gen1recomp.exe`, `.pcvrhub_voxelmod` and the selected profile's OpenXR files
are present; the game page then offers **Start Legacy Gen 1**.
A flat Gen1Recomp folder without that VR marker is deliberately
not reported as VR Ready.

The new v3 application is independent and remains the recommended installer.
Installing or removing it does not delete or modify the older application or
`%APPDATA%\pokemon-love2d`. Its old saves can be migrated manually; they are
not silently mixed with the new profile.

## First start

1. Make the OpenXR runtime you want to use active.
2. Choose **Start in VR** on this game page.
3. Import one of the supported ROMs you legally own from the launcher.
4. Let the first world bake finish. Later bakes are incremental and only
   rebuild maps whose source data changed.

The launcher stores imported ROM-derived data, settings, screenshots and saves
under `%APPDATA%\DramaticShapeVR`. The original ROM remains yours and is not
placed in the Hub folder.

Crystal is new in the v3 series. v3.0.1 substantially improves Gen 1 and Gen 2
cave interiors, fixes an Options-menu regression and improves HGSS sprite
imports. Large outdoor areas are heavier than Gen 1 and may miss a 90 Hz target
on some hardware. Reduce **CULL RADIUS** if necessary.

## VR modes

Press [[Left Stick Click]] to cycle through **Diorama**, **Diorama + 2D**,
**Diorama MR**, **Diorama MR + 2D**, **First Person** and **MR Portal**. The
right-hand beam can operate launcher, menu and confirmation panels.

## Core controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move through the world |
| [[A]] | Confirm or use the Game Boy A button |
| [[B]] | Go back or use the Game Boy B button |
| [[X]] | Open the Start menu; Controls is its first row |
| [[Y]] | Cycle hands, Pokedex and hidden state in diorama; draw or stow the Pokedex in first person |
| [[Left Stick Click]] | Cycle VR and MR modes |
| [[Right Trigger]] + [[Right-Hand Beam]] | Point at and choose a menu row, move or Yes/No answer |
| [[Trigger]] | Curl an index finger, operate the camera shutter or recall a held ball |
| [[Grip]] | Curl and grab with that hand |
| [[Headset Movement]] | Look around; in first person, physical room-scale walking moves through the map |

## Diorama controls

| Button | Action |
|---|---|
| [[Grip]] | Carry the model; in +2D modes the left hand carries the 2D screen and the right carries the model |
| [[Left Grip]] + [[Right Grip]] | Turn and resize the model |
| [[Right Stick Up]] / [[Right Stick Down]] | Zoom the model |
| [[Right Stick Left]] / [[Right Stick Right]] | Open or close the viewport |
| [[Right Stick Click]] | Step the V-Curve setting |
| [[B]] + [[Trigger]] | Pinch a sprite from the table and throw it |
| [[Y]] + [[Left Trigger]] | Pinch a sprite with the left hand |

## First-person controls

| Button | Action |
|---|---|
| [[Left Stick]] | Walk |
| [[Right Stick Left]] / [[Right Stick Right]] | Snap-turn 45 degrees, or smooth-turn when enabled |
| [[Left Grip]] | Show the party rack; grab and throw a party ball or an HM disc |
| [[Right Grip]] | Show the bag rack; grab and throw a ball, rock or bait when available |
| [[Grip]] | Stow the visible rack; the other grip swaps racks |
| [[Y]] | Draw the physical Pokedex |
| [[Fingertip]] | Tap Pokedex apps and controls |

## Pokemon Pinball controls

| Button | Action |
|---|---|
| [[Left Stick]] | Game Boy D-pad |
| [[A]] / [[B]] | Game Boy A and B buttons |
| [[X]] | Start |
| [[Left Trigger]] / [[Right Trigger]] | Operate the pinball paddles |
| [[Right Grip]] + [[Right Trigger]] | Grab, pull and release the plunger |
| [[Y]] + [[Left Hand]] | Adjust the physical table |
| [[Y]] + [[Right Stick]] | Adjust table orientation |
| [[Left Stick Click]] | Switch between the room and void view |

## Voice, fishing and physical tools

Voice control is enabled by default under **Battles > Voice**. At the battle
menu, commands include phrases such as “use Thundershock”, “fight” and “run
away”. The included offline voice runtime stays inside the application folder.

| Button | Action |
|---|---|
| [[Trigger]] or [[A]] | Hold and release to cast a fishing rod |
| [[Controller Movement]] | Pull back or lift the rod tip to set the hook |
| [[A]] | Reel in; release to ease line tension |
| [[B]] | Stow the rod |
| [[Y]] | Show the fishing controls popup |

## Storage and removal

**Uninstall now** removes files owned by the Hub installer and restores files
that existed before installation. If the publisher's in-app updater changed an
owned runtime file, the safety manifest preserves it rather than deleting an
unexpectedly changed file and reports that fact. You may then remove the
dedicated application folder after checking it contains no files you added.

The uninstaller deliberately preserves `%APPDATA%\DramaticShapeVR`, including
saves, imported data, settings and screenshots. Remove that profile manually
only if you also want to erase your progress and local imports. Old
`%APPDATA%\pokemon-love2d` profiles are unrelated and remain untouched.

## Official sources

- Project and documentation: https://github.com/prismaticShape/DramaticShapeVR
- Releases: https://github.com/prismaticShape/DramaticShapeVR/releases

The Windows archive carries the Khronos OpenXR loader and its license, the
LÖVE runtime libraries, and the publisher's offline voice components and
licenses. Keep the complete extracted package together.
