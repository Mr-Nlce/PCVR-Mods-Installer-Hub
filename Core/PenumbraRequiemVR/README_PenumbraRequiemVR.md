## About the Game

Penumbra: Requiem is the puzzle-focused expansion to Penumbra: Black Plague. Penumbra VR Framework supports both through the same publisher Setup and shared game folder.

## What you need

- The original Windows PC Black Plague game and Requiem expansion in the same `redist` folder. Both `Penumbra.exe` and `Requiem.exe` must be present.
- The publisher lists the Steam executable builds as verified. GOG and disc paths can be located, but their builds remain unconfirmed by the publisher.
- SteamVR and two tracked controllers. Close both games before setup.

## Install and update

The Hub downloads the latest official [Penumbra VR Framework release](https://github.com/rubocopter/penumbra_vr_framework/releases), including prereleases. Publisher Setup selects all detected Penumbra games by default. Check that Black Plague and Requiem are selected before Install; the Hub scans each component separately afterward. Setup also provides verification, repair and removal. Requiem shares Black Plague's installation root and backup transaction.

If Overture was installed with the older Hub-pinned Framework v0.x, update it from the **Penumbra: Overture VR** game tile before running this Setup. Do not use publisher Repair on that old Overture deployment; its managed file set differs from the current Framework.

[Watch Requiem VR gameplay](https://www.youtube.com/watch?v=FB6xXrBn-8E) · [Flat2VR modding discussion](https://discord.com/channels/747967102895390741/1540774759619629056)

For Steam, the Hub starts Requiem through Steam. Other confirmed game locations start through `redist\Requiem.exe`. The publisher validates the executable build before changing it.

## Controls and play

Use the SteamVR tracked controllers. The publisher currently reports the most complete testing with PlayStation VR2 Sense controllers; other profiles are included but need confirmation. Requiem currently has an intermittent startup crash reported by the publisher. If it occurs, close the game and try again; see the publisher release notes for updates.

## Troubleshooting

- If Requiem is absent from Setup, verify that its `Requiem.exe` is beside Black Plague's `Penumbra.exe` inside `redist`.
- If only Black Plague shows VR Ready, reopen publisher Setup and install or repair the Requiem component. A Black Plague install alone does not prove Requiem VR is installed.
- Use **Uninstall now** to open publisher maintenance. Requiem can be removed while retaining Black Plague VR.

## Publisher and support

[Penumbra VR Framework](https://github.com/rubocopter/penumbra_vr_framework) by rubocopter. Check its README and releases for current limitations and support options.

>>> The puzzles continue where Black Plague left you.
