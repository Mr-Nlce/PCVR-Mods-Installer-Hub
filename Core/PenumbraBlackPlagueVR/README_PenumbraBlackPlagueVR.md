## About the Game

Penumbra: Black Plague is Frictional Games' first-person survival horror adventure. Penumbra VR Framework adds room-scale VR with tracked controllers to the original PC game.

## What you need

- The original Steam Windows PC game. The current publisher supports Steam only; GOG and other non-Steam builds are unsupported and may be rejected by Setup.
- SteamVR and two tracked controllers.
- A supported Windows installation with enough free space for the publisher's backups. Close the game before setup.

## Install and update

The Hub downloads the latest official PenumbraVR Setup from the [publisher releases](https://github.com/rubocopter/penumbra_vr_framework/releases), including prereleases. Setup selects every detected Penumbra game by default. Review its Overture, Black Plague and Requiem checkboxes before installing; the Hub scans each component separately afterward. Publisher Setup also offers verification, repair and removal. It preserves existing settings and keeps backups of changed original files.

The current v1.0.13 prerelease Setup includes the earlier Black Plague object-interaction, examination and progression fixes, plus Requiem maintenance. Existing installations should use the publisher update/repair route only after the correct Framework components are selected.

If Overture was installed with the older Hub-pinned Framework v0.x, update it from the **Penumbra: Overture VR** game tile before running this Setup. Do not use publisher Repair on that old Overture deployment; its managed file set differs from the current Framework.

[Watch Black Plague VR gameplay](https://www.youtube.com/watch?v=NQWUBmgOjEw) · [Flat2VR modding discussion](https://discord.com/channels/747967102895390741/1540774759619629056)

For Steam, the Hub starts the game through Steam. Other confirmed game locations start through `redist\Penumbra.exe`. If the publisher rejects an unknown game build, use a supported original build; the Hub cannot make a different executable compatible.

## Controls and play

Use your tracked controllers in SteamVR. The publisher currently reports the most complete testing with PlayStation VR2 Sense controllers; other controller profiles are included but need individual confirmation. Use [[Start in VR]] in the Hub after installation.

## Troubleshooting

- If Setup does not recognize the game, point it at the folder containing `redist\Penumbra.exe`.
- If the Hub does not show VR Ready, reopen publisher Setup and verify or repair Black Plague, then scan games again.
- Use **Uninstall now** to open publisher maintenance. Removing Black Plague also removes the Requiem VR component when both are installed, because they share the same game folder and publisher transaction.

## Support rubocopter

[Support the VR Framework on Ko-fi](https://ko-fi.com/onitaku)

## Publisher and support

[Penumbra VR Framework](https://github.com/rubocopter/penumbra_vr_framework) by rubocopter. Check its README and releases for current limitations and support options.

>>> The dark has more to reveal.
