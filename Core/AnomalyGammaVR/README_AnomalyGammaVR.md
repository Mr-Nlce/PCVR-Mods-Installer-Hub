# S.T.A.L.K.E.R. GAMMA VR (Anomaly Gamma)

A motion-controlled VR build of **S.T.A.L.K.E.R. GAMMA** - the large,
curated modpack built on top of S.T.A.L.K.E.R. Anomaly. Unlike Anomaly
VR (which self-updates through a launcher), this ships as a **complete,
self-contained package**: you extract it and play.

**Free** - distributed through the mod's Discord (the **same server** as
Anomaly VR, so your existing membership works).

## What this Hub installer does

1. Looks at the folder you point it at. If GAMMA VR is already there, the
   **update** is offered first and named; if not, the **complete build** is.
   Either way it names the exact file and opens the matching post.
2. Opens the mod's Discord (join if you are not a member yet).
3. You drag the downloaded `.7z` into the installer window.
4. Fresh install: it extracts the **`Gamma VR`** folder into your Games
   root (default `C:\Games` -> `C:\Games\Gamma VR`).
   Update: it unpacks over your existing install, replacing files, and
   then clears the shader cache for you (see below).
5. Switches the in-game language to **English** (`localization.ltx`).
6. Drops the game icon and creates a desktop shortcut **`Anomaly Gamma`**.

## Which of the two archives do I need?

Both files are offered together in the same download folder, so the only
thing that can go wrong is grabbing the wrong one.

| your situation | the file to download |
|---|---|
| nothing installed yet | `STALKER GAMMA VR v0.3.2.7z` (the complete build, ~110 GB) |
| v0.3.1 already installed | `UPDATE FROM v0.3.1 TO v0.3.2c.7z` (small, goes on top) |

The installer picks the right row for you from what it finds on disk, and if
you drop the other archive by mistake it says so before unpacking anything.

After the update the **shader cache must go** - v0.3.2 changes the weapon
shaders and the engine would otherwise keep serving the compiled old ones.
The installer deletes the `shaders_cache` folder inside `appdata` for you;
if it reports that it could not find or remove it, delete it by hand before
playing.

The Hub's **Start in VR** button and the desktop shortcut are your two
launch routes - both start the game the same way.

## Requirements

- **Strong PC** - GAMMA is heavier than base Anomaly; in VR more so.
- **7-Zip** installed, so the installer can unpack the `.7z`
  (a manual-extract fallback is offered if it is missing).
- **Runtime**: Oculus OpenXR, SteamVR or VDXR.
- **Discord account** to reach the download.
- Plenty of free disk space, and a simple path on a spare drive -
  avoid `C:\Program Files`, the desktop, or paths with odd characters.

## Language

The pack starts in **Russian**. The installer sets it to English by
changing `language = rus` to `language = eng` in:

`...\Gamma VR\overwrite\gamedata\configs\localization.ltx`

If the game still shows Russian, set it **in-game**: open the **4th item**
in the main menu, then the **second-to-last item** in that list - the
language option is at the **top-right**. (You can navigate by position
without reading Russian.) Alternatively, set `language = eng` in the
`.ltx` by hand.

## Motion controls

GAMMA VR is fully motion-controlled - two-handed weapon handling, a
physical inventory, and gesture actions. The exact bindings live in the
in-game **VR controls / bindings** menu; common defaults:

- [[Trigger]] - fire / interact
- [[Grip]] - grab weapon foregrip, ladders, items
- [[Stick]] - move / smooth or snap turn
- [[A]] / [[X]] - jump / crouch
- [[B]] / [[Y]] - reload / holster
- Reach over your shoulder or to your belt for the **physical inventory**

Check the in-game bindings screen for the full, current layout - GAMMA's
controls are richer than base Anomaly's.

## Updating

This is a **pinned package**, not a launcher build. To update, grab the
newer `STALKER GAMMA` archive from the Discord and re-run this installer
(it re-extracts into the same folder).

## Credits

- **GAMMA VR build**: GAMMA VR Team (distributed via Discord)
- **GAMMA modpack** and **S.T.A.L.K.E.R. Anomaly** teams
