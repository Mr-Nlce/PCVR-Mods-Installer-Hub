# Halo Master Chief Collection VR

**Halo MCC VR** by **moistman42069** adds true stereo rendering, 6DOF motion
controls and VR-first weapon interaction to most of Halo: The Master Chief
Collection. The Hub downloads the current playable release automatically,
rejects source and diagnostic ZIPs, and validates the runtime files without
depending on changeable release-note filenames. Always launch without
anti-cheat and never use the mod in matchmaking.

## Supported campaigns

The maintained build supports **Halo 2 Classic / Anniversary, Halo 3, Halo 3:
ODST, Halo: Reach and Halo 4**. Halo: Combat Evolved is not supported.

It includes hand and weapon world contact, swing-triggered melee, Reach aiming,
left-handed controls and dual-weapon refinements. Features identified as WIP by
the current release still require headset testing and may behave differently
between campaigns.

## Before the first VR launch

1. Launch MCC flat once and finish the Microsoft account sign-in.
2. Install every supported Halo campaign you intend to play.
3. Set SteamVR as the active OpenXR runtime. Start Steam and SteamVR for the
   Steam edition; for the Xbox-app edition, start SteamVR and sign in to Xbox.
4. Disable Steam Input for MCC. It can otherwise break controller-directed
   weapon aim.
5. In MCC, turn V-Sync and FSR off.

## Start in VR

Use **Start in VR** in the Hub or the **Halo MCC VR** desktop shortcut. Both
start the mod launcher directly and select the anti-cheat-disabled route. The
normal Steam or Xbox-app launch remains flat.

The Xbox-app build can appear frozen for about nine seconds on its first
loading screen; wait for it to continue.

## Controls and useful settings

- [[Right Stick]] — turn
- [[Right Hand]] — aim and control the weapon
- [[L3]] + [[R3]] — recenter VR space and close the menu
- [[F1]] — open or close VR settings without recentering
- [[Left Face Buttons]] together — pause to the flat view; press again for VR
- [[Left Grip]] — support a two-handed weapon when enabled

Enable experimental world contact under **F1 > Body & Hands > World
collision**, then enable **Physical melee** below it if wanted. Adjust picture
resolution under **F1 > Picture** and restart MCC to apply it. First-person
vehicle seats in Halo 3, ODST and Reach need a one-time position adjustment
under **F1 > Vehicles** while sitting in each seat.

## Current limitations

- Halo 2 enemy perception and aiming can malfunction in both render modes.
- World collision and physical melee are experimental and off by default.
- Physical melee currently works only while world collision remains enabled.
- Contact, dual wielding, left-handed play, scopes, vehicles and weapon
  alignment still vary by Halo title.
- A saved resolution change takes effect only after fully restarting MCC.

## Uninstall and safety

The current release requires its new `halomccvr.cfg`; retaining an older config
can leave new settings at unsuitable built-in defaults. During an update, the
Hub therefore saves a timestamped copy of the previous config under
`Halo_MCC_VR_community\.pcvrhub-backups`, then installs the release config. You
can reapply personal preferences through the F1 menu.

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
