# Idols of Ash VR

The **UGVR Injector** by LXE97 - a fork of the Universal Godot VR
Injector - runs Idols of Ash in OpenXR with full motion controls,
including the grappling hook on your real hands. You own the game
(Steam app 4450800 or itch.io); the installer downloads the free mod
from the modder's GitHub and drops it straight into the game folder.
Tested by the modder on Quest with Virtual Desktop, roomscale enabled.

Working game versions: **1.30, 1.31, 1.32**.

## Requirements

- An owned copy of **Idols of Ash** (Steam or itch.io)
- A PC VR headset with a working OpenXR runtime
- Headset AND controllers connected and awake **before** the game
  starts - the injector binds them at launch

## How to play

1. Run the installer (it finds the game on Steam or in the itch app,
   downloads the mod, and places `xr_injector\`, `XRConfigs\` and
   `override.cfg` next to `idols_of_ash.exe`).
2. Put on the headset, wake the controllers.
3. Launch Idols of Ash normally (Steam / itch / the game exe). The
   injector loads by itself - no launcher, no extra step.

## Controls

![Controls](../Assets/IdolsOfAsh_controls.jpg)

- [[Left Stick]] Move (direction follows your head by default)
- [[Right Stick]] Turn
- [[Grip]] Throw the grappling hook (either hand)
- [[Left Stick]] click: Descend rope / [[Right Stick]] click: Ascend rope
- [[A]] Jump / accept in menus
- [[B]] Sprint
- [[X]] Interact
- [[Y]] Menu

**Compass:** hold the right controller palm-up at shoulder height.
Interact ([[X]]) shows/hides it, Sprint ([[B]]) switches it between
checkpoints and embers.

**Height calibration:** hold the right controller over your head and
click the joystick to match the unmodded game's height; press again to
reset.

## Options (XRConfigs folder in the game directory)

- `idols of ash_xr_game_options.cfg` - mod settings
- `idols of ash_xr_game_action_map.cfg` - game keybindings
- `idols of ash_xr_game_control_map.cfg` - misc controller settings

Highlights from `game_options.cfg`:

- `xr_world_scale` (default 0.85) - camera height and world scale
- `movement_direction_device` - joystick reference: 0 = HMD (default),
  1 = primary controller, 2 = secondary controller
- `use_physics_hands` (default true) - hand collision; keeps the rope
  from tangling inside terrain
- `physics_hand_drag` (default 0.06) - slows rope swings on wall
  contact; 0 disables
- `use_palm_healthbar` (default true) - the floating healthbar
- `xr_hand_material_choice` (default 6) - hand model: 0 transparent,
  1 full blue glove, 2 half glove dark, 3 no glove light, 4 no glove
  dark, 5 full yellow glove, 6 half glove light
- `terrain_collision_fade` (default true) - fade-to-black when the
  camera clips a wall
- `ignore_sprint` (default true) - joystick spans walk-to-sprint, no
  sprint button needed
- `player_light_multiplier` (default 0.8) - hook/player light strength
- `enable_hook_haptics` / `enable_hand_haptics` (default false) -
  vibration on hook attach / wall contact

## Other mods (override.cfg)

The mod ships its own `override.cfg`. If you already had one from
another mod, the installer saves it as `override.cfg.pre-ugvr.backup` -
merge the autoload lines by hand, e.g.:

```
[autoload_prepend]
XRInjector="*res://xr_injector/xr_injector.gd"
ModLoader="*res://addons/mod_loader/mod_loader.gd"
ModLoaderStore="*res://addons/mod_loader/mod_loader_store.gd"
```

## Disable / uninstall

- Disable the headset mode: comment the injector line in
  `override.cfg`: `;XRInjector="*res://xr_injector/xr_injector.gd"`
- Uninstall: delete the `xr_injector\` folder (and `XRConfigs\` if you
  want the settings gone too)
