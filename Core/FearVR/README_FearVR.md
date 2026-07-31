# F.E.A.R. VR Installer

## About this mod
**F.E.A.R. VR** by DR-89 is an open-source OpenXR VR mod for the single-player base game of **F.E.A.R. 1.08** (LithTech Jupiter EX, Direct3D 9). It renders the game in true stereo, with the LithTech camera drawing twice per frame from its own per-eye matrix, and adds full motion controls on top. It's confirmed in-game on Quest 3 with both SteamVR and VirtualDesktopXR.

This is an early **open beta**, built with heavy AI assistance. Bug reports and PRs are welcome on GitHub: https://github.com/DR-89/fear-vr

## Highlights
- **Native stereo rendering** - real per-eye rendering, toggleable with F8.
- **Relative headtracking** with recenter, plus optional HMD translation (opt-in).
- **Full motion controls** - move, turn, jump, crouch, sprint, weapon switch, reload, grenade, slow-mo, aim, fire and pause; lean via left-hand tilt.
- **Weapon follows the right hand**, with a red aim laser; activate and pick-up use that same ray.
- **Stereo HUD** in both eyes, plus a world-locked panel for menus, loading screens and the mission briefing.
- **Hand flashlight**, haptics on every shot, and a native VR settings page in the ESC menu.

## What you need first
Two things must already be installed - the mod cannot supply either:

- **F.E.A.R. 1.08 (Ultimate Shooter Edition)** - Steam App 21090, GOG Platinum Collection, or retail.
- **F.E.A.R. Public Tools 1.08** - a free download that ships in your F.E.A.R. folder under extras. The mod copies five proprietary engine modules from it. If it's missing, the Hub installer offers to install it and handles the Monolith registry step for you (with a UAC prompt).

An OpenXR runtime and headset are also required. SteamVR and VirtualDesktopXR are confirmed. Steam must be installed as the store, but under Virtual Desktop, SteamVR itself does not need to run.

## HD Textures - recommended by the mod author
The VR mod's author lists **HD Textures for F.E.A.R. & Extraction Point v2.0.2** by Rivarez as a required companion. Textures sit very close to your face in VR, and F.E.A.R.'s originals were built for 2005 monitors. The pack rebuilds them at four times the resolution and also covers Extraction Point.

https://www.moddb.com/downloads/fear-hd-textures-v202

The Hub installer asks about it before anything else. It is a 5.06 GB download that cannot be fetched automatically, so you grab `HDTextures4FEAR_XP_v2.0.2.rar` in your browser and the installer takes it from your Downloads folder or by drag-and-drop. Before any of that the Hub checks whether 7-Zip is on your machine, since the pack is a `.rar` that Windows cannot open on its own - if it is missing, it offers to fetch and install it silently. That check happens up front rather than after a 5 GB download. From there the Hub unpacks the archive - with a percentage, since that takes a few minutes - and hands you the author's own `FEAR_HDTextures.exe` with the two answers it needs filled in: the folder holding `FEAR.exe`, and whether your copy came from Steam. Afterwards F.E.A.R. is started once so it comes up with the new textures; quit at the main menu.

The pack is unpacked to a temporary folder rather than into the game directory. Users have reported the texture installer stalling with no progress bar when it is run from inside the F.E.A.R. folder.

**The installer asks you to choose:** original game, or original game plus the HD texture mod. You can switch back later - run the installer again and pick **Remove the HD texture mod**.

**The one thing that matters in the texture installer:** it asks whether your copy is from Steam, and the **Steam option sits on the RIGHT and is not preselected**. Click its text so the eye marker moves over to it, and only then click Install. Picking the wrong one patches `FEAR.exe` in a way Steam refuses to launch - the game then fails with `application load error 3:0000065432`, in VR and in flat mode alike.

The pack's own `FEAR_HDTextures.exe` is copied into the mod folder during installation, so removing it later never needs the 5 GB archive again.

**If textures go missing:** open the game's settings, set texture resolution to minimum, then back to maximum. That reloads them. If it happens as a new game starts, set it to minimum before starting, then back to maximum once you are in. This is a known quirk of the pack on the LithTech engine, not of the VR mod.

To remove the textures again, run the same installer and click Uninstall. Rivarez also offers an **HD Textures Lite Pack** patch on the mod's page, which shrinks the textures and improves stability if you run into trouble.

## How the installer works
It downloads the newest release from GitHub (pre-releases included, since the mod ships betas), unpacks it into your user profile, and runs the mod's own installer with explicit paths. Your retail install is never written to - the mod SHA-256 checks FEAR.exe before and after, so a Steam file-integrity check stays clean. If the GitHub download can't be reached, the installer looks in your Downloads folder or lets you drag the ZIP in.

## Launching
Start your OpenXR runtime (SteamVR or Virtual Desktop) and put the headset on, then use **Start in VR** in the Hub or the **F.E.A.R. VR** desktop shortcut. The mod resolves the runtime, starts its host, then launches F.E.A.R. through Steam. If the host ever crashes, the game simply continues flat.

## Controls
- [[Left stick]] move; [[Left grip]] sprint.
- [[Right stick]] turn; up jumps, down crouches; [[Right stick click]] recenters.
- [[A]] weapon switch; [[B]] reload or grenade; [[X]] slow-mo; [[Y]] pause.
- [[Right grip]] use; [[Right trigger]] aim and fire.
- [[Left trigger click]] toggles the hand flashlight.
- Tilt the left hand to lean; mouse, keyboard and gamepad still work.

## Hotkeys
- [[F8]] toggle stereo rendering
- [[F9]] recenter the view
- [[F10]] comfort screen for shakes and cutscenes
- [[F11]] recalibrate the body arm piece

The ESC menu has a VR settings page after Options for stereo rendering, HUD, turn speed, aim guide, vibration and recenter. HMD translation, head bob and the comfort screen live in the config file.

## Known limitations
- The classic D3D9 path needs one CPU readback per frame, as does the stereo HUD - both are proof-of-concept, not a performance path.
- HMD translation has no world collision and stays opt-in.
- Hooks are bound to F.E.A.R. 1.08.282.0; on any other build they stay off and the game runs flat.
- The left system button can't be bound - SteamVR captures it.

## Credits
The archive ships only the author's own MIT-licensed binaries and scripts - no retail files and no proprietary sources.

- **F.E.A.R. VR** by DR-89 (MIT) - https://github.com/DR-89/fear-vr
- F.E.A.R. by Monolith Productions and Sierra.
