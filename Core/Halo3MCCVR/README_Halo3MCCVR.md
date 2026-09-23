# Halo Master Chief Collection VR

**Halo MCC VR** by **moistman42069** adds true stereo rendering, 6DOF motion
controls and VR-first weapon interaction to all of Halo: The Master Chief
Collection. The Hub downloads the current playable release automatically,
rejects source and diagnostic ZIPs, and validates the runtime files without
depending on changeable release-note filenames. Always launch without
anti-cheat and never use the mod in matchmaking.

## Supported campaigns

The maintained build supports every MCC campaign: **Halo: Combat Evolved
Anniversary** in Original and Anniversary graphics, **Halo 2: Anniversary** in
Classic and Anniversary graphics, **Halo 3**, **Halo 3: ODST**, **Halo: Reach**
and **Halo 4**.

It includes hand and weapon world contact, swing-triggered melee, Reach aiming,
left-handed controls and dual-weapon refinements. Features identified as WIP by
the current release still require headset testing and may behave differently
between campaigns.

The current **0.5.1 alpha** adds experimental Combat Evolved multiplayer tracking
and grenade aiming while retaining the 0.5.0 all-campaign feature set. It expands vehicle cameras across the supported titles,
adds zoom, manual reload and dual-wield improvements, and corrects roomscale and
hand/body placement. These remain experimental cross-campaign systems rather
than a promise that every weapon, vehicle and mission has been validated.

## Before the first VR launch

1. Launch MCC flat once and finish the Microsoft account sign-in.
2. Install every Halo campaign you intend to play.
3. Set SteamVR as the active OpenXR runtime. Start Steam and SteamVR for the
   Steam edition; for the Xbox-app edition, start SteamVR and sign in to Xbox.
4. Disable Steam Input for MCC. It can otherwise break controller-directed
   weapon aim.
5. For each campaign, set FOV to 120 degrees, V-Sync and FSR off, and maximum
   frame rate to 120.

## Start in VR

Use **Start in VR** in the Hub or the **Halo MCC VR** desktop shortcut. Both
start the mod launcher directly and select the anti-cheat-disabled route. The
normal Steam or Xbox-app launch remains flat.

The Xbox-app build can appear frozen for about nine seconds on its first
loading screen; wait for it to continue.

## Controls and useful settings

| Button | Action |
|---|---|
| [[Right Stick]] | Turn |
| [[Right Hand]] | Aim and control the weapon |
| [[L3]] + [[R3]] | Open or close the VR menu |
| [[F1]] | Open or close VR settings without recentering |
| [[F3]] | Recenter VR space after entering gameplay |
| [[A]] | Select the pointed item in the VR menu |
| [[Left Hand at Head]] + [[Left Stick]] | Use D-pad directions |
| [[Left Hand at Head]] + [[Left Stick Click]] | Switch Original / Anniversary graphics during gameplay |
| [[Left Grip]] | Support a two-handed weapon when enabled |

Enable experimental world contact under **F1 > Body & Hands > World
collision**, then enable **Physical melee** below it if wanted. Adjust picture
resolution under **F1 > Picture** and restart MCC to apply it. First-person
vehicle seats can need a one-time position adjustment under **F1 > Vehicles**
while sitting in each seat.

## Current limitations

- Switching campaigns can occasionally crash MCC or leave the next title flat.
  Fully close MCC, restart through the VR launcher and load that campaign again.
- Wait at least seven seconds after entering a title or level before using
  Force Inject / Recover VR.
- Do not switch Halo CE Original / Anniversary graphics during a cinematic.
- Halo 2 Cairo / Outskirts, vehicle-checkpoint and co-op reports remain open.
- World collision and physical melee are experimental and off by default.
- Physical melee currently works only while world collision remains enabled.
- Contact, dual wielding, left-handed play, scopes, vehicles and weapon
  alignment still vary by Halo title.
- A saved resolution change takes effect only after fully restarting MCC.

## Uninstall and safety

Fresh installations receive the publisher's `halomccvr.cfg`. Updates preserve
the existing file exactly, as required by the publisher, so tuned resolution,
comfort, alignment and vehicle settings remain in place.

Use **Uninstall Now** on the detail page. It removes only unchanged files
recorded in the Hub ownership manifest. Personal settings, logs, changed files,
config backups, MCC, installed campaigns and saves remain untouched. Never
delete the MCC game folder.

The mod files are unsigned. Allow an individual DLL or launcher only when you
trust its source rather than disabling antivirus protection globally.

## Credits and mod pages

- Maintained MCCVR build: **moistman42069**
- [MCCVR project and issue tracker](https://github.com/moistman42069/MCCVR-Halo-Build)
- [MCCVR releases](https://github.com/moistman42069/MCCVR-Halo-Build/releases)
