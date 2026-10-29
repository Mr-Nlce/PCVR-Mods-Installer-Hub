## About the Game

Penumbra: Requiem is the puzzle-focused expansion to Penumbra: Black Plague. Penumbra VR Framework supports both through the same publisher Setup and shared game folder.

## What you need

- The original Windows PC Black Plague game and Requiem expansion in the same `redist` folder. Both `Penumbra.exe` and `Requiem.exe` must be present.
- The current publisher supports Steam executable builds only. GOG and other non-Steam builds are unsupported and may be rejected by Setup.
- SteamVR and two tracked controllers. Close both games before setup.

The 1.0.13 level08 corrections have automated host validation only; the publisher has not verified them in a game or headset.

## Install and update

The Hub downloads the latest official [Penumbra VR Framework release](https://github.com/rubocopter/penumbra_vr_framework/releases), including prereleases. Publisher Setup selects all detected Penumbra games by default. Check that Black Plague and Requiem are selected before Install; the Hub scans each component separately afterward. Setup also provides verification, repair and removal. Requiem shares Black Plague's installation root and backup transaction.

The current v1.0.13 prerelease Setup makes assisted throws follow the controller holding the object and separates head-directed examination/ladder selection from hand pointing. Movement, jumping and audio are unchanged in this maintenance update. Keep both components selected when updating Requiem. The publisher still reports an intermittent Requiem startup crash; this release does not claim to fix it.

If Overture was installed with the older Hub-pinned Framework v0.x, update it from the **Penumbra: Overture VR** game tile before running this Setup. Do not use publisher Repair on that old Overture deployment; its managed file set differs from the current Framework.

[Watch Requiem VR gameplay](https://www.youtube.com/watch?v=FB6xXrBn-8E) · [Flat2VR modding discussion](https://discord.com/channels/747967102895390741/1540774759619629056)

For Steam, the Hub starts Requiem through Steam. Other confirmed game locations start through `redist\Requiem.exe`. The publisher validates the executable build before changing it.

## Controls and play

Use the SteamVR tracked controllers. The publisher currently reports the most complete testing with PlayStation VR2 Sense controllers; other profiles are included but need confirmation. Requiem currently has an intermittent startup crash reported by the publisher. If it occurs, close the game and try again; see the publisher release notes for updates.

Use [[Start in VR]] in the Hub. For assisted throwing, aim the controller holding the object and press Examine. The default right-handed Touch binding is below; left-handed or custom bindings may differ.

| Button | Action |
|---|---|
| [[B]] | Examine; while holding an eligible object, assisted throw along its holding controller. |

## Troubleshooting

- If Requiem is absent from Setup, verify that its `Requiem.exe` is beside Black Plague's `Penumbra.exe` inside `redist`.
- If only Black Plague shows VR Ready, reopen publisher Setup and install or repair the Requiem component. A Black Plague install alone does not prove Requiem VR is installed.
- Use **Uninstall now** to open publisher maintenance. Requiem can be removed while retaining Black Plague VR.

## Support rubocopter

[Support the VR Framework on Ko-fi](https://ko-fi.com/onitaku)

## Publisher and support

[Penumbra VR Framework](https://github.com/rubocopter/penumbra_vr_framework) by rubocopter. Check its README and releases for current limitations and support options.

>>> The puzzles continue where Black Plague left you.
