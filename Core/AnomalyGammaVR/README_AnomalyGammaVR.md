# S.T.A.L.K.E.R. GAMMA VR (Anomaly Gamma)

A motion-controlled VR build of **S.T.A.L.K.E.R. GAMMA** - the large,
curated modpack built on top of S.T.A.L.K.E.R. Anomaly. Unlike Anomaly
VR (which self-updates through a launcher), this ships as a **complete,
self-contained package**: you extract it and play.

**Free** - distributed through the mod's Discord (the **same server** as
Anomaly VR, so your existing membership works).

## What this Hub installer does

1. Opens the mod's Discord (join if you are not a member yet).
2. Opens the download post - grab **`STALKER GAMMA v0.3.x.7z`**.
3. You drag the downloaded `.7z` into the installer window.
4. It extracts the **`Gamma VR`** folder into your Games root
   (default `C:\Games` -> `C:\Games\Gamma VR`).
5. Switches the in-game language to **English** (`localization.ltx`).
6. Drops the game icon and creates a desktop shortcut **`Anomaly Gamma`**.

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
