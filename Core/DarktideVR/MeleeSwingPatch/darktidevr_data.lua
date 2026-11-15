local mod = get_mod("darktidevr")

-- Optional add-on (darktidevr_melee_swing.lua): its menu section appears only
-- when the file is present.
local function melee_swing_addon_present()
    local io_api = rawget(_G, "Mods") and Mods.lua and Mods.lua.io
    local file = io_api and io_api.open("./../mods/darktidevr/scripts/mods/darktidevr/darktidevr_melee_swing.lua", "r")
    if file then file:close() end
    return file ~= nil
end

-- The options menu, grouped by what the player is trying to change rather
-- than by when each setting was added (user, 18 September: "the mod options
-- are getting pretty extensive... can we reorganise the segments either
-- way?"). Every top-level entry is a section, so the first screen is eight
-- lines instead of forty-three, and a setting that only matters when another
-- is on is nested under it: the wrist display's scale under the display, the
-- grip mode and the virtual stock under two-handed support, the haptic
-- strength under the haptics mode (where the dropdown's own `show_widgets`
-- hides it when haptics are off).
--
-- Nesting HIDES a child while its parent is off, so nothing may be nested
-- under a setting it can work without: the body mirror's key is a sibling of
-- Full body, not its child, because F8 toggles the mirror either way.
--
-- NOTHING here renames a setting_id: those are the saved keys, so every
-- setting keeps the value the player already chose, wherever it now appears.
return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = false,
    options = {
        widgets = {
            {
                setting_id = "aiming_options",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "vr_crosshair_scale", type = "numeric",
                        default_value = 70, range = {25, 150}, decimals_number = 0, step_size_value = 5,
                    },
                    {
                        setting_id = "vr_aim_stabilization", type = "numeric",
                        default_value = 75, range = {0, 100}, decimals_number = 0, step_size_value = 5,
                    },
                    {
                        setting_id = "vr_sway_cancel", type = "numeric",
                        default_value = 0, range = {0, 100}, decimals_number = 0, step_size_value = 10,
                    },
                    {
                        setting_id = "ads_focus",
                        type = "checkbox",
                        default_value = true,
                        sub_widgets = {
                            {
                                -- User, 18 September: "add a small zoom to ADS
                                -- - maybe 10-15%". Per cent of magnification
                                -- while the sights are up. Worn the same day
                                -- it was judged by eye at 12 and then at 3,
                                -- and the answer was "set the default zoom to
                                -- 5%" -- so 5, which is what a fresh install
                                -- gets. An install that has already saved a
                                -- value keeps it: DMF stores the chosen
                                -- number, and a default only ever applies to
                                -- a setting that has never been set.
                                -- Back on at 5 now that the magnification
                                -- reaches the viewer (19 September). It was
                                -- briefly 0 because the zoom narrows the
                                -- frustum the game's cameras render with and
                                -- the viewer -- which did not learn of it --
                                -- kept submitting the UNZOOMED projection to
                                -- the runtime. Each
                                -- eye's frustum is asymmetric in the opposite
                                -- direction, so magnifying each eye's image
                                -- about its own optical axis pushes the two
                                -- eyes' content apart: divergence is
                                -- 2 * 0.1224 * (m - 1) radians, which is 0.4
                                -- degrees at 3 per cent and 1.9 at fifteen.
                                -- Worn: "better but still present" at 1, and
                                -- at 15 "so diverged I couldn't visually
                                -- converge the reticules". Human fusion gives
                                -- out around a degree.
                                --
                                -- `dtvr_set_gameplay_zoom` carries it across
                                -- now and the viewer builds its submitted
                                -- frustum from the same zoomed one, so the
                                -- two projections agree by construction. With
                                -- no transport the Lua refuses to zoom at
                                -- all rather than diverge.
                                setting_id = "vr_ads_zoom",
                                type = "numeric",
                                default_value = 5,
                                range = {0, 30},
                                decimals_number = 0,
                                step_size_value = 1,
                            },
                        },
                    },
                    {
                        setting_id = "vr_sight_ads",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "vr_gun_pitch",
                        type = "numeric",
                        default_value = -10,
                        range = {-45, 45},
                        decimals_number = 0,
                        step_size_value = 1,
                    },
                    {
                        setting_id = "vr_two_hand_support",
                        type = "checkbox",
                        default_value = false,
                        sub_widgets = {
                            {
                                setting_id = "vr_two_hand_grip_mode",
                                type = "dropdown",
                                default_value = "hold",
                                options = {
                                    {text = "vr_two_hand_grip_hold", value = "hold"},
                                    {text = "vr_two_hand_grip_toggle", value = "toggle"},
                                },
                            },
                            {
                                setting_id = "vr_virtual_stock",
                                type = "checkbox",
                                default_value = false,
                            },
                        },
                    },
                    {
                        setting_id = "vr_ammo_readout",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        -- One display for a melee weapon's special charges
                        -- (user, 16 September: the count and the bars showed
                        -- the same thing in two places).
                        --
                        -- A sibling of the ammo readout, though only one of
                        -- its three values needs it. The COUNT draws inside
                        -- the readout's gate; the BARS are a different module
                        -- with a gate of its own that never mentions the
                        -- readout (darktidevr_weapon_charge_display.lua:120),
                        -- so nesting hid the only row that can turn the bars
                        -- off from anyone who had turned the readout off
                        -- (review, 18 September). The mod's own tooltip says
                        -- as much: "The count also needs Ammo count at the
                        -- hand on."
                        setting_id = "vr_weapon_charge_style",
                        type = "dropdown",
                        default_value = "count",
                        options = {
                            {text = "vr_weapon_charge_style_count", value = "count"},
                            {text = "vr_weapon_charge_style_bars", value = "bars"},
                            {text = "vr_weapon_charge_style_off", value = "off"},
                        },
                    },
                },
            },
            {
                setting_id = "body_options",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "vr_full_body_experimental",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        -- On by default: the new behaviour is turning the
                        -- swings OFF, so that is what has to be chosen.
                        setting_id = "vr_melee_animations",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        -- A sibling, not a child of Full body. DMF HIDES a
                        -- checkbox's children while it is off, and the mirror
                        -- this key toggles works whether Full body is on or
                        -- not -- so nesting it left a working F8 with no row
                        -- anywhere that names or rebinds it, which is where
                        -- the guide sends you (review, 18 September).
                        setting_id = "body_mirror_keybind",
                        type = "keybind",
                        default_value = {"f8"},
                        keybind_trigger = "pressed",
                        keybind_type = "function_call",
                        keybind_global = true,
                        function_name = "toggle_body_mirror",
                    },
                    {
                        setting_id = "vr_forearm_holsters",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        -- A sibling, though it reads like a child: the counts
                        -- label a BODY holster's zone and are suppressed on a
                        -- forearm one (darktidevr_holster_counts.lua:117), so
                        -- they do their work precisely when forearm holsters
                        -- are off. Nesting would hide the option exactly when
                        -- it applies.
                        setting_id = "vr_holster_counts",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "vr_item_radial",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "vr_wrist_display",
                        type = "checkbox",
                        default_value = false,
                        sub_widgets = {
                            {
                                setting_id = "vr_wrist_display_scale", type = "numeric",
                                default_value = 100, range = {50, 200}, decimals_number = 0, step_size_value = 5,
                            },
                        },
                    },
                    {
                        setting_id = "vr_haptics_mode",
                        type = "dropdown",
                        default_value = "off",
                        options = {
                            {text = "vr_haptics_off", value = "off", show_widgets = {}},
                            {text = "vr_haptics_informative", value = "informative", show_widgets = {1}},
                            {text = "vr_haptics_immersive", value = "immersive", show_widgets = {1}},
                        },
                        sub_widgets = {
                            {
                                setting_id = "vr_haptics_strength", type = "numeric",
                                default_value = 100, range = {25, 200}, decimals_number = 0, step_size_value = 5,
                            },
                        },
                    },
                },
            },
            {
                setting_id = "world_options",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "marker_plane",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "vr_teammate_status",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "vr_skull_throw",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "vr_comms_gesture",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "melee_preview_toggle",
                        type = "button",
                        button_text = "melee_preview_toggle_button",
                        button_trigger = "pressed",
                        function_name = "toggle_melee_preview",
                    },
                    {
                        -- A sibling, not a child: DMF unfolds sub_widgets only
                        -- under a header, group, checkbox or dropdown, so a
                        -- keybind nested under this button would never appear
                        -- (options.lua: allowed_parent_widget_types).
                        setting_id = "melee_preview_keybind",
                        type = "keybind",
                        default_value = {"f6"},
                        keybind_trigger = "pressed",
                        keybind_type = "function_call",
                        keybind_global = true,
                        function_name = "toggle_melee_preview",
                    },
                    {
                        setting_id = "scanner_test_keybind",
                        type = "keybind",
                        default_value = {"f7"},
                        keybind_trigger = "pressed",
                        keybind_type = "function_call",
                        keybind_global = true,
                        function_name = "toggle_scanner_test",
                    },
                },
            },
            {
                setting_id = "hud_options",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "hud_visible",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "hud_editor",
                        type = "button",
                        button_text = "hud_editor_button",
                        button_trigger = "pressed",
                        function_name = "toggle_vr_hud_editor",
                    },
                    {
                        setting_id = "hud_size",
                        type = "numeric",
                        default_value = 100,
                        range = {50, 150},
                        decimals_number = 0,
                        step_size_value = 5,
                    },
                    {
                        setting_id = "hud_distance",
                        type = "numeric",
                        default_value = 2,
                        range = {0.75, 4},
                        decimals_number = 2,
                        step_size_value = 0.25,
                    },
                    {
                        setting_id = "hud_internal_scale",
                        type = "numeric",
                        default_value = 100,
                        range = {50, 150},
                        decimals_number = 0,
                        step_size_value = 5,
                    },
                    {
                        setting_id = "focus_warning",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            {
                setting_id = "movement_options",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "movement_reference",
                        type = "dropdown",
                        default_value = "head",
                        options = {
                            {
                                text = "movement_reference_head",
                                value = "head",
                            },
                            {
                                -- The value is kept as it was so saved settings
                                -- survive; the label and the code behind it name the
                                -- off hand (docs/phase1/handedness-audit-2026-09-16.md).
                                text = "movement_reference_left_hand",
                                value = "left_hand",
                            },
                        },
                    },
                    mod:io_dofile("darktidevr/scripts/mods/darktidevr/darktidevr_turning").widgets(),
                },
            },
            {
                setting_id = "mode_options",
                type = "group",
                sub_widgets = {
                    {
                        setting_id = "hub_third_person",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        setting_id = "spectate_third_person",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "stereo_cinematics",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "remote_mission_input",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        setting_id = "psykhanium_online_rules",
                        type = "checkbox",
                        default_value = true,
                    },
                },
            },
            -- What is left here is genuinely unfinished rather than merely
            -- new: everything that had found its place moved to a section
            -- above, with its setting id unchanged.
            {
                setting_id = "experimental_options",
                type = "group",
                sub_widgets = {
                    mod:io_dofile("darktidevr/scripts/mods/darktidevr/darktidevr_keyboard_mouse").widgets(),
                },
            },
            mod:io_dofile("darktidevr/scripts/mods/darktidevr/darktidevr_controller_bindings").widgets(mod),
            melee_swing_addon_present() and
                mod:io_dofile("darktidevr/scripts/mods/darktidevr/darktidevr_melee_swing").widgets() or nil,
        },
    },
}
