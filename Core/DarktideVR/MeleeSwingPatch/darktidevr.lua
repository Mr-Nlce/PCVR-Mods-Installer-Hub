local mod = get_mod("darktidevr")

local ScriptCamera = require("scripts/foundation/utilities/script_camera")
local ScriptViewport = require("scripts/foundation/utilities/script_viewport")
local ScriptWorld = require("scripts/foundation/utilities/script_world")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")

local primary_viewport_name = "player1"
local right_viewport_name = "darktidevr_right_eye"
local half_ipd = 0.032
local stereo_vertical_tangent_scale = 2
local ui_eye_separation = half_ipd * 2

-- Arm the gameplay-world path as well as the separately managed character-
-- select UI world. CameraManager supplies the level world's player1 camera.
local requested = true
local active = false
local failed = false
local active_manager = nil
local active_world = nil
local active_base_rotation = nil
-- Physical head tracking and explicit stick yaw own orientation. Keep stock
-- animation/mouse-camera rotation out of the scene anchor; stick turning edits
-- that anchor directly and never enables the legacy game-yaw feedback path.
local game_rotation_mode = "fixed"
-- World markers are authored as one screen-GUI pass from the cached player
-- camera. Reproject and enqueue them between the sequential eye submissions so
-- the right eye receives depth-correct marker coordinates.
local stereo_world_markers_requested = true
local world_markers_context = nil
local interaction_hud_context = nil
local world_marker_reprojecting = false
local observed_ui_viewports = {}
local ui_stereo_spawner = nil
local ui_stereo_world = nil
local ui_stereo_right_viewport = nil
local ui_stereo_right_name = "darktidevr_main_menu_right_eye"
local ui_offscreen_requested = false -- accepted engine intermediate path
local ui_offscreen_primary_requested = true -- give each eye its own output slot
-- Native/DLAA aliases output_target to back_buffer. Override only back_buffer
-- for this control so the engine preserves that alias instead of layering a
-- distinct full-size output_target over the surface under inspection.
local ui_offscreen_trace_requested = false
local ui_offscreen_trace_frame = 0
local ui_offscreen_trace_complete = false
local ui_offscreen_trace_warmup_frames = 180
local ui_offscreen_active = false
local ui_left_output_target = nil
local ui_right_output_target = nil
local ui_left_render_target = nil
local ui_right_render_target = nil
local ui_left_material = nil
local ui_right_material = nil
local ui_compositor_package = "packages/ui/views/scanner_display_view/scanner_display_view"
local ui_compositor_package_reference = "DarktideVRStereoProbeCompositor"
local ui_compositor_material =
    "content/ui/materials/render_target_masks/ui_render_target_straight_blur"
-- Bounded pipeline-localization probe: show the left viewport's pre-final-blit
-- output_target beside the right viewport's completed back_buffer.  The two
-- cameras remain frozen so fixed-row artifacts can be compared directly.
local ui_compositor_package_id = nil
local ui_compositor_package_loaded = false
local ui_compositor_package_failed = false
-- Safe pre-XR fallback. The live OpenXR runtime recommendation replaces this
-- through the shared XR-state packet before eye resources are created.
-- The physical mirror is decoupled by swapchain-window WM_SIZE virtualization;
-- the remaining projection work must use an asymmetric per-eye frustum rather
-- than increasing this render extent for a symmetric overscan workaround.
-- Bootstrap layout only. Capture and target allocation must first acquire the
-- active OpenXR extent; these values must never select a render resolution.
local ui_eye_target_width = 2112
local ui_eye_target_height = 2304
-- Screen-space views have a separate 16:9 design surface. Publishing the
-- portrait eye extent for menus stretched both pixels and pointer coordinates
-- and was the common cause of half-height UI and a duplicate hover that drifted
-- farther from the ray as it moved down the panel.
local ui_runtime_extent_logged = false
local ui_native_capture_requested = true -- copy each completed full-origin eye
local ui_camera_output_candidate_probe_index = -1
local ui_native_observer_requested = false
local diagnostic_render_hooks_requested = false
local vertex_shader_dump_requested = false
-- PSO-time, whitelist-only substitution. Replacement shaders are validated
-- against the live shader interface before D3D12 ever sees them.
local billboard_shader_substitution_requested = true
-- Bounded ownership probe: replace only the pixel-shader partners observed on
-- live c_billboard draws with interface-identical constant-magenta shaders.
-- All five reflected billboard VS variants consume c_billboard[0].xy as the
-- normalized horizontal facing direction. The exact-CBV writer is limited to
-- exactly those two floats; registers 1-3 are unused by those VS variants and
-- registers 4-7 are the complete world-to-clip matrix.
-- The direct constant-buffer candidate was exercised in-headset on
-- 2026-08-26 and did not change the visible billboard orientation.  Keep the
-- hook available for diagnostics, but do not patch production draws while we
-- isolate the head-tracking regression.
local billboard_horizon_lock_requested = false
local billboard_direct_write_requested = false
-- Production cylindrical billboarding is the PSO-time shader substitution
-- above. The selector is a retired per-draw binding census whose descriptor
-- writer is fail-closed; leaving it armed installs thousands of diagnostic
-- D3D12 detours per stereo pair without changing the replacement shader.
local billboard_selector_probe_requested = false
local ui_table4_alias_probe_requested = false -- unsafe without exact draw identity
local ui_present_capture_requested = false
local ui_alternating_full_requested = false
local ui_top_bottom_requested = false -- shared-surface layouts are diagnostic only
local ui_alternating_full_eye = 0
local ui_alternating_full_last_present = nil
local ui_double_render_probe_requested = false
local ui_sequential_render_requested = false -- native capture owns sequencing
local ui_native_capture_active = false
local ui_native_capture = nil
local ui_native_capture_last_result = nil
local ui_native_sync_initialized = false
local ui_native_sync_last_result = nil
local ui_native_sync_timeout_ms = 100
local ui_native_sync_requested = false -- Lua blocks renderer submission; falsified
-- Resource-renderer redirection still causes cross-eye flicker for crafting.
-- Keep it disabled while shops temporarily use the proven character-select
-- style flat XR panel.
local ui_menu_resource_redirect_requested = false
-- The stock menu PSO/resource boundary is known. Keep the former focused
-- D3D12 trace opt-in only: its post-exit baseline used to remain armed because
-- SystemView.update no longer runs after on_exit, halving subsequent cadence.
local ui_menu_trace_requested = false
-- Bounded causal probe: Darktide exposes only a global DLSS history reset.
-- Reset before both sequential eyes to prevent either camera consuming the
-- other eye's history. This intentionally sacrifices temporal accumulation.
local ui_reset_dlss_each_eye_requested = false
-- Native/no-upscaler probe: after each sequential world submission, copy the
-- directly rendered swapchain before the following eye can overwrite it.
local ui_direct_swapchain_capture_requested = false
local ui_boundary_census_requested = false -- expensive diagnostic logging only
-- Authored desktop reference extent for the HUD editor preview seed and logs.
-- The window itself is no longer forced to this size: in-game menus are
-- published from the engine canvas at the presentation extent, so the
-- headset menu resolution and pointer mapping do not follow the client.
-- (Character select and title still use the window capture.)
local ui_mirror_client_width = 1920
local ui_mirror_client_height = 1080
local ui_virtual_client_extent_requested = false
local ui_virtual_size_message_requested = true
local head_pose_values = nil
local head_pose_sequence = nil
local head_tracking_requested = true
local head_translation_requested = true -- additive camera-only room-scale lean
local head_pose_last_sequence = 0
local head_render_vertical_fov = nil
local head_render_aspect_ratio = nil
local head_render_frusta = nil
local render_timing_label = nil
local render_timing_frequency = nil
local render_timing_samples = 0
local render_timing_left_ticks = 0
local render_timing_right_ticks = 0
local render_timing_pair_ticks = 0
local render_timing_left_max_ticks = 0
local render_timing_right_max_ticks = 0
local render_timing_pair_max_ticks = 0
local gpu_profile_values = nil
local gpu_stage_profile_values = nil
local controller_observation = {
    values = nil,
    tracking_flags = nil,
    buttons = nil,
    sequence = nil,
    timestamp_ns = nil,
    transport_generation = nil,
    last_transport_generation = 0,
    read_state_v2 = nil,
    gameplay_pressed = nil,
    gameplay_held = nil,
    gameplay_released = nil,
    gameplay_sequence = nil,
    gameplay_movement = nil,
    gameplay_input_enabled = false,
    gameplay_input_active = false,
    gameplay_input_last_check_t = -math.huge,
    gameplay_input_last_sequence = 0,
    gameplay_locomotion_last_frame = -math.huge,
    gameplay_stick_active = false,
    movement_inventory_done = false,
    movement_inventory_last_check_frame = -math.huge,
    last_sequence = 0,
    first_tracked_logged = false,
    right_aim_usable = false,
    right_aim_age_ms = math.huge,
    right_aim_flags = 0,
    right_aim_yaw = nil,
    right_aim_pitch = nil,
    right_aim_roll = nil,
    right_aim_x = nil,
    right_aim_y = nil,
    right_aim_z = nil,
    right_aim_qx = nil,
    right_aim_qy = nil,
    right_aim_qz = nil,
    right_aim_qw = nil,
    left_aim_usable = false,
    left_aim_flags = 0,
    left_aim_x = nil,
    left_aim_y = nil,
    left_aim_z = nil,
    left_aim_qx = nil,
    left_aim_qy = nil,
    left_aim_qz = nil,
    left_aim_qw = nil,
    left_trigger = 0,
    right_trigger = 0,
    left_stick_x = 0,
    left_stick_y = 0,
    right_stick_x = 0,
    right_stick_y = 0,
    right_grip_usable = false,
    right_grip_tracking_live = false,
    right_grip_tracking_last = nil,
    right_grip_flags = 0,
    right_grip_x = nil,
    right_grip_y = nil,
    right_grip_z = nil,
    right_grip_qx = nil,
    right_grip_qy = nil,
    right_grip_qz = nil,
    right_grip_qw = nil,
    left_grip_usable = false,
    left_grip_tracking_live = false,
    left_grip_tracking_last = nil,
    left_grip_flags = 0,
    left_grip_x = nil,
    left_grip_y = nil,
    left_grip_z = nil,
    left_grip_qx = nil,
    left_grip_qy = nil,
    left_grip_qz = nil,
    left_grip_qw = nil,
    body_anchor_x = nil,
    body_anchor_y = nil,
    body_anchor_z = nil,
    body_anchor_qx = nil,
    body_anchor_qy = nil,
    body_anchor_qz = nil,
    body_anchor_qw = nil,
    body_head_yaw = nil,
    physical_head_yaw = nil,
    head_aim_yaw = nil,
    head_aim_pitch = nil,
    head_aim_roll = nil,
    gameplay_yaw = nil,
    gameplay_pitch = nil,
    gameplay_roll = nil,
    gameplay_orientation_owner = nil,
    gameplay_orientation_suspended = false,
    body_visual_yaw = nil,
    body_visual_yaw_last_t = nil,
    body_heading_last_head_yaw = nil,
    body_heading_last_motion_t = -math.huge,
    body_yaw_anchor = nil,
    character_state_name = nil,
    hub_state_correction_logged = false,
    body_follow_x = 0,
    body_follow_y = 0,
    body_follow_z = 0,
    body_follow_mode = "disabled",
    body_follow_last_check_t = -math.huge,
    body_follow_last_log_t = -math.huge,
    body_follow_last_sequence = 0,
    body_follow_last_x = 0,
    body_follow_last_z = 0,
    body_follow_last_position_x = nil,
    body_follow_last_position_y = nil,
    body_follow_last_position_z = nil,
    body_follow_writes = 0,
    authoring_enabled = false,
    authoring_pose_active = false,
    authoring_unusable_last_flags = nil,
    authoring_unusable_last_log_t = -math.huge,
    authoring_last_check_t = -math.huge,
    authoring_writes = 0,
    epoch_block_sequence = -1,
    downstream_last_sequence = 0,
    downstream_missing_logged = false,
    downstream_forward_x = nil,
    downstream_forward_y = nil,
    downstream_forward_z = nil,
    first_person_seam_last_sequence = 0,
    first_person_seam_last_log_t = -math.huge,
    primary_action_armed = false,
    primary_action_injected = false,
    primary_action_cache_observed = false,
    primary_action_sequence = 0,
    primary_action_cache_frame = nil,
    primary_action_weapon_context_logged = false,
    primary_action_weapon_observed = false,
    primary_action_shot_observed = false,
    primary_action_projectile_observed = false,
    primary_action_stage = "idle",
    primary_action_last_check_t = -math.huge,
    weapon_inventory_done = false,
    weapon_inventory_last_check_frame = -math.huge,
    weapon_pose_trace_enabled = false,
    weapon_pose_trace_last_check_frame = -math.huge,
    weapon_pose_trace_last_log_frame = -math.huge,
    weapon_presentation_enabled = false,
    weapon_presentation_last_check_frame = -math.huge,
    weapon_presentation_last_log_frame = -math.huge,
    weapon_presentation_writes = 0,
    weapon_presentation_clamps = 0,
    weapon_presentation_max_post_error = 0,
    weapon_presentation_block_reason = nil,
    stock_melee_animation_active = false,
    stock_melee_animation_action = nil,
    stock_melee_animation_kind = nil,
    body_rig_inventory_done = false,
    body_rig_inventory_last_check_frame = -math.huge,
    body_visibility_enabled = false,
    body_visibility_update_frame = 0,
    body_visibility_last_check_frame = -math.huge,
    body_visibility_last_apply_frame = -math.huge,
    body_visibility_logged_slots = false,
    -- The drawn-body answer as of the last APPLIED pass, and as of the last
    -- report. Declared here with their neighbours so a body-state reset
    -- clears them too: a stale copy_drew swallows the one forced pass that
    -- the reset exists to produce.
    body_visibility_copy_drew = nil,
    body_visibility_logged_copy = nil,
    body_visibility_faulted = false,
    full_body_experimental_enabled = false,
    body_fade_override_logged = false,
    body_camera_anchor_logged = false,
    body_eye_anchor_logged = false,
    body_eye_anchor_unit = nil,
    body_eye_anchor_local_x = nil,
    body_eye_anchor_local_y = nil,
    body_eye_anchor_local_z = nil,
    body_eye_anchor_source = nil,
    body_camera_eye_offset_unit = nil,
    body_camera_eye_offset_since = nil,
    body_camera_eye_offset_x = nil,
    body_camera_eye_offset_y = nil,
    body_camera_eye_offset_z = nil,
    body_camera_sweep_start_t = nil,
    body_camera_sweep_last_bucket = -1,
    body_head_visible = true,
    force_hub_first_person_enabled = false,
    body_ik_trace_enabled = false,
    body_ik_trace_last_check_frame = -math.huge,
    body_ik_trace_last_log_frame = -math.huge,
    body_ik_presentation_enabled = false,
    body_ik_presentation_update_frame = 0,
    body_ik_presentation_last_check_frame = -math.huge,
    body_ik_presentation_last_log_frame = -math.huge,
    body_ik_presentation_writes = 0,
    body_ik_presentation_max_error = 0,
    body_ik_presentation_max_angle_error = 0,
    body_ik_basis_last_log_frame = -math.huge,
    body_ik_hand_offsets = {},
    body_ik_hand_anatomy = {},
    body_ik_hand_proxy_pose = {},
    body_ik_hand_proxy_held = {},
    body_ik_shoulder_reach = {},
    body_ik_spine_trace_frame = -math.huge,
    body_ik_torso_axis_unit = nil,
    body_ik_torso_axis_local = nil,
    body_ik_torso_block_reason = false,
    body_ik_torso_residual = nil,
    body_ik_shoulder_block_reason = false,
    body_ik_presentation_faulted = false,
    body_ik_presentation_block_reason = nil,
    body_ik_crouch_offset = 0,
    body_ik_crouch_last_t = nil,
    body_ik_crouch_max_foot_error = 0,
    body_ik_crouch_result = "inactive",
    head_recenter_generation = 0,
    body_ik_neck_unit = nil,
    body_ik_neck_generation = nil,
    body_ik_neck_offset_x = nil,
    body_ik_neck_offset_y = nil,
    body_ik_neck_offset_z = nil,
    body_ik_neck_baseline_raw = nil,
    body_ik_neck_baseline_arc = nil,
    body_ik_neck_anchor_unit = nil,
    body_ik_neck_anchor_generation = nil,
    body_ik_neck_anchor_local = nil,
    body_ik_neck_raw_vertical = 0,
    body_ik_neck_compensated_vertical = 0,
    body_ik_neck_arc_vertical = 0,
    body_ik_neck_last_log_t = -math.huge,
    ik_input = nil,
    ik_output = nil,
    ik_flags = nil
}
local performance_profile_requested = false -- opt-in diagnostic; allocates GPU timestamp work
-- Reuse the shading/LOD preparation performed by the primary eye. The second
-- eye still receives a complete native Application.render_world submission.
local reuse_prepared_frame_requested = true
local reuse_prepared_frame_failed = false
local ui_native_observer_last_present = 0
local main_menu_ui_hidden = false
local ui_swap_viewport_halves_requested = false -- bounded identity probe; normal mapping restored
local ui_focused_ab_trace_requested = false
-- One bounded causal probe: only the observed physical-right, six-index batch
-- with cached PSO fingerprint 6427276088126068298 is clamped to the left-eye
-- instance count. Revert to false immediately after the capture.
local ui_candidate_instance_clamp_requested = false
-- Second bounded test for the same PSO: pair its unique per-frame left/right
-- batch, require compatible table-4 layouts, alias only that right batch to
-- the left data, and retain the already-falsified count clamp as a control.
local ui_candidate_table4_probe_requested = false
-- Bounded architecture probe: build both eyes at the known-rich logical
-- right-half center, tag the left with a tiny X offset, and let the native
-- command-list hook remap both raster outputs to true SBS halves.
local ui_rich_center_sbs_remap_requested = false
local ui_full_origin_ab_requested = false
local ui_full_origin_ab_start_present = nil
local ui_full_origin_ab_phase_presents = 4800
local ui_full_origin_ab_duplicate_active = false
local ui_full_origin_ab_complete = false
local ui_camera_freeze_requested = false -- normal tracked-camera behavior
local ui_camera_freeze_start_present = nil
local ui_camera_freeze_warmup_presents = 0
local ui_camera_frozen_position = nil
local ui_camera_frozen_rotation = nil
local ui_base_vertical_fov = nil
local ui_rect_matrix_requested = false
local ui_rect_matrix_start_present = nil
local ui_rect_matrix_phase = 0
local ui_rect_matrix_phase_presents = 2400
local ui_rect_matrix_complete = false
-- Capture-only four-rectangle pass census. One frozen primary camera is
-- sampled for two presents at each known detail tier after a short settle.
local ui_rect_trace_requested = false
local ui_rect_trace_phase = 0
local ui_rect_trace_phase_start_present = nil
local ui_rect_trace_sample_start_present = nil
local ui_rect_trace_sampling = false
local ui_rect_trace_complete = false
local ui_rect_trace_warmup_presents = 120
local ui_rect_trace_sample_presents = 2
local ui_focused_ab_trace_frame = 0
local ui_focused_ab_trace_complete = false
local ui_focused_ab_warmup_frames = 180
local ui_focused_ab_sample_frames = 3
-- Armed only for the current assertion-bypass feasibility run. Revert to false
-- immediately after the bounded test.
local ui_stereo_requested = true -- zero-IPD stereo cached-pipeline census
local presentation = {
    flat_target_width = 1920,
    flat_target_height = 1080,
    full_second_eye_probe_requested = false,
    full_second_eye_probe_check_frame = 0,
    full_second_eye_probe_last_check_frame = -math.huge,
    eye_transform_probe_mode = "disabled",
    eye_transform_probe_check_frame = 0,
    eye_transform_probe_last_check_frame = -math.huge,
    render_projection_vertical_fov = nil,
    cluster_light_visibility_fix_active = false,
    reverse_eye_order_probe_requested = false,
    inherit_viewport_metadata_probe_mode = "disabled",
    shared_shadow_cull_enabled = true,
    performance_pass_trace_requested = false,
    performance_pass_trace_frame = 0,
    performance_pass_trace_complete = false,
    offline_dual_view_requested = false,
    offline_benchmark_start_t = nil,
    offline_benchmark_last_log_t = -math.huge,
    head_translation_trace_requested = true,
    head_translation_trace_last_sequence = 0,
    head_translation_trace_interval = 600,
    head_pose_transport_generation = nil,
    head_pose_last_transport_generation = 0,
    read_head_pose_v2 = nil,
    sequence = 0,
    mode = nil,
    last_mode_publish_t = -math.huge,
    menu_resource_renderer = nil,
    menu_resource_gui = nil,
    menu_resource_base_render_pass = nil,
    menu_resource_render_pass_flag = nil,
    menu_display_target = nil,
    menu_display_copy_sequence = -1,
    menu_display_copy_error_logged = false,
    menu_resource_clear_time = nil,
    menu_resource_pass_states = setmetatable({}, { __mode = "k" }),
    menu_resource_gui_mismatches = setmetatable({}, { __mode = "k" }),
    menu_resource_invalidated_views = setmetatable({}, { __mode = "k" }),
    world_menu_views = {},
    flat_panel_views = {
        main_menu_view = true,
        main_menu_background_view = true,
    },
    -- Hub facilities are view families rather than single views. Their
    -- background/landing view and nested interactive view have distinct names,
    -- but must remain on the same proven native-window mode-5 panel throughout
    -- the transition. Keep this explicit: `disable_game_world` also covers
    -- unrelated cinematics and fullscreen flows that need separate policy.
    shop_panel_views = {
        -- Operative UI includes a separate 3D preview world and image passes.
        -- Capture the complete native window with its matching pointer route.
        inventory_background_view = true,
        inventory_view = true,
        barber_vendor_background_view = true,
        character_appearance_view = true,
        contracts_background_view = true,
        contracts_view = true,
        live_events_view = true,
        credits_vendor_background_view = true,
        credits_vendor_view = true,
        credits_goods_vendor_view = true,
        cosmetics_vendor_background_view = true,
        cosmetics_vendor_view = true,
        marks_vendor_view = true,
        marks_goods_vendor_view = true,
        -- These NPC facilities use the same fullscreen, world-disabling
        -- transition contract as vendors. Keep both Psykhanium stages in one
        -- family so selecting a training mode cannot briefly fall back to the
        -- generic world-menu route between views.
        penance_overview_view = true,
        training_grounds_view = true,
        training_grounds_options_view = true,
    },
    -- Mode 6 retains premium-store lifecycle identity. Its visual aspect now
    -- follows the same attached-eye canvas rule as other native menus.
    native_aspect_shop_panel_views = {
        store_view = true,
        store_item_detail_view = true,
        -- Keep the currency child on the same panel throughout navigation.
        premium_currency_purchase_view = true,
    },
    world_menu_gui = nil,
    world_menu_gui_world = nil,
    world_menu_material = nil,
    world_menu_anchor = nil,
    world_menu_draw_logged = false,
    -- Temporary target-boundary proof for the engine-world menu path. These
    -- opaque marks are authored into the same render pass as the menu. If they
    -- appear on the world panel, target population and sampling are both
    -- proven independently of the SystemView widget draw. Remove after that
    -- live gate. This belongs in the state table rather than a file-scope
    -- local because the mod chunk is at LuaJIT's local-variable ceiling.
    world_menu_target_probe_requested = false,
    -- Temporary boundary diagnostic: composite the redirected menu resource
    -- through Darktide's documented resource-renderer `to_screen` path. This
    -- distinguishes an empty target from a valid target that the world GUI
    -- cannot sample at the required render-graph point.
    world_menu_target_desktop_probe = false,
    fullscreen_view_signature = "",
    fullscreen_empty_updates = 0,
    fullscreen_restore_delay_updates = 12,
    logged_view_classification = {},
    input_inventory_done = false,
    active_menu_view_instance = nil,
    active_menu_input_service = nil,
    system_view_hovered_widget = nil,
    system_view_source_widget = nil,
    dropdown_open_pending = nil,
    dropdown_close_pending = nil,
    options_modal_instance = nil,
    options_modal_widget = nil,
    slider_drag = nil,
    menu_pointer = {
        values = nil,
        sequence = nil,
        timestamp_ns = nil,
        transport_generation_value = nil,
        read_state = nil,
        read_state_v2 = false,
        read_state_v3 = false,
        last_sequence = 0,
        available = false,
        active = false,
        x = 0,
        y = 0,
        source_width = 0,
        source_height = 0,
        primary_down = false,
        primary_pressed = false,
        secondary_down = false,
        secondary_pressed = false,
        secondary_press_sequence = 0,
        secondary_consumed_sequence = 0,
        back_down = false,
        back_pressed = false,
        scroll_steps = 0,
        transport_generation = 0,
        event_sequences_initialized = false,
        primary_press_sequence = 0,
        primary_consumed_sequence = 0,
        back_press_sequence = 0,
        back_consumed_sequence = 0,
        scroll_sequence = 0,
        scroll_consumed_sequence = 0,
        diagnostic_miss_sequence = 0,
    },
    menu_input_probe = {
        stage = "idle",
        poll_updates = 0,
        action = nil,
        hovered_widget = nil,
    },
    vendor_menu_test_view = nil,
    vendor_menu_close_pending = nil,
    vendor_widget_scope_enabled = false,
    vendor_ui_renderer = nil,
    vendor_resource_enabled = false,
    vendor_anchor = {
        valid = false,
        view_name = nil,
        revision = 0,
        published_revision = -1,
        x = 0,
        y = 0,
        z = 0,
        qx = 0,
        qy = 0,
        qz = 0,
        qw = 1,
    },
    psykhanium = {
        stage = "idle",
        deadline = 0,
        last_error = nil,
    },
    explicit_flat_menu_views = {
        system_view = true,
        options_view = true,
        player_character_options_view = true,
        custom_settings_view = true,
        social_menu_roster_view = true,
        mission_voting_view = true,
    },
    -- Bounded lifecycle probe for the complete native menu surface. Keep the
    -- view family together while nested settings views overlap SystemView.
    direct_menu_surface_views = {},
    flat_loading_views = {
        splash_view = true,
        title_view = true,
        loading_view = true,
        mission_intro_view = true,
        video_view = true,
        splash_video_view = true,
        cutscene_view = true,
    },
    non_gameplay_views = {
        class_selection_view = true,
        main_menu_view = true,
        main_menu_background_view = true,
    },
    hud_panel = nil,
}

-- Native hooks initialize during this chunk, before gameplay hooks install.
presentation.spectator_module = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_spectator_input")

-- Stingray 1.6 exposed a native SteamVR namespace when its VR subsystem was
-- compiled in. Record presence only; do not call or mutate an undocumented
-- backend in the correctness build.
mod:info(
    "DARKTIDEVR_STEREO engine_vr_namespace SteamVR=%s SteamVRSystem=%s OpenVR=%s",
    type(rawget(_G, "SteamVR")),
    type(rawget(_G, "SteamVRSystem")),
    type(rawget(_G, "OpenVR"))
)

-- Indexing an FFI namespace never yields nil: a missing symbol raises. Probe
-- optional exports through pcall once and remember the answer.
function presentation.native_export(library, name)
    local cache = presentation.native_export_cache
    if not cache then
        cache = {}
        presentation.native_export_cache = cache
    end
    local known = cache[name]
    if known == nil then
        local ok, symbol = pcall(function() return library[name] end)
        known = ok and symbol ~= nil
        cache[name] = known
    end
    return known
end

local function ensure_ui_native_hooks()
    if ui_native_capture then
        return true
    end

    local ffi = Mods and Mods.lua and Mods.lua.ffi

    if not ffi then
        mod:error("DARKTIDEVR_STEREO native_capture ffi_unavailable")
        return false
    end

    pcall(ffi.cdef, [[
        int dtvr_install(void);
        int dtvr_prepare_process_exit(void);
        int dtvr_set_projection_active(int enabled);
        int dtvr_set_presentation_state(unsigned int mode, unsigned long long sequence,
            unsigned int source_width, unsigned int source_height,
            unsigned int crop_x, unsigned int crop_y,
            unsigned int crop_width, unsigned int crop_height,
            float maximum_panel_width_metres,
            float maximum_panel_height_metres);
        int dtvr_set_presentation_state_v2(unsigned int mode,
            unsigned long long sequence, unsigned int source_width,
            unsigned int source_height, unsigned int crop_x,
            unsigned int crop_y, unsigned int crop_width,
            unsigned int crop_height, float maximum_panel_width_metres,
            float maximum_panel_height_metres, int body_panel_pose_valid,
            float panel_x, float panel_y, float panel_z, float panel_qx,
            float panel_qy, float panel_qz, float panel_qw);
        int dtvr_commit_gameplay_generation(unsigned long long generation);
        int dtvr_set_gameplay_ads(int active);
        int dtvr_set_gameplay_zoom(float magnification);
        int dtvr_set_gameplay_aim_state(int active, int hit,
            float distance_metres);
        int dtvr_set_gameplay_aim_target(int hit, float distance_metres,
            float x, float y, float z, unsigned long long head_sequence,
            unsigned long long head_generation, unsigned int recenter_generation);
        int dtvr_capture_eye(int eye);
        int dtvr_capture_armed_swapchain_eye(int eye);
        int dtvr_set_camera_output_candidate_index(int index);
        int dtvr_arm_eye_capture(int eye);
        int dtvr_arm_eye_capture_pose(int eye, unsigned long long pose_sequence);
        int dtvr_reset_eye_capture_tags(void);
        int dtvr_wait_eye_capture_count(int eye, unsigned long long target, unsigned int timeout_ms);
        int dtvr_set_swapchain_render_extent(unsigned long long width, unsigned int height);
        int dtvr_enable_boundary_census(void);
        int dtvr_set_mirror_client_extent(unsigned int width, unsigned int height);
        int dtvr_read_mirror_cursor(int* values, unsigned int count);
        int dtvr_viewer_control(int enabled);
        int dtvr_viewer_state(int* values, unsigned int count);
        int dtvr_bootstrap_state(void);
        int dtvr_set_virtual_client_extent(int enabled);
        int dtvr_set_virtual_size_message(int enabled);
        int dtvr_lock_swapchain_client_extent(int enabled);
        int dtvr_set_render_projection(float vertical_fov_radians, float aspect_ratio);
        int dtvr_cluster_light_visibility_fix_active(void);
        unsigned long long dtvr_cluster_light_visibility_fix_candidate_count(void);
        unsigned long long dtvr_cluster_light_visibility_fix_patch_count(void);
        unsigned long long dtvr_cluster_light_visibility_fix_reject_count(void);
        unsigned long long dtvr_cluster_light_visibility_fix_target_draw_count(void);
        unsigned long long dtvr_cluster_light_visibility_fix_root_missing_count(void);
        unsigned long long dtvr_cluster_light_visibility_fix_resource_missing_count(void);
        unsigned long long dtvr_boundary_arm_count(void);
        unsigned long long dtvr_boundary_transition_count(void);
        unsigned long long dtvr_boundary_eye_capture_count(int eye);
        unsigned long long dtvr_boundary_eye_pose_sequence(int eye);
        unsigned long long dtvr_boundary_tag_queue_depth(void);
        unsigned long long dtvr_boundary_tag_reset_count(void);
        unsigned long long dtvr_ready_value(void);
        unsigned long long dtvr_execute_call_count(void);
        unsigned long long dtvr_present_count(void);
        int dtvr_capture_stage(void);
        int dtvr_enable_present_capture(void);
        int dtvr_disable_present_capture(void);
        int dtvr_enable_alternating_full_capture(void);
        int dtvr_disable_alternating_full_capture(void);
        int dtvr_set_alternating_present_eye(int eye);
        int dtvr_enable_top_bottom_capture(void);
        int dtvr_disable_top_bottom_capture(void);
        unsigned long long dtvr_alternating_eye_copy_count(int eye);
        unsigned long long dtvr_alternating_eye_tag_count(void);
        int dtvr_alternating_last_capture_result(void);
        int dtvr_enable_table4_alias(void);
        int dtvr_disable_table4_alias(void);
        unsigned long long dtvr_table4_alias_count(void);
        unsigned long long dtvr_table4_exact_match_count(void);
        unsigned long long dtvr_table4_exact_ambiguous_count(void);
        int dtvr_enable_candidate_instance_clamp(void);
        int dtvr_disable_candidate_instance_clamp(void);
        unsigned long long dtvr_candidate_instance_clamp_count(void);
        int dtvr_enable_candidate_table4_alias(void);
        int dtvr_disable_candidate_table4_alias(void);
        unsigned long long dtvr_candidate_table4_alias_count(void);
        unsigned long long dtvr_candidate_table4_match_count(void);
        unsigned long long dtvr_candidate_table4_ambiguous_count(void);
        int dtvr_enable_rich_center_sbs_remap(void);
        int dtvr_disable_rich_center_sbs_remap(void);
        int dtvr_set_focused_trace_phase(int phase);
        unsigned long long dtvr_focused_trace_count(void);
        int dtvr_enable_marker_log(void);
        int dtvr_set_diagnostic_render_hooks(int enabled);
        int dtvr_set_billboard_shader_substitution(int enabled);
        int dtvr_begin_billboard_draw_readback(void);
        int dtvr_set_billboard_pixel_shader_probe(int enabled);
        typedef struct {
            unsigned int vertex_low, vertex_high, pixel_low, pixel_high;
            unsigned long long count;
        } dtvr_billboard_pair_sample;
        unsigned int dtvr_copy_billboard_candidate_pairs(
            dtvr_billboard_pair_sample* output, unsigned int capacity);
        unsigned long long dtvr_billboard_pixel_shader_probe_result_count(
            unsigned int kind);
        unsigned long long dtvr_billboard_shader_substitution_count(void);
        unsigned long long dtvr_billboard_shader_substitution_reject_count(void);
        unsigned long long dtvr_billboard_shader_substitution_result_count(
            unsigned int rank, unsigned int kind);
        int dtvr_set_vertex_shader_dump(int enabled);
        int dtvr_set_billboard_view_basis(float right_x, float right_y,
            float right_z, float up_x, float up_y,
            float up_z, int enabled);
        int dtvr_set_billboard_staging_view_basis(float right_x, float right_y,
            float right_z, float up_x, float up_y,
            float up_z, int enabled);
        int dtvr_set_billboard_direct_view_direction(float right_x,
            float right_y, int enabled);
        int dtvr_solve_two_bone_ik(const float *input,
            unsigned int input_count, float *output,
            unsigned int output_count, unsigned int *flags);
        unsigned long long dtvr_billboard_stride_candidate_count(void);
        unsigned long long dtvr_billboard_b1_bound_count(void);
        unsigned long long dtvr_billboard_b2_bound_count(void);
        unsigned long long dtvr_billboard_exact_shader_draw_count(void);
        unsigned long long dtvr_billboard_exact_pso_draw_count(void);
        unsigned long long dtvr_billboard_exact_pso_cbv_slot_count(
            unsigned int slot);
        unsigned long long dtvr_billboard_exact_pso_table_slot_count(
            unsigned int slot);
        unsigned long long dtvr_billboard_exact_register_count(
            unsigned int shader_register);
        unsigned long long dtvr_billboard_exact_vertex_table_slot_count(
            unsigned int slot);
        unsigned long long dtvr_billboard_exact_descriptor_offset_count(
            unsigned int offset);
        unsigned long long dtvr_billboard_exact_table_span_count(
            unsigned int span);
        unsigned long long dtvr_billboard_exact_cbv_descriptor_count(void);
        unsigned long long dtvr_billboard_exact_buffer_resource_count(void);
        unsigned long long dtvr_billboard_exact_heap_type_count(
            unsigned int heap_type);
        unsigned long long dtvr_billboard_exact_map_success_count(void);
        unsigned long long dtvr_billboard_exact_map_failure_count(void);
        unsigned long long dtvr_billboard_resource_map_count(void);
        unsigned long long dtvr_billboard_resource_map_match_count(void);
        unsigned long long dtvr_billboard_resource_unmap_count(void);
        unsigned long long dtvr_billboard_selected_map_stack_count(void);
        unsigned long long dtvr_billboard_upload_flush_count(void);
        unsigned long long dtvr_billboard_direct_patch_count(void);
        int dtvr_billboard_upload_flush_hook_state(void);
        unsigned long long dtvr_billboard_selected_cpu_address(void);
        unsigned long long dtvr_billboard_selected_gpu_address(void);
        unsigned long long dtvr_billboard_selected_size(void);
        unsigned long long dtvr_billboard_shadow_stage_count(
            unsigned int stage);
        unsigned long long dtvr_billboard_exact_command_list_type_count(
            unsigned int type);
        unsigned long long dtvr_billboard_exact_root_mapping_count(void);
        unsigned long long dtvr_billboard_root_metadata_draw_count(void);
        unsigned long long dtvr_diagnostic_root_signature_create_count(void);
        unsigned long long dtvr_diagnostic_graphics_pso_create_count(void);
        unsigned long long dtvr_diagnostic_compute_pso_create_count(void);
        unsigned long long dtvr_diagnostic_stream_pso_create_count(void);
        unsigned long long dtvr_diagnostic_graphics_pipeline_load_count(void);
        unsigned long long dtvr_diagnostic_compute_pipeline_load_count(void);
        unsigned long long dtvr_diagnostic_stream_pipeline_load_count(void);
        unsigned long long dtvr_billboard_root_b2_candidate_draw_count(void);
        typedef struct {
            unsigned int hash_low, hash_high;
            unsigned long long count;
        } dtvr_billboard_shader_sample;
        unsigned int dtvr_copy_billboard_candidate_shaders(
            dtvr_billboard_shader_sample* output, unsigned int capacity);
        unsigned long long dtvr_billboard_candidate_shader_hash(unsigned int rank);
        unsigned long long dtvr_billboard_candidate_shader_count(unsigned int rank);
        unsigned int dtvr_billboard_candidate_shader_hash_low(unsigned int rank);
        unsigned int dtvr_billboard_candidate_shader_hash_high(unsigned int rank);
        unsigned long long dtvr_billboard_candidate_pair_vertex_shader(
            unsigned int rank);
        unsigned long long dtvr_billboard_candidate_pair_pixel_shader(
            unsigned int rank);
        unsigned long long dtvr_billboard_candidate_pair_count(unsigned int rank);
        unsigned int dtvr_billboard_candidate_pair_vertex_low(unsigned int rank);
        unsigned int dtvr_billboard_candidate_pair_vertex_high(unsigned int rank);
        unsigned int dtvr_billboard_candidate_pair_pixel_low(unsigned int rank);
        unsigned int dtvr_billboard_candidate_pair_pixel_high(unsigned int rank);
        unsigned long long dtvr_billboard_table_b2_draw_count(void);
        unsigned long long dtvr_billboard_bound_table_b2_draw_count(void);
        unsigned long long dtvr_billboard_observed_draw_count(void);
        unsigned long long dtvr_billboard_direct_draw_hook_count(void);
        int dtvr_billboard_probe_state(void);
        unsigned long long dtvr_billboard_observed_stride_count(
            unsigned int slot, unsigned int stride);
        unsigned long long dtvr_billboard_basis_patch_count(void);
        int dtvr_read_head_pose(float *values, unsigned long long *sequence);
        int dtvr_read_head_pose_v2(float *values,
            unsigned long long *sequence,
            unsigned long long *transport_generation);
        int dtvr_read_controller_state(float *values,
            unsigned int *tracking_flags, unsigned int *buttons,
            unsigned long long *sequence,
            unsigned long long *timestamp_ns);
        int dtvr_read_controller_state_v2(float *values,
            unsigned int *tracking_flags, unsigned int *buttons,
            unsigned long long *sequence, unsigned long long *timestamp_ns,
            unsigned long long *transport_generation);
        int dtvr_read_menu_pointer_state(unsigned int *values,
            unsigned long long *sequence,
            unsigned long long *timestamp_ns);
        int dtvr_read_menu_pointer_state_v2(unsigned int *values,
            unsigned long long *sequence,
            unsigned long long *timestamp_ns,
            unsigned long long *transport_generation);
        int dtvr_read_menu_pointer_state_v3(unsigned int *values,
            unsigned int value_count, unsigned long long *sequence,
            unsigned long long *timestamp_ns,
            unsigned long long *transport_generation);
        int dtvr_read_gameplay_input(int gameplay_active,
            unsigned long long *pressed, unsigned long long *held,
            unsigned long long *released, unsigned long long *sequence,
            float *movement);
        int dtvr_read_spectator_input(int active,
            unsigned long long *pressed, unsigned long long *held,
            unsigned long long *released, unsigned long long *sequence,
            float *movement, unsigned long long *generation, float *right_stick);
        unsigned long long dtvr_qpc_ticks(void);
        unsigned long long dtvr_qpc_frequency(void);
        int dtvr_take_gpu_eye_profile(int eye, unsigned long long *values);
        int dtvr_take_gpu_stage_profile(int eye, unsigned long long *values);
        int dtvr_set_gpu_eye_profile(int enabled);
        int dtvr_queue_priority_raised(void);
        int dtvr_queue_priority_refused(void);
        int dtvr_set_menu_draw_scope(int enabled);
        unsigned long long dtvr_menu_draw_scope_redirect_count(void);
        int dtvr_arm_options_menu_capture(void);
        int dtvr_set_vendor_menu_widget_capture(int enabled);
        int dtvr_set_menu_direct_capture(int enabled);
        int dtvr_set_input_preferences_v2(int keyboard_mouse,
            int controllers_disabled, unsigned long long recenter_request);
        int dtvr_request_haptic_v1(int hands, float amplitude, int duration_ms,
            float frequency_hz);
        int dtvr_backup_user_settings(void);
    ]])

    local ok, library = pcall(
        ffi.load,
        "../mods/darktidevr/bin/darktidevr_native_capture.dll"
    )

    if not ok then
        mod:error("DARKTIDEVR_STEREO native_capture load_failed error=%s", tostring(library))
        return false
    end

    local snapshot_ok, snapshot = pcall(function()
        return library.dtvr_copy_billboard_candidate_shaders
    end)
    presentation.billboard_shader_snapshot = snapshot_ok and snapshot or false

    local diagnostic_result = library.dtvr_set_diagnostic_render_hooks(
        (diagnostic_render_hooks_requested or vertex_shader_dump_requested or
            billboard_horizon_lock_requested or
            billboard_selector_probe_requested or
            ui_native_observer_requested or
            presentation.performance_pass_trace_requested) and
            1 or 0)
    if diagnostic_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO diagnostic_hook_select_failed code=%d",
            diagnostic_result)
        return false
    end

    local substitution_result = library.dtvr_set_billboard_shader_substitution(
        billboard_shader_substitution_requested and 1 or 0)
    if substitution_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO billboard_shader_substitution_select_failed code=%d",
            substitution_result)
        return false
    end

    local pixel_probe_result = library.dtvr_set_billboard_pixel_shader_probe(
        presentation.billboard_pixel_shader_probe_requested and 1 or 0)
    if pixel_probe_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO billboard_pixel_shader_probe_select_failed code=%d",
            pixel_probe_result)
        return false
    end

    local shader_dump_result = library.dtvr_set_vertex_shader_dump(
        vertex_shader_dump_requested and 1 or 0)
    if shader_dump_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO shader_dump_select_failed code=%d",
            shader_dump_result)
        return false
    end

    local install_result = library.dtvr_install()

    if install_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO native_capture install_failed code=%d", install_result)
        return false
    end

    -- Keep a copy of the settings file from a sound launch: a crash while the
    -- game writes it leaves the launcher starting from defaults (14 September).
    -- The mode switch restores the newest copy.
    if presentation.native_export(library, "dtvr_backup_user_settings") then
        local names = {"saved", "unchanged", "missing", "invalid", "shrunk", "failed"}
        local code = tonumber(library.dtvr_backup_user_settings())
        mod:info("DARKTIDEVR_SETTINGS backup=%s", tostring(names[(code or 5) + 1] or code))
    end
    -- Selector-only diagnostics must be active before any particular camera
    -- path exists. Character select uses UIWorldSpawner rather than the
    -- gameplay CameraManager, so enabling this only from update_stereo left
    -- the native draw hooks active while the dry selector itself stayed off.
    -- Mode 2 records state and categorizes draws but is hard-disabled from
    -- issuing any GPU writes.
    if billboard_horizon_lock_requested then
        -- Darktide is Z-up. Only c_billboard[0].xy is the shader-proven
        -- horizontal facing direction; the native writer leaves every other
        -- word byte-for-byte unchanged.
        library.dtvr_set_billboard_direct_view_direction(
            1, 0, billboard_direct_write_requested and 1 or 0)
    elseif billboard_selector_probe_requested then
        library.dtvr_set_billboard_view_basis(
            1, 0, 0,
            0, 1, 0,
            2
        )
    end

    if vertex_shader_dump_requested then
        library.dtvr_enable_marker_log()
    end

    ui_native_capture = library
    do
        -- This optional readback does not select startup hooks. It requires the
        -- separate census mode, whose bootstrap/Lua agreement is already gated.
        local flag = Mods.lua.io.open(
            "./../mods/darktidevr/darktidevr_billboard_readback.flag", "r")
        if flag then
            local value = flag:read("*all")
            flag:close()
            if type(value) == "string" and #value <= 31 and
                    value:lower():match("^[ \t\r\n]*enabled[ \t\r\n]*$") then
                local ok, result = pcall(function() return library.dtvr_begin_billboard_draw_readback() end)
                mod:info("DARKTIDEVR_BILLBOARD_READBACK startup_ok=%s result=%s",
                    tostring(ok), tostring(result))
            end
        end
    end
    -- The aim zoom the cameras are rendering with, sent to the viewer so it
    -- submits the SAME projection to the runtime. Optional like the target
    -- transport above: an older capture DLL has no such symbol, and touching
    -- a missing one through the FFI raises. Without it the zoom stays off
    -- (see zoom_magnification's own guard), because a zoom the viewer cannot
    -- be told about is the fault this exists to fix.
    local zoom_ok, zoom_function = pcall(function()
        return library.dtvr_set_gameplay_zoom
    end)
    presentation.native_gameplay_zoom = zoom_ok and zoom_function or nil
    mod:info("DARKTIDEVR_AIM zoom_transport=%s",
        zoom_ok and "ready" or "unavailable")
    local target_ok, target_function = pcall(function()
        return library.dtvr_set_gameplay_aim_target
    end)
    presentation.native_gameplay_aim_target = target_ok and target_function or nil
    mod:info("DARKTIDEVR_ONLINE_RETICLE target_transport=%s",
        target_ok and "ready" or "unavailable")
    presentation.cluster_light_visibility_fix_active =
        tonumber(library.dtvr_cluster_light_visibility_fix_active()) == 1
    mod:info(
        "DARKTIDEVR_STEREO cluster_light_visibility_fix active=%s",
        tostring(presentation.cluster_light_visibility_fix_active))
    ui_native_capture.dtvr_set_projection_active(0)
    presentation.hud_mirror_values = ffi.new("int[5]")
    head_pose_values = ffi.new("float[25]")
    head_pose_sequence = ffi.new("unsigned long long[1]")
    presentation.head_pose_transport_generation =
        ffi.new("unsigned long long[1]")
    local head_pose_v2_ok, head_pose_v2 = pcall(
        function()
            return library.dtvr_read_head_pose_v2
        end)
    presentation.read_head_pose_v2 = head_pose_v2_ok and head_pose_v2 or nil
    if not head_pose_v2_ok then
        presentation.head_pose_transport_generation[0] = 1
        mod:warning(
            "DARKTIDEVR_STEREO head_pose_transport_generation_unavailable fallback=v1")
    end
    controller_observation.values = ffi.new("float[36]")
    controller_observation.tracking_flags = ffi.new("unsigned int[4]")
    controller_observation.buttons = ffi.new("unsigned int[2]")
    controller_observation.sequence = ffi.new("unsigned long long[1]")
    controller_observation.timestamp_ns = ffi.new("unsigned long long[1]")
    controller_observation.transport_generation =
        ffi.new("unsigned long long[1]")
    local controller_v2_ok, controller_v2 = pcall(
        function()
            return library.dtvr_read_controller_state_v2
        end)
    controller_observation.read_state_v2 = controller_v2_ok and
        controller_v2 or nil
    if not controller_v2_ok then
        controller_observation.transport_generation[0] = 1
        mod:warning(
            "DARKTIDEVR_CONTROLLER transport_generation_unavailable fallback=v1")
    end
    presentation.menu_pointer.values = ffi.new("unsigned int[13]")
    presentation.menu_pointer.sequence =
        ffi.new("unsigned long long[1]")
    presentation.menu_pointer.timestamp_ns =
        ffi.new("unsigned long long[1]")
    presentation.menu_pointer.transport_generation_value =
        ffi.new("unsigned long long[1]")
    local menu_pointer_v2_ok, menu_pointer_v2 = pcall(
        function()
            return library.dtvr_read_menu_pointer_state_v2
        end)
    presentation.menu_pointer.read_state_v2 = menu_pointer_v2_ok
    presentation.menu_pointer.read_state = menu_pointer_v2_ok and
        menu_pointer_v2 or library.dtvr_read_menu_pointer_state
    local menu_pointer_v3_ok, menu_pointer_v3 = pcall(function()
        return library.dtvr_read_menu_pointer_state_v3
    end)
    presentation.menu_pointer.read_state_v3 = menu_pointer_v3_ok
    if menu_pointer_v3_ok then presentation.menu_pointer.read_state = menu_pointer_v3 end
    if not menu_pointer_v2_ok then
        presentation.menu_pointer.transport_generation_value[0] = 1
        mod:warning(
            "DARKTIDEVR_MENU_INPUT transport_generation_unavailable fallback=v1")
    end
    controller_observation.gameplay_pressed =
        ffi.new("unsigned long long[1]")
    controller_observation.gameplay_held = ffi.new("unsigned long long[1]")
    controller_observation.gameplay_released =
        ffi.new("unsigned long long[1]")
    controller_observation.gameplay_sequence =
        ffi.new("unsigned long long[1]")
    controller_observation.gameplay_movement = ffi.new("float[2]")
    presentation.spectator_reader = presentation.spectator_module.native_reader(ffi,library)
    controller_observation.ik_input = ffi.new("float[17]")
    controller_observation.ik_output = ffi.new("float[14]")
    controller_observation.ik_flags = ffi.new("unsigned int[1]")
    gpu_profile_values = ffi.new("unsigned long long[6]")
    gpu_stage_profile_values = ffi.new("unsigned long long[6]")
    ui_native_capture.dtvr_set_gpu_eye_profile(
        performance_profile_requested and 1 or 0)
    mod:info("DARKTIDEVR_STEREO native_hooks installed")
    if billboard_shader_substitution_requested then
        mod:info(
            "DARKTIDEVR_STEREO billboard_shader_substitution applied=%d rejected=%d",
            tonumber(library.dtvr_billboard_shader_substitution_count()),
            tonumber(library.dtvr_billboard_shader_substitution_reject_count())
        )
        local shader_labels = {
            "6e5fa4d1f1e2cd16", "25920ba45ba58e76",
            "af848a96a230342a", "903cb53d8ac05f28",
            "13e04962148fc216", "42f73c7d12e99db7",
            "c403cfbf17d9fc49", "30408e39c8028272",
            "e18a274cd89282e8", "f0c85040e349f799",
            "fe64037664924d52", "9edf5361a4db2da1",
            "6a0153ef1f6c56fd", "42e436fb1ef1b392"
        }
        for rank = 0, #shader_labels - 1 do
            mod:info(
                "DARKTIDEVR_STEREO billboard_shader_result hash=%s attempts=%d applied=%d validation_rejects=%d creation_rejects=%d",
                shader_labels[rank + 1],
                tonumber(library.dtvr_billboard_shader_substitution_result_count(rank, 0)),
                tonumber(library.dtvr_billboard_shader_substitution_result_count(rank, 1)),
                tonumber(library.dtvr_billboard_shader_substitution_result_count(rank, 2)),
                tonumber(library.dtvr_billboard_shader_substitution_result_count(rank, 3))
            )
        end
    end

    return true
end

function presentation.publish_mode(mode, reason)
    local vendor_anchor = presentation.vendor_anchor
    local anchor_changed = mode == 3 and vendor_anchor.valid and
        vendor_anchor.published_revision ~= vendor_anchor.revision
    local now = Managers and Managers.time and Managers.time:time("main") or 0
    local mode_changed = presentation.mode ~= mode
    local heartbeat_due = not mode_changed and now > 0 and
        now - presentation.last_mode_publish_t >= 0.5
    if ui_native_capture and presentation.publish_input_preferences then
        presentation.publish_input_preferences()
    end
    if not ui_native_capture or
            (not mode_changed and not anchor_changed and not heartbeat_due) then
        return
    end
    presentation.sequence = presentation.sequence + 1
    -- Loading boards, videos and cutscenes (mode 2) precede every map unload.
    -- The marker atlas and the HUD panel's mirrored elements hold material
    -- instances made from widgets, some from the mission's own packages
    -- (survival markers, the buff choice); an engine crash followed the
    -- survival mission's unload with a material still referenced. Release
    -- them at the first heartbeat in mode 2 (0.5 s in, after the last frame
    -- that drew with them, with the world still alive); the next routed draw
    -- re-creates them.
    if not mode_changed and heartbeat_due and mode == 2 then
        if presentation.marker_atlas then pcall(presentation.marker_atlas.destroy) end
        if presentation.hand_overlay then presentation.hand_overlay.destroy() end
        if presentation.hud_panel and presentation.hud_panel.release_mirror_materials then
            pcall(presentation.hud_panel.release_mirror_materials)
        end
    end
    local flat_mode = mode == 2 or mode == 3 or mode == 4 or mode == 5 or
        mode == 6
    -- UI layout is authored at 1920x1080 logical pixels and then multiplied
    -- by RESOLUTION_LOOKUP.scale. The old fixed 1920x1080 crop truncated the
    -- scaled menu and made the XR pointer diverge from engine hotspots.
    local ui_scale = RESOLUTION_LOOKUP and RESOLUTION_LOOKUP.scale or 1
    local scaled_flat_width = math.floor(
        presentation.flat_target_width * ui_scale + 0.5)
    local scaled_flat_height = math.floor(
        presentation.flat_target_height * ui_scale + 0.5)
    local direct_menu_target = mode == 3 or mode == 4
    -- Interactive menus, loading boards and video cutscenes have a dedicated
    -- 16:9 RGBA source blitted from the engine canvas at this extent. Taking
    -- loading boards from the portrait eye source through the desktop window
    -- showed them squashed to the window's aspect.
    local native_window_target = mode == 2 or mode == 5 or mode == 6
    local source_width = native_window_target and scaled_flat_width or
        (direct_menu_target and math.min(
            scaled_flat_width, ui_eye_target_width) or ui_eye_target_width)
    -- The direct D3D12 menu target is created from the full eye-sized render
    -- target. Publish that physical resource extent even though the authored
    -- 16:9 menu occupies only the crop below; otherwise the XR process rejects
    -- the valid shared handle as an extent mismatch.
    local source_height = native_window_target and scaled_flat_height or
        ui_eye_target_height
    local crop_width = flat_mode and math.min(
        scaled_flat_width, source_width) or source_width
    local crop_height = flat_mode and math.min(
        scaled_flat_height, source_height) or source_height
    -- The stock fullscreen UI is centered vertically inside the portrait eye
    -- target. Its non-transparent bounds were measured at y=735..1512 in a
    -- 2112x2304 resource, so a centered 2112x1188 crop contains the complete
    -- menu instead of the former empty-top/trimmed-bottom region.
    local crop_y = direct_menu_target and math.floor(
        (source_height - crop_height) * 0.5 + 0.5) or 0
    -- Never resize the renderer on a presentation transition. The producer's
    -- shared-eye resources are bound to a swapchain generation; resizing for a
    -- loading panel and restoring on gameplay leaves the harness attached to
    -- the retired generation and silently stops fresh stereo. Flat content is
    -- fitted in the capture/compositor path instead.
    -- Direct D3D12 menu redirection must never remain armed in the ordinary
    -- stereo or loading scenes. The retained UI shader set is shared with
    -- title/character-select rendering; leaving the redirect globally enabled
    -- can preserve one of those old targets and replay it during hub Presents.
    if presentation.native_export(ui_native_capture, "dtvr_set_menu_direct_capture") then
        ui_native_capture.dtvr_set_menu_direct_capture(
            direct_menu_target and 1 or 0)
    end
    local result = nil
    if mode == 3 and vendor_anchor.valid then
        result = tonumber(ui_native_capture.dtvr_set_presentation_state_v2(
            mode,
            presentation.sequence,
            source_width,
            source_height,
            0,
            crop_y,
            crop_width,
            crop_height,
            2,
            2,
            1,
            vendor_anchor.x,
            vendor_anchor.y,
            vendor_anchor.z,
            vendor_anchor.qx,
            vendor_anchor.qy,
            vendor_anchor.qz,
            vendor_anchor.qw
        ))
    else
        result = tonumber(ui_native_capture.dtvr_set_presentation_state(
            mode,
            presentation.sequence,
            source_width,
            source_height,
            0,
            crop_y,
            crop_width,
            crop_height,
            2,
            2
        ))
    end
    if result ~= 0 then
        presentation.last_mode_publish_t = now
        mod:error(
            "DARKTIDEVR_PRESENTATION publish_failed mode=%d sequence=%d code=%d",
            mode,
            presentation.sequence,
            result
        )
        return
    end
    presentation.mode = mode
    presentation.last_mode_publish_t = now
    if mode == 3 then
        vendor_anchor.published_revision = vendor_anchor.revision
    end
    if mode_changed or anchor_changed then
        mod:info(
            "DARKTIDEVR_PRESENTATION mode=%d sequence=%d reason=%s source=%dx%d crop=0,%d,%dx%d ui_lookup=%sx%s scale=%s mirror=%dx%d",
            mode,
            presentation.sequence,
            tostring(reason),
            source_width,
            source_height,
            crop_y,
            crop_width,
            crop_height,
            tostring(RESOLUTION_LOOKUP and RESOLUTION_LOOKUP.width),
            tostring(RESOLUTION_LOOKUP and RESOLUTION_LOOKUP.height),
            tostring(RESOLUTION_LOOKUP and RESOLUTION_LOOKUP.scale),
            ui_mirror_client_width,
            ui_mirror_client_height
        )
    end
end

function presentation.menu_resource_extent()
    local scale = RESOLUTION_LOOKUP and RESOLUTION_LOOKUP.scale or 1
    return math.min(
            math.floor(presentation.flat_target_width * scale + 0.5),
            ui_eye_target_width),
        math.min(
            math.floor(presentation.flat_target_height * scale + 0.5),
            ui_eye_target_height)
end

function presentation.world_menu_active()
    return presentation.active_menu_view_instance ~= nil or
        next(presentation.world_menu_views) ~= nil
end

function presentation.destroy_world_menu_surface()
    local world = presentation.world_menu_gui_world
    local gui = presentation.world_menu_gui
    if world and gui then
        pcall(World.destroy_gui, world, gui)
    end
    presentation.world_menu_gui = nil
    presentation.world_menu_gui_world = nil
    presentation.world_menu_material = nil
    presentation.world_menu_anchor = nil
    presentation.world_menu_draw_logged = false
end

function presentation.destroy_menu_resource()
    presentation.destroy_world_menu_surface()
    local renderer = presentation.menu_resource_renderer
    local gui = presentation.menu_resource_gui
    if renderer then
        if gui and renderer.render_target_material then
            pcall(Gui.destroy_material, gui, renderer.render_target_material)
        end
        if renderer.render_target then
            pcall(Renderer.destroy_resource, renderer.render_target)
        end
    end
    if presentation.menu_display_target then
        pcall(Renderer.destroy_resource, presentation.menu_display_target)
    end
    presentation.menu_resource_renderer = nil
    presentation.menu_resource_gui = nil
    presentation.menu_resource_base_render_pass = nil
    presentation.menu_resource_render_pass_flag = nil
    presentation.menu_display_target = nil
    presentation.menu_display_copy_sequence = -1
    presentation.menu_display_copy_error_logged = false
    presentation.menu_resource_clear_time = nil
    presentation.menu_resource_pass_states = setmetatable({}, { __mode = "k" })
    presentation.menu_resource_gui_mismatches =
        setmetatable({}, { __mode = "k" })
    presentation.menu_resource_invalidated_views =
        setmetatable({}, { __mode = "k" })
end

function presentation.invalidate_retained_widgets(widgets)
    local count = 0
    if type(widgets) ~= "table" then
        return count
    end
    for i = 1, #widgets do
        local widget = widgets[i]
        if widget then
            widget.dirty = true
            local passes = widget.passes
            if type(passes) == "table" then
                for j = 1, #passes do
                    local pass = passes[j]
                    if pass and pass.retained_mode and pass.data then
                        pass.data.dirty = true
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

function presentation.ensure_menu_resource(source_renderer)
    local resource_renderer = presentation.menu_resource_renderer
    if resource_renderer then
        return resource_renderer
    end
    local width, height = presentation.menu_resource_extent()
    local ok, created = pcall(
        UIRenderer.create_resource_renderer,
        source_renderer.world,
        source_renderer.gui,
        source_renderer.gui_retained,
        "darktidevr_menu_ui",
        "content/ui/materials/render_target_masks/ui_render_target_straight_blur",
        width,
        height,
        true
    )
    if not ok then
        mod:error(
            "DARKTIDEVR_MENU_TARGET create_failed renderer=%s error=%s",
            tostring(source_renderer.name),
            tostring(created))
        return nil
    end
    presentation.menu_resource_renderer = created
    presentation.menu_resource_gui = source_renderer.gui
    presentation.menu_resource_base_render_pass = created.base_render_pass
    presentation.menu_resource_render_pass_flag = created.render_pass_flag
    local display_ok, display_target = pcall(
        Renderer.create_resource,
        "render_target",
        "R8G8B8A8",
        nil,
        width,
        height,
        "darktidevr_menu_display")
    if not display_ok or not display_target then
        mod:error(
            "DARKTIDEVR_MENU_TARGET display_create_failed error=%s",
            tostring(display_target))
        presentation.destroy_menu_resource()
        return nil
    end
    presentation.menu_display_target = display_target
    mod:info(
        "DARKTIDEVR_MENU_TARGET created width=%d height=%d renderer=%s",
        width,
        height,
        tostring(source_renderer.name))
    return created
end

function presentation.draw_world_menu_surface(world, position, rotation)
    if not presentation.world_menu_active() then
        if presentation.world_menu_gui then
            presentation.destroy_menu_resource()
        end
        return
    end
    local resource_renderer = presentation.menu_resource_renderer
    local render_target = resource_renderer and resource_renderer.render_target
    local display_target = presentation.menu_display_target
    if not render_target or not display_target then
        return
    end
    local copy_sequence = controller_observation.last_sequence or 0
    if presentation.menu_display_copy_sequence ~= copy_sequence then
        local copy_ok, copy_error = pcall(
            Renderer.copy_render_target_rect,
            render_target,
            0,
            0,
            1,
            1,
            display_target,
            0,
            0,
            1,
            1)
        if copy_ok then
            presentation.menu_display_copy_sequence = copy_sequence
        elseif not presentation.menu_display_copy_error_logged then
            presentation.menu_display_copy_error_logged = true
            mod:error(
                "DARKTIDEVR_MENU_TARGET display_copy_failed error=%s",
                tostring(copy_error))
        end
    end
    if presentation.world_menu_gui_world ~= world then
        presentation.destroy_world_menu_surface()
    end
    if not presentation.world_menu_gui then
        local gui = World.create_world_gui(
            world, Matrix4x4.identity(), 1, 1)
        local material = Gui.create_material(
            gui,
            ui_compositor_material,
            GuiMaterialFlag.GUI_RENDER_PASS_LAYER)
        Material.set_resource(material, "source", display_target)
        presentation.world_menu_gui = gui
        presentation.world_menu_gui_world = world
        presentation.world_menu_material = material
    end
    if not presentation.world_menu_anchor then
        local yaw_rotation = Quaternion.axis_angle(
            Vector3.up(), Quaternion.yaw(rotation))
        local forward = Quaternion.forward(yaw_rotation)
        local tm = Matrix4x4.identity()
        -- Darktide's Gui 2D coordinates occupy transform X/Z (see
        -- UIRenderer.draw_rect_rotated, which maps screen Y to translation Z).
        -- The previous basis put transform Z along -camera-forward and made
        -- the menu lie on the floor. Keep X camera-right, Z world-up and the
        -- transform normal on horizontal camera-forward.
        Matrix4x4.set_right(tm, Quaternion.right(yaw_rotation))
        Matrix4x4.set_forward(tm, forward)
        Matrix4x4.set_up(tm, Vector3.up())
        Matrix4x4.set_translation(tm, position + forward * 2)
        presentation.world_menu_anchor = Matrix4x4Box(tm)
    end
    local tm = presentation.world_menu_anchor:unbox()
    local width = 2
    local height = width * 9 / 16
    -- The render-target mask material normally derives UVs from screen
    -- position.  That is correct for a fullscreen 2D composite, but a world
    -- GUI has no corresponding screen-space rectangle and sampled black in
    -- the previous Gui.bitmap_3d path.  Gui2's 3D overload exposes the same
    -- explicit local UV contract used by the working SBS compositor.
    Gui2.bitmap_3d(
        presentation.world_menu_gui,
        presentation.world_menu_material,
        GuiMaterialFlag.GUI_RENDER_PASS_LAYER,
        tm,
        1000,
        {
            color = Color(255, 255, 255, 255),
            position_offset = Vector3(-width * 0.5, -height * 0.5, 0),
            size = Vector2(width, height),
            uv00 = Vector2(0, 0),
            uv11 = Vector2(1, 1),
        })
    -- A world-owned opaque backing plane makes the geometry independently
    -- observable if the menu render target is transparent or not yet ready.
    -- It also prevents the live scene from reducing menu legibility without
    -- applying any post-process blur to either eye.
    Gui.rect_3d(
        presentation.world_menu_gui,
        tm,
        Vector2(-width * 0.5, -height * 0.5),
        999,
        Vector2(width, height),
        Color(255, 8, 10, 12))
    if not presentation.world_menu_draw_logged then
        presentation.world_menu_draw_logged = true
        mod:info(
            "DARKTIDEVR_WORLD_MENU active width=%.3f height=%.3f distance=2.000",
            width,
            height)
    end
end

function presentation.classify_active_view(manager, view_name)
    if view_name == "cutscene_view" and presentation.cinematic_stereo_active() then
        -- An in-engine cinematic keeps the stereo world: the game camera
        -- leads translation and yaw, the headset adds its own rotation.
        return nil
    end
    if presentation.flat_loading_views[view_name] then
        return 2, "loading_or_cinematic"
    end
    local native_mode = presentation.native_menu_mode and presentation.native_menu_mode(view_name)
    if native_mode then
        return native_mode, "registered_menu_family"
    end
    if presentation.direct_menu_surface_views[view_name] then
        return 4, "direct_menu_surface_probe"
    end
    if presentation.native_aspect_shop_panel_views[view_name] then
        return 6, "native_aspect_shop_panel"
    end
    if presentation.shop_panel_views[view_name] or
            view_name == "crafting_view" or
            string.find(view_name, "crafting_", 1, true) == 1 then
        -- The captured-client mode-5 route is proven through Hadron. Explicit
        -- family membership keeps each facility on that same panel while its
        -- landing/background view hands off to nested interactive children.
        return 5, "native_window_shop_panel"
    end
    if presentation.flat_panel_views[view_name] then
        return 5, "interactive_flat_fallback"
    end
    if presentation.non_gameplay_views[view_name] then
        return 5, "non_gameplay_interactive_flat_fallback"
    end
    if presentation.vendor_anchor.valid and
            (presentation.vendor_anchor.view_name == view_name or
                (presentation.vendor_anchor.view_name == "crafting_view" and
                    string.find(view_name, "crafting_", 1, true) == 1)) then
        -- Crafting children share their parent's renderer and presentation
        -- world. Keep the entire view family on the NPC-relative anchor;
        -- treating a child as a generic mode-4 menu made the panel jump from
        -- world space to a new head-relative pose during tab transitions.
        return 3, "interacted_world_anchor"
    end
    if presentation.world_menu_views[view_name] then
        return 4, "world_preserved_menu"
    end

    local settings = nil
    local handler = manager and manager._view_handler
    if handler and handler.settings_by_view_name then
        local ok, value = pcall(handler.settings_by_view_name, handler, view_name)
        if ok then
            settings = value
        end
    end
    local disables_world = settings and settings.disable_game_world == true
    local explicit = presentation.explicit_flat_menu_views[view_name] == true
    -- View identity and settings are authoritative. The shared `active` flag
    -- tracks whichever stereo world was most recently constructed and can be
    -- cleared by destruction of the old character-select world after the hub
    -- camera is already live.
    local classification = (disables_world or explicit) and 5 or nil
    if not presentation.logged_view_classification[view_name] then
        presentation.logged_view_classification[view_name] = true
        mod:info(
            "DARKTIDEVR_PRESENTATION classify view=%s class=%s disable_game_world=%s allow_hud=%s",
            tostring(view_name),
            classification == 5 and "interactive_flat_fallback" or "ignored",
            tostring(settings and settings.disable_game_world),
            tostring(settings and settings.allow_hud)
        )
    end
    return classification, disables_world and "disable_game_world" or
        (explicit and "explicit" or "spatial_or_hud")
end

function presentation.reconcile_fullscreen_views(manager)
    if not ui_native_capture or not manager or not manager.active_views then
        return
    end
    local ok, views = pcall(manager.active_views, manager)
    if not ok or type(views) ~= "table" then
        return
    end

    local classified = {}
    local desired_mode = nil
    local observed_world_menu_views = {}
    for i = 1, #views do
        local view_name = views[i]
        local mode, reason = presentation.classify_active_view(manager, view_name)
        if mode then
            classified[#classified + 1] = tostring(view_name) .. ":" .. reason
            if mode == 2 then
                -- Loading/cinematic content is non-interactive and must win a
                -- one-update overlap with a closing interactive view.
                desired_mode = mode
            elseif (mode == 5 or mode == 6) and desired_mode ~= 2 and
                    desired_mode ~= 4 then
                desired_mode = mode
            elseif mode == 3 or mode == 4 then
                observed_world_menu_views[view_name] = true
                -- Interactive menus keep the stereo projection alive, but the
                -- compositor still needs their distinct presentation mode in
                -- order to attach the additive shared-menu quad.  Recording
                -- the view without selecting its mode left the producer
                -- publishing menu frames that no consumer ever opened.
                desired_mode = mode
            end
        end
    end
    -- Custom HUD is a HUD element, not a registered fullscreen view. Route
    -- its desktop editor through the same full-window path as native menus so
    -- packed DLSS world presentation cannot overwrite or crop its overlay.
    if not desired_mode and presentation.hud_panel and presentation.hud_panel.editing() then
        desired_mode = 5
        classified[#classified + 1] = "custom_hud:desktop_editor"
    end
    -- Confirmation popups (the training grounds "continue?" question, party
    -- and matchmaking prompts) are constant elements, not views. In the
    -- stereo world they were drawn only on the desktop canvas, which stalled
    -- the training at its end. Present them on the interactive flat panel,
    -- and let them outrank a loading board or a cutscene view too: the hub's
    -- "summoned to the strategium" notice arrives while the Path of Trust
    -- cutscene view is already open and waits for its Obey button, so a
    -- non-interactive panel left it unanswerable.
    local active_popups = manager and manager._active_popups
    if active_popups and active_popups[1] and desired_mode ~= 5 and desired_mode ~= 6 then
        desired_mode = 5
        classified[#classified + 1] = "popup:" .. tostring(active_popups[1].id or "active")
    end
    -- The survival-mode buff choice is a constant element, like the popups:
    -- while a choice is open and unanswered, present it on the interactive
    -- panel so it takes the pointer (hover, and aim and RT on a card) as
    -- every other menu does. Unanswered, the stock timer picks at random.
    if desired_mode ~= 5 and desired_mode ~= 6 and presentation.mission_buff_choice_open(manager) then
        desired_mode = 5
        classified[#classified + 1] = "mission_buffs:choice"
    end
    presentation.world_menu_views = observed_world_menu_views
    local signature = table.concat(classified, ",")
    if signature ~= presentation.fullscreen_view_signature then
        presentation.fullscreen_view_signature = signature
        mod:info(
            "DARKTIDEVR_PRESENTATION fullscreen_stack count=%d views=%s",
            #classified,
            signature ~= "" and signature or "none"
        )
    end

    if desired_mode then
        presentation.fullscreen_empty_updates = 0
        presentation.publish_mode(desired_mode, signature)
    else
        -- publish_mode internally rate-limits unchanged state to the transport
        -- heartbeat. Calling it here even after stereo mode is established is
        -- what lets the compositor distinguish a healthy mod from a stopped
        -- Lua producer while the game process itself remains alive.
        presentation.publish_mode(1, "stereo_world")
    end
end

function presentation.mission_buff_choice_open(manager)
    local constants = manager and manager._ui_constant_elements
    if not constants and manager and manager.ui_constant_elements then
        local ok, value = pcall(manager.ui_constant_elements, manager)
        constants = ok and value or nil
    end
    local element = constants and constants._elements and
        constants._elements.ConstantElementMissionBuffs
    local context = element and element._context
    -- The element holds input (`_using_input`) only while a live choice is
    -- shown; its context outlives the choice.
    return context ~= nil and context.is_choice == true and not context.buff_chosen and
        element._using_input == true and element._is_visible ~= false and
        not (element._states and element._states.view == "inactive")
end

function presentation.on_view_open(manager, view_name)
    local active_ok, is_active = pcall(manager.view_active, manager, view_name)
    mod:info(
        "DARKTIDEVR_PRESENTATION open view=%s active=%s",
        tostring(view_name),
        tostring(active_ok and is_active)
    )
    if active_ok and is_active then
        if view_name == "main_menu_view" or
                view_name == "main_menu_background_view" or
                presentation.shop_panel_views[view_name] or
                view_name == "crafting_view" or
                string.find(view_name, "crafting_", 1, true) == 1 then
            presentation.flat_panel_views[view_name] = true
        end
        if ensure_ui_native_hooks() and
                ui_native_capture.dtvr_set_vendor_menu_widget_capture then
            if view_name == "crafting_view" then
                local view = manager:view_instance(view_name)
                presentation.vendor_ui_renderer = view and view._ui_renderer
                presentation.vendor_resource_enabled = false
                ui_native_capture.dtvr_set_vendor_menu_widget_capture(0)
                presentation.vendor_widget_scope_enabled = false
                if presentation.native_export(ui_native_capture, "dtvr_set_menu_direct_capture") then
                    ui_native_capture.dtvr_set_menu_direct_capture(0)
                end
                presentation.world_menu_anchor = nil
                presentation.world_menu_draw_logged = false
                mod:info(
                    "DARKTIDEVR_MENU_CAPTURE window_panel view=%s enabled=true renderer=%s",
                    tostring(view_name),
                    tostring(view and view._ui_renderer and
                        view._ui_renderer.name))
            elseif string.find(view_name, "crafting_", 1, true) == 1 then
                ui_native_capture.dtvr_set_vendor_menu_widget_capture(0)
                presentation.vendor_widget_scope_enabled = false
                local child_view = manager:view_instance(view_name)
                presentation.vendor_resource_enabled = false
                presentation.world_menu_anchor = nil
                presentation.world_menu_draw_logged = false
                if presentation.native_export(ui_native_capture, "dtvr_set_menu_direct_capture") then
                    ui_native_capture.dtvr_set_menu_direct_capture(0)
                end
                mod:info(
                    "DARKTIDEVR_MENU_CAPTURE window_panel view=%s enabled=true renderer=%s",
                    tostring(view_name),
                    tostring(child_view and child_view._ui_renderer and
                        child_view._ui_renderer.name))
            end
        end
        local mode, reason = presentation.classify_active_view(manager, view_name)
        if mode then
            presentation.fullscreen_empty_updates = 0
            if mode == 2 or mode == 5 or mode == 6 then
                presentation.publish_mode(mode, tostring(view_name) .. ":" .. reason)
            else
                presentation.world_menu_views[view_name] = true
                presentation.publish_mode(
                    mode, tostring(view_name) .. ":world_space_menu")
            end
        end
    end
end

function presentation.on_view_close(manager, view_name)
    mod:info(
        "DARKTIDEVR_PRESENTATION close view=%s",
        tostring(view_name)
    )
    local vendor_anchor = presentation.vendor_anchor
    presentation.flat_panel_views[view_name] = nil
    if ensure_ui_native_hooks() and
            ui_native_capture.dtvr_set_vendor_menu_widget_capture and
            string.find(view_name, "crafting_", 1, true) == 1 then
        local base_active = manager:view_active("crafting_view")
        if presentation.vendor_resource_enabled then
            mod:info(
                "DARKTIDEVR_MENU_TARGET vendor_family_resource view=%s result=closed base_active=%s",
                tostring(view_name),
                tostring(base_active))
        end
        presentation.vendor_resource_enabled = base_active and
            presentation.menu_resource_renderer ~= nil
        ui_native_capture.dtvr_set_vendor_menu_widget_capture(0)
        presentation.vendor_widget_scope_enabled = false
        if presentation.native_export(ui_native_capture, "dtvr_set_menu_direct_capture") then
            ui_native_capture.dtvr_set_menu_direct_capture(0)
        end
        if not base_active then
            presentation.vendor_ui_renderer = nil
        end
    end
    presentation.world_menu_views[view_name] = nil
    if vendor_anchor.valid and vendor_anchor.view_name == view_name then
        vendor_anchor.valid = false
        vendor_anchor.view_name = nil
        vendor_anchor.revision = vendor_anchor.revision + 1
        mod:info(
            "DARKTIDEVR_PRESENTATION world_anchor cleared view=%s revision=%d",
            tostring(view_name),
            vendor_anchor.revision
        )
    end
    if not presentation.world_menu_active() then
        presentation.destroy_menu_resource()
    end
    presentation.reconcile_fullscreen_views(manager)
end

function presentation.trigger_widget(manager, view_name, widget_name)
    local view = manager:view_instance(view_name)
    if not view or type(view.widgets_by_name) ~= "function" or
            type(view.widget_hotspot_content) ~= "function" then
        return false, "view_instance_not_ready"
    end
    local widgets = view:widgets_by_name()
    local widget = widgets and widgets[widget_name]
    local hotspot = widget and view:widget_hotspot_content(widget_name)
    if not widget or not hotspot then
        return false, "widget_not_ready"
    end
    if hotspot.disabled then
        return false, "widget_disabled"
    end
    if type(hotspot.pressed_callback) ~= "function" then
        return false, "pressed_callback_missing"
    end
    local ok, error_message = pcall(hotspot.pressed_callback)
    if not ok then
        return false, tostring(error_message)
    end
    return true, nil
end

function presentation.trigger_option(manager, view_name, display_name)
    local view = manager:view_instance(view_name)
    local definitions = view and view._base_definitions
    local options = definitions and definitions.button_options_definitions
    if type(options) ~= "table" then
        return false, "option_definitions_not_ready"
    end
    for index = 1, #options do
        local option = options[index]
        if option and option.display_name == display_name then
            local widget_name = "option_button_" .. tostring(index)
            local ok, reason = presentation.trigger_widget(
                manager, view_name, widget_name)
            if ok then
                mod:info(
                    "DARKTIDEVR_PSYKHANIUM selected option=%s index=%d widget=%s",
                    tostring(display_name), index, widget_name)
            end
            return ok, reason
        end
    end
    return false, "semantic_option_missing"
end

function presentation.update_psykhanium(manager, t)
    local state = presentation.psykhanium
    if (state.stage == "idle" or state.stage == "blocked" or
            state.stage == "complete") and Mods and Mods.lua and Mods.lua.io and
            t >= (state.flag_last_poll_t or -math.huge) + 0.25 then
        state.flag_last_poll_t = t
        local flag_path =
            "./../mods/darktidevr/darktidevr_enter_psykhanium.flag"
        local flag = Mods.lua.io.open(flag_path, "r")
        if flag then
            local request = flag:read("*all")
            flag:close()
            if string.find(request or "", "enter", 1, true) then
                local consumed = Mods.lua.io.open(flag_path, "w")
                if consumed then
                    consumed:write("consumed\n")
                    consumed:close()
                end
                state.stage = "wait_for_hub"
                -- Steam/launcher/login startup can exceed five minutes during
                -- unattended runs. Keep the one-shot armed until the hub is
                -- genuinely ready; later stages retain their short deadlines.
                state.deadline = t + 1200
                state.last_error = nil
                mod:info("DARKTIDEVR_PSYKHANIUM armed source=one_shot_flag")
            end
        end
    end
    if state.stage == "idle" or state.stage == "complete" or
            state.stage == "blocked" then
        return
    end
    if t > state.deadline then
        state.stage = "blocked"
        state.last_error = "timeout"
        mod:error("DARKTIDEVR_PSYKHANIUM blocked reason=timeout")
        return
    end

    if state.stage == "wait_for_hub" then
        if presentation.current_game_mode_name() ~= "hub" then return end
        local auth_ok, authenticated = pcall(function()
            local backend = Managers and Managers.backend
            return backend and backend:authenticated()
        end)
        if not auth_ok or not authenticated then
            return
        end
        state.stage = "open_training_view"
        state.deadline = t + 20
        mod:info("DARKTIDEVR_PSYKHANIUM stage=open_training_view")
    end

    if state.stage == "open_training_view" then
        if manager:view_active("training_grounds_view") then
            state.stage = "select_shooting_range"
            state.deadline = t + 20
            mod:info("DARKTIDEVR_PSYKHANIUM stage=select_shooting_range")
            return
        end
        local ok, result = pcall(
            manager.open_view, manager, "training_grounds_view")
        if not ok then
            state.stage = "blocked"
            state.last_error = tostring(result)
            mod:error(
                "DARKTIDEVR_PSYKHANIUM blocked stage=open_training_view error=%s",
                state.last_error)
        else
            state.stage = "wait_training_view"
            state.deadline = t + 20
            mod:info("DARKTIDEVR_PSYKHANIUM stage=wait_training_view")
        end
        return
    end

    if state.stage == "wait_training_view" and
            manager:view_active("training_grounds_view") then
        state.stage = "select_shooting_range"
    end
    if state.stage == "select_shooting_range" then
        local ok, reason = presentation.trigger_option(
            manager,
            "training_grounds_view",
            "loc_training_grounds_view_shooting_range_text")
        if ok then
            state.stage = "wait_options_view"
            state.deadline = t + 20
            mod:info("DARKTIDEVR_PSYKHANIUM stage=wait_options_view")
        elseif reason == "widget_disabled" then
            state.stage = "blocked"
            state.last_error = reason
            mod:error(
                "DARKTIDEVR_PSYKHANIUM blocked stage=select_shooting_range reason=%s",
                reason)
        end
        return
    end

    if state.stage == "wait_options_view" and
            manager:view_active("training_grounds_options_view") then
        local options_view = manager:view_instance("training_grounds_options_view")
        local mechanism_context = options_view and options_view._context and
            options_view._context.mechanism_context
        local mission_name = mechanism_context and mechanism_context.mission_name
        if mission_name ~= "tg_shooting_range" then
            state.stage = "blocked"
            state.last_error = "unexpected_mission:" .. tostring(mission_name)
            mod:error(
                "DARKTIDEVR_PSYKHANIUM blocked stage=verify_options mission=%s",
                tostring(mission_name))
            return
        end
        local ok, reason = presentation.trigger_widget(
            manager, "training_grounds_options_view", "play_button")
        if ok then
            state.stage = "wait_shooting_range"
            state.deadline = t + 90
            mod:info("DARKTIDEVR_PSYKHANIUM stage=wait_shooting_range")
        elseif reason == "widget_disabled" then
            state.stage = "blocked"
            state.last_error = reason
            mod:error(
                "DARKTIDEVR_PSYKHANIUM blocked stage=play reason=%s", reason)
        end
        return
    end

    if state.stage == "wait_shooting_range" then
        local game_mode = presentation.current_game_mode_name()
        local mission_ok, mission_name = pcall(function()
            local mission = Managers and Managers.state and Managers.state.mission
            return mission and mission:mission_name()
        end)
        if game_mode == "shooting_range" and mission_ok and
                mission_name == "tg_shooting_range" then
            state.stage = "complete"
            state.last_error = nil
            mod:info(
                "DARKTIDEVR_PSYKHANIUM result=pass game_mode=%s mission=%s",
                tostring(game_mode), tostring(mission_name))
        end
    end
end

-- Test-only: apply a DLSS quality change the way the options menu does, from
-- a flag file, so the live quality-change FG failure can be reproduced in the
-- simulator. Mirrors scripts/settings/options/settings_utils.lua without
-- saving user settings to disk.
function presentation.update_dlss_quality_test()
    if not Mods or not Mods.lua or not Mods.lua.io then
        return
    end
    presentation.dlss_quality_test_poll_updates =
        (presentation.dlss_quality_test_poll_updates or 0) + 1
    if presentation.dlss_quality_test_poll_updates < 15 then
        return
    end
    presentation.dlss_quality_test_poll_updates = 0

    local flag_path =
        "./../mods/darktidevr/darktidevr_set_dlss_quality.flag"
    local flag = Mods.lua.io.open(flag_path, "r")
    if not flag then
        return
    end
    local request = flag:read("*all")
    flag:close()
    local quality = string.match(request or "", "^%s*([%a_]+)")
    local allowed = {
        auto = true, ultra_performance = true, performance = true,
        balanced = true, quality = true, dlaa = true,
        -- Frame-generation toggle, applied the way the options menu's
        -- dlss_g entry does (test only, same flag).
        fg_off = true, fg_on = true,
    }
    if not quality or not allowed[quality] then
        return
    end
    local consumed = Mods.lua.io.open(flag_path, "w")
    if consumed then
        consumed:write("consumed\n")
        consumed:close()
    end

    local ok, error_message = pcall(function()
        if quality == "fg_off" or quality == "fg_on" then
            local enabled = quality == "fg_on"
            Application.set_user_setting("master_render_settings", "dlss_g", enabled and 1 or 0)
            Application.set_user_setting("render_settings", "dlss_g_enabled", enabled)
            Application.set_render_setting("dlss_g_enabled", enabled and "true" or "false")
            if enabled then
                Application.set_user_setting("render_settings", "dlss_g_frames_to_generate", 1)
                Application.set_render_setting("dlss_g_frames_to_generate", "1")
            end
        else
            Application.set_user_setting("render_settings", "dlss_enabled", true)
            Application.set_render_setting("dlss_enabled", "true")
            Application.set_user_setting("render_settings", "upscaling_quality", quality)
            Application.set_render_setting("upscaling_quality", quality)
        end
        Application.apply_user_settings()
        Renderer.bake_static_shadows()
        if Managers and Managers.event then
            Managers.event:trigger("event_on_render_settings_applied")
        end
    end)
    mod:info(
        "DARKTIDEVR_STEREO dlss_quality_change value=%s result=%s",
        quality, ok and "applied" or tostring(error_message)
    )
end

function presentation.update_system_menu_test(manager)
    if not Mods or not Mods.lua or not Mods.lua.io then
        return
    end
    presentation.system_menu_test_poll_updates =
        (presentation.system_menu_test_poll_updates or 0) + 1
    if presentation.system_menu_test_poll_updates < 15 then
        return
    end
    presentation.system_menu_test_poll_updates = 0

    local flag_path =
        "./../mods/darktidevr/darktidevr_open_system_menu.flag"
    local flag = Mods.lua.io.open(flag_path, "r")
    if not flag then
        return
    end

    local request = flag:read("*all")
    flag:close()
    local command = string.match(request or "", "^%s*(%a+)")
    if command ~= "open" and command ~= "close" then
        return
    end

    local consumed = Mods.lua.io.open(flag_path, "w")
    if consumed then
        consumed:write("consumed\n")
        consumed:close()
    end

    local active = manager:view_active("system_view")
    if command == "close" then
        if not active then
            mod:info(
                "DARKTIDEVR_MENU_INPUT system_menu_test result=already_closed")
            return
        end
        local ok, result = pcall(manager.close_view, manager, "system_view")
        if ok then
            mod:info(
                "DARKTIDEVR_MENU_INPUT system_menu_test result=close_requested")
        else
            mod:error(
                "DARKTIDEVR_MENU_INPUT system_menu_test result=close_failed error=%s",
                tostring(result))
        end
        return
    end

    if active then
        mod:info(
            "DARKTIDEVR_MENU_INPUT system_menu_test result=already_active")
        return
    end

    local ok, result = pcall(manager.open_view, manager, "system_view")
    if ok then
        mod:info(
            "DARKTIDEVR_MENU_INPUT system_menu_test result=requested")
    else
        mod:error(
            "DARKTIDEVR_MENU_INPUT system_menu_test result=failed error=%s",
            tostring(result))
    end
end

function presentation.update_vendor_menu_test(manager)
    if not Mods or not Mods.lua or not Mods.lua.io then
        return
    end

    local pending_close = presentation.vendor_menu_close_pending
    if pending_close then
        local child_active = pending_close.child_name and
            manager:view_active(pending_close.child_name)
        if child_active and pending_close.frames > 0 then
            pending_close.frames = pending_close.frames - 1
            return
        end
        if child_active then
            presentation.vendor_menu_close_pending = nil
            mod:error(
                "DARKTIDEVR_MENU_INPUT vendor_menu_test result=child_close_timeout view=%s parent=%s",
                tostring(pending_close.child_name),
                tostring(pending_close.view_name))
            return
        end
        presentation.vendor_menu_close_pending = nil
        local ok, result = pcall(
            manager.close_view, manager, pending_close.view_name)
        mod:info(
            "DARKTIDEVR_MENU_INPUT vendor_menu_test result=%s view=%s detail=%s",
            ok and "parent_close_requested" or "parent_close_failed",
            tostring(pending_close.view_name), tostring(result))
        if ok then
            presentation.vendor_menu_test_view = nil
        end
        return
    end

    presentation.vendor_menu_test_poll_updates =
        (presentation.vendor_menu_test_poll_updates or 0) + 1
    if presentation.vendor_menu_test_poll_updates < 15 then
        return
    end
    presentation.vendor_menu_test_poll_updates = 0

    local flag_path =
        "./../mods/darktidevr/darktidevr_open_vendor_menu.flag"
    local flag = Mods.lua.io.open(flag_path, "r")
    if not flag then
        return
    end
    local request = flag:read("*all")
    flag:close()
    local command = string.match(request or "", "^%s*([%a_]+)")
    local allowed = {
        crafting = "crafting_view",
        contracts = "contracts_background_view",
        armoury = "credits_vendor_background_view",
        cosmetics = "cosmetics_vendor_background_view",
        barber = "barber_vendor_background_view",
        store = "store_view",
        penances = "penance_overview_view",
        psykhanium = "training_grounds_view",
    }
    if command ~= "close" and command ~= "crafting_widgets" and
            command ~= "crafting_entreat" and not allowed[command] then
        return
    end

    local consumed = Mods.lua.io.open(flag_path, "w")
    if consumed then
        consumed:write("consumed\n")
        consumed:close()
    end

    if command == "close" then
        local view_name = presentation.vendor_menu_test_view
        if not view_name or not manager:view_active(view_name) then
            mod:info(
                "DARKTIDEVR_MENU_INPUT vendor_menu_test result=already_closed")
            presentation.vendor_menu_test_view = nil
            return
        end
        local active_ok, active_views = pcall(manager.active_views, manager)
        if active_ok and type(active_views) == "table" then
            for index = #active_views, 1, -1 do
                local child_name = active_views[index]
                if child_name ~= view_name and
                        (string.find(child_name, "crafting_", 1, true) == 1 or
                            presentation.shop_panel_views[child_name] or
                            presentation.native_aspect_shop_panel_views[
                                child_name]) then
                    local ok, result = pcall(
                        manager.close_view, manager, child_name)
                    mod:info(
                        "DARKTIDEVR_MENU_INPUT vendor_menu_test result=%s view=%s parent=%s detail=%s",
                        ok and "child_close_requested" or
                            "child_close_failed",
                        tostring(child_name), tostring(view_name),
                        tostring(result))
                    if ok then
                        presentation.vendor_menu_close_pending = {
                            view_name = view_name,
                            child_name = child_name,
                            frames = 120,
                        }
                    end
                    return
                end
            end
        end
        local ok, result = pcall(manager.close_view, manager, view_name)
        mod:info(
            "DARKTIDEVR_MENU_INPUT vendor_menu_test result=%s view=%s detail=%s",
            ok and "close_requested" or "close_failed",
            tostring(view_name), tostring(result))
        if ok then
            presentation.vendor_menu_test_view = nil
        end
        return
    end

    if command == "crafting_widgets" or command == "crafting_entreat" then
        local view_name = "crafting_view"
        if not manager:view_active(view_name) then
            mod:error(
                "DARKTIDEVR_MENU_INPUT vendor_menu_test result=view_not_active view=%s command=%s",
                view_name, tostring(command))
            return
        end
        local view = manager:view_instance(view_name)
        local widgets = view and type(view.widgets_by_name) == "function" and
            view:widgets_by_name()
        if type(widgets) ~= "table" then
            mod:error(
                "DARKTIDEVR_MENU_INPUT vendor_menu_test result=widgets_not_ready view=%s",
                view_name)
            return
        end
        local names = {}
        for name, widget in pairs(widgets) do
            local hotspot = type(view.widget_hotspot_content) == "function" and
                view:widget_hotspot_content(name)
            names[#names + 1] = string.format(
                "%s(callback=%s disabled=%s)",
                tostring(name),
                tostring(hotspot and type(hotspot.pressed_callback) == "function"),
                tostring(hotspot and hotspot.disabled))
        end
        table.sort(names)
        mod:info(
            "DARKTIDEVR_MENU_INPUT vendor_menu_widgets view=%s widgets=%s",
            view_name, table.concat(names, ","))
        if command == "crafting_widgets" then
            return
        end
        presentation.vendor_widget_scope_enabled = false
        if ensure_ui_native_hooks() then
            if presentation.native_export(ui_native_capture, "dtvr_set_vendor_menu_widget_capture") then
                ui_native_capture.dtvr_set_vendor_menu_widget_capture(0)
            end
            if presentation.native_export(ui_native_capture, "dtvr_set_menu_direct_capture") then
                ui_native_capture.dtvr_set_menu_direct_capture(0)
            end
        end
        local ok, reason = presentation.trigger_widget(
            manager, view_name, "option_button_1")
        mod:info(
            "DARKTIDEVR_MENU_INPUT vendor_menu_test result=%s view=%s widget=option_button_1 detail=%s",
            ok and "submenu_requested" or "submenu_failed",
            view_name, tostring(reason))
        return
    end

    local view_name = allowed[command]
    if manager:view_active(view_name) then
        mod:info(
            "DARKTIDEVR_MENU_INPUT vendor_menu_test result=already_active view=%s",
            view_name)
        presentation.vendor_menu_test_view = view_name
        return
    end

    -- This guarded diagnostic has no physical interactee from which to derive
    -- a vendor anchor. Keep it on the generic horizon-locked board while the
    -- view's native shader batch is traced; real ViewInteraction opens still
    -- use the NPC-relative mode-3 anchor.
    presentation.world_menu_views[view_name] = true
    presentation.vendor_menu_test_view = view_name
    local ok, result = pcall(manager.open_view, manager, view_name)
    if ok then
        mod:info(
            "DARKTIDEVR_MENU_INPUT vendor_menu_test result=requested view=%s",
            view_name)
    else
        presentation.world_menu_views[view_name] = nil
        presentation.vendor_menu_test_view = nil
        mod:error(
            "DARKTIDEVR_MENU_INPUT vendor_menu_test result=failed view=%s error=%s",
            view_name, tostring(result))
    end
end

-- A dev diagnostic armed by a flag file. It used to try to open that file on
-- every InputManager update: with no file present, which is every player, a
-- failed open on the main thread each frame, and the frame profiler put the
-- hook at 64 us in the Hub (docs/LUA-FRAME-PROFILE-2026-09-16.md). Polled
-- every INPUT_FLAG_POLL updates now; nothing waits on it faster than that.
presentation.INPUT_FLAG_POLL = 300
function presentation.scan_input_services(manager)
    if presentation.input_inventory_done or not Mods or not Mods.lua or
            not Mods.lua.io then
        return
    end
    presentation.input_inventory_poll = (presentation.input_inventory_poll or 0) + 1
    if presentation.input_inventory_poll < presentation.INPUT_FLAG_POLL then return end
    presentation.input_inventory_poll = 0
    local flag_path =
        "./../mods/darktidevr/darktidevr_input_inventory.flag"
    local flag = Mods.lua.io.open(flag_path, "r")
    if not flag then
        return
    end
    local request = flag:read("*all")
    flag:close()
    if not string.find(request or "", "scan", 1, true) then
        return
    end
    local consumed = Mods.lua.io.open(flag_path, "w")
    if consumed then
        consumed:write("consumed\n")
        consumed:close()
    end
    presentation.input_inventory_done = true
    local services = manager and manager._input_services or {}
    for service_name, service in pairs(services) do
        local fields = {}
        for key, value in pairs(service) do
            fields[#fields + 1] = tostring(key) .. ":" .. type(value)
        end
        table.sort(fields)
        while #fields > 80 do
            table.remove(fields)
        end
        mod:info(
            "DARKTIDEVR_INPUT inventory service=%s fields=%s",
            tostring(service_name),
            table.concat(fields, ",")
        )
        for field_name, values in pairs(service) do
            local lower_name = string.lower(tostring(field_name))
            if type(values) == "table" and
                    (string.find(lower_name, "action", 1, true) or
                     string.find(lower_name, "alias", 1, true)) then
                local names = {}
                for name in pairs(values) do
                    local lower = string.lower(tostring(name))
                    if string.find(lower, "action", 1, true) or
                            string.find(lower, "attack", 1, true) or
                            string.find(lower, "weapon", 1, true) or
                            string.find(lower, "shoot", 1, true) then
                        names[#names + 1] = tostring(name)
                    end
                end
                table.sort(names)
                while #names > 100 do
                    table.remove(names)
                end
                mod:info(
                    "DARKTIDEVR_INPUT inventory service=%s table=%s names=%s",
                    tostring(service_name),
                    tostring(field_name),
                    table.concat(names, ",")
                )
            end
        end
    end
    mod:info("DARKTIDEVR_INPUT inventory result=complete")
end

-- Diagnostic one-shot actions retained from menu-input localization. The
-- production path below no longer depends on Windows cursor or raw-input
-- coordinates: OpenXR publishes source pixels and Lua activates the matching
-- engine widget through force_input_pressed.
function presentation.update_menu_input_probe(manager)
    local probe = presentation.menu_input_probe
    probe.poll_updates = (probe.poll_updates or 0) + 1
    -- The same slow poll as the inventory scan above: this is a dev probe
    -- armed by a flag, and a file open every 15 updates was the second
    -- largest piece of the hook's cost.
    if probe.poll_updates >= presentation.INPUT_FLAG_POLL and Mods and Mods.lua and Mods.lua.io then
        probe.poll_updates = 0
        local flag_path =
            "./../mods/darktidevr/darktidevr_menu_input_probe.flag"
        local flag = Mods.lua.io.open(flag_path, "r")
        if flag then
            local request = flag:read("*all")
            flag:close()
            local action = request and request:match("^%s*([%w_]+)%s*$")
            if action and action ~= "consumed" then
                local consumed = Mods.lua.io.open(flag_path, "w")
                if consumed then
                    consumed:write("consumed\n")
                    consumed:close()
                end
                probe.action = action
                probe.stage = "press"
                mod:info(
                    "DARKTIDEVR_MENU_INPUT probe armed action=%s",
                    tostring(action))
            end
        end
    end
end

function presentation.apply_menu_pointer_probe(pointer)
    local probe = presentation.menu_input_probe
    if probe.stage ~= "press" and probe.stage ~= "armed" then
        return pointer
    end
    local x, y, width, height = string.match(
        probe.action or "", "^pointer_(%d+)_(%d+)_(%d+)_(%d+)$")
    x = tonumber(x)
    y = tonumber(y)
    width = tonumber(width)
    height = tonumber(height)
    if not x or not y or not width or not height or width <= 0 or height <= 0 then
        probe.stage = "idle"
        probe.action = nil
        return pointer
    end
    if probe.stage == "press" then
        probe.sequence = math.max(
            tonumber(probe.sequence) or 0,
            tonumber(pointer.primary_press_sequence) or 0) + 1
        probe.stage = "armed"
        mod:info(
            "DARKTIDEVR_MENU_INPUT probe pointer=%d,%d/%dx%d sequence=%d",
            x, y, width, height, probe.sequence)
    end
    -- Native pointer reads occur independently in each hooked UI pass. Keep
    -- the diagnostic edge stable across those reads until the semantic owner
    -- consumes it; otherwise BaseView.update observes the edge and the later
    -- Store grid sees the native sequence again.
    pointer.primary_press_sequence = probe.sequence
    pointer.last_sequence = probe.sequence
    pointer.x = x
    pointer.y = y
    pointer.source_width = width
    pointer.source_height = height
    pointer.available = true
    pointer.active = x >= 0 and x < width and y >= 0 and y < height
    pointer.primary_pressed = pointer.primary_press_sequence ~=
        pointer.primary_consumed_sequence
    return pointer
end

function presentation.read_menu_pointer()
    local pointer = presentation.menu_pointer
    -- All widget passes in this UI frame resolve the same ray and edge.
    -- Resampling after a miss could move that edge onto a different control.
    if not presentation.claim_menu_pointer_sample(pointer) then
        return pointer
    end
    pointer.available = false
    pointer.active = false
    pointer.primary_pressed = false
    pointer.back_pressed = false
    pointer.secondary_pressed = false
    pointer.scroll_steps = 0
    if not ui_native_capture or not pointer.values or
            not pointer.read_state then
        return presentation.apply_menu_pointer_probe(pointer)
    end
    local read_result = nil
    if pointer.read_state_v3 then
        read_result = pointer.read_state(pointer.values, 13, pointer.sequence,
            pointer.timestamp_ns, pointer.transport_generation_value)
    elseif pointer.read_state_v2 then
        read_result = pointer.read_state(
            pointer.values,
            pointer.sequence,
            pointer.timestamp_ns,
            pointer.transport_generation_value)
    else
        read_result = pointer.read_state(
            pointer.values,
            pointer.sequence,
            pointer.timestamp_ns)
    end
    if read_result ~= 0 then
        return presentation.apply_menu_pointer_probe(pointer)
    end
    local sequence = tonumber(pointer.sequence[0])
    local timestamp_ns = tonumber(pointer.timestamp_ns[0])
    local transport_generation =
        tonumber(pointer.transport_generation_value[0])
    local qpc_frequency = tonumber(ui_native_capture.dtvr_qpc_frequency())
    local age_ns = math.huge
    if qpc_frequency > 0 then
        age_ns = tonumber(ui_native_capture.dtvr_qpc_ticks()) *
            1000000000 / qpc_frequency - timestamp_ns
    end
    local generation_changed =
        transport_generation ~= pointer.transport_generation
    local is_new = generation_changed or sequence ~= pointer.last_sequence
    pointer.x = tonumber(pointer.values[1])
    pointer.y = tonumber(pointer.values[2])
    pointer.source_width = tonumber(pointer.values[3])
    pointer.source_height = tonumber(pointer.values[4])
    pointer.available = age_ns >= -5000000 and age_ns <= 100000000
    pointer.active = pointer.available and tonumber(pointer.values[0]) ~= 0 and
        pointer.source_width > 0 and pointer.source_height > 0 and
        pointer.x >= 0 and pointer.x < pointer.source_width and
        pointer.y >= 0 and pointer.y < pointer.source_height
    if is_new then
        local primary_down = tonumber(pointer.values[5]) ~= 0
        local back_down = tonumber(pointer.values[6]) ~= 0
        local scroll_steps = tonumber(pointer.values[7])
        if scroll_steps >= 2147483648 then
            scroll_steps = scroll_steps - 4294967296
        end
        local primary_press_sequence = tonumber(pointer.values[8])
        local secondary_press_sequence = tonumber(pointer.values[12])
        local back_press_sequence = tonumber(pointer.values[9])
        local scroll_sequence = tonumber(pointer.values[10])
        if generation_changed then
            -- A restarted XR harness begins its edge counters at zero. Treat
            -- the first packet as a baseline, otherwise inequality against the
            -- old consumed counters synthesizes a click/back/scroll event.
            pointer.event_sequences_initialized = true
            pointer.primary_consumed_sequence = primary_press_sequence
            pointer.secondary_consumed_sequence = secondary_press_sequence
            pointer.back_consumed_sequence = back_press_sequence
            pointer.scroll_consumed_sequence = scroll_sequence
            mod:info(
                "DARKTIDEVR_MENU_INPUT event_transport_generation generation=%d primary=%d back=%d scroll=%d",
                transport_generation,
                primary_press_sequence,
                back_press_sequence,
                scroll_sequence)
        elseif not pointer.event_sequences_initialized then
            pointer.event_sequences_initialized = true
            mod:info(
                "DARKTIDEVR_MENU_INPUT event_transport_initialized primary=%d back=%d scroll=%d",
                primary_press_sequence,
                back_press_sequence,
                scroll_sequence)
        elseif primary_press_sequence ~= pointer.primary_press_sequence or
                back_press_sequence ~= pointer.back_press_sequence or
                scroll_sequence ~= pointer.scroll_sequence then
            mod:info(
                "DARKTIDEVR_MENU_INPUT event_transport_changed primary=%d back=%d scroll=%d active=%s available=%s source=%d,%d/%dx%d consumed=%d",
                primary_press_sequence,
                back_press_sequence,
                scroll_sequence,
                tostring(pointer.active),
                tostring(pointer.available),
                pointer.x,
                pointer.y,
                pointer.source_width,
                pointer.source_height,
                pointer.primary_consumed_sequence)
        end
        pointer.primary_press_sequence = primary_press_sequence
        pointer.secondary_press_sequence = secondary_press_sequence
        pointer.secondary_down = pointer.read_state_v3 and tonumber(pointer.values[11]) ~= 0
        pointer.back_press_sequence = back_press_sequence
        pointer.scroll_sequence = scroll_sequence
        pointer.transport_generation = transport_generation
        pointer.primary_down = primary_down
        pointer.back_down = back_down
        pointer.last_sequence = sequence
    end
    -- Keep an edge eligible only for this UI frame. The next update consumes
    -- any unhandled primary sequence before sampling again.
    pointer.primary_pressed = pointer.available and
        pointer.primary_press_sequence ~= pointer.primary_consumed_sequence
    pointer.secondary_pressed = pointer.available and pointer.read_state_v3 and
        pointer.secondary_press_sequence ~= pointer.secondary_consumed_sequence
    pointer.back_pressed = pointer.available and
        pointer.back_press_sequence ~= pointer.back_consumed_sequence
    if pointer.available and
            pointer.scroll_sequence ~= pointer.scroll_consumed_sequence then
        local scroll_steps = tonumber(pointer.values[7])
        if scroll_steps >= 2147483648 then
            scroll_steps = scroll_steps - 4294967296
        end
        pointer.scroll_steps = scroll_steps
    end
    return presentation.apply_menu_pointer_probe(pointer)
end

function presentation.consume_menu_secondary(pointer)
    pointer.secondary_consumed_sequence = pointer.secondary_press_sequence
    pointer.secondary_pressed = false
end

function presentation.consume_menu_primary(pointer)
    pointer.primary_consumed_sequence = pointer.primary_press_sequence
    pointer.primary_pressed = false
    local probe = presentation.menu_input_probe
    if probe.stage == "armed" then
        -- The diagnostic edge deliberately advances beyond the native
        -- transport sequence. Rejoin the native counter when the synthetic
        -- owner consumes it; otherwise the lower native value looks like a
        -- permanently unconsumed press on every following UI pass.
        if pointer.values then
            pointer.primary_consumed_sequence =
                tonumber(pointer.values[8]) or
                    pointer.primary_consumed_sequence
        end
        probe.stage = "idle"
        probe.action = nil
    end
end

function presentation.consume_menu_back(pointer)
    pointer.back_consumed_sequence = pointer.back_press_sequence
    pointer.back_pressed = false
end

function presentation.consume_menu_scroll(pointer)
    pointer.scroll_consumed_sequence = pointer.scroll_sequence
    pointer.scroll_steps = 0
end

function presentation.scroll_menu_grid(grid, steps)
    if not grid then
        return false, "missing_grid"
    end
    if steps == 0 then
        return false, "no_steps"
    end
    if not grid.can_scroll then
        return false, "missing_can_scroll"
    end
    if not grid:can_scroll() then
        return false, "not_scrollable"
    end
    if not grid.scrollbar_progress then
        return false, "missing_scrollbar_progress"
    end
    if not grid.set_scrollbar_progress then
        return false, "missing_set_scrollbar_progress"
    end
    local progress = grid:scrollbar_progress()
    if type(progress) ~= "number" then
        return false, "invalid_scrollbar_progress"
    end
    grid:set_scrollbar_progress(
        math.clamp(progress - steps * 0.1, 0, 1),
        true)
    if grid._update_scroll_progress then
        grid:_update_scroll_progress(true)
    end
    return true, "scrolled"
end

function presentation.is_top_menu_view(instance)
    local manager = Managers and Managers.ui
    if manager and manager.active_views and manager.view_instance then
        local ok, views = pcall(manager.active_views, manager)
        if ok and type(views) == "table" then
            for i = #views, 1, -1 do
                local view_ok, view = pcall(
                    manager.view_instance, manager, views[i])
                if view_ok and view then
                    return view == instance
                end
            end
        end
    end
    return presentation.active_menu_view_instance == instance
end

mod:io_dofile("darktidevr/scripts/mods/darktidevr/darktidevr_menu_widgets").install(mod, presentation)
mod:io_dofile("darktidevr/scripts/mods/darktidevr/darktidevr_menu_input").install(mod, presentation)

local function refresh_xr_render_extent()
    if not ui_native_capture or not head_pose_values or not head_pose_sequence then
        return false
    end

    if presentation.read_head_pose() ~= 0 then
        return false
    end

    local width = math.floor(tonumber(head_pose_values[17]) + 0.5)
    local height = math.floor(tonumber(head_pose_values[18]) + 0.5)
    -- NaN compares false against every range bound; reject it explicitly so
    -- it cannot replace the eye target extent.
    if width ~= width or height ~= height or
            width < 640 or width > 7680 or height < 640 or height > 7680 then
        return false
    end

    if width ~= ui_eye_target_width or height ~= ui_eye_target_height then
        mod:info(
            "DARKTIDEVR_STEREO runtime_extent %dx%d previous=%dx%d",
            width, height, ui_eye_target_width, ui_eye_target_height
        )
        ui_eye_target_width = width
        ui_eye_target_height = height
    end
    if not ui_runtime_extent_logged then
        mod:info(
            "DARKTIDEVR_STEREO render_extent source=openxr size=%dx%d",
            width, height
        )
        ui_runtime_extent_logged = true
    end
    return true
end

function presentation.read_head_pose()
    if presentation.read_head_pose_v2 then
        return presentation.read_head_pose_v2(
            head_pose_values, head_pose_sequence,
            presentation.head_pose_transport_generation)
    end
    return ui_native_capture.dtvr_read_head_pose(
        head_pose_values, head_pose_sequence)
end

function presentation.current_game_mode_name()
    return presentation.gameplay_context.game_mode_name(
        Managers and Managers.state and Managers.state.game_mode)
end

function presentation.apply_offline_benchmark_spin(rotation)
    if not presentation.offline_dual_view_requested or
            presentation.current_game_mode_name() ~= "hub" then
        presentation.offline_benchmark_start_t = nil
        return rotation
    end
    local t = Managers and Managers.time and Managers.time:time("main") or 0
    if not presentation.offline_benchmark_start_t then
        presentation.offline_benchmark_start_t = t
    end
    -- One smooth revolution every twenty seconds gives the renderer a stable,
    -- repeatable visibility/lighting workload without walking an unattended
    -- operative through a populated hub.
    local elapsed = t - presentation.offline_benchmark_start_t
    local angle = elapsed * math.pi * 0.1
    if t >= presentation.offline_benchmark_last_log_t + 20 then
        presentation.offline_benchmark_last_log_t = t
        mod:info(
            "DARKTIDEVR_PERF offline_dual_view workload=hub_spin elapsed=%.2f angle=%.4f",
            elapsed, angle)
    end
    return Quaternion.multiply(
        Quaternion.axis_angle(Vector3.up(), angle), rotation)
end

function presentation.clamp_hub_head_horizontal(x, z)
    if presentation.current_game_mode_name() ~= "hub" then
        controller_observation.hub_head_requested_horizontal = nil
        controller_observation.hub_head_applied_horizontal = nil
        return x, z
    end
    local distance = math.sqrt(x * x + z * z)
    local limit = 0.25
    controller_observation.hub_head_requested_horizontal = distance
    controller_observation.hub_head_applied_horizontal = math.min(
        distance, limit)
    if distance <= limit or distance < 0.000001 then
        return x, z
    end
    local fraction = limit / distance
    return x * fraction, z * fraction
end

local function apply_head_tracking(clean_position, clean_rotation)
    if not head_tracking_requested or not ui_native_capture or
            not head_pose_values or not head_pose_sequence then
        return clean_position, clean_rotation
    end

    local result = presentation.read_head_pose()

    if result ~= 0 then
        return clean_position, clean_rotation
    end

    local sequence = tonumber(head_pose_sequence[0])
    local transport_generation = tonumber(
        presentation.head_pose_transport_generation[0])
    if presentation.head_pose_last_transport_generation ~= 0 and
            (transport_generation ~=
                presentation.head_pose_last_transport_generation or
                sequence < head_pose_last_sequence) then
        -- The OpenXR bridge owns the shared head-pose writer and restarts its
        -- sequence at one.  Darktide can outlive that process, leaving native
        -- eye-capture tags from the previous bridge session queued ahead of
        -- the new sequence.  Since producer and consumer then advance at the
        -- same rate, the new bridge can never catch that old tag stream and
        -- rejects every otherwise-fresh pair as pose-mismatched.  Drop those
        -- obsolete tags at the observed epoch boundary before either camera
        -- is armed for this frame.
        ui_native_capture.dtvr_reset_eye_capture_tags()
        mod:info(
            "DARKTIDEVR_STEREO bridge_restart old_sequence=%d new_sequence=%d generation=%d->%d action=reset_capture_tags",
            head_pose_last_sequence,
            sequence,
            presentation.head_pose_last_transport_generation,
            transport_generation)
        presentation.head_translation_trace_last_sequence = 0
        controller_observation.body_follow_last_sequence = sequence
    end
    local render_vertical_fov = tonumber(head_pose_values[7])
    local render_aspect_ratio = tonumber(head_pose_values[8])
    if render_vertical_fov > 0 and render_vertical_fov < math.pi and
            render_aspect_ratio > 0 then
        -- Kept unzoomed: the zoom is applied to a copy below, because this
        -- value survives a frame whose sample is unusable and dividing the
        -- stored one would zoom an already zoomed value again, and again
        -- (review, 18 September).
        presentation.head_render_vertical_fov_unzoomed = render_vertical_fov
        head_render_vertical_fov = render_vertical_fov
        head_render_aspect_ratio = render_aspect_ratio
    end
    local left_frustum = {
        left = tonumber(head_pose_values[9]),
        right = tonumber(head_pose_values[10]),
        down = tonumber(head_pose_values[11]),
        up = tonumber(head_pose_values[12])
    }
    local right_frustum = {
        left = tonumber(head_pose_values[13]),
        right = tonumber(head_pose_values[14]),
        down = tonumber(head_pose_values[15]),
        up = tonumber(head_pose_values[16])
    }
    local function valid_frustum(frustum)
        return frustum.left == frustum.left and
            frustum.right == frustum.right and
            frustum.down == frustum.down and
            frustum.up == frustum.up and
            frustum.left > -math.pi * 0.5 and
            frustum.right < math.pi * 0.5 and
            frustum.down > -math.pi * 0.5 and
            frustum.up < math.pi * 0.5 and
            frustum.left < frustum.right and
            frustum.down < frustum.up
    end
    if valid_frustum(left_frustum) and valid_frustum(right_frustum) then
        -- Aim down sights magnifies by rendering a narrower cone into the same
        -- eye image (user, 18 September: "add a small zoom to ADS - maybe
        -- 10-15%"). Every consumer of the frusta -- the eye cameras, the HUD
        -- panel, the marker projection -- takes the zoomed pair, so the world
        -- and everything drawn over it stay in register; only the viewer's
        -- submitted field of view is unchanged, which is what makes it a zoom.
        local zoom = presentation.ads_zoom_magnification()
        head_render_frusta = {
            presentation.projection_math.zoomed_frustum(left_frustum, zoom),
            presentation.projection_math.zoomed_frustum(right_frustum, zoom)
        }
        local unzoomed = presentation.head_render_vertical_fov_unzoomed
        if unzoomed then
            head_render_vertical_fov = zoom > 1.0001 and
                2 * math.atan(math.tan(unzoomed * 0.5) / zoom) or unzoomed
        end
        -- Recorded, not yet believed: whether it reaches the cameras is
        -- decided where they are set.
        presentation.ads_zoom_frame = zoom
        -- NOT published here. This is the zoom that was ASKED for, and the
        -- cameras only receive it when runtime_projection_matches_target
        -- holds; when it does not, apply_runtime_recentered_projection never
        -- runs and copy_projection hands both cameras the stock unzoomed
        -- projection. Telling the viewer to narrow for a zoom that never
        -- reached the cameras is this same divergence with its sign flipped
        -- -- the hazard the comment beside ads_zoom_applied already names.
        -- It is published from there instead (review, 19 September).
        -- THE OTHER END OF THE FRUSTUM RATIO (19 September). The world is
        -- rendered through THIS frustum; the reticle is placed through the one
        -- the viewer submits. The user reports the reticle sits 1.2x to 1.7x
        -- too far and only in the sights, and a factor that size is not the
        -- 3 per cent zoom -- so the question is what else differs between the
        -- two, and tangent spans are how that is read off rather than argued.
        -- Printed on entry and exit only: this runs every frame.
        if (zoom > 1.0001) ~= (presentation.ads_frusta_logged == true) then
            presentation.ads_frusta_logged = zoom > 1.0001
            local function span(f)
                return f and math.tan(f.right) - math.tan(f.left) or 0
            end
            mod:info(
                "DARKTIDEVR_AIM ads_frusta zoom=%.4f runtime_tan_span=%.5f " ..
                "render_tan_span=%.5f render_over_runtime=%.5f " ..
                "render_vfov=%.5f unzoomed_vfov=%.5f",
                zoom, span(left_frustum), span(head_render_frusta[1]),
                span(left_frustum) ~= 0 and
                    span(head_render_frusta[1]) / span(left_frustum) or 0,
                head_render_vertical_fov or 0,
                presentation.head_render_vertical_fov_unzoomed or 0)
        end
    end
    local runtime_ipd = tonumber(head_pose_values[19])
    controller_observation.body_follow_x = tonumber(head_pose_values[20])
    controller_observation.body_follow_y = tonumber(head_pose_values[21])
    controller_observation.body_follow_z = tonumber(head_pose_values[22])
    local recenter_generation = math.floor(
        tonumber(head_pose_values[23]) + 0.5)
    if recenter_generation ~= controller_observation.head_recenter_generation then
        controller_observation.head_recenter_generation = recenter_generation
        -- Third-person hub: a reset view looks at the character, i.e. along
        -- the stock orbit orientation, so the room anchor takes that yaw.
        if active_base_rotation and controller_observation.gameplay_yaw and
                presentation.hub_third_person_active() then
            active_base_rotation:store(Quaternion.axis_angle(
                Vector3.up(), controller_observation.gameplay_yaw))
            mod:info("DARKTIDEVR_AIM hub_third_person recenter anchor_yaw=%.4f generation=%d",
                controller_observation.gameplay_yaw, recenter_generation)
        end
        -- Keyboard and mouse: the view is turned onto the aim below, once the
        -- recentred head rotation of this same sample is known. The
        -- third-person hub has already faced its orbit above.
        if presentation.keyboard_mouse_enabled() and not presentation.hub_third_person_active() then
            controller_observation.keyboard_mouse_recenter_pending = true
        end
        controller_observation.body_ik_neck_unit = nil
        controller_observation.body_ik_neck_generation = nil
        controller_observation.body_ik_neck_baseline_raw = nil
        controller_observation.body_ik_neck_baseline_arc = nil
        controller_observation.body_ik_neck_anchor_unit = nil
        controller_observation.body_ik_neck_anchor_generation = nil
        controller_observation.body_ik_neck_anchor_local = nil
        mod:info(
            "DARKTIDEVR_IK neck_pivot rebase generation=%d",
            recenter_generation)
    end
    -- Aim must stop authoring immediately when its live tracking is lost.
    -- Grip IK deliberately keeps the last valid wrist pose, however: dropping
    -- its target for one bad OpenXR sample hands that limb back to Darktide's
    -- stock animation graph and causes a visible ownership switch. A new
    -- valid sample replaces the held pose as soon as tracking returns.
    controller_observation.right_aim_usable = false
    controller_observation.left_aim_usable = false
    controller_observation.right_grip_tracking_live = false
    controller_observation.left_grip_tracking_live = false
    local controller_result = 2
    if controller_observation.values then
        if controller_observation.read_state_v2 then
            controller_result = controller_observation.read_state_v2(
                controller_observation.values,
                controller_observation.tracking_flags,
                controller_observation.buttons,
                controller_observation.sequence,
                controller_observation.timestamp_ns,
                controller_observation.transport_generation)
        else
            controller_result = ui_native_capture.dtvr_read_controller_state(
                controller_observation.values,
                controller_observation.tracking_flags,
                controller_observation.buttons,
                controller_observation.sequence,
                controller_observation.timestamp_ns)
        end
    end
    if controller_result == 0 then
        local controller_sequence = tonumber(controller_observation.sequence[0])
        local controller_generation =
            tonumber(controller_observation.transport_generation[0])
        if controller_generation ~=
                controller_observation.last_transport_generation or
                controller_sequence < controller_observation.last_sequence then
            -- A new harness/XR session starts controller sequencing at one.
            -- Capture a new game-world yaw when its first pose reaches the
            -- active orientation class.
            controller_observation.body_yaw_anchor = nil
            controller_observation.first_person_seam_last_sequence = 0
            controller_observation.right_grip_usable = false
            controller_observation.left_grip_usable = false
            -- One complete fresh sample must follow an epoch transition before
            -- authoring can resume.
            controller_observation.epoch_block_sequence = controller_sequence
        end
        controller_observation.last_transport_generation = controller_generation
        controller_observation.last_sequence = controller_sequence
        local left_aim_flags = tonumber(controller_observation.tracking_flags[0])
        local left_grip_flags =
            tonumber(controller_observation.tracking_flags[1])
        local right_aim_flags = tonumber(controller_observation.tracking_flags[2])
        local right_grip_flags =
            tonumber(controller_observation.tracking_flags[3])
        controller_observation.right_aim_flags = right_aim_flags
        controller_observation.left_aim_flags = left_aim_flags
        controller_observation.left_grip_flags = left_grip_flags
        controller_observation.right_grip_flags = right_grip_flags
        local controller_timestamp_ns =
            tonumber(controller_observation.timestamp_ns[0])
        local qpc_frequency =
            tonumber(ui_native_capture.dtvr_qpc_frequency())
        local controller_age_ns = math.huge
        if qpc_frequency > 0 then
            controller_age_ns =
                tonumber(ui_native_capture.dtvr_qpc_ticks()) *
                    1000000000 / qpc_frequency - controller_timestamp_ns
        end
        controller_observation.right_aim_age_ms = controller_age_ns / 1000000
        -- These are bridge flags, not raw XrSpaceLocationFlags: bits 0/1
        -- mean orientation/position valid. Mask 5 instead requires tracked
        -- orientation and accidentally omits position validity.
        controller_observation.right_aim_usable =
            bit.band(right_aim_flags, 3) == 3 and
            controller_age_ns >= -5000000 and
            controller_age_ns <= 100000000 and
            controller_sequence ~= controller_observation.epoch_block_sequence
        controller_observation.left_aim_usable =
            bit.band(left_aim_flags, 3) == 3 and
            controller_age_ns >= -5000000 and
            controller_age_ns <= 100000000 and
            controller_sequence ~= controller_observation.epoch_block_sequence
        controller_observation.right_grip_tracking_live =
            bit.band(right_grip_flags, 3) == 3 and
            controller_age_ns >= -5000000 and
            controller_age_ns <= 100000000 and
            controller_sequence ~= controller_observation.epoch_block_sequence
        controller_observation.left_grip_tracking_live =
            bit.band(left_grip_flags, 3) == 3 and
            controller_age_ns >= -5000000 and
            controller_age_ns <= 100000000 and
            controller_sequence ~= controller_observation.epoch_block_sequence
        if controller_observation.left_grip_tracking_live then
            controller_observation.left_grip_usable = true
            controller_observation.left_grip_x =
                tonumber(controller_observation.values[7])
            controller_observation.left_grip_y =
                tonumber(controller_observation.values[8])
            controller_observation.left_grip_z =
                tonumber(controller_observation.values[9])
            controller_observation.left_grip_qx =
                tonumber(controller_observation.values[10])
            controller_observation.left_grip_qy =
                tonumber(controller_observation.values[11])
            controller_observation.left_grip_qz =
                tonumber(controller_observation.values[12])
            controller_observation.left_grip_qw =
                tonumber(controller_observation.values[13])
        end
        if controller_observation.right_grip_tracking_live then
            controller_observation.right_grip_usable = true
            controller_observation.right_grip_x =
                tonumber(controller_observation.values[25])
            controller_observation.right_grip_y =
                tonumber(controller_observation.values[26])
            controller_observation.right_grip_z =
                tonumber(controller_observation.values[27])
            controller_observation.right_grip_qx =
                tonumber(controller_observation.values[28])
            controller_observation.right_grip_qy =
                tonumber(controller_observation.values[29])
            controller_observation.right_grip_qz =
                tonumber(controller_observation.values[30])
            controller_observation.right_grip_qw =
                tonumber(controller_observation.values[31])
        end
        if controller_observation.left_grip_tracking_live ~=
                controller_observation.left_grip_tracking_last or
                controller_observation.right_grip_tracking_live ~=
                    controller_observation.right_grip_tracking_last then
            mod:info(
                "DARKTIDEVR_CONTROLLER tracking_transition sequence=%d left_live=%s left_flags=%d left_held=%s right_live=%s right_flags=%d right_held=%s",
                controller_sequence,
                tostring(controller_observation.left_grip_tracking_live),
                left_grip_flags,
                tostring(controller_observation.left_grip_usable),
                tostring(controller_observation.right_grip_tracking_live),
                right_grip_flags,
                tostring(controller_observation.right_grip_usable))
            controller_observation.left_grip_tracking_last =
                controller_observation.left_grip_tracking_live
            controller_observation.right_grip_tracking_last =
                controller_observation.right_grip_tracking_live
        end
        controller_observation.right_trigger =
            tonumber(controller_observation.values[32])
        controller_observation.left_trigger =
            tonumber(controller_observation.values[14])
        controller_observation.left_stick_x =
            tonumber(controller_observation.values[16])
        controller_observation.left_stick_y =
            tonumber(controller_observation.values[17])
        controller_observation.right_stick_x =
            tonumber(controller_observation.values[34])
        controller_observation.right_stick_y =
            tonumber(controller_observation.values[35])
        if controller_observation.left_aim_usable then
            controller_observation.left_aim_x =
                tonumber(controller_observation.values[0])
            controller_observation.left_aim_y =
                tonumber(controller_observation.values[1])
            controller_observation.left_aim_z =
                tonumber(controller_observation.values[2])
            controller_observation.left_aim_qx =
                tonumber(controller_observation.values[3])
            controller_observation.left_aim_qy =
                tonumber(controller_observation.values[4])
            controller_observation.left_aim_qz =
                tonumber(controller_observation.values[5])
            controller_observation.left_aim_qw =
                tonumber(controller_observation.values[6])
        end
        if controller_observation.right_aim_usable then
            controller_observation.right_aim_x =
                tonumber(controller_observation.values[18])
            controller_observation.right_aim_y =
                tonumber(controller_observation.values[19])
            controller_observation.right_aim_z =
                tonumber(controller_observation.values[20])
            controller_observation.right_aim_qx =
                tonumber(controller_observation.values[21])
            controller_observation.right_aim_qy =
                tonumber(controller_observation.values[22])
            controller_observation.right_aim_qz =
                tonumber(controller_observation.values[23])
            controller_observation.right_aim_qw =
                tonumber(controller_observation.values[24])
            local right_aim_rotation = Quaternion.from_elements(
                controller_observation.right_aim_qx,
                controller_observation.right_aim_qy,
                controller_observation.right_aim_qz,
                controller_observation.right_aim_qw
            )
            controller_observation.right_aim_yaw,
                controller_observation.right_aim_pitch,
                controller_observation.right_aim_roll =
                    Quaternion.to_yaw_pitch_roll(right_aim_rotation)
        end
        if presentation.attachment_scan and presentation.attachment_scan.override_controllers then
            presentation.attachment_scan.override_controllers(controller_observation)
        end
        if not controller_observation.first_tracked_logged and
                (bit.band(left_aim_flags, 4) ~= 0 or
                 bit.band(right_aim_flags, 4) ~= 0) then
            controller_observation.first_tracked_logged = true
            mod:info("DARKTIDEVR_CONTROLLER observed sequence=%d left_aim_flags=%d right_aim_flags=%d right_aim_age_ms=%.3f usable=%s left_stick=%.3f,%.3f right_stick=%.3f,%.3f",
                controller_sequence,
                left_aim_flags,
                right_aim_flags,
                controller_observation.right_aim_age_ms,
                tostring(controller_observation.right_aim_usable),
                controller_observation.left_stick_x,
                controller_observation.left_stick_y,
                controller_observation.right_stick_x,
                controller_observation.right_stick_y)
        end
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    local character_scale, scale_source, target_eye_height,
        source_eye_height =
            presentation.calibrated_character_scale(local_player)
    if runtime_ipd >= 0.03 and runtime_ipd <= 0.10 then
        half_ipd = runtime_ipd * character_scale * 0.5
        ui_eye_separation = half_ipd * 2
    end
    local head_rotation = Quaternion.from_elements(
        head_pose_values[3],
        -head_pose_values[5],
        head_pose_values[4],
        head_pose_values[6]
    )
    controller_observation.physical_head_yaw =
        Quaternion.yaw(head_rotation)
    if controller_observation.keyboard_mouse_recenter_pending and active_base_rotation and
            presentation.hub_third_person_active() then
        -- The fallback request (an older viewer) in the third-person hub faces
        -- the orbit, as a runtime recentre does there.
        controller_observation.keyboard_mouse_recenter_pending = nil
        if controller_observation.gameplay_yaw then
            active_base_rotation:store(Quaternion.axis_angle(
                Vector3.up(), controller_observation.gameplay_yaw))
            clean_rotation = active_base_rotation:unbox()
        end
    end
    if controller_observation.keyboard_mouse_recenter_pending and active_base_rotation and
            not presentation.cinematic_stereo_active() then
        controller_observation.keyboard_mouse_recenter_pending = nil
        -- Keep the aim where it is in the world and turn the scene so this
        -- recentred view looks along it. Mouse camera pitch is levelled too, so
        -- the view for this sample is rebuilt from the turned anchor alone.
        local anchor = active_base_rotation:unbox()
        local turn = presentation.keyboard_mouse.recenter(
            Quaternion.yaw(Quaternion.multiply(anchor, head_rotation)))
        anchor = Quaternion.multiply(Quaternion.axis_angle(Vector3.up(), turn), anchor)
        active_base_rotation:store(anchor)
        clean_rotation = anchor
        mod:info("DARKTIDEVR_KBM recenter turn=%.4f generation=%d", turn,
            controller_observation.head_recenter_generation)
    end
    local tracked_rotation = Quaternion.multiply(clean_rotation, head_rotation)
    controller_observation.head_aim_yaw,
        controller_observation.head_aim_pitch,
        controller_observation.head_aim_roll =
            Quaternion.to_yaw_pitch_roll(tracked_rotation)
    -- The rendered head rotation itself, for headset-relative directions
    -- (keyboard and mouse melee), without an Euler round trip.
    controller_observation.head_aim_qx, controller_observation.head_aim_qy,
        controller_observation.head_aim_qz, controller_observation.head_aim_qw =
            Quaternion.to_elements(tracked_rotation)
    local tracked_position = clean_position

    if head_translation_requested then
        local raw_x = tonumber(head_pose_values[0])
        local raw_z = tonumber(head_pose_values[2])
        -- camera_delta is already relative to the bridge's sliding recenter
        -- origin. body_follow is the cumulative excess intended for an
        -- authoritative collision root; adding it here recreates a fixed box
        -- and strands a donned headset at its edge in the public hub.
        local local_x, horizontal_z = presentation.clamp_hub_head_horizontal(
            raw_x * character_scale, raw_z * character_scale)
        local local_y = -horizontal_z
        local local_z = head_pose_values[1] * character_scale
        tracked_position = clean_position +
            Quaternion.right(clean_rotation) * local_x +
            Quaternion.forward(clean_rotation) * local_y +
            Quaternion.up(clean_rotation) * local_z
    end

    if presentation.head_translation_trace_requested and
            (presentation.head_translation_trace_last_sequence == 0 or
             sequence < presentation.head_translation_trace_last_sequence or
             sequence - presentation.head_translation_trace_last_sequence >=
                presentation.head_translation_trace_interval) then
        mod:info(
            "DARKTIDEVR_STEREO head_translation sequence=%d delta=%.5f,%.5f,%.5f body_follow=%.5f,%.5f,%.5f clean=%.5f,%.5f,%.5f tracked=%.5f,%.5f,%.5f",
            sequence,
            tonumber(head_pose_values[0]) * character_scale,
            tonumber(head_pose_values[1]) * character_scale,
            tonumber(head_pose_values[2]) * character_scale,
            controller_observation.body_follow_x * character_scale,
            controller_observation.body_follow_y * character_scale,
            controller_observation.body_follow_z * character_scale,
            Vector3.x(clean_position), Vector3.y(clean_position),
            Vector3.z(clean_position), Vector3.x(tracked_position),
            Vector3.y(tracked_position), Vector3.z(tracked_position))
        presentation.head_translation_trace_last_sequence = sequence
    end

    if head_pose_last_sequence == 0 then
        mod:info("DARKTIDEVR_STEREO head_tracking active mode=%s sequence=%d runtime_ipd=%.4f character_scale=%.3f scale_source=%s target_eye_height_m=%s source_eye_height_m=%s",
            head_translation_requested and "6dof" or "3dof",
            sequence,
            runtime_ipd,
            character_scale,
            tostring(scale_source), tostring(target_eye_height),
            tostring(source_eye_height))
    end
    head_pose_last_sequence = sequence
    presentation.head_pose_last_transport_generation = transport_generation

    return tracked_position, tracked_rotation
end

-- Renderer diagnostics must install while the title state is still active so
-- subsequent main-menu and gameplay package loads pass their real PSO and
-- root-signature creation descriptors through our hooks. Delaying this until
-- UIWorldSpawner.create_viewport is too late for shader/root localization.
presentation.native_startup = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_native_startup")
-- Per-frame cost of the mod's own Lua by section, opt-in (frame profile flag).
presentation.frame_profile = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_frame_profile").install(mod,
    function() return tonumber(ui_native_capture.dtvr_qpc_ticks()) end,
    function() return tonumber(ui_native_capture.dtvr_qpc_frequency()) end)
-- The game boots with jit.off() (scripts/boot_init.lua), so every Lua function
-- runs interpreted. Whether the mod can reach the jit table at all decides
-- whether its own hot functions could be compiled selectively; one line, once.
pcall(function()
    local global_jit = rawget(_G, "jit")
    local mods_jit = Mods and Mods.lua and Mods.lua.jit
    local required
    pcall(function() required = require("jit") end)
    local status
    local probe = global_jit or mods_jit or required
    if probe and probe.status then pcall(function() status = tostring(probe.status()) end) end
    mod:info("DARKTIDEVR_FRAME_PROFILE jit global=%s mods_lua=%s require=%s status=%s version=%s",
        tostring(global_jit ~= nil), tostring(mods_jit ~= nil), tostring(required ~= nil),
        tostring(status), tostring(probe and probe.version))
end)
function presentation.refresh_performance_profile_request()
    local startup = presentation.native_startup.read(Mods.lua.io.open)
    diagnostic_render_hooks_requested = startup.diagnostic_hooks
    billboard_selector_probe_requested = startup.draw_census
    vertex_shader_dump_requested = startup.vertex_dump
    billboard_shader_substitution_requested = startup.substitution
    performance_profile_requested = startup.performance_profile
    presentation.performance_pass_trace_requested = startup.pass_trace
    presentation.offline_dual_view_requested = startup.offline_dual_view
    presentation.billboard_pixel_shader_probe_requested = startup.pixel_probe
    mod:info(
        "DARKTIDEVR_PERF profile_enabled=%s pass_trace=%s offline_dual_view=%s pixel_probe=%s diagnostic_hooks=%s vertex_dump=%s substitution=%s draw_census=%s",
        tostring(performance_profile_requested),
        tostring(presentation.performance_pass_trace_requested),
        tostring(presentation.offline_dual_view_requested),
        tostring(presentation.billboard_pixel_shader_probe_requested),
        tostring(diagnostic_render_hooks_requested),
        tostring(vertex_shader_dump_requested),
        tostring(billboard_shader_substitution_requested),
        tostring(billboard_selector_probe_requested))
end

presentation.refresh_performance_profile_request()
if ui_native_observer_requested or diagnostic_render_hooks_requested or
        vertex_shader_dump_requested or billboard_horizon_lock_requested or
        billboard_shader_substitution_requested or
        billboard_selector_probe_requested or performance_profile_requested then
    ensure_ui_native_hooks()
end

local function enable_ui_native_capture()
    if not ensure_ui_native_hooks() then
        return false
    end

    if not refresh_xr_render_extent() then
        ui_native_capture_active = false
        return false
    end

    ui_native_capture_active = true
    ui_native_capture_last_result = nil
    ui_native_sync_initialized = false
    ui_native_sync_last_result = nil

    if ui_boundary_census_requested then
        local census_result = ui_native_capture.dtvr_enable_boundary_census()
        if census_result ~= 0 then
            mod:error("DARKTIDEVR_STEREO boundary_census_failed code=%d",
                tonumber(census_result))
        end
    end

    -- The desktop window keeps whatever size the player chose: in-game menus
    -- are published from the engine canvas at the presentation extent, so
    -- neither the headset menu resolution nor the pointer depends on the
    -- client. Zero leaves the native resize nudge restoring the original
    -- window rectangle instead of forcing 1920x1080.
    local mirror_result = ui_native_capture.dtvr_set_mirror_client_extent(0, 0)
    if mirror_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO mirror_extent_failed code=%d",
            tonumber(mirror_result))
    end

    local extent_result = ui_native_capture.dtvr_set_swapchain_render_extent(
        ui_eye_target_width,
        ui_eye_target_height
    )
    if extent_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO swapchain_extent_failed code=%d",
            tonumber(extent_result))
        ui_native_capture_active = false
        return false
    end
    local virtual_client_result =
        ui_native_capture.dtvr_set_virtual_client_extent(
            ui_virtual_client_extent_requested and 1 or 0
        )
    if virtual_client_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO virtual_client_extent_failed code=%d",
            tonumber(virtual_client_result))
    end

    local virtual_size_message_result =
        ui_native_capture.dtvr_set_virtual_size_message(
            ui_virtual_size_message_requested and 1 or 0
        )
    if virtual_size_message_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO virtual_size_message_failed code=%d",
            tonumber(virtual_size_message_result))
    end
    local candidate_result =
        ui_native_capture.dtvr_set_camera_output_candidate_index(
            ui_camera_output_candidate_probe_index
        )
    if candidate_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO candidate_select_failed code=%d",
            tonumber(candidate_result))
    end
    local client_lock_result =
        ui_native_capture.dtvr_lock_swapchain_client_extent(0)
    if client_lock_result ~= 0 then
        mod:error("DARKTIDEVR_STEREO client_extent_lock_failed code=%d",
            tonumber(client_lock_result))
        ui_native_capture_active = false
        return false
    end

    return true
end

local function report_native_observer()
    if not ui_native_capture or
            (not ui_native_observer_requested and
                not ui_present_capture_requested and
                not head_tracking_requested) then
        return
    end

    local presents = tonumber(ui_native_capture.dtvr_present_count())

    if presents >= ui_native_observer_last_present + 120 then
        local executes = tonumber(ui_native_capture.dtvr_execute_call_count())
        mod:info(
            "DARKTIDEVR_STEREO native_observer presents=%d execute_calls=%d ratio=%.3f ready=%d",
            presents,
            executes,
            executes / presents,
            tonumber(ui_native_capture.dtvr_ready_value())
        )
        if presentation.cluster_light_visibility_fix_active then
            mod:info(
                "DARKTIDEVR_STEREO cluster_light_visibility_fix draws=%d candidates=%d patches=%d rejects=%d root_missing=%d resource_missing=%d",
                tonumber(ui_native_capture.dtvr_cluster_light_visibility_fix_target_draw_count()),
                tonumber(ui_native_capture.dtvr_cluster_light_visibility_fix_candidate_count()),
                tonumber(ui_native_capture.dtvr_cluster_light_visibility_fix_patch_count()),
                tonumber(ui_native_capture.dtvr_cluster_light_visibility_fix_reject_count()),
                tonumber(ui_native_capture.dtvr_cluster_light_visibility_fix_root_missing_count()),
                tonumber(ui_native_capture.dtvr_cluster_light_visibility_fix_resource_missing_count())
            )
        end
        if ui_table4_alias_probe_requested then
            mod:info(
                "DARKTIDEVR_STEREO table4_alias substitutions=%d",
                tonumber(ui_native_capture.dtvr_table4_alias_count())
            )
        end
        mod:info(
            "DARKTIDEVR_STEREO table4_exact matches=%d ambiguous=%d",
            tonumber(ui_native_capture.dtvr_table4_exact_match_count()),
            tonumber(ui_native_capture.dtvr_table4_exact_ambiguous_count())
        )
        mod:info(
            "DARKTIDEVR_STEREO boundary arms=%d transitions=%d captures=%d/%d pose=%d/%d queue=%d resets=%d",
            tonumber(ui_native_capture.dtvr_boundary_arm_count()),
            tonumber(ui_native_capture.dtvr_boundary_transition_count()),
            tonumber(ui_native_capture.dtvr_boundary_eye_capture_count(0)),
            tonumber(ui_native_capture.dtvr_boundary_eye_capture_count(1)),
            tonumber(ui_native_capture.dtvr_boundary_eye_pose_sequence(0)),
            tonumber(ui_native_capture.dtvr_boundary_eye_pose_sequence(1)),
            tonumber(ui_native_capture.dtvr_boundary_tag_queue_depth()),
            tonumber(ui_native_capture.dtvr_boundary_tag_reset_count())
        )
        if ui_alternating_full_requested then
            mod:info(
                "DARKTIDEVR_STEREO alternating tags=%d copies=%d/%d capture_result=%d",
                tonumber(ui_native_capture.dtvr_alternating_eye_tag_count()),
                tonumber(ui_native_capture.dtvr_alternating_eye_copy_count(0)),
                tonumber(ui_native_capture.dtvr_alternating_eye_copy_count(1)),
                tonumber(ui_native_capture.dtvr_alternating_last_capture_result())
            )
        end
        if ui_candidate_instance_clamp_requested then
            mod:info(
                "DARKTIDEVR_STEREO candidate_instance_clamp substitutions=%d",
                tonumber(ui_native_capture.dtvr_candidate_instance_clamp_count())
            )
        end
        if ui_candidate_table4_probe_requested then
            mod:info(
                "DARKTIDEVR_STEREO candidate_table4 matches=%d aliases=%d ambiguous=%d clamp=%d",
                tonumber(ui_native_capture.dtvr_candidate_table4_match_count()),
                tonumber(ui_native_capture.dtvr_candidate_table4_alias_count()),
                tonumber(ui_native_capture.dtvr_candidate_table4_ambiguous_count()),
                tonumber(ui_native_capture.dtvr_candidate_instance_clamp_count())
            )
        end
        if billboard_horizon_lock_requested or
                billboard_selector_probe_requested then
            local function top_billboard_strides(slot)
                local ranked = {}
                for stride = 0, 256 do
                    local count = tonumber(
                        ui_native_capture.dtvr_billboard_observed_stride_count(
                            slot, stride))
                    if count > 0 then
                        ranked[#ranked + 1] = { stride = stride, count = count }
                    end
                end
                table.sort(ranked, function(a, b)
                    return a.count > b.count
                end)
                local values = {}
                for index = 1, math.min(5, #ranked) do
                    values[#values + 1] = string.format(
                        "%d:%d", ranked[index].stride, ranked[index].count)
                end
                return table.concat(values, ",")
            end
            local function top_billboard_root_slots(counter, maximum)
                local ranked = {}
                for slot = 0, maximum or 31 do
                    local count = tonumber(counter(slot))
                    if count > 0 then
                        ranked[#ranked + 1] = { slot = slot, count = count }
                    end
                end
                table.sort(ranked, function(a, b)
                    return a.count > b.count
                end)
                local values = {}
                for index = 1, math.min(8, #ranked) do
                    values[#values + 1] = string.format(
                        "%d:%d", ranked[index].slot, ranked[index].count)
                end
                return table.concat(values, ",")
            end
            mod:info(
                "DARKTIDEVR_STEREO billboard state=%d hook_draws=%d observed=%d slot0=%s slot1=%s particle_layout=%d exact_pso=%d cl_types=%s registers=%s cbv_slots=%s table_slots=%s selected_tables=%s descriptor_offsets=%s table_spans=%s cbv_desc=%d buffers=%d heaps=%s map=%d/%d tracked_maps=%d/%d/%d producer_stacks=%d upload_flush=%d/%d direct_patches=%d selected=%d/%d shadow_stages=%s root_meta=%d direct_cbv=%d table_cbv=%d table_cbv_bound=%d patches=%d",
                ui_native_capture.dtvr_billboard_probe_state(),
                tonumber(ui_native_capture.dtvr_billboard_direct_draw_hook_count()),
                tonumber(ui_native_capture.dtvr_billboard_observed_draw_count()),
                top_billboard_strides(0), top_billboard_strides(1),
                tonumber(ui_native_capture.dtvr_billboard_exact_shader_draw_count()),
                tonumber(ui_native_capture.dtvr_billboard_exact_pso_draw_count()),
                top_billboard_root_slots(
                    ui_native_capture.dtvr_billboard_exact_command_list_type_count,
                    7),
                top_billboard_root_slots(
                    ui_native_capture.dtvr_billboard_exact_register_count, 63),
                top_billboard_root_slots(
                    ui_native_capture.dtvr_billboard_exact_pso_cbv_slot_count),
                top_billboard_root_slots(
                    ui_native_capture.dtvr_billboard_exact_pso_table_slot_count),
                top_billboard_root_slots(
                    ui_native_capture.dtvr_billboard_exact_vertex_table_slot_count),
                top_billboard_root_slots(
                    ui_native_capture.dtvr_billboard_exact_descriptor_offset_count,
                    63),
                top_billboard_root_slots(
                    ui_native_capture.dtvr_billboard_exact_table_span_count, 63),
                tonumber(ui_native_capture.dtvr_billboard_exact_cbv_descriptor_count()),
                tonumber(ui_native_capture.dtvr_billboard_exact_buffer_resource_count()),
                top_billboard_root_slots(
                    ui_native_capture.dtvr_billboard_exact_heap_type_count, 4),
                tonumber(ui_native_capture.dtvr_billboard_exact_map_success_count()),
                tonumber(ui_native_capture.dtvr_billboard_exact_map_failure_count()),
                tonumber(ui_native_capture.dtvr_billboard_resource_map_count()),
                tonumber(ui_native_capture.dtvr_billboard_resource_map_match_count()),
                tonumber(ui_native_capture.dtvr_billboard_resource_unmap_count()),
                tonumber(ui_native_capture.dtvr_billboard_selected_map_stack_count()),
                ui_native_capture.dtvr_billboard_upload_flush_hook_state(),
                tonumber(ui_native_capture.dtvr_billboard_upload_flush_count()),
                tonumber(ui_native_capture.dtvr_billboard_direct_patch_count()),
                ui_native_capture.dtvr_billboard_selected_cpu_address() ~= 0 and 1 or 0,
                tonumber(ui_native_capture.dtvr_billboard_selected_size()),
                top_billboard_root_slots(
                    ui_native_capture.dtvr_billboard_shadow_stage_count, 15),
                tonumber(ui_native_capture.dtvr_billboard_root_metadata_draw_count()),
                tonumber(ui_native_capture.dtvr_billboard_exact_root_mapping_count()),
                tonumber(ui_native_capture.dtvr_billboard_table_b2_draw_count()),
                tonumber(ui_native_capture.dtvr_billboard_bound_table_b2_draw_count()),
                tonumber(ui_native_capture.dtvr_billboard_basis_patch_count())
            )
            mod:info(
                "DARKTIDEVR_STEREO creation_hooks roots=%d pso=%d/%d/%d loads=%d/%d/%d",
                tonumber(ui_native_capture.dtvr_diagnostic_root_signature_create_count()),
                tonumber(ui_native_capture.dtvr_diagnostic_graphics_pso_create_count()),
                tonumber(ui_native_capture.dtvr_diagnostic_compute_pso_create_count()),
                tonumber(ui_native_capture.dtvr_diagnostic_stream_pso_create_count()),
                tonumber(ui_native_capture.dtvr_diagnostic_graphics_pipeline_load_count()),
                tonumber(ui_native_capture.dtvr_diagnostic_compute_pipeline_load_count()),
                tonumber(ui_native_capture.dtvr_diagnostic_stream_pipeline_load_count())
            )
            local candidate_shaders = {}
            if presentation.billboard_shader_snapshot then
                presentation.billboard_shader_samples = presentation.billboard_shader_samples or
                    Mods.lua.ffi.new("dtvr_billboard_shader_sample[8]")
                local samples = presentation.billboard_shader_samples
                local count = tonumber(presentation.billboard_shader_snapshot(samples, 8))
                for rank = 0, count - 1 do
                    local sample = samples[rank]
                    if sample.count > 0 then
                        candidate_shaders[#candidate_shaders + 1] = string.format(
                            "%08x%08x:%d", tonumber(sample.hash_high),
                            tonumber(sample.hash_low), tonumber(sample.count))
                    end
                end
            else
                for rank = 0, 7 do
                    local hash_low = tonumber(
                        ui_native_capture.dtvr_billboard_candidate_shader_hash_low(rank))
                    local hash_high = tonumber(
                        ui_native_capture.dtvr_billboard_candidate_shader_hash_high(rank))
                    local count = tonumber(
                        ui_native_capture.dtvr_billboard_candidate_shader_count(rank))
                    if count > 0 then
                        candidate_shaders[#candidate_shaders + 1] = string.format(
                            "%08x%08x:%d", hash_high, hash_low, count)
                    end
                end
            end
            mod:info(
                "DARKTIDEVR_STEREO billboard_b2 candidates=%d shaders=%s",
                tonumber(ui_native_capture.dtvr_billboard_root_b2_candidate_draw_count()),
                table.concat(candidate_shaders, ",")
            )
            local candidate_pairs = {}
            presentation.billboard_pair_samples = presentation.billboard_pair_samples or
                Mods.lua.ffi.new("dtvr_billboard_pair_sample[32]")
            local samples = presentation.billboard_pair_samples
            local sample_count = tonumber(
                ui_native_capture.dtvr_copy_billboard_candidate_pairs(samples, 32))
            for rank = 0, sample_count - 1 do
                local sample = samples[rank]
                candidate_pairs[#candidate_pairs + 1] = string.format(
                    "%08x%08x/%08x%08x:%d", tonumber(sample.vertex_high),
                    tonumber(sample.vertex_low), tonumber(sample.pixel_high),
                    tonumber(sample.pixel_low), tonumber(sample.count))
            end
            mod:info("DARKTIDEVR_STEREO billboard_pairs %s",
                table.concat(candidate_pairs, ","))
        end
        ui_native_observer_last_present = presents
    end
end

local function arm_eye_capture(eye)
    return ui_native_capture.dtvr_arm_eye_capture_pose(
        eye,
        head_pose_last_sequence
    )
end

local function report_native_capture_result(result)
    if result ~= ui_native_capture_last_result then
        if result == 0 then
            mod:info("DARKTIDEVR_STEREO native_capture publishing")
        else
            mod:warning(
                "DARKTIDEVR_STEREO native_capture waiting code=%d stage=%d",
                result,
                ui_native_capture.dtvr_capture_stage()
            )
        end

        ui_native_capture_last_result = result
    end
end

do
    local flag = Mods.lua.io.open("./../mods/darktidevr/darktidevr_cpu_render_timing.flag", "r")
    local value = flag and flag:read(32) or ""
    if flag then flag:close() end
    presentation.cpu_render_timing_requested = #value < 32 and value:match("^%s*enabled%s*$") ~= nil
    if presentation.cpu_render_timing_requested then
        local ok, kernel = pcall(function()
            local ffi = Mods.lua.ffi
            ffi.cdef("uint32_t GetCurrentThreadId(void);")
            return ffi.load("kernel32")
        end)
        if ok then presentation.cpu_render_timing_kernel = kernel
        else mod:warning("DARKTIDEVR_PERF render_caller_thread=unavailable") end
        mod:info("DARKTIDEVR_PERF cpu_render_timing=true gpu_profile=%s", tostring(performance_profile_requested))
    end
end

local function performance_tick()
    if not (performance_profile_requested or presentation.cpu_render_timing_requested) or not ui_native_capture then
        return nil
    end
    local value = tonumber(ui_native_capture.dtvr_qpc_ticks())
    if not value or value == 0 then
        return nil
    end
    return value
end

local function reset_render_timings(label)
    render_timing_label = label
    render_timing_frequency = ui_native_capture and
        tonumber(ui_native_capture.dtvr_qpc_frequency()) or nil
    render_timing_samples = 0
    render_timing_left_ticks = 0
    render_timing_right_ticks = 0
    render_timing_pair_ticks = 0
    render_timing_left_max_ticks = 0
    render_timing_right_max_ticks = 0
    render_timing_pair_max_ticks = 0
    presentation.render_timing_left_samples = {}
    presentation.render_timing_right_samples = {}
    presentation.render_timing_pair_samples = {}
end

function presentation.update_performance_pass_trace()
    if not presentation.performance_pass_trace_requested or
            presentation.performance_pass_trace_complete or
            not ui_native_capture then
        return
    end
    presentation.performance_pass_trace_frame =
        presentation.performance_pass_trace_frame + 1
    local frame = presentation.performance_pass_trace_frame
    if frame == 180 then
        local result = ui_native_capture.dtvr_set_focused_trace_phase(1)
        mod:info(
            "DARKTIDEVR_PERF pass_trace_started result=%d",
            tonumber(result))
    elseif frame == 200 then
        ui_native_capture.dtvr_set_focused_trace_phase(0)
        presentation.performance_pass_trace_complete = true
        mod:info(
            "DARKTIDEVR_PERF pass_trace_complete records=%d",
            tonumber(ui_native_capture.dtvr_focused_trace_count()))
    end
end

local function take_gpu_eye_profile(eye)
    if not ui_native_capture or not gpu_profile_values then
        return nil
    end
    if ui_native_capture.dtvr_take_gpu_eye_profile(
            eye, gpu_profile_values) ~= 0 then
        return nil
    end
    local count = tonumber(gpu_profile_values[0])
    local total = tonumber(gpu_profile_values[1])
    local maximum = tonumber(gpu_profile_values[2])
    local frequency = tonumber(gpu_profile_values[3])
    local median = tonumber(gpu_profile_values[4])
    local p95 = tonumber(gpu_profile_values[5])
    if not count or count == 0 or not frequency or frequency <= 0 then
        return nil
    end
    return {
        count = count,
        average_ms = total / count * 1000 / frequency,
        maximum_ms = maximum * 1000 / frequency,
        median_ms = median / frequency * 1000,
        p95_ms = p95 / frequency * 1000
    }
end

local function take_gpu_stage_profile(eye)
    if not ui_native_capture or not gpu_stage_profile_values then
        return nil
    end
    if ui_native_capture.dtvr_take_gpu_stage_profile(
            eye, gpu_stage_profile_values) ~= 0 then
        return nil
    end
    local count = tonumber(gpu_stage_profile_values[0])
    local world_total = tonumber(gpu_stage_profile_values[1])
    local world_maximum = tonumber(gpu_stage_profile_values[2])
    local output_total = tonumber(gpu_stage_profile_values[3])
    local output_maximum = tonumber(gpu_stage_profile_values[4])
    local frequency = tonumber(gpu_stage_profile_values[5])
    if not count or count == 0 or not frequency or frequency <= 0 then
        return nil
    end
    return {
        count = count,
        pre_full_average_ms = world_total / count * 1000 / frequency,
        pre_full_maximum_ms = world_maximum * 1000 / frequency,
        post_full_average_ms = output_total / count * 1000 / frequency,
        post_full_maximum_ms = output_maximum * 1000 / frequency
    }
end

local function record_render_timings(label, left_ticks, right_ticks, pair_ticks)
    if not left_ticks or not right_ticks or not pair_ticks then
        return
    end
    if render_timing_label ~= label or not render_timing_frequency or
            render_timing_frequency <= 0 then
        reset_render_timings(label)
    end
    if not render_timing_frequency or render_timing_frequency <= 0 then
        return
    end
    render_timing_samples = render_timing_samples + 1
    render_timing_left_ticks = render_timing_left_ticks + left_ticks
    render_timing_right_ticks = render_timing_right_ticks + right_ticks
    render_timing_pair_ticks = render_timing_pair_ticks + pair_ticks
    render_timing_left_max_ticks = math.max(
        render_timing_left_max_ticks, left_ticks)
    render_timing_right_max_ticks = math.max(
        render_timing_right_max_ticks, right_ticks)
    render_timing_pair_max_ticks = math.max(
        render_timing_pair_max_ticks, pair_ticks)
    table.insert(presentation.render_timing_left_samples, left_ticks)
    table.insert(presentation.render_timing_right_samples, right_ticks)
    table.insert(presentation.render_timing_pair_samples, pair_ticks)
    if render_timing_samples >= 240 then
        if presentation.cpu_render_timing_kernel then
            mod:info("DARKTIDEVR_PERF render_caller_thread=%d target=%s samples=%d",
                tonumber(presentation.cpu_render_timing_kernel.GetCurrentThreadId()), label, render_timing_samples)
            local ok, render_time, gpu_time = pcall(Application.get_frame_times)
            mod:info("DARKTIDEVR_PERF engine_frame_times_read=%s render_value=%s gpu_value=%s gpu_profile_requested=%s",
                tostring(ok), tostring(render_time), tostring(gpu_time), tostring(performance_profile_requested))
            -- The queue-priority experiment's evidence (darktidevr_queue_priority.flag);
            -- an older native module without the export reads as unavailable.
            local ok_raised, raised = pcall(function() return ui_native_capture.dtvr_queue_priority_raised() end)
            local ok_refused, refused = pcall(function() return ui_native_capture.dtvr_queue_priority_refused() end)
            mod:info("DARKTIDEVR_PERF queue_priority_raised=%s refused=%s",
                ok_raised and tostring(raised) or "unavailable", ok_refused and tostring(refused) or "unavailable")
        end
        local to_ms = 1000 / render_timing_frequency
        table.sort(presentation.render_timing_left_samples)
        table.sort(presentation.render_timing_right_samples)
        table.sort(presentation.render_timing_pair_samples)
        local p50_index = math.max(1, math.ceil(render_timing_samples * 0.50))
        local p95_index = math.max(1, math.ceil(render_timing_samples * 0.95))
        mod:info(
            "DARKTIDEVR_PERF target=%s samples=%d left_avg_ms=%.3f right_avg_ms=%.3f pair_avg_ms=%.3f left_p50_ms=%.3f right_p50_ms=%.3f pair_p50_ms=%.3f left_p95_ms=%.3f right_p95_ms=%.3f pair_p95_ms=%.3f left_max_ms=%.3f right_max_ms=%.3f pair_max_ms=%.3f",
            label,
            render_timing_samples,
            render_timing_left_ticks / render_timing_samples * to_ms,
            render_timing_right_ticks / render_timing_samples * to_ms,
            render_timing_pair_ticks / render_timing_samples * to_ms,
            presentation.render_timing_left_samples[p50_index] * to_ms,
            presentation.render_timing_right_samples[p50_index] * to_ms,
            presentation.render_timing_pair_samples[p50_index] * to_ms,
            presentation.render_timing_left_samples[p95_index] * to_ms,
            presentation.render_timing_right_samples[p95_index] * to_ms,
            presentation.render_timing_pair_samples[p95_index] * to_ms,
            render_timing_left_max_ticks * to_ms,
            render_timing_right_max_ticks * to_ms,
            render_timing_pair_max_ticks * to_ms
        )
        local left_gpu = take_gpu_eye_profile(0)
        local right_gpu = take_gpu_eye_profile(1)
        if left_gpu and right_gpu then
            mod:info(
                "DARKTIDEVR_GPU_PERF target=%s left_samples=%d right_samples=%d left_avg_ms=%.3f right_avg_ms=%.3f interval_sum_avg_ms=%.3f left_p50_ms=%.3f right_p50_ms=%.3f interval_sum_of_p50_ms=%.3f left_p95_ms=%.3f right_p95_ms=%.3f interval_sum_of_p95_ms=%.3f left_max_ms=%.3f right_max_ms=%.3f",
                label,
                left_gpu.count,
                right_gpu.count,
                left_gpu.average_ms,
                right_gpu.average_ms,
                left_gpu.average_ms + right_gpu.average_ms,
                left_gpu.median_ms,
                right_gpu.median_ms,
                left_gpu.median_ms + right_gpu.median_ms,
                left_gpu.p95_ms,
                right_gpu.p95_ms,
                left_gpu.p95_ms + right_gpu.p95_ms,
                left_gpu.maximum_ms,
                right_gpu.maximum_ms
            )
        end
        local left_stage = take_gpu_stage_profile(0)
        local right_stage = take_gpu_stage_profile(1)
        if left_stage and right_stage then
            mod:info(
                "DARKTIDEVR_GPU_STAGE target=%s left_samples=%d right_samples=%d left_pre_full_avg_ms=%.3f left_post_full_avg_ms=%.3f right_pre_full_avg_ms=%.3f right_post_full_avg_ms=%.3f left_pre_full_max_ms=%.3f left_post_full_max_ms=%.3f right_pre_full_max_ms=%.3f right_post_full_max_ms=%.3f",
                label,
                left_stage.count,
                right_stage.count,
                left_stage.pre_full_average_ms,
                left_stage.post_full_average_ms,
                right_stage.pre_full_average_ms,
                right_stage.post_full_average_ms,
                left_stage.pre_full_maximum_ms,
                left_stage.post_full_maximum_ms,
                right_stage.pre_full_maximum_ms,
                right_stage.post_full_maximum_ms
            )
        end
        reset_render_timings(label)
    end
end

local function render_eye_from_prepared_frame(world, prepared, target)
    presentation.full_second_eye_probe_check_frame =
        presentation.full_second_eye_probe_check_frame + 1
    if presentation.full_second_eye_probe_check_frame >=
            presentation.full_second_eye_probe_last_check_frame + 120 and
            Mods and Mods.lua and Mods.lua.io then
        presentation.full_second_eye_probe_last_check_frame =
            presentation.full_second_eye_probe_check_frame
        local flag = Mods.lua.io.open(
            "./../mods/darktidevr/darktidevr_full_second_eye.flag",
            "r")
        local enabled = false
        if flag then
            enabled = flag:read("*all"):match("^%s*enabled%s*$") ~= nil
            flag:close()
        end
        if enabled ~= presentation.full_second_eye_probe_requested then
            presentation.full_second_eye_probe_requested = enabled
            mod:info(
                "DARKTIDEVR_RENDER second_eye_path=%s source=test_flag",
                enabled and "full_wrapper" or "prepared_frame")
        end
        local marker_flag = Mods.lua.io.open(
            "./../mods/darktidevr/darktidevr_marker_reprojection_disabled.flag",
            "r")
        local markers_disabled = false
        if marker_flag then
            markers_disabled = marker_flag:read("*all"):match("^%s*enabled%s*$") ~= nil
            marker_flag:close()
        end
        if markers_disabled ~= (presentation.marker_reprojection_probe_disabled == true) then
            presentation.marker_reprojection_probe_disabled = markers_disabled
            mod:info("DARKTIDEVR_RENDER marker_reprojection=%s source=test_flag",
                markers_disabled and "disabled" or "enabled")
        end
    end
    if presentation.full_second_eye_probe_requested then
        return false
    end
    if not reuse_prepared_frame_requested or reuse_prepared_frame_failed then
        return false
    end
    local camera = ScriptViewport.camera(target)
    local shading_environment =
        Viewport.get_data(prepared, "shading_environment")
    if not camera or not shading_environment then
        reuse_prepared_frame_failed = true
        mod:warning(
            "DARKTIDEVR_PERF prepared_second_eye unavailable; restoring full wrapper"
        )
        return false
    end
    local ok, error_message = pcall(
        Application.render_world,
        world,
        camera,
        target,
        shading_environment
    )
    if not ok then
        reuse_prepared_frame_failed = true
        mod:error(
            "DARKTIDEVR_PERF prepared_second_eye failed error=%s",
            tostring(error_message)
        )
        return false
    end
    return true
end

local function wait_for_eye_capture(eye, target)
    local result = tonumber(ui_native_capture.dtvr_wait_eye_capture_count(
        eye,
        target,
        ui_native_sync_timeout_ms
    ))
    if result ~= ui_native_sync_last_result then
        if result == 0 then
            mod:info("DARKTIDEVR_STEREO native_sync publishing")
        else
            mod:warning(
                "DARKTIDEVR_STEREO native_sync waiting code=%d eye=%d target=%d",
                result,
                eye,
                target
            )
        end
        ui_native_sync_last_result = result
    end
    return result
end

local function teardown()
    if ui_native_capture then
        ui_native_capture.dtvr_set_projection_active(0)
    end
    -- This function is reached when CameraManager has already transitioned to
    -- a different world. Stingray owns the old world's viewports and destroys
    -- them with that world; even querying ScriptWorld here reports a fatal
    -- script error once its `viewports` data is gone. Clear only our references
    -- and let world destruction reclaim the old right-eye viewport.

    active = false
    active_manager = nil
    active_world = nil
    active_base_rotation = nil
    -- The engine owns objects allocated in the world being torn down.  Do not
    -- call into that invalid world here; only discard our handles.
    presentation.world_menu_gui = nil
    presentation.world_menu_gui_world = nil
    presentation.world_menu_material = nil
    presentation.world_menu_anchor = nil
    presentation.world_menu_draw_logged = false
    if presentation.marker_atlas then pcall(presentation.marker_atlas.forget_world) end
    if presentation.hand_overlay then presentation.hand_overlay.forget_world() end
end

local function setup(manager)
    local world = manager._world

    if not world or not ScriptWorld.has_viewport(world, primary_viewport_name) then
        return false
    end

    if ScriptWorld.has_viewport(world, right_viewport_name) then
        ScriptWorld.destroy_viewport(world, right_viewport_name)
    end

    local primary = ScriptWorld.viewport(world, primary_viewport_name)
    local primary_camera = ScriptViewport.camera(primary)
    local shading_environment_name =
        Viewport.get_data(primary, "default_shading_environment_name")
    local primary_shading_callback =
        Viewport.get_data(primary, "shading_callback")
    local primary_layer = Viewport.get_data(primary, "layer")

    local metadata_flag = Mods.lua.io.open(
        "./../mods/darktidevr/darktidevr_inherit_viewport_metadata.flag",
        "r")
    local inherit_viewport_metadata_mode = "disabled"
    if metadata_flag then
        inherit_viewport_metadata_mode = metadata_flag:read("*all"):match(
            "^%s*(%S+)%s*$") or "disabled"
        metadata_flag:close()
    end
    local inherit_viewport_layer =
        inherit_viewport_metadata_mode == "layer" or
        inherit_viewport_metadata_mode == "both" or
        inherit_viewport_metadata_mode == "enabled"
    local inherit_viewport_callback =
        inherit_viewport_metadata_mode == "callback" or
        inherit_viewport_metadata_mode == "both" or
        inherit_viewport_metadata_mode == "enabled"
    presentation.inherit_viewport_metadata_probe_mode =
        inherit_viewport_metadata_mode

    if not shading_environment_name then
        return false
    end

    if ui_native_capture_requested and not ui_native_capture_active and
            not enable_ui_native_capture() then
        return false
    end

    local right = ScriptWorld.create_viewport(
        world,
        right_viewport_name,
        ui_offscreen_active and "default_with_alpha" or "default",
        inherit_viewport_layer and primary_layer or 2,
        nil,
        nil,
        nil,
        false,
        shading_environment_name,
        inherit_viewport_callback and primary_shading_callback or nil
    )

    local shadow_cull_flag = Mods.lua.io.open(
        "./../mods/darktidevr/darktidevr_shared_shadow_cull.flag",
        "r")
    -- The stock primary viewport owns a dedicated shadow-cull camera which the
    -- camera manager updates before this late VR hook applies the tracked eye
    -- pose. The duplicate eye has no such camera. Using the already tracked
    -- primary render camera for both viewport cull decisions is the measured
    -- parity path: it reduced equal-pose eye differences from about 8% to
    -- 0.095% of pixels. Keep an explicit diagnostic opt-out.
    local shared_shadow_cull = true
    if shadow_cull_flag then
        shared_shadow_cull = shadow_cull_flag:read("*all"):match(
            "^%s*disabled%s*$") == nil
        shadow_cull_flag:close()
    end
    presentation.shared_shadow_cull_enabled = shared_shadow_cull
    local original_primary_shadow_cull_camera =
        ScriptViewport.shadow_cull_camera(primary)
    if shared_shadow_cull then
        Viewport.set_data(primary, "shadow_cull_camera", primary_camera)
        Viewport.set_data(right, "shadow_cull_camera", primary_camera)
    end

    mod:info(
        "DARKTIDEVR_STEREO viewport_metadata mode=%s primary_layer=%s right_layer=%s primary_callback=%s right_callback=%s",
        tostring(inherit_viewport_metadata_mode),
        tostring(primary_layer),
        tostring(Viewport.get_data(right, "layer")),
        tostring(primary_shading_callback),
        tostring(Viewport.get_data(right, "shading_callback")))
    mod:info(
        "DARKTIDEVR_STEREO shadow_cull shared=%s primary=%s right=%s",
        tostring(shared_shadow_cull),
        tostring(original_primary_shadow_cull_camera),
        tostring(ScriptViewport.shadow_cull_camera(right)))

    if ui_native_capture_active then
        -- Each sequential submission renders from a complete, identical
        -- viewport origin. Native capture publishes the intermediate target
        -- before the following eye can overwrite it.
        Viewport.set_rect(primary, 0, 0, 1, 1)
        Viewport.set_rect(right, 0, 0, 1, 1)
    else
        Viewport.set_rect(primary, 0, 0, 0.5, 1)
        Viewport.set_rect(right, 0.5, 0, 0.5, 1)
    end

    active = true
    active_manager = manager
    active_world = world
    -- Preserve only the scene's initial heading. Darktide's lobby camera
    -- starts with a downward presentation pitch; VR must initialize level and
    -- let the headset provide every subsequent pitch/roll component.
    local base_yaw = Quaternion.yaw(
        ScriptCamera.local_rotation(primary_camera)
    )
    local game_mode = Managers and Managers.state and
        Managers.state.game_mode
    local game_mode_name = game_mode and game_mode:game_mode_name()
    if game_mode_name == "hub" then
        -- The hub's third-person presentation camera faces back toward the
        -- operative. Its stored yaw is opposite the desired neutral headset
        -- heading when VR takes orientation ownership.
        base_yaw = base_yaw + math.pi
    end
    active_base_rotation = QuaternionBox(
        Quaternion.axis_angle(Vector3.up(), base_yaw)
    )
    -- CameraManager is also present on the title screen. Only gameplay owns
    -- this generic stereo path; character select is signalled separately by
    -- setup_ui_stereo, and title/loading remain on the spatial flat panel.
    if Managers and Managers.state and Managers.state.game_mode then
        ui_native_capture.dtvr_set_projection_active(1)
    end
    mod:info(
        "DARKTIDEVR_STEREO active mode=synchronized_sequential half_ipd=%.3f",
        half_ipd
    )

    return true
end

local function copy_projection(source, destination)
    Camera.set_vertical_fov(destination, Camera.vertical_fov(source))
    Camera.set_near_range(destination, Camera.near_range(source))
    Camera.set_far_range(destination, Camera.far_range(source))
end

local function publish_render_projection(camera, vertical_fov)
    if not ui_native_capture then
        return
    end

    local projection_result = ui_native_capture.dtvr_set_render_projection(
        vertical_fov or Camera.vertical_fov(camera),
        ui_eye_target_width / ui_eye_target_height
    )
    if projection_result ~= 0 then
        error("native render projection rejected: " ..
            tostring(projection_result))
    end
end

local runtime_recentered_projection_logged = false

local function runtime_recentered_eye(frustum, aspect)
    return presentation.projection_math.recentered_eye(frustum, aspect)
end

local function apply_runtime_recentered_projection(primary, right)
    if not head_render_frusta then
        return false
    end

    local target_aspect_ratio = ui_eye_target_width / ui_eye_target_height
    local left = runtime_recentered_eye(
        head_render_frusta[1], target_aspect_ratio
    )
    local right_eye = runtime_recentered_eye(
        head_render_frusta[2], target_aspect_ratio
    )
    local visibility_scale = 1
    if presentation.cluster_light_visibility_fix_active then
        visibility_scale = presentation.projection_math.binocular_visibility_scale(left, right_eye)
    elseif presentation.eye_transform_probe_mode == "visibility_padding" then
        visibility_scale = 1.2
    end
    presentation.render_visibility_scale = visibility_scale
    presentation.lod_primary_camera = primary
    presentation.lod_right_camera = right
    presentation.lod_primary_fov = left.vertical_fov
    presentation.lod_right_fov = right_eye.vertical_fov
    local post_projection = Matrix4x4.from_elements(
        visibility_scale, 0, 0,
        0, visibility_scale, 0,
        0, 0, 1,
        0, 0, 0
    )
    Camera.set_post_projection_transform(primary, post_projection)
    Camera.set_post_projection_transform(right, post_projection)
    Camera.set_vertical_fov(
        primary,
        2 * math.atan(math.tan(left.vertical_fov * 0.5) * visibility_scale))
    Camera.set_vertical_fov(
        right,
        2 * math.atan(
            math.tan(right_eye.vertical_fov * 0.5) * visibility_scale))
    presentation.render_projection_vertical_fov = left.vertical_fov
    if not runtime_recentered_projection_logged then
        mod:info("DARKTIDEVR_STEREO binocular_light_visibility_scale=%.6f",
            visibility_scale)
        mod:info(
            "DARKTIDEVR_STEREO runtime_recentered_projection left=%.6f,%.6f,%.6f right=%.6f,%.6f,%.6f",
            left.vertical_fov,
            left.horizontal_center,
            left.vertical_center,
            right_eye.vertical_fov,
            right_eye.horizontal_center,
            right_eye.vertical_center
        )
        runtime_recentered_projection_logged = true
    end
    return left.rotation, right_eye.rotation
end

local function apply_half_width_projection(primary, right)
    local base_vertical_fov = ui_base_vertical_fov or Camera.vertical_fov(primary)
    local tangent_scale = stereo_vertical_tangent_scale
    local target_aspect_ratio = ui_eye_target_width / ui_eye_target_height
    local runtime_projection_matches_target = head_render_vertical_fov and
        head_render_aspect_ratio and
        math.abs(head_render_aspect_ratio - target_aspect_ratio) < 0.001
    local left_optical_rotation = nil
    local right_optical_rotation = nil
    if runtime_projection_matches_target then
        left_optical_rotation, right_optical_rotation =
            apply_runtime_recentered_projection(primary, right)
    end
    if left_optical_rotation and right_optical_rotation then
        Camera.set_near_range(right, Camera.near_range(primary))
        Camera.set_far_range(right, Camera.far_range(primary))
        publish_render_projection(
            primary, presentation.render_projection_vertical_fov)
        return left_optical_rotation, right_optical_rotation
    end

    local stereo_vertical_fov = runtime_projection_matches_target and
        head_render_vertical_fov or
        2 * math.atan(math.tan(base_vertical_fov * 0.5) * tangent_scale)

    -- Each eye owns half the backbuffer width. Preserve the original
    -- horizontal scene coverage by doubling tan(vertical_fov / 2), rather
    -- than allowing the half-width viewport to crop the image horizontally.
    Camera.set_vertical_fov(primary, stereo_vertical_fov)
    Camera.set_vertical_fov(right, stereo_vertical_fov)
    Camera.set_near_range(right, Camera.near_range(primary))
    Camera.set_far_range(right, Camera.far_range(primary))

    presentation.render_projection_vertical_fov = nil
    publish_render_projection(primary)
    return nil, nil
end

local function apply_ui_eye_offsets(spawner)
    if spawner ~= ui_stereo_spawner or not ui_stereo_right_viewport then
        return
    end

    local primary_camera = spawner._camera
    local right_camera = ScriptViewport.camera(ui_stereo_right_viewport)
    local primary_unit = spawner._camera_unit
    local right_unit = Camera.get_data(right_camera, "unit")
    local clean_position = Unit.local_position(primary_unit, 1)
    local clean_rotation = Unit.local_rotation(primary_unit, 1)

    if ui_camera_freeze_requested and ui_native_capture then
        local presents = tonumber(ui_native_capture.dtvr_present_count())

        if not ui_camera_freeze_start_present then
            ui_camera_freeze_start_present = presents
        end

        if not ui_camera_frozen_position and
                presents - ui_camera_freeze_start_present >=
                    ui_camera_freeze_warmup_presents then
            -- Unit.local_* returns frame-scoped values.  Retaining those raw
            -- userdata objects across presents leaves an invalid value for
            -- Unit.set_local_*.  Boxes own a durable copy; unbox a fresh
            -- engine value each time the frozen transform is applied.
            ui_camera_frozen_position = Vector3Box(clean_position)
            ui_camera_frozen_rotation = QuaternionBox(clean_rotation)
            mod:info(
                "DARKTIDEVR_STEREO camera_freeze locked present=%d",
                presents
            )
        end

        if ui_camera_frozen_position then
            clean_position = ui_camera_frozen_position:unbox()
            clean_rotation = ui_camera_frozen_rotation:unbox()
            Unit.set_local_position(primary_unit, 1, clean_position)
            Unit.set_local_rotation(primary_unit, 1, clean_rotation)
            ScriptCamera.force_update(ui_stereo_world, primary_camera)
        end
    end
    clean_position, clean_rotation = apply_head_tracking(
        clean_position,
        clean_rotation
    )
    Unit.set_local_position(primary_unit, 1, clean_position)
    Unit.set_local_rotation(primary_unit, 1, clean_rotation)
    ScriptCamera.force_update(ui_stereo_world, primary_camera)
    local eye_axis = Quaternion.right(clean_rotation)

    -- The frozen base pose is restored before tracking is composed, preventing
    -- repeated pre-render callbacks from accumulating head motion. Keep the
    -- two eyes symmetric around that tracked center so their camera geometry
    -- matches the recentered OpenXR projection poses.
    local left_optical_rotation, right_optical_rotation =
        apply_half_width_projection(primary_camera, right_camera)
    local primary_rotation = left_optical_rotation and
        Quaternion.multiply(clean_rotation, left_optical_rotation) or
        clean_rotation
    local duplicate_rotation = right_optical_rotation and
        Quaternion.multiply(clean_rotation, right_optical_rotation) or
        clean_rotation
    Unit.set_local_position(
        primary_unit,
        1,
        clean_position - eye_axis * (ui_eye_separation * 0.5)
    )
    Unit.set_local_rotation(primary_unit, 1, primary_rotation)
    -- Unit movement does not immediately refresh the camera's cached view
    -- matrix. The previous force_update occurred at clean_position, which
    -- made the primary render use the center pose while only the duplicate
    -- received its eye offset.
    ScriptCamera.force_update(ui_stereo_world, primary_camera)
    Unit.set_local_position(
        right_unit,
        1,
        clean_position + eye_axis * (ui_eye_separation * 0.5)
    )
    Unit.set_local_rotation(right_unit, 1, duplicate_rotation)
    ScriptCamera.force_update(ui_stereo_world, right_camera)
end

local ui_rect_matrix_phases = {
    { name = "left_half", x = 0, width = 0.5 },
    { name = "center_half", x = 0.25, width = 0.5 },
    { name = "right_half", x = 0.5, width = 0.5 },
    { name = "full", x = 0, width = 1 }
}

local function apply_ui_rect_matrix_phase(primary, phase)
    local definition = ui_rect_matrix_phases[phase]
    Viewport.set_rect(primary, definition.x, 0, definition.width, 1)
    mod:info(
        "DARKTIDEVR_STEREO rect_matrix phase=%s x=%.2f width=%.2f",
        definition.name,
        definition.x,
        definition.width
    )
end

local function update_ui_rect_matrix()
    if not ui_rect_matrix_requested or ui_rect_matrix_complete or
            not ui_camera_frozen_position or not ui_stereo_world or
            not ui_stereo_spawner or not ui_stereo_right_viewport or
            not ui_native_capture then
        return
    end

    local primary = ui_stereo_spawner._viewport
    local duplicate = ui_stereo_right_viewport
    local presents = tonumber(ui_native_capture.dtvr_present_count())

    if not ui_rect_matrix_start_present then
        ui_rect_matrix_start_present = presents
        ui_rect_matrix_phase = 1
        ScriptWorld.activate_viewport(ui_stereo_world, primary)
        ScriptWorld.deactivate_viewport(ui_stereo_world, duplicate)
        apply_ui_rect_matrix_phase(primary, ui_rect_matrix_phase)
        return
    end

    local next_phase = math.floor(
        (presents - ui_rect_matrix_start_present) /
            ui_rect_matrix_phase_presents
    ) + 1

    if next_phase > #ui_rect_matrix_phases then
        ScriptWorld.activate_viewport(ui_stereo_world, primary)
        ScriptWorld.activate_viewport(ui_stereo_world, duplicate)
        if ui_swap_viewport_halves_requested then
            Viewport.set_rect(primary, 0.5, 0, 0.5, 1)
            Viewport.set_rect(duplicate, 0, 0, 0.5, 1)
        else
            Viewport.set_rect(primary, 0, 0, 0.5, 1)
            Viewport.set_rect(duplicate, 0.5, 0, 0.5, 1)
        end
        ui_rect_matrix_complete = true
        mod:info("DARKTIDEVR_STEREO rect_matrix complete restored=sbs")
    elseif next_phase ~= ui_rect_matrix_phase then
        ui_rect_matrix_phase = next_phase
        apply_ui_rect_matrix_phase(primary, ui_rect_matrix_phase)
    end
end

local function update_ui_rect_trace()
    if not ui_rect_trace_requested or ui_rect_trace_complete or
            not ui_camera_frozen_position or not ui_stereo_world or
            not ui_stereo_spawner or not ui_stereo_right_viewport or
            not ui_native_capture then
        return
    end

    local primary = ui_stereo_spawner._viewport
    local duplicate = ui_stereo_right_viewport
    local presents = tonumber(ui_native_capture.dtvr_present_count())

    if ui_rect_trace_phase == 0 then
        ui_rect_trace_phase = 1
        ui_rect_trace_phase_start_present = presents
        ScriptWorld.activate_viewport(ui_stereo_world, primary)
        ScriptWorld.deactivate_viewport(ui_stereo_world, duplicate)
        apply_ui_rect_matrix_phase(primary, ui_rect_trace_phase)
        mod:info("DARKTIDEVR_STEREO rect_trace warmup phase=1")
        return
    end

    if not ui_rect_trace_sampling and
            presents - ui_rect_trace_phase_start_present >=
                ui_rect_trace_warmup_presents then
        local result = ui_native_capture.dtvr_set_focused_trace_phase(
            ui_rect_trace_phase
        )
        ui_rect_trace_sampling = true
        ui_rect_trace_sample_start_present = presents
        mod:info(
            "DARKTIDEVR_STEREO rect_trace sample phase=%d result=%d",
            ui_rect_trace_phase,
            tonumber(result)
        )
        return
    end

    if ui_rect_trace_sampling and
            presents - ui_rect_trace_sample_start_present >=
                ui_rect_trace_sample_presents then
        ui_native_capture.dtvr_set_focused_trace_phase(0)
        ui_rect_trace_sampling = false

        if ui_rect_trace_phase == #ui_rect_matrix_phases then
            ScriptWorld.activate_viewport(ui_stereo_world, primary)
            ScriptWorld.activate_viewport(ui_stereo_world, duplicate)
            Viewport.set_rect(primary, 0, 0, 0.5, 1)
            Viewport.set_rect(duplicate, 0.5, 0, 0.5, 1)
            ui_rect_trace_complete = true
            mod:info(
                "DARKTIDEVR_STEREO rect_trace complete records=%d",
                tonumber(ui_native_capture.dtvr_focused_trace_count())
            )
            return
        end

        ui_rect_trace_phase = ui_rect_trace_phase + 1
        ui_rect_trace_phase_start_present = presents
        apply_ui_rect_matrix_phase(primary, ui_rect_trace_phase)
        mod:info(
            "DARKTIDEVR_STEREO rect_trace warmup phase=%d",
            ui_rect_trace_phase
        )
    end
end

local function apply_ui_direct_sbs_rects(primary, duplicate)
    if ui_swap_viewport_halves_requested then
        Viewport.set_rect(primary, 0.5, 0, 0.5, 1)
        Viewport.set_rect(duplicate, 0, 0, 0.5, 1)
    else
        Viewport.set_rect(primary, 0, 0, 0.5, 1)
        Viewport.set_rect(duplicate, 0.5, 0, 0.5, 1)
    end
end

local function apply_ui_rich_center_sbs_rects(primary, duplicate)
    -- x/width=0.996 and 1.0 are native eye tags. Both centers remain in the
    -- matrix's rich-right tier while native RSSetViewports/ScissorRects moves
    -- their actual raster output to x=0 and x=width respectively.
    Viewport.set_rect(primary, 0.498, 0, 0.5, 1)
    Viewport.set_rect(duplicate, 0.5, 0, 0.5, 1)
end

local function update_ui_alternating_full()
    if not ui_alternating_full_requested or not ui_native_capture or
            not ui_stereo_world or not ui_stereo_spawner or
            not ui_stereo_right_viewport then
        return
    end

    local presents = tonumber(ui_native_capture.dtvr_present_count())
    if ui_alternating_full_last_present == nil then
        ui_alternating_full_last_present = presents
    elseif presents == ui_alternating_full_last_present then
        return
    else
        ui_alternating_full_last_present = presents
        ui_alternating_full_eye = 1 - ui_alternating_full_eye
    end

    local primary = ui_stereo_spawner._viewport
    local duplicate = ui_stereo_right_viewport
    if ui_alternating_full_eye == 0 then
        ScriptWorld.activate_viewport(ui_stereo_world, primary)
        ScriptWorld.deactivate_viewport(ui_stereo_world, duplicate)
    else
        ScriptWorld.deactivate_viewport(ui_stereo_world, primary)
        ScriptWorld.activate_viewport(ui_stereo_world, duplicate)
    end
    ui_native_capture.dtvr_set_alternating_present_eye(
        ui_alternating_full_eye
    )
end

local function update_ui_full_origin_ab()
    if not ui_full_origin_ab_requested or ui_full_origin_ab_complete or
            not ui_stereo_world or not ui_stereo_spawner or
            not ui_stereo_right_viewport or not ui_native_capture then
        return
    end

    local primary = ui_stereo_spawner._viewport
    local duplicate = ui_stereo_right_viewport
    local presents = tonumber(ui_native_capture.dtvr_present_count())

    if not ui_full_origin_ab_start_present then
        ui_full_origin_ab_start_present = presents
        Viewport.set_rect(primary, 0, 0, 1, 1)
        Viewport.set_rect(duplicate, 0, 0, 1, 1)
        ScriptWorld.activate_viewport(ui_stereo_world, primary)
        ScriptWorld.deactivate_viewport(ui_stereo_world, duplicate)
        mod:info("DARKTIDEVR_STEREO full_origin_ab phase=primary")
        return
    end

    local elapsed = presents - ui_full_origin_ab_start_present
    if not ui_full_origin_ab_duplicate_active and
            elapsed >= ui_full_origin_ab_phase_presents then
        ScriptWorld.deactivate_viewport(ui_stereo_world, primary)
        ScriptWorld.activate_viewport(ui_stereo_world, duplicate)
        ui_full_origin_ab_duplicate_active = true
        mod:info("DARKTIDEVR_STEREO full_origin_ab phase=duplicate")
    elseif ui_full_origin_ab_duplicate_active and
            elapsed >= ui_full_origin_ab_phase_presents * 2 then
        ScriptWorld.activate_viewport(ui_stereo_world, primary)
        ScriptWorld.activate_viewport(ui_stereo_world, duplicate)
        apply_ui_direct_sbs_rects(primary, duplicate)
        ui_full_origin_ab_complete = true
        mod:info("DARKTIDEVR_STEREO full_origin_ab complete restored=sbs")
    end
end

local function update_ui_focused_ab_trace()
    if not ui_focused_ab_trace_requested or ui_focused_ab_trace_complete or
            not ui_native_capture or not ui_stereo_spawner or
            not ui_stereo_right_viewport or head_pose_last_sequence == 0 then
        return
    end

    ui_focused_ab_trace_frame = ui_focused_ab_trace_frame + 1

    local phase_a_start = ui_focused_ab_warmup_frames
    local swap_frame = phase_a_start + ui_focused_ab_sample_frames
    local phase_b_start = swap_frame + ui_focused_ab_warmup_frames
    local complete_frame = phase_b_start + ui_focused_ab_sample_frames

    if ui_focused_ab_trace_frame == phase_a_start then
        local result = ui_native_capture.dtvr_set_focused_trace_phase(1)
        mod:info(
            "DARKTIDEVR_STEREO focused_trace phase=A primary_half=left result=%d",
            tonumber(result)
        )
    elseif ui_focused_ab_trace_frame == swap_frame then
        ui_native_capture.dtvr_set_focused_trace_phase(0)
        ui_swap_viewport_halves_requested = true
        apply_ui_direct_sbs_rects(
            ui_stereo_spawner._viewport,
            ui_stereo_right_viewport
        )
        mod:info(
            "DARKTIDEVR_STEREO focused_trace warmup=B primary_half=right"
        )
    elseif ui_focused_ab_trace_frame == phase_b_start then
        local result = ui_native_capture.dtvr_set_focused_trace_phase(2)
        mod:info(
            "DARKTIDEVR_STEREO focused_trace phase=B primary_half=right result=%d",
            tonumber(result)
        )
    elseif ui_focused_ab_trace_frame == complete_frame then
        ui_native_capture.dtvr_set_focused_trace_phase(0)
        ui_focused_ab_trace_complete = true
        mod:info(
            "DARKTIDEVR_STEREO focused_trace complete records=%d",
            tonumber(ui_native_capture.dtvr_focused_trace_count())
        )
    end
end

local function teardown_ui_stereo()
    if ui_native_capture then
        -- Character-select and gameplay stereo sources overlap during world
        -- transitions. The old UI world can be destroyed after CameraManager
        -- has already activated the gameplay producer; unconditionally
        -- clearing this process-wide flag then silently stops fresh eye pairs.
        -- Release projection only when no gameplay stereo owner remains.
        ui_native_capture.dtvr_set_projection_active(active and 1 or 0)
        mod:info(
            "DARKTIDEVR_STEREO ui_teardown projection_owner=%s",
            active and "gameplay" or "none")
    end
    if ui_native_capture then
        ui_native_capture.dtvr_disable_rich_center_sbs_remap()
        ui_native_capture.dtvr_disable_alternating_full_capture()
        ui_native_capture.dtvr_disable_top_bottom_capture()
        if ui_alternating_full_requested or ui_top_bottom_requested then
            ui_native_capture.dtvr_disable_present_capture()
        end
    end

    if ui_stereo_world then
        if ui_stereo_spawner and ui_stereo_spawner._viewport then
            Viewport.set_rect(ui_stereo_spawner._viewport, 0, 0, 1, 1)
        end

        if ScriptWorld.has_viewport(ui_stereo_world, ui_stereo_right_name) then
            ScriptWorld.destroy_viewport(ui_stereo_world, ui_stereo_right_name)
        end
    end

    ui_stereo_spawner = nil
    ui_stereo_world = nil
    ui_stereo_right_viewport = nil
    ui_base_vertical_fov = nil
end

local function destroy_ui_offscreen_resources()
    if ui_left_material then
        Gui.destroy_material(ui_left_material.gui, ui_left_material.material)
        ui_left_material = nil
    end

    if ui_right_material then
        Gui.destroy_material(ui_right_material.gui, ui_right_material.material)
        ui_right_material = nil
    end

    if ui_left_render_target then
        Renderer.destroy_resource(ui_left_render_target)
        ui_left_render_target = nil
    end

    if ui_right_render_target then
        Renderer.destroy_resource(ui_right_render_target)
        ui_right_render_target = nil
    end

    if ui_left_output_target then
        Renderer.destroy_resource(ui_left_output_target)
        ui_left_output_target = nil
    end

    if ui_right_output_target then
        Renderer.destroy_resource(ui_right_output_target)
        ui_right_output_target = nil
    end

    ui_offscreen_active = false
end

local function create_eye_render_target(name, width, height)
    ResourceReferenceContext.push("DarktideVR:offscreen_stereo")
    ResourceReferenceContext.push(name)
    local target = Renderer.create_resource(
        "render_target",
        "R8G8B8A8",
        nil,
        width,
        height,
        name
    )
    ResourceReferenceContext.pop(name)
    ResourceReferenceContext.pop("DarktideVR:offscreen_stereo")

    return target
end

local function eye_render_target_mapping(output_target, back_buffer)
    if false then
        return { back_buffer = back_buffer }
    end

    return {
        output_target = output_target,
        back_buffer = back_buffer
    }
end

local function setup_ui_stereo(spawner)
    local world = spawner._world
    local primary = spawner._viewport

    if not world or not primary then
        return
    end

    assert(ensure_ui_native_hooks() and refresh_xr_render_extent(),
        "stereo menu setup requires the active OpenXR render extent")

    if ScriptWorld.has_viewport(world, ui_stereo_right_name) then
        ScriptWorld.destroy_viewport(world, ui_stereo_right_name)
    end

    local shading_environment_name =
        Viewport.get_data(primary, "default_shading_environment_name")
    local shading_callback = Viewport.get_data(primary, "shading_callback")
    local viewport_layer = Viewport.get_data(primary, "layer")
    if not shading_environment_name then
        error("main-menu viewport has no shading environment")
    end

    if ui_offscreen_requested then
        if ui_offscreen_primary_requested and
                (not ui_left_render_target or not ui_left_output_target) then
            error("primary eye targets were not installed at viewport creation")
        end

        ui_right_output_target = create_eye_render_target(
            "darktidevr_right_eye_output",
            ui_eye_target_width,
            ui_eye_target_height
        )
        ui_right_render_target = create_eye_render_target(
            "darktidevr_right_eye_final",
            ui_eye_target_width,
            ui_eye_target_height
        )
        ui_offscreen_active = true
    end

    local right = ScriptWorld.create_viewport(
        world,
        ui_stereo_right_name,
        ui_offscreen_active and "default_with_alpha" or "default",
        2,
        nil,
        nil,
        nil,
        false,
        shading_environment_name,
        shading_callback,
        nil,
        -- `output_target` drives the deferred attachment dimensions, while
        -- `back_buffer` receives the completed/tonemapped viewport. They must
        -- be distinct: mapping only one either leaves the world graph at the
        -- desktop size or exposes an internal intermediate to the compositor.
        ui_offscreen_active and eye_render_target_mapping(
            ui_right_output_target,
            ui_right_render_target
        ) or nil
    )

    if ui_top_bottom_requested then
        if not ensure_ui_native_hooks() then
            error("top/bottom eye publication requires native hooks")
        end
        local layout_result = ui_native_capture.dtvr_enable_top_bottom_capture()
        local capture_result = ui_native_capture.dtvr_enable_present_capture()
        if layout_result ~= 0 or capture_result ~= 0 then
            error("top/bottom eye publication failed")
        end
        Viewport.set_rect(primary, 0, 0, 1, 0.5)
        Viewport.set_rect(right, 0, 0.5, 1, 0.5)
    elseif ui_alternating_full_requested then
        if not ensure_ui_native_hooks() then
            error("alternating full-eye capture requires native hooks")
        end
        local alternating_result =
            ui_native_capture.dtvr_enable_alternating_full_capture()
        local capture_result = ui_native_capture.dtvr_enable_present_capture()
        if alternating_result ~= 0 or capture_result ~= 0 then
            error("alternating full-eye capture failed")
        end
        Viewport.set_rect(primary, 0, 0, 1, 1)
        Viewport.set_rect(right, 0, 0, 1, 1)
        ui_alternating_full_eye = 0
        ui_alternating_full_last_present =
            tonumber(ui_native_capture.dtvr_present_count())
        ScriptWorld.activate_viewport(world, primary)
        ScriptWorld.deactivate_viewport(world, right)
        ui_native_capture.dtvr_set_alternating_present_eye(0)
    elseif ui_rich_center_sbs_remap_requested then
        if not ensure_ui_native_hooks() then
            error("rich-center SBS remap requires native hooks")
        end
        local remap_result =
            ui_native_capture.dtvr_enable_rich_center_sbs_remap()
        if remap_result ~= 0 then
            error("native rich-center SBS remap failed: " ..
                tostring(remap_result))
        end
        apply_ui_rich_center_sbs_rects(primary, right)
    elseif ui_double_render_probe_requested then
        Viewport.set_rect(primary, 0, 0, 1, 1)
        Viewport.set_rect(right, 0, 0, 1, 1)
    elseif ui_native_capture_active then
        Viewport.set_rect(primary, 0, 0, 1, 1)
        Viewport.set_rect(right, 0, 0, 1, 1)
    elseif ui_offscreen_active then
        Viewport.set_rect(primary, 0, 0, 1, 1)
        Viewport.set_rect(right, 0, 0, 1, 1)
    else
        apply_ui_direct_sbs_rects(primary, right)
    end
    ui_base_vertical_fov = Camera.vertical_fov(spawner._camera)
    ui_stereo_spawner = spawner
    ui_stereo_world = world
    ui_stereo_right_viewport = right
    if ui_full_origin_ab_requested then
        ui_full_origin_ab_start_present = nil
        ui_full_origin_ab_duplicate_active = false
        ui_full_origin_ab_complete = false
    end
    if ui_camera_freeze_requested then
        ui_camera_freeze_start_present = nil
        ui_camera_frozen_position = nil
        ui_camera_frozen_rotation = nil
    end
    if ui_rect_matrix_requested then
        ui_rect_matrix_start_present = nil
        ui_rect_matrix_phase = 0
        ui_rect_matrix_complete = false
    end
    if ui_rect_trace_requested then
        ui_rect_trace_phase = 0
        ui_rect_trace_phase_start_present = nil
        ui_rect_trace_sample_start_present = nil
        ui_rect_trace_sampling = false
        ui_rect_trace_complete = false
    end
    if ui_focused_ab_trace_requested then
        ui_focused_ab_trace_frame = 0
        ui_focused_ab_trace_complete = false
        ui_swap_viewport_halves_requested = false
        apply_ui_direct_sbs_rects(primary, right)
    end
    if ui_offscreen_trace_requested then
        ui_offscreen_trace_frame = 0
        ui_offscreen_trace_complete = false
    end
    apply_ui_eye_offsets(spawner)
    ui_native_capture.dtvr_set_projection_active(1)
    mod:info(
        "DARKTIDEVR_STEREO active target=ui_main_menu_world mode=%s half_ipd=%.3f layer=%s/2 primary_half=%s",
        ui_top_bottom_requested and "top_bottom_same_horizontal_center" or
            (ui_alternating_full_requested and "alternating_full_origin" or
            (ui_rich_center_sbs_remap_requested and "rich_center_native_sbs" or
            (ui_offscreen_active and "offscreen_full_origin" or
                "binding_census_baseline"))),
        half_ipd,
        tostring(viewport_layer),
        ui_swap_viewport_halves_requested and "right" or "left"
    )
end

function presentation.body_model_eye_anchor(unit)
    if not unit or not Unit.alive(unit) then
        return nil, "unit_unavailable"
    end
    local candidates = { unit }
    local visual_loadout = ScriptUnit.has_extension(
        unit, "visual_loadout_system")
    if visual_loadout then
        local face_ok, face_unit = pcall(
            visual_loadout.unit_3p_from_slot,
            visual_loadout,
            "slot_body_face")
        if face_ok and face_unit and Unit.alive(face_unit) then
            candidates[#candidates + 1] = face_unit
        end
    end
    for i = 1, #candidates do
        local candidate = candidates[i]
        if Unit.has_node(candidate, "j_lefteye") and
                Unit.has_node(candidate, "j_righteye") then
            local left = Unit.world_position(
                candidate, Unit.node(candidate, "j_lefteye"))
            local right = Unit.world_position(
                candidate, Unit.node(candidate, "j_righteye"))
            return (left + right) * 0.5,
                candidate == unit and "player_rig" or "face_attachment",
                left,
                right
        end
    end
    return nil, "eye_nodes_missing"
end

-- Eye bones are calibration landmarks, not a live camera parent. Their world
-- transforms include facial/head animation, which would inject authored bob
-- and look motion into an otherwise runtime-owned 6DoF head pose. Capture the
-- midpoint once in the character root's coordinates, then move that stable
-- offset only with the locomotion/root transform. OpenXR supplies all motion
-- of the real viewer relative to this neutral model-eye origin.
-- The eye offsets are measured once per unit and then held. A unit that
-- spawns hanging at a respawn point (hogtied) or lies knocked down carries
-- its eyes far from where they sit standing; measuring there lowered the
-- view for the rest of the mission after a rescue. Measure only in ordinary
-- upright locomotion states; until then the first-person fallback serves.
local upright_states = {walking=true, sprinting=true, sliding=true, jumping=true,
    falling=true, dodging=true, interacting=true, minigame=true, lunging=true,
    stunned=true, exploding=true}
function presentation.body_upright_state(unit)
    local extension = unit and ScriptUnit.has_extension(unit, "character_state_machine_system")
    if not extension then return true end
    local ok, name = pcall(extension.current_state_name, extension)
    return ok and upright_states[name] == true
end

function presentation.body_stable_eye_anchor(unit)
    if not unit or not Unit.alive(unit) then
        return nil, "unit_unavailable"
    end
    local observation = controller_observation
    local needs_capture = observation.body_eye_anchor_unit ~= unit or
        observation.body_eye_anchor_local_x == nil
    if needs_capture and not presentation.body_upright_state(unit) then
        return nil, "state_not_upright"
    end
    local measured_eye = nil
    local measured_source = observation.body_eye_anchor_source
    local measured_left = nil
    local measured_right = nil
    local root_position = Unit.world_position(unit, 1)
    local root_rotation = Unit.world_rotation(unit, 1)
    if needs_capture then
        measured_eye, measured_source, measured_left, measured_right =
            presentation.body_model_eye_anchor(unit)
        if not measured_eye then
            return nil, measured_source
        end
        local root_inverse = presentation.inverse_quaternion(root_rotation)
        local local_eye = presentation.rotate_vector(
            root_inverse, measured_eye - root_position)
        observation.body_eye_anchor_unit = unit
        observation.body_eye_anchor_local_x = Vector3.x(local_eye)
        observation.body_eye_anchor_local_y = Vector3.y(local_eye)
        observation.body_eye_anchor_local_z = Vector3.z(local_eye)
        observation.body_eye_anchor_source = measured_source
    end
    local local_eye = Vector3(
        observation.body_eye_anchor_local_x,
        observation.body_eye_anchor_local_y,
        observation.body_eye_anchor_local_z)
    return root_position +
            presentation.rotate_vector(root_rotation, local_eye),
        observation.body_eye_anchor_source,
        measured_left,
        measured_right,
        needs_capture
end

-- The model eye sits a little forward of and above the authoritative
-- first-person position. That offset is anatomical, so it must be measured in
-- the avatar's own aim frame and only then expressed in the recenter basis,
-- which is where it belongs: the anchor is the neutral eye origin, the one the
-- tracked head pose is added to, and at recenter the aim looks along the basis.
-- Measuring it in the basis directly (as this did) only holds while the avatar
-- happens to face along it. Entering a scene turned 90 degrees away put the
-- eye's forward depth on the basis' lateral axis, which is then zeroed, so the
-- depth was lost; the 8.52 cm lateral offset once measured in the Psykhanium
-- was that depth, not an anatomical sideways shift.
-- Animation audit item K (docs/phase1/animation-audit-2026-09-16.md): reading
-- the aim rather than the 3p root also keeps the capture clear of the root's
-- turn-to-run-at-an-angle, and a pitched aim defers it rather than baking a
-- look-down into the height.
presentation.MAX_EYE_CAPTURE_PITCH = math.rad(15)

-- The lateral-free eye offset for an aim rotation, in that aim's yaw frame, so
-- it can be applied in the recenter basis. A cyclopean camera has no
-- anatomical lateral offset, so only depth and height are kept. nil with a
-- reason when the aim is pitched too far to measure from.
-- A capture deferred this long takes whatever pitch it can get. Waiting for a
-- level view is right at first, but a player who spends a minute looking down
-- would otherwise sit on the fallback origin, which is about 8.5 cm behind the
-- real one; and the jump when they finally look up is a world translation, not
-- a rotation, which is visible in a headset.
presentation.EYE_CAPTURE_DEADLINE = 2

-- The measured anchor puts the camera on the avatar's own eyes, and worn that
-- still reads as sitting too low and too far back inside the head (user, 18
-- September: "eyes only need to come up ~5cm, they also need to come forward
-- ~5cm too"). The measurement is not wrong -- the model's eye node is where it
-- is -- so this is a correction on top of it rather than a different
-- measurement. In the aim's own yaw frame, +y is forward and +z is up, so both
-- are positive. The capture reads about 8.5 cm forward and 6 cm above the
-- first-person position, which these take to about 13.5 cm and 11 cm.
presentation.EYE_ANCHOR_FORWARD_M = 0.05
presentation.EYE_ANCHOR_UP_M = 0.05

function presentation.cyclopean_eye_offset(aim_rotation, offset, allow_pitch)
    if not aim_rotation or not offset then return nil, "aim_unavailable" end
    local ok, pitch = pcall(Quaternion.pitch, aim_rotation)
    if not ok or type(pitch) ~= "number" or pitch ~= pitch then return nil, "aim_unavailable" end
    if not allow_pitch and math.abs(pitch) > presentation.MAX_EYE_CAPTURE_PITCH then
        return nil, "aim_pitched"
    end
    local yaw_only = Quaternion.from_yaw_pitch_roll(Quaternion.yaw(aim_rotation), 0, 0)
    local local_offset = presentation.rotate_vector(
        presentation.inverse_quaternion(yaw_only), offset)
    return Vector3(0, Vector3.y(local_offset), Vector3.z(local_offset))
end

-- Applied to the CAPTURED offset every call, never folded into the stored one:
-- the capture happens once per unit and a correction written into it would
-- compound on every later read. Pure, and separate from the measurement above
-- so the measurement stays a measurement.
function presentation.eye_anchor_correction(local_offset)
    if not local_offset then return nil end
    return Vector3(
        Vector3.x(local_offset),
        Vector3.y(local_offset) + presentation.EYE_ANCHOR_FORWARD_M,
        Vector3.z(local_offset) + presentation.EYE_ANCHOR_UP_M)
end

-- Where the camera goes before the capture succeeds, or when it cannot.
--
-- This has to carry the correction as well, and that is not tidiness. The
-- guess is 5 cm straight up; the capture is about 8.5 cm forward and 6 cm up.
-- The gap between them is a world-space translation of the whole scene at the
-- instant the capture lands, and bounding it is the reason
-- EYE_CAPTURE_DEADLINE exists at all. Correcting only the captured path would
-- have grown that jump from 8.6 cm to 14.8 cm -- making the artifact the
-- deadline was written against 72% worse, in the name of a 5 cm fix (review,
-- 18 September).
--
-- Without a basis there is no forward to put the forward term along, so only
-- the height is applied. That case already has no forward term to disagree
-- with, so it does not widen the jump either.
presentation.EYE_ANCHOR_FALLBACK_UP_M = 0.05
function presentation.eye_anchor_fallback(head_position, basis)
    if not head_position then return nil end
    local corrected = presentation.eye_anchor_correction(
        Vector3(0, 0, presentation.EYE_ANCHOR_FALLBACK_UP_M))
    if not basis then
        return head_position + Vector3.up() *
            (presentation.EYE_ANCHOR_FALLBACK_UP_M + presentation.EYE_ANCHOR_UP_M)
    end
    return head_position + presentation.rotate_vector(basis, corrected)
end

-- THE ANCHOR'S TIMELINE (19 September, 15:10). The first-person
-- component's position is written in the game's FIXED update: at ~113
-- frames a second it stands still for a frame and then steps 7 cm. The
-- camera, the hands, the weapon, the body copy and the skulls are all
-- built on it, so they step together and hold still against each other,
-- and the whole world steps against the player, and cloth simulated on
-- the stepping body jitters ("physics objects are still moving as if
-- there's still a flicker"). The game's first-person UNIT carries the
-- same point on its interpolated timeline (update_unit_position, every
-- frame from the interpolated root); the body mirror's probe has measured
-- the difference all day as anchor_lag_m. This returns the unit's position
-- when it is alive, the component's otherwise, and the anchor moves every
-- frame. Observable: the probe's d_eye_m, 0 then 0.074 until now, reads
-- one smooth step a frame; the copy's d_unit_rel_eye_m stays near zero.
-- THE CAMERA'S HEIGHT IS THE CALIBRATED EYE HEIGHT (19 September, 17:30).
-- Every log today read camera_origin=first_person_fallback: the model eye
-- anchor never captured, and the camera sat at the game's first-person
-- point -- its camera height times the character scale, 1.896 m -- plus
-- two 5 cm fallback offsets, 2.0 m above the floor, against the player's
-- calibrated 1.72. "every time I load into the psykh I'm too far up";
-- "resetting the camera view should reset headset height to the
-- calibrated height". The calibration knows the standing eye height, so
-- the camera's height above the avatar's root is that, whatever the anchor
-- source; the source still gives the horizontal position. The hands'
-- anchor takes the same height, so they agree.
function presentation.calibrated_eye_height()
    local result = mod.darktidevr_calibration and mod.darktidevr_calibration.result or mod:get("vr_calibration_v1")
    local height = result and not result.seated and tonumber(result.floor_eye_height)
    if height and height >= 0.8 and height <= 2.4 then return height end
    return nil
end
-- The game's own height changes still apply on top: crouching, sliding,
-- peeking and being knocked down lower the character's first-person point
-- (its extrapolated height against its standing one), and the calibrated
-- height is scaled by the same fraction. Pinned to the standing height alone,
-- the crouch button stopped moving the camera (worn, 17 October).
function presentation.game_height_fraction(unit)
    local first_person = ScriptUnit.has_extension(unit, "first_person_system")
    local standing = first_person and first_person._heights and
        tonumber(first_person._heights.default)
    local current = first_person and first_person.extrapolated_character_height and
        tonumber(first_person:extrapolated_character_height())
    if not standing or standing <= 0 or not current or current <= 0 then return 1 end
    return math.min(1, current / standing)
end
function presentation.at_calibrated_eye_height(position, unit)
    local height = presentation.calibrated_eye_height()
    if not height or not position or not unit or not Unit.alive(unit) then return position end
    height = height * presentation.game_height_fraction(unit)
    return Vector3(Vector3.x(position), Vector3.y(position), Vector3.z(Unit.world_position(unit, 1)) + height)
end
function presentation.anchor_head_position(first_person_extension)
    local component = first_person_extension and first_person_extension._first_person_component
    local eye_unit = first_person_extension and first_person_extension.first_person_unit and
        first_person_extension:first_person_unit()
    if eye_unit and Unit.alive(eye_unit) then
        local smooth = Unit.world_position(eye_unit, 1)
        if not component or not component.position or Vector3.length(smooth - component.position) <= 0.5 then
            return smooth
        end
    end
    return component and component.position
end
function presentation.body_camera_anchor(unit)
    if not unit or not Unit.alive(unit) then
        return nil, "unit_unavailable"
    end
    local first_person_extension = ScriptUnit.has_extension(
        unit, "first_person_system")
    local component = first_person_extension and
        first_person_extension._first_person_component
    local head_position = component and presentation.anchor_head_position(first_person_extension)
    local model_eye, eye_source, left_eye, right_eye, captured =
        presentation.body_stable_eye_anchor(unit)
    if not head_position then
        return model_eye, eye_source, left_eye, right_eye, captured
    end
    local observation = controller_observation
    if observation.body_camera_eye_offset_unit ~= unit or
            observation.body_camera_eye_offset_x == nil then
        if not model_eye or not active_base_rotation or
                not presentation.body_upright_state(unit) then
            return presentation.eye_anchor_fallback(head_position,
                    active_base_rotation and active_base_rotation:unbox()),
                "first_person_fallback", left_eye, right_eye, captured
        end
        -- Measured in the aim's own yaw frame, so the avatar's facing (and
        -- the root's turn to run at an angle) leaves the constant alone.
        -- Before the dev-flag read below: while this refuses, the whole block
        -- runs again every call, and that file was being opened three times a
        -- frame for as long as the player kept looking down.
        local waiting_since = observation.body_camera_eye_offset_since
        local now = Managers and Managers.time and Managers.time:time("main")
        if not waiting_since and now then
            observation.body_camera_eye_offset_since = now
            waiting_since = now
        end
        local overdue = now ~= nil and waiting_since ~= nil and
            now - waiting_since >= presentation.EYE_CAPTURE_DEADLINE
        local local_offset, refused = presentation.cyclopean_eye_offset(
            component.rotation, model_eye - head_position, overdue)
        if not local_offset then
            return presentation.eye_anchor_fallback(head_position,
                    active_base_rotation and active_base_rotation:unbox()),
                refused == "aim_pitched" and "aim_pitched" or "first_person_fallback",
                left_eye, right_eye, captured
        end
        local reverse_order_flag = Mods.lua.io.open(
            "./../mods/darktidevr/darktidevr_reverse_eye_order.flag",
            "r")
        local reverse_order_enabled = false
        if reverse_order_flag then
            reverse_order_enabled = reverse_order_flag:read("*all"):match(
                "^%s*enabled%s*$") ~= nil
            reverse_order_flag:close()
        end
        if reverse_order_enabled ~=
                presentation.reverse_eye_order_probe_requested then
            presentation.reverse_eye_order_probe_requested =
                reverse_order_enabled
            mod:info(
                "DARKTIDEVR_STEREO reverse_eye_order=%s source=test_flag",
                tostring(reverse_order_enabled))
        end
        observation.body_camera_eye_offset_unit = unit
        -- The wait is over: clear its start, or the NEXT capture (a body
        -- visibility toggle, a height calibration, a respawn) reads this one's
        -- timer, is overdue on its first frame, waives MAX_EYE_CAPTURE_PITCH
        -- and bakes whatever pitch the player happened to be holding into the
        -- height -- which is the fault this correction exists to fix, arriving
        -- by another door (review, 18 September).
        observation.body_camera_eye_offset_since = nil
        observation.body_camera_eye_offset_x = Vector3.x(local_offset)
        observation.body_camera_eye_offset_y = Vector3.y(local_offset)
        observation.body_camera_eye_offset_z = Vector3.z(local_offset)
        -- Once per unit: the numbers to compare across spawns. Depth and
        -- height should repeat whatever the avatar's facing; before audit K
        -- the depth followed the angle between that facing and the basis.
        local aim_yaw = Quaternion.yaw(component.rotation)
        local basis_yaw = Quaternion.yaw(active_base_rotation:unbox())
        mod:info("DARKTIDEVR_ANCHOR eye_capture depth_m=%.4f height_m=%.4f " ..
            "aim_from_basis_deg=%.1f source=%s overdue=%s",
            Vector3.y(local_offset), Vector3.z(local_offset),
            math.deg(aim_yaw - basis_yaw), tostring(eye_source), tostring(overdue == true))
    end
    local basis = active_base_rotation and active_base_rotation:unbox() or
        Quaternion.identity()
    local local_offset = presentation.eye_anchor_correction(Vector3(
        observation.body_camera_eye_offset_x,
        observation.body_camera_eye_offset_y,
        observation.body_camera_eye_offset_z))
    return head_position + presentation.rotate_vector(basis, local_offset),
        "stable_first_person_cyclopean_offset", left_eye, right_eye, captured
end

-- Diagnose the remaining avatar-centering error in a single, explicit scene
-- basis.  The neutral camera anchor should sit on the model-eye/head/shoulder
-- sagittal plane; tracked camera travel is reported separately so picking up
-- the headset cannot be mistaken for a bad anatomical anchor.  This is a
-- measurement only: no corrective offset is authored here.
function presentation.log_body_camera_alignment(
        unit, neutral_camera, tracked_camera)
    if not unit or not Unit.alive(unit) or not active_base_rotation then
        return
    end
    local now = Managers and Managers.time and Managers.time:time("main") or 0
    if now < (presentation.body_alignment_last_t or -math.huge) + 1 then
        return
    end
    if not Unit.has_node(unit, "j_head") or
            not Unit.has_node(unit, "j_leftarm") or
            not Unit.has_node(unit, "j_rightarm") then
        return
    end
    presentation.body_alignment_last_t = now
    local scene_right = Quaternion.right(active_base_rotation:unbox())
    local root = Unit.world_position(unit, 1)
    local head = Unit.world_position(unit, Unit.node(unit, "j_head"))
    local left_shoulder = Unit.world_position(
        unit, Unit.node(unit, "j_leftarm"))
    local right_shoulder = Unit.world_position(
        unit, Unit.node(unit, "j_rightarm"))
    local shoulder_midpoint = (left_shoulder + right_shoulder) * 0.5
    local model_eye = presentation.body_model_eye_anchor(unit)
    local stable_eye = presentation.body_stable_eye_anchor(unit)
    local first_person_extension = ScriptUnit.has_extension(
        unit, "first_person_system")
    local component = first_person_extension and
        first_person_extension._first_person_component
    local first_person = component and presentation.anchor_head_position(first_person_extension) or neutral_camera
    mod:info(
        "DARKTIDEVR_BODY_ALIGNMENT neutral_to_root_right_m=%.5f neutral_to_head_right_m=%.5f neutral_to_shoulders_right_m=%.5f neutral_to_live_eyes_right_m=%.5f neutral_to_stable_eyes_right_m=%.5f neutral_to_first_person_right_m=%.5f tracked_from_neutral_right_m=%.5f neutral=%.4f,%.4f,%.4f head=%.4f,%.4f,%.4f shoulders=%.4f,%.4f,%.4f",
        Vector3.dot(neutral_camera - root, scene_right),
        Vector3.dot(neutral_camera - head, scene_right),
        Vector3.dot(neutral_camera - shoulder_midpoint, scene_right),
        model_eye and Vector3.dot(
            neutral_camera - model_eye, scene_right) or -999,
        stable_eye and Vector3.dot(
            neutral_camera - stable_eye, scene_right) or -999,
        Vector3.dot(neutral_camera - first_person, scene_right),
        Vector3.dot(tracked_camera - neutral_camera, scene_right),
        Vector3.x(neutral_camera), Vector3.y(neutral_camera),
        Vector3.z(neutral_camera), Vector3.x(head), Vector3.y(head),
        Vector3.z(head), Vector3.x(shoulder_midpoint),
        Vector3.y(shoulder_midpoint), Vector3.z(shoulder_midpoint))
end

-- Arm IK runs at the post-animation first-person seam, before the later
-- stereo camera update refreshes its clean tracking anchor. Rebuild that
-- anchor from the avatar's final authored root transform here; otherwise
-- controller targets trail artificial locomotion by one render frame. The
-- body-heading correction must run first: Darktide turns the stock root toward
-- travel, and sampling the off-centre model-eye anchor before restoring HMD
-- heading makes both wrist targets trace a fixed-radius circle with the stick.
function presentation.roomscale_anchor_offset(unit, rotation)
    controller_observation.body_anchor_pose_sequence = 0
    if not presentation.roomscale or not head_translation_requested or
            not head_pose_values or not head_pose_sequence or
            presentation.read_head_pose() ~= 0 then return Vector3.zero() end
    controller_observation.body_anchor_pose_sequence = tonumber(head_pose_sequence[0])
    controller_observation.body_anchor_pose_generation = tonumber(presentation.head_pose_transport_generation[0])
    controller_observation.body_anchor_recenter_generation = tonumber(head_pose_values[23])
    local player = Managers and Managers.player and Managers.player:local_player(1)
    unit = unit or (player and player.player_unit)
    local x, y, z = presentation.roomscale.offset(unit,
        tostring(tonumber(presentation.head_pose_transport_generation[0])) .. ":" ..
            tostring(tonumber(head_pose_values[23])),
        tonumber(head_pose_sequence[0]), Managers.time:time("main"),
        tonumber(head_pose_values[20]), tonumber(head_pose_values[22]),
        tonumber(head_pose_values[1]), tonumber(head_pose_values[24]),
        presentation.calibrated_character_scale(player), Quaternion.yaw(rotation))
    return Vector3(x, y, z)
end

function presentation.refresh_body_anchor_from_avatar(unit)
    if not active_base_rotation or not unit or not Unit.alive(unit) then
        return false
    end
    local eye_position = presentation.body_camera_anchor(unit)
    if not eye_position then
        return false
    end
    local anchor_rotation = active_base_rotation:unbox()
    eye_position = presentation.at_calibrated_eye_height(eye_position, unit)
    eye_position = eye_position + presentation.roomscale_anchor_offset(unit, anchor_rotation)
    -- The former one-user lateral correction subtracted 6 cm along the
    -- recenter-frame right axis. That is exactly a persistent leftward camera
    -- displacement and, by construction, cannot be changed by recentering.
    -- The stable model-eye anchor already contains the skeleton's anatomical
    -- eye depth. Applying an extra correction through camera-forward turned
    -- that depth into a 7.5 cm lateral displacement whenever the gameplay
    -- camera's authored heading differed from the avatar basis.
    controller_observation.body_anchor_x = Vector3.x(eye_position)
    controller_observation.body_anchor_y = Vector3.y(eye_position)
    controller_observation.body_anchor_z = Vector3.z(eye_position)
    controller_observation.body_anchor_qx,
        controller_observation.body_anchor_qy,
    controller_observation.body_anchor_qz,
        controller_observation.body_anchor_qw =
            Quaternion.to_elements(anchor_rotation)
    return true
end

local function update_stereo(manager)
    presentation.eye_transform_probe_check_frame =
        presentation.eye_transform_probe_check_frame + 1
    if presentation.eye_transform_probe_check_frame >=
            presentation.eye_transform_probe_last_check_frame + 60 then
        presentation.eye_transform_probe_last_check_frame =
            presentation.eye_transform_probe_check_frame
        local probe_flag = Mods.lua.io.open(
            "./../mods/darktidevr/darktidevr_coincident_eyes.flag",
            "r")
        local probe_value = "disabled"
        if probe_flag then
            probe_value = probe_flag:read("*all"):match("^%s*(.-)%s*$") or
                "disabled"
            probe_flag:close()
        end
        local probe_mode = probe_value == "enabled" and "coincident" or
            probe_value
        if probe_mode ~= "coincident" and probe_mode ~= "zero_ipd" and
                probe_mode ~= "matched_orientation" and
                probe_mode ~= "visibility_padding" then
            probe_mode = "disabled"
        end
        if probe_mode ~= presentation.eye_transform_probe_mode then
            presentation.eye_transform_probe_mode = probe_mode
            mod:info(
                "DARKTIDEVR_STEREO eye_transform_probe=%s source=test_flag",
                probe_mode)
        end
    end
    if not requested or failed then
        return
    end

    if active and manager ~= active_manager then
        teardown()
    end

    if not active and not setup(manager) then
        return
    end

    local world = active_world
    local primary_viewport = ScriptWorld.viewport(world, primary_viewport_name)
    local right_viewport = ScriptWorld.viewport(world, right_viewport_name)
    local primary_camera = ScriptViewport.camera(primary_viewport)
    local right_camera = ScriptViewport.camera(right_viewport)
    local clean_position = ScriptCamera.local_position(primary_camera)
    local body_anchor_position = clean_position
    -- A stereo cinematic keeps the game camera's own origin and yaw; the
    -- body anchor and the room anchor's yaw step aside until it ends.
    local cinematic_stereo = presentation.cinematic_stereo_active()
    if cinematic_stereo ~= controller_observation.cinematic_stereo_logged then
        controller_observation.cinematic_stereo_logged = cinematic_stereo
        mod:info("DARKTIDEVR_STEREO cinematic=%s camera=%s",
            cinematic_stereo and "stereo" or "off",
            cinematic_stereo and "game_translation_yaw" or "anchor")
        -- The viewer's reticle follows the published scale; zero hides it
        -- for the cinematic and the setting returns afterwards.
        if presentation.crosshair_feedback and presentation.crosshair_feedback.set_hidden then
            presentation.crosshair_feedback.set_hidden(cinematic_stereo)
        end
    end
    -- Keep Darktide's genuine 3P camera tree active so its skinned-local-player
    -- submission policy remains active, but replace the tree's final render
    -- origin with the first-person head anchor. Choosing the 1P camera tree
    -- itself suppresses the skinned body even when every unit/slot is visible.
    if controller_observation.body_visibility_enabled and not cinematic_stereo then
        local local_player = Managers and Managers.player and
            Managers.player:local_player(1)
        local player_unit = local_player and local_player.player_unit
        presentation.body_alignment_unit = player_unit
        local first_person_extension = player_unit and
            ScriptUnit.has_extension(player_unit, "first_person_system")
        local first_person_component = first_person_extension and
            first_person_extension._first_person_component
        if first_person_component and first_person_component.position then
            local head_position = presentation.anchor_head_position(first_person_extension)
            local model_eye_position, eye_source, left_eye, right_eye,
                eye_anchor_captured =
                    presentation.body_camera_anchor(player_unit)
            clean_position = model_eye_position or
                presentation.eye_anchor_fallback(head_position,
                    active_base_rotation and active_base_rotation:unbox())
            clean_position = presentation.at_calibrated_eye_height(clean_position, player_unit)
            body_anchor_position = clean_position
            if not controller_observation.body_camera_anchor_logged then
                controller_observation.body_camera_anchor_logged = true
                mod:info(
                    "DARKTIDEVR_BODY camera_origin=%s camera=%.4f,%.4f,%.4f first_person=%.4f,%.4f,%.4f tree_preserved=third_person",
                    tostring(model_eye_position and eye_source or
                        "head_fallback"),
                    Vector3.x(clean_position),
                    Vector3.y(clean_position),
                    Vector3.z(clean_position),
                    Vector3.x(head_position),
                    Vector3.y(head_position),
                    Vector3.z(head_position))
                if model_eye_position and eye_anchor_captured then
                    mod:info(
                        "DARKTIDEVR_BODY model_eyes calibration=stable_root_space left=%.4f,%.4f,%.4f right=%.4f,%.4f,%.4f ipd=%.4f corrected_first_person_delta=%.4f,%.4f,%.4f correction=%.2f,%.2f",
                        Vector3.x(left_eye), Vector3.y(left_eye),
                        Vector3.z(left_eye), Vector3.x(right_eye),
                        Vector3.y(right_eye), Vector3.z(right_eye),
                        presentation.vector_distance(left_eye, right_eye),
                        Vector3.x(model_eye_position - head_position),
                        Vector3.y(model_eye_position - head_position),
                        -- Named, because DARKTIDEVR_ANCHOR eye_capture prints
                        -- the RAW capture a few lines away and the two now
                        -- differ by exactly this. A log that quietly disagrees
                        -- with itself is what cost the day's first diagnosis.
                        Vector3.z(model_eye_position - head_position),
                        presentation.EYE_ANCHOR_FORWARD_M,
                        presentation.EYE_ANCHOR_UP_M)
                end
            end
        end
    end
    -- The game remains authoritative for camera translation, but VR owns the
    -- complete orientation. Reusing the live game rotation allowed orbital
    -- camera pitch/roll (and occasionally the prior tracked result) to feed
    -- back into the next headset pose when the player moved vertically.
    local clean_rotation = active_base_rotation:unbox()
    if controller_observation.body_visibility_enabled then
        -- body_camera_anchor is already the calibrated model-eye origin. Do
        -- not add a second camera-basis depth term here: in a rotated scene it
        -- becomes the persistent lateral offset seen after recentering.
        body_anchor_position = clean_position
    end
    if game_rotation_mode == "yaw_only" or cinematic_stereo then
        local live_rotation = ScriptCamera.local_rotation(primary_camera)
        local yaw_delta = Quaternion.yaw(live_rotation) -
            Quaternion.yaw(clean_rotation)
        clean_rotation = Quaternion.multiply(
            Quaternion.axis_angle(Vector3.up(), yaw_delta),
            clean_rotation
        )
    end
    local roomscale_offset = presentation.roomscale_anchor_offset(nil, clean_rotation)
    clean_position = clean_position + roomscale_offset
    body_anchor_position = body_anchor_position + roomscale_offset
    controller_observation.body_anchor_x = Vector3.x(body_anchor_position)
    controller_observation.body_anchor_y = Vector3.y(body_anchor_position)
    controller_observation.body_anchor_z = Vector3.z(body_anchor_position)
    controller_observation.body_anchor_qx,
        controller_observation.body_anchor_qy,
    controller_observation.body_anchor_qz,
        controller_observation.body_anchor_qw =
            Quaternion.to_elements(clean_rotation)
    -- Full keyboard and mouse mouselook tilts the room about the anchor's
    -- horizontal axis. It stays out of the published yaw-only anchor above.
    local keyboard_mouse_pitch = not cinematic_stereo and presentation.keyboard_mouse_view_pitch() or 0
    if keyboard_mouse_pitch ~= 0 then
        clean_rotation = Quaternion.multiply(clean_rotation,
            Quaternion.axis_angle(Vector3.right(), keyboard_mouse_pitch))
    end
    clean_position, clean_rotation = apply_head_tracking(
        clean_position,
        clean_rotation
    )
    clean_rotation = presentation.apply_offline_benchmark_spin(clean_rotation)
    presentation.store_tracked_eye(clean_position, clean_rotation)
    if controller_observation.body_visibility_enabled then
        presentation.log_body_camera_alignment(
            presentation.body_alignment_unit,
            body_anchor_position,
            clean_position)
    end
    -- The temporary gameplay aim policy authors Darktide's first-person
    -- orientation from the cyclopean HMD pose, so locomotion and the implicit
    -- screen-centre reticle do not follow either hand. Body heading comes from
    -- the shared scene heading (including stick turns) plus physical HMD yaw.
    -- Weapon-relative aim remains independent of the locomotion frame.
    controller_observation.body_head_yaw =
        Quaternion.yaw(active_base_rotation:unbox()) +
        (controller_observation.physical_head_yaw or 0)
    if ui_native_capture and (billboard_horizon_lock_requested or
            billboard_selector_probe_requested) then
        local horizon_rotation = Quaternion.axis_angle(
            Vector3.up(), Quaternion.yaw(clean_rotation))
        local billboard_right = Quaternion.right(horizon_rotation)
        local billboard_up = Quaternion.up(horizon_rotation)
        if billboard_horizon_lock_requested and
                billboard_direct_write_requested then
            ui_native_capture.dtvr_set_billboard_direct_view_direction(
                billboard_right.x, billboard_right.y, 1)
        else
            ui_native_capture.dtvr_set_billboard_view_basis(
                billboard_right.x, billboard_right.y, billboard_right.z,
                billboard_up.x, billboard_up.y, billboard_up.z,
                2
            )
        end
    end
    local eye_axis = Quaternion.right(clean_rotation)

    local runtime_projection_matches_target = head_render_vertical_fov and
        head_render_aspect_ratio and
        math.abs(head_render_aspect_ratio -
            (ui_eye_target_width / ui_eye_target_height)) < 0.001
    -- The magnification the eyes are actually rendered with. The reticle is
    -- corrected for it, and correcting for a zoom that never reached the
    -- cameras is the original error with its sign flipped (review,
    -- 18 September).
    presentation.ads_zoom_applied = runtime_projection_matches_target and
        presentation.ads_zoom_frame or 1
    -- The viewer is told THIS, the magnification the eyes are actually
    -- rendered with, so the projection it submits to the runtime is the one
    -- these cameras used. Every frame rather than on change: the producer
    -- lets the value decay to 1 if it stops hearing, so silence has to mean
    -- "no zoom" rather than "carry on".
    if presentation.native_gameplay_zoom then
        pcall(presentation.native_gameplay_zoom,
            presentation.ads_zoom_applied or 1)
    end
    local left_optical_rotation = nil
    local right_optical_rotation = nil
    if runtime_projection_matches_target then
        Camera.set_near_range(right_camera, Camera.near_range(primary_camera))
        Camera.set_far_range(right_camera, Camera.far_range(primary_camera))
        left_optical_rotation, right_optical_rotation =
            apply_runtime_recentered_projection(primary_camera, right_camera)
        if not left_optical_rotation or not right_optical_rotation then
            Camera.set_vertical_fov(primary_camera, head_render_vertical_fov)
            Camera.set_vertical_fov(right_camera, head_render_vertical_fov)
        end
    end
    if presentation.eye_transform_probe_mode == "coincident" or
            presentation.eye_transform_probe_mode == "matched_orientation" then
        right_optical_rotation = left_optical_rotation
    end

    local effective_half_ipd =
        (presentation.eye_transform_probe_mode == "coincident" or
            presentation.eye_transform_probe_mode == "zero_ipd") and
                0 or half_ipd
    ScriptCamera.set_local_position(
        primary_camera,
        clean_position - eye_axis * effective_half_ipd
    )
    ScriptCamera.set_local_rotation(
        primary_camera,
        left_optical_rotation and
            Quaternion.multiply(clean_rotation, left_optical_rotation) or
            clean_rotation
    )
    ScriptCamera.set_local_position(
        right_camera,
        clean_position + eye_axis * effective_half_ipd
    )
    ScriptCamera.set_local_rotation(
        right_camera,
        right_optical_rotation and
            Quaternion.multiply(clean_rotation, right_optical_rotation) or
            clean_rotation
    )
    if not runtime_projection_matches_target then
        copy_projection(primary_camera, right_camera)
    end
    publish_render_projection(
        primary_camera, presentation.render_projection_vertical_fov)

    presentation.draw_world_menu_surface(
        world, clean_position, clean_rotation)
    local hud_width = presentation.hud_panel.distance
    local hud_center = 0
    if presentation.hud_panel.enabled() and head_render_frusta then
        local hud_aspect = ui_eye_target_width / ui_eye_target_height
        hud_width, hud_center = presentation.projection_math.binocular_panel_width(
            runtime_recentered_eye(head_render_frusta[1], hud_aspect),
            runtime_recentered_eye(head_render_frusta[2], hud_aspect),
            effective_half_ipd, presentation.hud_panel.distance,
            presentation.hud_panel.height, 2 * presentation.hud_panel.distance)
    end
    presentation.frame_profile.section("render.hud_panel", presentation.hud_panel.draw,
        world, clean_position, clean_rotation, hud_width, hud_center)
    -- Both of these show a whole atlas of cells on their quads, and both were
    -- the only draws in the camera update outside a profiler section, so
    -- every profile taken so far has been blind to them (survey, 18
    -- September). The pcall stays inside the section, so a failure is still
    -- caught and still reported once.
    if presentation.hand_overlay then
        local overlay_ok, overlay_error = presentation.frame_profile.section(
            "render.hand_overlay", pcall, presentation.hand_overlay.draw, world)
        if not overlay_ok and not presentation.hand_overlay_error_logged then
            presentation.hand_overlay_error_logged = true
            mod:error("DARKTIDEVR_HAND_OVERLAY draw_failed error=%s", tostring(overlay_error))
        end
    end
    if presentation.marker_atlas then
        local atlas_ok, atlas_error = presentation.frame_profile.section(
            "render.marker_atlas", pcall, presentation.marker_atlas.draw, world,
            presentation.marker_atlas_frame)
        if not atlas_ok and not presentation.marker_atlas_error_logged then
            presentation.marker_atlas_error_logged = true
            mod:error("DARKTIDEVR_MARKER_ATLAS draw_failed error=%s", tostring(atlas_error))
        end
    end
    if presentation.weapon_charge_display then
        presentation.frame_profile.section("render.weapon_charge",presentation.weapon_charge_display.draw,world,clean_position,clean_rotation)
    end
    if presentation.crosshair_feedback then
        presentation.frame_profile.section("render.crosshair_feedback",presentation.crosshair_feedback.draw,world,clean_position,clean_rotation)
    end

    ScriptCamera.force_update(world, primary_camera)
    ScriptCamera.force_update(world, right_camera)
end

mod:hook(World, "update_lod_levels", function(func, world, camera, ...)
    local rendered_fov = camera == presentation.lod_primary_camera and
        presentation.lod_primary_fov or
        camera == presentation.lod_right_camera and presentation.lod_right_fov
    if rendered_fov and (presentation.render_visibility_scale or 1) > 1 then
        if presentation.lod_logged_camera ~= camera then
            presentation.lod_logged_camera = camera
            mod:info("DARKTIDEVR_LOD visible_fov=%.4f visibility_fov=%.4f scale=%.4f",
                rendered_fov, Camera.vertical_fov(camera),
                presentation.render_visibility_scale)
        end
        return presentation.projection_math.update_lod_levels(
            func, world, camera, rendered_fov, ...)
    end
    return func(world, camera, ...)
end)

mod:hook(
    require("scripts/managers/ui/ui_manager"),
    "update",
    function(func, self, dt, t, ...)
    presentation.begin_menu_pointer_frame(presentation.menu_pointer)
    if presentation.visual_settings then
        presentation.visual_settings.update()
    end
    local result = func(self, dt, t, ...)
    presentation.reconcile_fullscreen_views(self)
    presentation.update_system_menu_test(self)
    presentation.update_dlss_quality_test()
    if presentation.gameplay_ui then presentation.gameplay_ui.update_menu(self) end
    presentation.update_vendor_menu_test(self)
    presentation.update_psykhanium(self, t or 0)
    if presentation.billboard_pixel_shader_probe_requested and
            ui_native_capture and
            (not presentation.billboard_pixel_probe_last_log_time or
                (t or 0) - presentation.billboard_pixel_probe_last_log_time >= 5) then
        presentation.billboard_pixel_probe_last_log_time = t or 0
        mod:info(
            "DARKTIDEVR_STEREO billboard_pixel_probe attempts=%d applied=%d validation_rejects=%d creation_rejects=%d",
            tonumber(ui_native_capture.dtvr_billboard_pixel_shader_probe_result_count(0)),
            tonumber(ui_native_capture.dtvr_billboard_pixel_shader_probe_result_count(1)),
            tonumber(ui_native_capture.dtvr_billboard_pixel_shader_probe_result_count(2)),
            tonumber(ui_native_capture.dtvr_billboard_pixel_shader_probe_result_count(3)))
    end
    return result
end)

-- Darktide's ordinary system/options views explicitly keep the game world
-- enabled (`disable_game_world = false`) and request `game_world_blur = 1.1`.
-- In stereo that post effect is applied to the stock player1 viewport only,
-- which is why menu open originally blurred the left eye. Spatial XR menus do
-- not use that world blur: the live projection remains untouched behind the
-- separate menu quad.
mod:hook(
    require("scripts/managers/ui/ui_manager"),
    "use_fullscreen_blur",
    function(func, self, ...)
        return false, 0
    end)

mod:hook_safe("InputManager", "update", function(self)
    local input_mark = presentation.frame_profile.begin()
    presentation.scan_input_services(self)
    presentation.update_menu_input_probe(self)
    if presentation.system_view_trace_pending and ui_native_capture then
        presentation.system_view_trace_pending = nil
        presentation.system_view_trace_phase = 1
        presentation.system_view_trace_frames = 4
        local marker_result = ui_native_capture.dtvr_enable_marker_log()
        local trace_result = ui_native_capture.dtvr_set_focused_trace_phase(1)
        mod:info(
            "DARKTIDEVR_MENU_TRACE started_deferred frames=%d marker_result=%s trace_result=%s",
            presentation.system_view_trace_frames,
            tostring(marker_result),
            tostring(trace_result))
    end
    local trace_frames = presentation.system_view_trace_frames
    if trace_frames and presentation.system_view_trace_phase == 2 then
        trace_frames = trace_frames - 1
        presentation.system_view_trace_frames = trace_frames
        if trace_frames <= 0 then
            presentation.system_view_trace_frames = nil
            presentation.system_view_trace_phase = nil
            if ui_native_capture then
                ui_native_capture.dtvr_set_focused_trace_phase(0)
            end
            mod:info("DARKTIDEVR_MENU_TRACE stopped reason=baseline_budget")
        end
    end
    presentation.frame_profile.finish("input.manager_update", input_mark)
end)

-- Gameplay and rendering share the cyclopean heading built from the immutable
-- scene anchor and tracked head. Integrating deltas from a separate stock spawn
-- yaw preserves any initial disagreement forever, including across map entry.
function presentation.observe_controller_aim(self, main_t, orientation_class, main_dt)
    if presentation.keyboard_mouse_enabled() then
        presentation.keyboard_mouse.touch(self, main_t, main_dt)
    end
    if main_t >= controller_observation.authoring_last_check_t + 1 then
        controller_observation.authoring_last_check_t = main_t
        local flag_path =
            "./../mods/darktidevr/darktidevr_controller_aim_test.flag"
        local flag = Mods.lua.io.open(flag_path, "r")
        -- Play default when the flag is absent; a present file decides.
        local enabled = true
        if flag then
            enabled = flag:read("*all"):match("^%s*enabled%s*$") ~= nil
            flag:close()
        end
        if enabled ~= controller_observation.authoring_enabled then
            controller_observation.authoring_enabled = enabled
            if not enabled then
                controller_observation.authoring_pose_active = false
                controller_observation.body_yaw_anchor = nil
                controller_observation.gameplay_yaw = nil
                controller_observation.gameplay_pitch = nil
                controller_observation.gameplay_roll = nil
                controller_observation.gameplay_orientation_owner = nil
                controller_observation.gameplay_orientation_suspended = false
            end
            mod:info(
                "DARKTIDEVR_AIM authoring=%s source=test_flag writes=%d",
                enabled and "enabled" or "disabled",
                controller_observation.authoring_writes
            )
        end
    end
    if not controller_observation.authoring_enabled or
            not controller_observation.head_aim_yaw or
            not controller_observation.head_aim_pitch then
        controller_observation.authoring_pose_active = false
        return
    end
    if head_pose_last_sequence ==
            controller_observation.first_person_seam_last_sequence then
        return
    end
    controller_observation.first_person_seam_last_sequence =
        head_pose_last_sequence
    local game_yaw = self._orientation.yaw
    local game_pitch = self._orientation.pitch
    local game_roll = self._orientation.roll
    local physical_yaw = controller_observation.physical_head_yaw or 0
    if controller_observation.gameplay_orientation_owner ~= self then
        controller_observation.gameplay_orientation_owner = self
        controller_observation.gameplay_yaw = game_yaw
        controller_observation.gameplay_pitch = game_pitch
        controller_observation.gameplay_roll = game_roll
        controller_observation.gameplay_orientation_suspended = false
        controller_observation.body_yaw_anchor = physical_yaw
        -- A new map's orientation owner may appear while the loading panel is
        -- still active. Keep the commit pending until gameplay authoring below
        -- is complete; a one-shot mode check here loses that transition.
        controller_observation.gameplay_generation_pending = "orientation_owner"
    end
    local prior_physical_yaw = controller_observation.body_yaw_anchor
    local yaw_delta = 0
    if prior_physical_yaw ~= nil then
        yaw_delta = physical_yaw - prior_physical_yaw
        if yaw_delta > math.pi then
            yaw_delta = yaw_delta - math.pi * 2
        elseif yaw_delta < -math.pi then
            yaw_delta = yaw_delta + math.pi * 2
        end
    end
    controller_observation.body_yaw_anchor = physical_yaw
    local gameplay_yaw = controller_observation.head_aim_yaw % (math.pi * 2)
    -- Third-person hub: the stock orientation (camera orbit and movement
    -- frame) follows the stick-turned room anchor rather than the head, so
    -- looking around does not swing the camera, and the right stick's
    -- vertical axis moves the orbit while the headset keeps its own pitch.
    local hub_third_person = presentation.hub_third_person_active()
    local hub_third_person_pitch = nil
    if hub_third_person then
        -- The mouse already moves this orbit; stick deltas add to the same
        -- stock orientation instead of owning it.
        if not controller_observation.hub_third_person_orbit then
            controller_observation.hub_third_person_orbit = true
            controller_observation.hub_third_person_yaw_delta = 0
            controller_observation.hub_third_person_pitch_delta = 0
            mod:info("DARKTIDEVR_AIM hub_third_person orbit=stock+stick yaw=%.4f pitch=%.4f",
                game_yaw, game_pitch)
        end
        -- A menu (mode 5/6) may point the stock orientation at its own
        -- camera; hold the orbit from before it opened until the modal
        -- restore below has put it back, or the camera returns elsewhere.
        local menu_open = presentation.mode == 5 or presentation.mode == 6 or
            controller_observation.gameplay_orientation_suspended
        if menu_open and controller_observation.hub_third_person_held_yaw then
            gameplay_yaw = controller_observation.hub_third_person_held_yaw
            hub_third_person_pitch = controller_observation.hub_third_person_held_pitch
        else
            -- Keyboard and mouse: the mouse orbit must turn the view as well,
            -- exactly as a stick turn does, or a seated player's character
            -- swings out of sight. Its change since the last write is the orbit.
            if presentation.keyboard_mouse_enabled() and active_base_rotation then
                local orbit = presentation.keyboard_mouse.orbit_turn(self, main_t, game_yaw,
                    controller_observation.hub_third_person_held_yaw)
                if orbit ~= 0 then
                    active_base_rotation:store(Quaternion.multiply(
                        Quaternion.axis_angle(Vector3.up(), orbit), active_base_rotation:unbox()))
                end
            end
            gameplay_yaw = (game_yaw +
                (controller_observation.hub_third_person_yaw_delta or 0)) % (math.pi * 2)
            -- Stock keeps pitch wrapped into [0, 2pi); add the delta in that
            -- range and leave the limits to the stock orientation update.
            hub_third_person_pitch = (game_pitch +
                (controller_observation.hub_third_person_pitch_delta or 0)) % (math.pi * 2)
            controller_observation.hub_third_person_held_yaw = gameplay_yaw
            controller_observation.hub_third_person_held_pitch = hub_third_person_pitch
        end
        controller_observation.hub_third_person_yaw_delta = 0
        controller_observation.hub_third_person_pitch_delta = 0
    else
        controller_observation.hub_third_person_orbit = nil
        controller_observation.hub_third_person_held_yaw = nil
        controller_observation.hub_third_person_held_pitch = nil
    end
    -- Keyboard and mouse: the stock orientation's mouse delta since the last
    -- write moves the aim inside a keyhole around the rendered view, and the
    -- excess turns the scene anchor exactly as stick turning does. Menus hold
    -- the aim; the modal restore below writes it back.
    local keyboard_mouse_pitch = nil
    if not hub_third_person and presentation.keyboard_mouse_enabled() then
        local aim_yaw, aim_pitch, turn = presentation.keyboard_mouse.observe(self, main_t,
            game_yaw, game_pitch, controller_observation.head_aim_yaw,
            controller_observation.head_aim_pitch,
            presentation.mode == 5 or presentation.mode == 6 or
                controller_observation.gameplay_orientation_suspended,
            self._min_pitch, self._max_pitch)
        if aim_yaw then
            gameplay_yaw, keyboard_mouse_pitch = aim_yaw, aim_pitch
            if turn ~= 0 and active_base_rotation then
                active_base_rotation:store(Quaternion.multiply(
                    Quaternion.axis_angle(Vector3.up(), turn), active_base_rotation:unbox()))
            end
        end
    end
    controller_observation.gameplay_yaw = gameplay_yaw

    -- Native fullscreen shop views temporarily force Darktide's mutable
    -- first-person orientation to their own camera. The rendered XR eyes do
    -- not use that orientation, so adopting it here leaves locomotion and
    -- interaction facing rotated away from what the player sees after exit.
    -- Keep the VR-owned heading following the rendered cyclopean pose while the
    -- shop is open, but do not feed the shop camera back into gameplay.
    -- Escape and inventory use the same compositor resume gate in missions
    -- and Psykhanium as vendors do in the hub. Always publish a restored
    -- gameplay generation when returning from these modal views.
    local modal_orientation = presentation.mode == 5 or presentation.mode == 6
    if presentation.mode ~= 1 then
        controller_observation.gameplay_generation_pending =
            controller_observation.gameplay_generation_pending or "presentation_resume"
    end
    if modal_orientation then
        if not controller_observation.gameplay_orientation_suspended then
            controller_observation.gameplay_pitch = game_pitch
            controller_observation.gameplay_roll = game_roll
            controller_observation.gameplay_orientation_suspended = true
            mod:info(
                "DARKTIDEVR_AIM modal_suspend yaw=%.4f pitch=%.4f roll=%.4f",
                gameplay_yaw, game_pitch, game_roll)
        end
        controller_observation.authoring_pose_active = false
        return
    end
    if controller_observation.gameplay_orientation_suspended then
        self._orientation.yaw = gameplay_yaw
        -- The third-person orbit restores the pitch held from before the
        -- menu; first person keeps the pitch stored at suspension.
        self._orientation.pitch = keyboard_mouse_pitch or hub_third_person_pitch or
            controller_observation.gameplay_pitch or game_pitch
        self._orientation.roll = controller_observation.gameplay_roll or
            game_roll
        controller_observation.gameplay_orientation_suspended = false
        controller_observation.gameplay_generation_pending = "modal_restore"
        mod:info(
            "DARKTIDEVR_AIM modal_restore yaw=%.4f pitch=%.4f roll=%.4f replaced=%.4f,%.4f,%.4f generation_pending=%d",
            self._orientation.yaw,
            self._orientation.pitch,
            self._orientation.roll,
            game_yaw, game_pitch, game_roll,
            presentation.sequence)
    else
        self._orientation.yaw = gameplay_yaw
        if hub_third_person_pitch then
            self._orientation.pitch = hub_third_person_pitch
        elseif keyboard_mouse_pitch then
            self._orientation.pitch = keyboard_mouse_pitch
        end
        controller_observation.gameplay_pitch = self._orientation.pitch
        controller_observation.gameplay_roll = game_roll
    end
    controller_observation.authoring_writes =
        controller_observation.authoring_writes + 1
    controller_observation.authoring_pose_active = true
    if presentation.mode == 1 and controller_observation.gameplay_generation_pending then
        local generation_result = tonumber(
            ui_native_capture.dtvr_commit_gameplay_generation(presentation.sequence))
        if generation_result == 0 or not controller_observation.gameplay_generation_last_log_t or
                main_t >= controller_observation.gameplay_generation_last_log_t + 2 then
            controller_observation.gameplay_generation_last_log_t = main_t
            mod:info("DARKTIDEVR_AIM gameplay_generation=%d result=%s reason=%s",
                presentation.sequence, tostring(generation_result),
                controller_observation.gameplay_generation_pending)
        end
        if generation_result == 0 then
            controller_observation.gameplay_generation_pending = nil
        end
    end
    if main_t < controller_observation.first_person_seam_last_log_t + 2 then
        return
    end
    controller_observation.first_person_seam_last_log_t = main_t
    mod:info(
        "DARKTIDEVR_AIM observation class=%s source=cyclopean_head_absolute sequence=%d head_ypr=%.4f,%.4f,%.4f prior_game_ypr=%.4f,%.4f,%.4f yaw_delta=%.4f write=enabled",
        orientation_class,
        head_pose_last_sequence,
        controller_observation.head_aim_yaw,
        controller_observation.head_aim_pitch,
        controller_observation.head_aim_roll or 0,
        game_yaw,
        game_pitch,
        game_roll,
        yaw_delta
    )
end

mod:hook_safe(
    require("scripts/extension_systems/first_person/character_state_orientation/default_player_orientation"),
    "pre_update",
    function(self, main_t, main_dt)
    presentation.observe_controller_aim(self, main_t, "default", main_dt)
    presentation.apply_keyboard_mouse_melee_roll(self, main_t)
end)

mod:hook_safe(
    require("scripts/extension_systems/first_person/character_state_orientation/hub_player_orientation"),
    "pre_update",
    function(self, main_t, main_dt)
        presentation.observe_controller_aim(self, main_t, "hub", main_dt)
    end)

local function active_game_mode_name()
    return presentation.gameplay_context.game_mode_name(
        Managers and Managers.state and Managers.state.game_mode)
end

presentation.gameplay_context = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_gameplay_context")
-- Remote (dedicated-server) missions admit stock input, presentation and the
-- stock-input aim route unless the user turns the setting off; the switch is
-- read per query so it applies without a relaunch.
presentation.gameplay_context.remote_missions_allowed = function()
    return mod:get("remote_mission_input") ~= false
end
-- Foundation only: keep the accepted right-dominant presentation until weapon
-- attachments/effects and input rearming support a complete handedness option.
presentation.weapon_hand_roles = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_weapon_hand_roles").new("right")
-- One answer to "which physical side is this role", including when the role
-- policy is somehow missing. Five modules each kept their own copy of the
-- right-dominant fallback table, which is five places to correct when the
-- handedness option lands (docs/phase1/handedness-audit-2026-09-16.md).
-- Kept on presentation rather than as a local: the main chunk is at LuaJIT's
-- 200-local ceiling.
presentation.DEFAULT_HAND_SIDES = {dominant = "right", support = "left", left = "left", right = "right"}
-- The policy answers when it is there, including answering nothing for a role
-- it does not know; the table is only for its absence.
function presentation.hand_side(role)
    local roles = presentation.weapon_hand_roles
    if roles then return roles.physical(role) end
    return presentation.DEFAULT_HAND_SIDES[role]
end

-- Whether a role's hand is tracking well enough to author aim with. The
-- callers meant "the weapon hand's aim is live" and read the right channel
-- (docs/phase1/handedness-audit-2026-09-16.md).
function presentation.hand_aim_usable(role)
    local side = presentation.hand_side(role)
    if side == "left" then return controller_observation.left_aim_usable == true end
    if side == "right" then return controller_observation.right_aim_usable == true end
    return false
end
presentation.online_rules = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_online_rules"
).install(mod, presentation, controller_observation, active_game_mode_name)
presentation.roomscale = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_roomscale"
).install(mod, presentation)
presentation.online_reticle = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_online_reticle"
).install(mod, presentation)

function presentation.is_first_person_body_mode(mode)
    return presentation.gameplay_context.body_mode(mode,
        Managers and Managers.state and Managers.state.game_session)
end

function presentation.is_controller_aim_mode()
    if presentation.online_rules.enabled() then return false end
    return presentation.gameplay_context.aim_mode(active_game_mode_name(),
        Managers and Managers.state and Managers.state.game_session)
end

function presentation.inject_primary_action(self, main_t, input)
    if not presentation.gameplay_context.local_input_handler(
            self, Managers and Managers.player) then return end
    if not presentation.gameplay_context.input_service_enabled(input) then return end
    if not Mods or not Mods.lua or not Mods.lua.io then
        return
    end
    if not controller_observation.primary_action_armed and
            main_t >= controller_observation.primary_action_last_check_t + 0.25 then
        controller_observation.primary_action_last_check_t = main_t
        local flag_path =
            "./../mods/darktidevr/darktidevr_primary_action_test.flag"
        local flag = Mods.lua.io.open(flag_path, "r")
        if flag then
            local request = flag:read("*all")
            flag:close()
            if request and request:match("^%s*fire_once%s*$") then
                local consumed = Mods.lua.io.open(flag_path, "w")
                if consumed then
                    consumed:write("consumed\n")
                    consumed:close()
                end
                controller_observation.primary_action_armed = true
                mod:info("DARKTIDEVR_INPUT primary_action armed")
            end
        end
    end
    if controller_observation.primary_action_stage == "held" then
        local actions = self._ephemeral_actions
        local cache = self._ephemeral_action_cache
        if type(actions) == "table" and type(cache) == "table" then
            for i = 1, #actions do
                if actions[i] == "action_one_release" then
                    cache[i] = true
                    controller_observation.primary_action_stage = "release"
                    mod:info(
                        "DARKTIDEVR_INPUT primary_action release_queued sequence=%d",
                        controller_observation.primary_action_sequence
                    )
                    break
                end
            end
        end
    end
    if not controller_observation.primary_action_armed or
            controller_observation.primary_action_injected then
        return
    end
    local game_mode_name = active_game_mode_name()
    if game_mode_name ~= "shooting_range" and
            game_mode_name ~= "training_grounds" then
        return
    end
    if not controller_observation.authoring_enabled or
            not presentation.hand_aim_usable("dominant") or
            controller_observation.last_sequence <= 0 then
        return
    end
    local actions = self._ephemeral_actions
    local cache = self._ephemeral_action_cache
    if type(actions) ~= "table" or type(cache) ~= "table" then
        mod:warning(
            "DARKTIDEVR_INPUT primary_action blocked reason=missing_ephemeral_cache"
        )
        controller_observation.primary_action_armed = false
        return
    end
    local action_index = nil
    for i = 1, #actions do
        if actions[i] == "action_one_pressed" then
            action_index = i
            break
        end
    end
    if not action_index then
        mod:warning(
            "DARKTIDEVR_INPUT primary_action blocked reason=missing_action"
        )
        controller_observation.primary_action_armed = false
        return
    end
    cache[action_index] = true
    controller_observation.primary_action_armed = false
    controller_observation.primary_action_injected = true
    controller_observation.primary_action_stage = "press"
    controller_observation.primary_action_sequence =
        controller_observation.last_sequence
    mod:info(
        "DARKTIDEVR_INPUT primary_action injected action=action_one_pressed sequence=%d age_ms=%.3f forward=%.4f,%.4f,%.4f",
        controller_observation.primary_action_sequence,
        controller_observation.right_aim_age_ms,
        controller_observation.downstream_forward_x or 0,
        controller_observation.downstream_forward_y or 0,
        controller_observation.downstream_forward_z or 0
    )
end

presentation.controller_bindings_module = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_controller_bindings")
presentation.controller_bindings = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_controller_bindings"
).install(mod)
presentation.gameplay_input_bindings = presentation.controller_bindings.bindings
presentation.spectator_module.install(mod,mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_controller_bindings"),
    presentation.gameplay_context,function(enabled)
        if presentation.spectator_reader then return presentation.spectator_reader(enabled) end
        return 2,0,0
    end,function()
        return controller_observation.gameplay_input_enabled == true and presentation.mode == 1 and
            not (presentation.keyboard_mouse and presentation.keyboard_mouse.controllers_disabled()) and
            presentation.is_first_person_body_mode(active_game_mode_name())
    end)
presentation.turning = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_turning"
).install(mod)
-- Experimental keyboard and mouse play: controllers are ignored and the stock
-- mouse orientation aims inside a keyhole around the rendered view.
presentation.keyboard_mouse = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_keyboard_mouse"
).install(mod)
function presentation.keyboard_mouse_enabled()
    return presentation.keyboard_mouse.enabled()
end
-- Controllers are ignored only when keyboard and mouse mode disables them;
-- otherwise both inputs add together, conflicts included.
function presentation.controllers_disabled()
    return presentation.keyboard_mouse.controllers_disabled()
end
-- Shared with modules installed with only the mod, such as calibration.
mod.darktidevr_controllers_disabled = presentation.controllers_disabled
-- Controller aim and hand tracking are withheld while controllers are
-- disabled, and in keyboard and mouse play with controllers enabled for a few
-- seconds after any keyboard or mouse use. Buttons and sticks are unaffected.
function presentation.controllers_suppressed()
    if presentation.controllers_disabled() then return true end
    return presentation.keyboard_mouse_enabled() and presentation.keyboard_mouse.recent_input()
end
mod:hook_safe("InputManager", "_update_devices", function(self, dt, t)
    if not presentation.keyboard_mouse_enabled() or presentation.controllers_disabled() then return end
    if presentation.keyboard_mouse.sample_devices(self._all_input_devices, t, presentation.mode == 1) then
        mod:info("DARKTIDEVR_KBM controller_aim=%s cooldown_s=%.1f",
            presentation.keyboard_mouse.recent_input() and "suppressed" or "active",
            presentation.keyboard_mouse.controller_cooldown or 0)
    end
end)
-- The body's hands follow the stock animation in keyboard and mouse play
-- unless a controller is tracked and allowed to drive them.
function presentation.keyboard_mouse_hands()
    if not presentation.keyboard_mouse_enabled() then return false end
    return presentation.controllers_suppressed() or
        not (controller_observation.left_grip_tracking_live or controller_observation.right_grip_tracking_live)
end
-- Keyboard and mouse melee direction. The weapon's first light swing is
-- sampled from its authored geometry, unrolled and at 45 degrees, to find its
-- on-screen direction and which way input roll turns it. While idle, the roll
-- that sends the swing along the recent cursor movement is written into the
-- stock orientation, and it is held once the attack starts, as wrist roll is.
function presentation.keyboard_mouse_swing_basis(extension)
    local Preview = presentation.keyboard_mouse_swing_preview
    if not Preview then
        Preview = mod:io_dofile("darktidevr/scripts/mods/darktidevr/darktidevr_melee_preview")
        presentation.keyboard_mouse_swing_preview = Preview
    end
    local aim = presentation.keyboard_mouse.state
    local t = Managers.time:time("gameplay")
    local base = Quaternion.from_yaw_pitch_roll(aim.aim_yaw, aim.aim_pitch, 0)
    local right, up = Quaternion.right(base), Quaternion.up(base)
    local function movement(roll)
        local sample = Preview.context(extension, presentation, t,
            presentation.keyboard_mouse_look_roll(aim.aim_yaw, aim.aim_pitch, roll))
        local path = sample and sample.paths and sample.paths[1]
        if not path or #path < 2 then return nil end
        local first, last = path[1].tip, path[#path].tip
        local delta = Vector3(last.x - first.x, last.y - first.y, last.z - first.z)
        return Vector3.dot(delta, right), Vector3.dot(delta, up)
    end
    local zero_right, zero_up = movement(0)
    local rolled_right, rolled_up = movement(math.pi / 4)
    return presentation.keyboard_mouse.swing_basis(zero_right, zero_up, rolled_right, rolled_up)
end
function presentation.keyboard_mouse_melee_roll(orientation, main_t)
    local extension = orientation._weapon_extension
    local template = extension and extension.weapon_template and extension:weapon_template()
    local melee = false
    for _, keyword in ipairs(template and template.keywords or {}) do
        if keyword == "melee" then melee = true end
    end
    local slot = melee and extension._inventory_component and extension._inventory_component.wielded_slot
    local weapon = melee and extension._weapons and extension._weapons[slot] or nil
    local kbm = presentation.keyboard_mouse
    return kbm.melee_roll(weapon, weapon ~= nil and extension:running_action_settings() ~= nil, function()
        local cache = presentation.keyboard_mouse_swing_cache
        if not cache or cache.weapon ~= weapon or
                (not cache.authored and main_t >= cache.retry_t) then
            local authored, sign = presentation.keyboard_mouse_swing_basis(extension)
            -- An unsupported or not-yet-valid swing is retried each second.
            cache = {weapon = weapon, authored = authored, sign = sign, retry_t = main_t + 1}
            presentation.keyboard_mouse_swing_cache = cache
        end
        return presentation.keyboard_mouse_swing_roll(main_t, cache.authored, cache.sign)
    end)
end
-- Both the cursor movement and the reticle's offset are read in the headset's
-- frame, so a tilted head tilts the directions with it: leaning 45 degrees
-- left and moving the mouse left to right swings up and to the right. The
-- chosen direction is then expressed on the unrolled aim's axes, where the
-- swing is authored.
function presentation.keyboard_mouse_swing_roll(main_t, authored, sign)
    local kbm = presentation.keyboard_mouse
    local aim = kbm.state
    if not authored or not aim.aim_yaw or not controller_observation.head_aim_qw then return 0 end
    local head = Quaternion.from_elements(controller_observation.head_aim_qx,
        controller_observation.head_aim_qy, controller_observation.head_aim_qz,
        controller_observation.head_aim_qw)
    local base = Quaternion.from_yaw_pitch_roll(aim.aim_yaw, aim.aim_pitch, 0)
    local head_right, head_up = Quaternion.right(head), Quaternion.up(head)
    local aim_forward = Quaternion.forward(base)
    -- Mouse deltas are yaw/pitch changes: rightward movement lowers yaw.
    local dx, dy = kbm.mouse_motion(main_t)
    local wx, wy = kbm.melee_direction(dx, dy,
        Vector3.dot(aim_forward, head_right), Vector3.dot(aim_forward, head_up))
    if not wx then return 0 end
    local wanted = head_right * wx + head_up * wy
    return kbm.roll_for(Vector3.dot(wanted, Quaternion.right(base)),
        Vector3.dot(wanted, Quaternion.up(base)), authored, sign)
end
-- Runs on every orientation update. The roll is chosen while idle and held
-- through the attack, but it is used only while the attack runs, and only in
-- the input frame the simulation reads (keyboard_mouse_roll_input), never in
-- the player orientation: written there while idle, the worn log showed it
-- throwing the reticle around the aim whenever the aim was pitched, because
-- Darktide's roll is not about the look direction.
function presentation.apply_keyboard_mouse_melee_roll(orientation, main_t)
    presentation.keyboard_mouse_attack_roll = nil
    if not presentation.keyboard_mouse_enabled() or presentation.hub_third_person_active() or
            not orientation._orientation or
            not presentation.keyboard_mouse.live(main_t) then return end
    local ok, roll, held_now = pcall(presentation.keyboard_mouse_melee_roll, orientation, main_t)
    if not ok then
        if not presentation.keyboard_mouse_melee_error_logged then
            presentation.keyboard_mouse_melee_error_logged = true
            mod:warning("DARKTIDEVR_KBM melee_roll_failed error=%s", tostring(roll))
        end
        return
    end
    local latch = presentation.keyboard_mouse.state.melee
    if latch and latch.held and roll ~= 0 then presentation.keyboard_mouse_attack_roll = roll end
    if held_now then
        local cache = presentation.keyboard_mouse_swing_cache
        mod:info("DARKTIDEVR_KBM melee_roll_deg=%.0f swing_basis=%s", math.deg(roll),
            cache and cache.authored and string.format("%.0f,%d", math.deg(cache.authored), cache.sign) or "unavailable")
    end
end
-- The aim turned about its own look direction. Darktide's yaw/pitch/roll
-- applies roll about the level forward axis outside the pitch, which moves
-- the look direction once the aim is pitched (the worn log: 5 degrees off at
-- 45 degrees roll, level at 90), so the roll is built here instead.
function presentation.keyboard_mouse_look_roll(yaw, pitch, roll)
    return Quaternion.multiply(Quaternion.from_yaw_pitch_roll(yaw, pitch, 0),
        Quaternion.axis_angle(Vector3(0, 1, 0), roll))
end
-- Engine yaw, pitch and roll reproducing a rotation, on a branch whose pitch
-- stays within a quarter turn. The engine's own rotation is the judge, so the
-- branch rule needs no assumed Euler convention. Returns nil when no branch
-- reproduces the rotation within a degree.
presentation.keyboard_mouse_pitch_forms = {}
function presentation.keyboard_mouse_input_euler(rotation)
    local yaw, pitch, roll = Quaternion.to_yaw_pitch_roll(rotation)
    local want_forward, want_up = Quaternion.forward(rotation), Quaternion.up(rotation)
    local forms = presentation.keyboard_mouse_pitch_forms
    forms[1], forms[2], forms[3], forms[4], forms[5] = pitch, math.pi - pitch, -math.pi - pitch,
        pitch - math.pi, pitch + math.pi
    local best_yaw, best_pitch, best_roll, best_error
    for yaw_turn = 0, 1 do
        for form = 1, 5 do
            local candidate_pitch = (forms[form] + math.pi) % (math.pi * 2) - math.pi
            if math.abs(candidate_pitch) <= math.pi / 2 + 1e-6 then
                for roll_form = 1, 3 do
                    local candidate_yaw = yaw + yaw_turn * math.pi
                    local candidate_roll = roll_form == 1 and roll or roll_form == 2 and math.pi - roll or roll + math.pi
                    local candidate = Quaternion.from_yaw_pitch_roll(candidate_yaw, candidate_pitch, candidate_roll)
                    local error = math.max(
                        math.acos(math.max(-1, math.min(1, Vector3.dot(Quaternion.forward(candidate), want_forward)))),
                        math.acos(math.max(-1, math.min(1, Vector3.dot(Quaternion.up(candidate), want_up)))))
                    if not best_error or error < best_error - 1e-9 then
                        best_yaw, best_pitch, best_roll, best_error = candidate_yaw, candidate_pitch, candidate_roll, error
                    end
                end
            end
        end
    end
    if not best_error or best_error > math.rad(1) then return nil, nil, nil, best_error end
    return best_yaw, best_pitch, best_roll, best_error
end
-- Writes the attack roll into this fixed frame's input, after stock caching.
-- A frame where a controller ray authored the aim keeps the controller's own.
function presentation.keyboard_mouse_roll_input(handler, frame)
    local roll = presentation.keyboard_mouse_attack_roll
    if not roll or roll == 0 or not presentation.keyboard_mouse_enabled() or
            presentation.weapon_aim_target("dominant") then return end
    local cache = handler._input_cache
    local index = handler._buffer_index and handler:_buffer_index(frame)
    local yaws, pitches, rolls = cache and cache[handler._yaw_index], cache and cache[handler._pitch_index],
        cache and cache[handler._roll_index]
    if not index or not yaws or not pitches or not rolls then return end
    local yaw, pitch = tonumber(yaws[index]), tonumber(pitches[index])
    if not yaw or not pitch then return end
    pitch = (pitch + math.pi) % (math.pi * 2) - math.pi
    local input_yaw, input_pitch, input_roll, error =
        presentation.keyboard_mouse_input_euler(presentation.keyboard_mouse_look_roll(yaw, pitch, roll))
    if presentation.keyboard_mouse_roll_logged ~= roll then
        presentation.keyboard_mouse_roll_logged = roll
        mod:info("DARKTIDEVR_KBM melee_roll_input deg=%.0f aim_pitch_deg=%.1f input_ypr=%s,%s,%s error_deg=%s",
            math.deg(roll), math.deg(pitch), tostring(input_yaw), tostring(input_pitch), tostring(input_roll),
            error and string.format("%.3f", math.deg(error)) or "nil")
    end
    if not input_yaw then return end
    yaws[index] = input_yaw % (math.pi * 2)
    pitches[index] = input_pitch % (math.pi * 2)
    rolls[index] = input_roll % (math.pi * 2)
end
-- Called from the one HumanInputHandler.fixed_update hook (DMF allows a mod a
-- single hook per function), after the online-rules capture.
function presentation.apply_keyboard_mouse_roll_input(handler, frame)
    if not presentation.keyboard_mouse_attack_roll then
        presentation.keyboard_mouse_roll_logged = nil
        return
    end
    local ok, err = pcall(presentation.keyboard_mouse_roll_input, handler, frame)
    if not ok and not presentation.keyboard_mouse_roll_input_failed then
        presentation.keyboard_mouse_roll_input_failed = true
        mod:warning("DARKTIDEVR_KBM melee_roll_input_failed error=%s", tostring(err))
    end
end
function presentation.keyboard_mouse_view_pitch()
    if not presentation.keyboard_mouse_enabled() then return 0 end
    return presentation.keyboard_mouse.state.camera_pitch or 0
end
-- The stock first-person hands animate around the camera, which in VR puts
-- them beside the head. Keyboard and mouse hands keep that animation, moved
-- 10 cm forward along the aim heading and 10 cm down, in player scale.
function presentation.keyboard_mouse_hand_offset()
    local kbm = presentation.keyboard_mouse
    local aim = kbm.state
    if not presentation.keyboard_mouse_enabled() or not aim.aim_yaw then return nil end
    local player = Managers.player and Managers.player:local_player(1)
    local scale = presentation.calibrated_character_scale(player) or 1
    local forward = Quaternion.forward(Quaternion.from_yaw_pitch_roll(aim.aim_yaw, 0, 0))
    return (forward * kbm.hand_forward - Vector3.up() * kbm.hand_down) * scale
end
-- Keyboard and mouse hands hang from the same anchor the VR camera and
-- tracked hands use, rebuilt from the avatar at this seam as tracked arms do.
-- The rendered first-person root follows the smoothed character position
-- instead, so hands placed from it jumped against the view while moving.
function presentation.keyboard_mouse_hand_pivot(unit)
    if not presentation.refresh_body_anchor_from_avatar(unit) or
            not controller_observation.body_anchor_x then return nil end
    return Vector3(controller_observation.body_anchor_x, controller_observation.body_anchor_y,
        controller_observation.body_anchor_z)
end
function presentation.keyboard_mouse_aim_rotation()
    local aim = presentation.keyboard_mouse.state
    if not presentation.keyboard_mouse_enabled() or not aim.aim_yaw then return nil end
    return Quaternion.from_yaw_pitch_roll(aim.aim_yaw, aim.aim_pitch, 0)
end
-- The viewer follows the desktop mouse with its cursor marker, ignores
-- disabled controllers and applies recentre requests. Publish only on change;
-- the capture library keeps the values in every presentation heartbeat.
function presentation.publish_input_preferences()
    local keyboard_mouse = presentation.keyboard_mouse_enabled()
    local controllers_disabled = presentation.controllers_disabled()
    local requests = presentation.keyboard_mouse.recenter_requests
    if presentation.input_preferences_keyboard_mouse == keyboard_mouse and
            presentation.input_preferences_controllers_disabled == controllers_disabled and
            presentation.input_preferences_requests == requests then return true end
    if not ui_native_capture or
            not presentation.native_export(ui_native_capture, "dtvr_set_input_preferences_v2") then
        return false
    end
    local result = tonumber(ui_native_capture.dtvr_set_input_preferences_v2(
        keyboard_mouse and 1 or 0, controllers_disabled and 1 or 0, requests))
    if result ~= 0 then return false end
    presentation.input_preferences_keyboard_mouse = keyboard_mouse
    presentation.input_preferences_controllers_disabled = controllers_disabled
    presentation.input_preferences_requests = requests
    mod:info("DARKTIDEVR_KBM input_preferences keyboard_mouse=%s controllers_disabled=%s recenter_requests=%d",
        tostring(keyboard_mouse), tostring(controllers_disabled), requests)
    return true
end
presentation.keyboard_mouse.on_mode_changed = function(enabled, controllers_disabled)
    mod:info("DARKTIDEVR_KBM mode=%s controllers=%s", enabled and "keyboard_mouse" or "controllers",
        controllers_disabled and "disabled" or "enabled")
    presentation.publish_input_preferences()
end
-- Recentre view keybind: the viewer recentres the headset (position and
-- facing), and the new recenter generation turns the view onto the aim. An
-- older viewer without the request turns the view onto the aim directly.
mod.recenter_vr_view = function()
    if not presentation.keyboard_mouse_enabled() then return end
    presentation.keyboard_mouse.recenter_requests = presentation.keyboard_mouse.recenter_requests + 1
    if not presentation.publish_input_preferences() then
        controller_observation.keyboard_mouse_recenter_pending = true
    end
    mod:info("DARKTIDEVR_KBM recenter_requested count=%d", presentation.keyboard_mouse.recenter_requests)
end

function presentation.apply_controller_turning(main_t,exclusive_stick)
    local delta = presentation.turning.sample(
        controller_observation.gameplay_input_active and active and active_base_rotation ~= nil,
        controller_observation.right_stick_x, controller_observation.right_stick_y,
        controller_observation.right_aim_usable,
        controller_observation.last_transport_generation,
        controller_observation.head_recenter_generation, active_world, main_t,exclusive_stick)
    -- The turn, for the body trace. It is the column item 4 actually needs and
    -- the first cut did not have: `gameplay_stick_active` is the MOVEMENT
    -- stick, so the trace's `solver=stick` rows were the player walking, not
    -- turning, and the two were read as the same thing. Accumulated rather
    -- than sampled, because the input path runs more often than the trace.
    local heading_trace = presentation.body_heading_trace
    if heading_trace then
        heading_trace.turn_accum = (heading_trace.turn_accum or 0) + delta
    end
    if delta ~= 0 and active_base_rotation then
        -- One shared world-up rotation: head, both hands, body-follow translation
        -- and gameplay heading all read this anchor. Never inject mouse motion.
        active_base_rotation:store(Quaternion.multiply(
            Quaternion.axis_angle(Vector3.up(), delta), active_base_rotation:unbox()))
    end
    -- Third-person hub orbit: stick turning also turns the stock orientation,
    -- and the stick's vertical axis moves the orbit camera up and down. Both
    -- are deltas onto the stock orientation, applied by the aim authoring.
    if controller_observation.hub_third_person_orbit then
        if delta ~= 0 then
            controller_observation.hub_third_person_yaw_delta =
                (controller_observation.hub_third_person_yaw_delta or 0) + delta
        end
        local last_t = controller_observation.hub_third_person_last_t or main_t
        local dt = math.clamp(main_t - last_t, 0, 0.1)
        local y = controller_observation.gameplay_input_active and
            controller_observation.right_aim_usable and
            tonumber(controller_observation.right_stick_y) or 0
        if not exclusive_stick and math.abs(y) > 0.2 then
            local rate = 1.6 -- radians per second at full deflection
            controller_observation.hub_third_person_pitch_delta =
                (controller_observation.hub_third_person_pitch_delta or 0) + y * rate * dt
        end
    end
    controller_observation.hub_third_person_last_t = main_t
end
presentation.menu_prompts = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_menu_prompts"
).install(mod,function()
    return ui_native_capture_active == true and not presentation.keyboard_mouse_enabled()
end,function()
    return presentation.menu_pointer.read_state_v3 == true
end)
mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_controller_prompts"
).install(mod,presentation.controller_bindings,function()
    return controller_observation.gameplay_input_enabled == true and
        not presentation.keyboard_mouse_enabled()
end,presentation.menu_prompts)

function presentation.inject_ephemeral_action_names(
        actions, cache, names, delivered, missing)
    for name_index = 1, #names do
        local requested_name = names[name_index]
        local found = false
        for action_index = 1, #actions do
            if actions[action_index] == requested_name then
                cache[action_index] = true
                found = true
                break
            end
        end
        local destination = found and delivered or missing
        destination[#destination + 1] = requested_name
    end
end

-- Observe identity without keeping a retired player/input cache alive.
presentation.gameplay_input_owner = setmetatable({}, {__mode = "v"})
presentation.communication_input = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_communication_input"
).install(mod,presentation,controller_observation,{
    mode=active_game_mode_name,world=function()return active_world end,
})
presentation.push_to_talk = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_push_to_talk"
).install(mod,presentation,controller_observation,{
    mode=active_game_mode_name,world=function()return active_world end,
})

-- Quick wield from a grenade, pocketable, stim or device returns to the
-- weapon last held rather than to the stock default. The last weapon slot is
-- sampled every input update from the stock inventory component.
local last_wielded_weapon_slot = nil
function presentation.track_wielded_weapon()
    local unit = presentation.gameplay_input_owner[2]
    local script_unit = rawget(_G, "ScriptUnit")
    if not unit or not script_unit or not Unit.alive(unit) then return end
    local unit_data = script_unit.has_extension(unit, "unit_data_system")
    local inventory = unit_data and unit_data:read_component("inventory")
    local wielded = inventory and inventory.wielded_slot
    if wielded == "slot_primary" or wielded == "slot_secondary" then
        last_wielded_weapon_slot = wielded
    end
    return wielded
end

-- The tracked cyclopean eye: the stereo camera pose after head tracking,
-- stored each rendered frame. Presentation that must match what the headset
-- sees (sight-to-eye ADS, the body frame's shoulders, wrist and forearm
-- displays) reads it instead of the first-person unit, which does not carry
-- the head's tracked translation (worn, 15 September: sight ADS never
-- engaged from the headset eye).
--
-- The eye is also kept relative to the body anchor the camera has just
-- written, and read back from the anchor current at the time of the read.
-- It is stored at the camera update, after everything placed in the
-- locomotion post-update; those placements read it one frame late, and on
-- frames where a fixed step moved the player it lagged a step of travel
-- behind their anchor. While strafing that step is sideways to the view, so
-- the forearm miniatures (billboarded to the eye) turned back and forth
-- between two poses (worn, 15 September evening; audit 16 September). Readers
-- at input time see the anchor the eye was stored with, so they are
-- unchanged.
presentation.TRACKED_EYE_MAX_AGE = 0.25
local function current_body_anchor()
    local o = controller_observation
    if not o.body_anchor_qw or not o.body_anchor_x then return nil end
    return Vector3(o.body_anchor_x, o.body_anchor_y, o.body_anchor_z),
        Quaternion.from_elements(o.body_anchor_qx, o.body_anchor_qy, o.body_anchor_qz, o.body_anchor_qw)
end
function presentation.store_tracked_eye(position, rotation)
    if not position or not rotation then return end
    if presentation.tracked_eye_position then
        presentation.tracked_eye_position:store(position)
        presentation.tracked_eye_rotation:store(rotation)
    else
        presentation.tracked_eye_position = Vector3Box(position)
        presentation.tracked_eye_rotation = QuaternionBox(rotation)
    end
    local anchor_position, anchor_rotation = current_body_anchor()
    if anchor_position then
        local offset = position - anchor_position
        local in_anchor = Vector3(Vector3.dot(offset, Quaternion.right(anchor_rotation)),
            Vector3.dot(offset, Quaternion.forward(anchor_rotation)), Vector3.dot(offset, Quaternion.up(anchor_rotation)))
        local rotation_in_anchor = Quaternion.multiply(Quaternion.inverse(anchor_rotation), rotation)
        if presentation.tracked_eye_in_anchor then
            presentation.tracked_eye_in_anchor:store(in_anchor)
            presentation.tracked_eye_rotation_in_anchor:store(rotation_in_anchor)
        else
            presentation.tracked_eye_in_anchor = Vector3Box(in_anchor)
            presentation.tracked_eye_rotation_in_anchor = QuaternionBox(rotation_in_anchor)
        end
        presentation.tracked_eye_anchored = true
    else
        presentation.tracked_eye_anchored = false
    end
    presentation.tracked_eye_t = Managers and Managers.time and Managers.time:time("main") or nil
end

-- The eye's world position and rotation: the tracked eye while it is fresh
-- (from the current body anchor when it was stored with one), otherwise the
-- unit's first-person unit (nil when neither exists).
function presentation.eye_pose(unit)
    local now = Managers and Managers.time and Managers.time:time("main") or nil
    if presentation.tracked_eye_position and presentation.tracked_eye_t and now and
            now - presentation.tracked_eye_t <= presentation.TRACKED_EYE_MAX_AGE and
            now >= presentation.tracked_eye_t then
        local anchor_position, anchor_rotation
        if presentation.tracked_eye_anchored then anchor_position, anchor_rotation = current_body_anchor() end
        if anchor_position then
            local in_anchor = presentation.tracked_eye_in_anchor:unbox()
            return anchor_position + presentation.rotate_vector(anchor_rotation, in_anchor),
                Quaternion.multiply(anchor_rotation, presentation.tracked_eye_rotation_in_anchor:unbox())
        end
        return presentation.tracked_eye_position:unbox(), presentation.tracked_eye_rotation:unbox()
    end
    local first_person = unit and ScriptUnit.has_extension(unit, "first_person_system")
    local eye_unit = first_person and first_person:first_person_unit()
    if not eye_unit or not Unit.alive(eye_unit) then return nil end
    return Unit.world_position(eye_unit, 1), Unit.world_rotation(eye_unit, 1)
end

-- Whether a feature hands the one claim slot to another's request this
-- frame (darktidevr_item_radial's rule, shared).
function presentation.claim_yields(request, other_holds)
    return presentation.item_radial_module.yields(request, other_holds)
end

-- The magnification the rendered frusta carry this sample: 1 unless the
-- sights are up and the zoom option is above zero, eased in and out with the
-- vignette's time constant. State hangs off `presentation` because this
-- chunk is at LuaJIT's local ceiling.
presentation.ads_zoom_blend = 0
function presentation.ads_zoom_magnification()
    local percent = mod.get and mod:get("vr_ads_zoom") or 0
    local focus = not mod.get or mod:get("ads_focus") ~= false
    local active = presentation.ads_active == true and focus and
        presentation.mode == 1 and (tonumber(percent) or 0) > 0
    local now = Managers and Managers.time and Managers.time.has_timer and
        Managers.time:has_timer("main") and Managers.time:time("main") or nil
    if now then
        local dt = presentation.ads_zoom_t and now - presentation.ads_zoom_t or nil
        presentation.ads_zoom_t = now
        presentation.ads_zoom_blend = presentation.projection_math.zoom_blend(
            presentation.ads_zoom_blend, active, dt)
    elseif not active then
        presentation.ads_zoom_blend = 0
    end
    local magnification = presentation.projection_math.zoom_magnification(
        percent, presentation.ads_zoom_blend)
    -- No transport, no zoom. The viewer has to submit the projection the
    -- cameras rendered with; if the magnification cannot reach it, zooming
    -- would pull the player's two eyes apart by 2 * 0.1224 * (m - 1) radians
    -- and there would be no way for the viewer to undo it (19 September).
    if not presentation.native_gameplay_zoom then
        if not presentation.ads_zoom_untransported_logged then
            presentation.ads_zoom_untransported_logged = true
            mod:info("DARKTIDEVR_AIM zoom=suppressed reason=no_transport")
        end
        return 1
    end
    if (magnification > 1.0001) ~= (presentation.ads_zoom_logged == true) then
        presentation.ads_zoom_logged = magnification > 1.0001
        mod:info("DARKTIDEVR_AIM zoom=%s magnification=%.3f percent=%s",
            presentation.ads_zoom_logged and "on" or "off", magnification, tostring(percent))
    end
    return magnification
end

-- Aim-down-sights (alternate fire) on the wielded weapon. The viewer
-- tightens the reticle and eases in a focus vignette; the stabilisation
-- filter steadies the hand. Off through the ads_focus option.
-- An unattended run cannot press the alternate fire, so nothing downstream of
-- this (the reticle's tightening, the focus vignette, the aim zoom) could be
-- proven without a person in the headset; the vignette went five days unseen
-- for want of it. `darktidevr_ads_test.flag` holds the sights up, polled like
-- the other modules' test flags. Players never have the file.
presentation.ads_test_poll = 0
function presentation.ads_test_flag()
    presentation.ads_test_poll = (presentation.ads_test_poll or 0) - 1
    if presentation.ads_test_poll > 0 then return presentation.ads_test_enabled == true end
    presentation.ads_test_poll = 300
    local io_api = Mods and Mods.lua and Mods.lua.io
    local file = io_api and io_api.open("./../mods/darktidevr/darktidevr_ads_test.flag", "r")
    if not file then presentation.ads_test_enabled = false; return false end
    local value = file:read(32) or ""
    file:close()
    presentation.ads_test_enabled = value:match("^%s*enabled%s*$") ~= nil
    return presentation.ads_test_enabled
end

function presentation.track_aim_down_sights()
    local unit = presentation.gameplay_input_owner[2]
    local script_unit = rawget(_G, "ScriptUnit")
    local active = false
    if unit and script_unit and Unit.alive(unit) and
            (not mod.get or mod:get("ads_focus") ~= false) then
        local unit_data = script_unit.has_extension(unit, "unit_data_system")
        local ok, component = pcall(function()
            return unit_data and unit_data:read_component("alternate_fire")
        end)
        active = (ok and component ~= nil and component.is_active == true) or
            presentation.ads_test_flag()
    end
    if active ~= presentation.ads_active then
        presentation.ads_active = active
        if ui_native_capture and presentation.native_export and
                presentation.native_export(ui_native_capture, "dtvr_set_gameplay_ads") then
            ui_native_capture.dtvr_set_gameplay_ads(active and 1 or 0)
        end
        mod:info("DARKTIDEVR_AIM ads=%s", active and "active" or "off")
    end
end

function presentation.quick_wield_names(names)
    if not names or names[1] ~= "quick_wield" or #names ~= 1 then
        return names
    end
    local wielded = presentation.track_wielded_weapon()
    if not wielded or wielded == "slot_primary" or wielded == "slot_secondary" or
            not last_wielded_weapon_slot then
        return names
    end
    return {last_wielded_weapon_slot == "slot_primary" and "wield_1" or "wield_2"}
end

-- A press selecting several wield targets becomes a cycle over them, device
-- first (Bindings.wield_press); the game would apply only one of the wield
-- inputs, not a chosen one.
function presentation.device_wield_precedence(pressed, player_unit)
    local bindings = presentation.controller_bindings
    if not bindings or not bindings.wield_press or
            bit.band(pressed, 16 + 65536 + 131072 + 262144 + 524288) == 0 then
        return pressed
    end
    local ok, result = pcall(function()
        local unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")
        local inventory = unit_data and unit_data:read_component("inventory")
        return bindings.wield_press(pressed, inventory)
    end)
    return ok and result or pressed
end

function presentation.inject_gameplay_input(self, main_t, input)
    if not presentation.gameplay_context.local_input_handler(
            self, Managers and Managers.player) then return end
    if not ui_native_capture or not Mods or not Mods.lua or not Mods.lua.io or
            not controller_observation.gameplay_pressed then
        return
    end
    if main_t >= controller_observation.gameplay_input_last_check_t + 0.25 then
        controller_observation.gameplay_input_last_check_t = main_t
        local flag = Mods.lua.io.open(
            "./../mods/darktidevr/darktidevr_gameplay_input_test.flag",
            "r")
        -- Play default when the flag is absent; a present file decides.
        local requested = true
        if flag then
            local value = flag:read("*all")
            flag:close()
            requested = value and value:match("^%s*enabled%s*$") ~= nil
        end
        if requested ~= controller_observation.gameplay_input_enabled then
            controller_observation.gameplay_input_enabled = requested
            mod:info(
                "DARKTIDEVR_INPUT gameplay_adapter enabled=%s",
                tostring(requested))
        end
    end

    local game_mode_name = active_game_mode_name()
    local ui_inputs_in_use = presentation.gameplay_context.ui_blocks_gameplay(
        Managers and Managers.ui)
    local player_unit = presentation.gameplay_context.local_input_unit(
        self, Managers and Managers.player)
    local owner_changed = presentation.gameplay_input_owner[1] ~= self or
        presentation.gameplay_input_owner[2] ~= player_unit
    presentation.gameplay_input_owner[1], presentation.gameplay_input_owner[2] = self, player_unit
    -- Loading can replace the handler, or stock can replace its character,
    -- without an intervening inactive callback. Drain and require neutral input.
    -- Disabled controllers still drain the native reader inactive, so turning
    -- them back on later cannot replay buttons pressed in the meantime.
    local active = player_unit ~= nil and not owner_changed and controller_observation.gameplay_input_enabled and
        not presentation.controllers_disabled() and
        presentation.is_first_person_body_mode(game_mode_name) and
        presentation.mode == 1 and not ui_inputs_in_use and
        presentation.gameplay_context.input_service_enabled(input)
    local result = ui_native_capture.dtvr_read_gameplay_input(
        active and 1 or 0,
        controller_observation.gameplay_pressed,
        controller_observation.gameplay_held,
        controller_observation.gameplay_released,
        controller_observation.gameplay_sequence,
        controller_observation.gameplay_movement)
    controller_observation.gameplay_input_active = active and result == 0
    if presentation.attachment_scan and presentation.attachment_scan.mask_gameplay_input then
        presentation.attachment_scan.mask_gameplay_input(controller_observation)
    end
    local profile=presentation.frame_profile
    if presentation.sight_ads then
        profile.section("input.sight_ads", presentation.sight_ads.apply, self, player_unit)
    end
    if presentation.weapon_inspect then
        -- After the sights, which get first claim on a weapon at the eye.
        profile.section("input.weapon_inspect", presentation.weapon_inspect.apply, player_unit,
            controller_observation.gameplay_input_active and game_mode_name~="hub", main_t)
    end
    if presentation.comms_gesture then
        -- Talking works in the hub too.
        profile.section("input.comms_gesture", presentation.comms_gesture.apply, player_unit,
            controller_observation.gameplay_input_active, main_t)
    end
    if presentation.tag_gesture then
        -- After the talk gesture, which has first claim on that hand.
        profile.section("input.tag_gesture", presentation.tag_gesture.apply, player_unit,
            controller_observation.gameplay_input_active and game_mode_name~="hub", main_t)
    end
    if presentation.melee_swing then
        -- Swinging the weapon hand holds the primary action as the trigger
        -- would: a small swing is a light attack, a big one a heavy. Before
        -- the bindings sample, which consumes bindings.forced.
        profile.section("input.melee_swing", presentation.melee_swing.apply, player_unit,
            controller_observation.gameplay_input_active and game_mode_name~="hub", main_t,
            tonumber(controller_observation.gameplay_held[0]), game_mode_name)
    end
    local exclusive_stick=profile.section("input.communication",presentation.communication_input.sample,self,player_unit,input,
        controller_observation.gameplay_input_active,
        tonumber(controller_observation.gameplay_held[0]),game_mode_name,active_world)
    -- The radial owns the stick while it is open, as the comms wheel does.
    if presentation.item_radial and presentation.item_radial.open() then exclusive_stick=true end
    presentation.apply_controller_turning(main_t,exclusive_stick)
    local support_request=presentation.two_hand and profile.section("input.two_hand",presentation.two_hand.sample,
        player_unit,controller_observation.gameplay_input_active,main_t,self)
    local holster_request=false
    if presentation.holsters then
        -- The hub has nothing to wield; its grip opens the inventory.
        support_request,holster_request=profile.section("input.holsters",presentation.holsters.sample,player_unit,
            controller_observation.gameplay_input_active and game_mode_name~="hub",main_t,support_request)
    end
    if presentation.reach_interact then
        -- Last: a holster or the gun's support grip owns the hand first.
        support_request=profile.section("input.reach",presentation.reach_interact.sample,player_unit,
            controller_observation.gameplay_input_active and game_mode_name~="hub",main_t,support_request)
    end
    local radial_request=false
    if presentation.item_radial then
        -- Last of all: it takes the carried-items button, not a grip, and only
        -- when no grip claim wants the slot. Not in the hub.
        support_request,radial_request=profile.section("input.item_radial",presentation.item_radial.sample,
            controller_observation.gameplay_input_active and game_mode_name~="hub",support_request)
    end
    -- The input time, for the bindings' reverse grip grace.
    if type(support_request)=='table' then support_request.now=main_t end
    local pressed, held, released = profile.section("input.bindings",presentation.controller_bindings.sample,
        controller_observation.gameplay_input_active,
        tonumber(controller_observation.gameplay_held[0]),
        controller_observation.right_stick_x,controller_observation.right_stick_y,
        controller_observation.right_aim_usable,
        controller_observation.last_transport_generation, game_mode_name,support_request,exclusive_stick)
    if presentation.holsters then
        presentation.holsters.finish_grip(presentation.controller_bindings.support_grip,holster_request)
    end
    if presentation.item_radial then
        presentation.item_radial.finish(presentation.controller_bindings.support_grip,radial_request,
            controller_observation.right_stick_x,controller_observation.right_stick_y,
            controller_observation.right_aim_usable)
    end
    if presentation.two_hand then
        -- A holster or radial claim is not the support hand's grip. The
        -- radial is its own option, so the holsters may not be loaded.
        local idle = presentation.holsters and presentation.holsters.idle_grip
        presentation.two_hand.finish((holster_request or radial_request) and idle or
            presentation.controller_bindings.support_grip)
    end
    if presentation.haptics then
        profile.section("input.haptics", pcall, presentation.haptics.sample,
            controller_observation.gameplay_input_active and player_unit or nil)
    end
    -- One input frame done: the profiler polls its flag and reports here.
    profile.frame(main_t)
    if presentation.gameplay_ui then
        presentation.gameplay_ui.sample(controller_observation.gameplay_input_active, pressed, held)
    end
    presentation.push_to_talk.sample(self,player_unit,input,
        controller_observation.gameplay_input_active,held,game_mode_name,active_world)
    controller_observation.gameplay_input_last_sequence =
        tonumber(controller_observation.gameplay_sequence[0])
    presentation.track_wielded_weapon()
    presentation.track_aim_down_sights()
    -- Which units are drawing arms, when what is wielded changes. Off unless
    -- its flag says otherwise; it exists because four separate explanations for
    -- "I have two arms" were reasoned out of the code and all four were wrong.
    if presentation.arm_census then
        pcall(presentation.arm_census.report, player_unit)
    end
    -- Still sample/cancel both mappers and UI requests while blocked or after
    -- a failed native read. Do not inject synthetic cancellation release edges;
    -- stock false-held action behavior still applies.
    if not controller_observation.gameplay_input_active then return end
    -- Holds and movement are merged by fixed_update below. An unchanged sample
    -- has no ephemeral actions, so avoid its tables and binding scan entirely.
    if pressed == 0 and released == 0 then return end
    if pressed ~= 0 or released ~= 0 then
        mod:info(
            "DARKTIDEVR_INPUT gameplay_edges sequence=%d pressed=%d held=%d released=%d move=%.3f,%.3f",
            controller_observation.gameplay_input_last_sequence,
            pressed, held, released,
            tonumber(controller_observation.gameplay_movement[0]),
            tonumber(controller_observation.gameplay_movement[1]))
    end

    local actions = self._ephemeral_actions
    local cache = self._ephemeral_action_cache
    if type(actions) ~= "table" or type(cache) ~= "table" then
        return
    end
    pressed = presentation.device_wield_precedence(pressed, player_unit)
    local delivered = {}
    local missing = {}
    for binding_index = 1, #presentation.gameplay_input_bindings do
        local binding = presentation.gameplay_input_bindings[binding_index]
        local names = nil
        if bit.band(pressed, binding.mask) ~= 0 then
            names = presentation.quick_wield_names(binding.pressed)
        end
        if names then
            presentation.inject_ephemeral_action_names(
                actions, cache, names, delivered, missing)
        end
        if bit.band(released, binding.mask) ~= 0 then
            names = binding.released
            presentation.inject_ephemeral_action_names(
                actions, cache, names, delivered, missing)
        end
    end
    if pressed ~= 0 or released ~= 0 then
        mod:info(
            "DARKTIDEVR_INPUT gameplay_delivery sequence=%d delivered=%s missing=%s",
            controller_observation.gameplay_input_last_sequence,
            #delivered > 0 and table.concat(delivered, ",") or "none",
            #missing > 0 and table.concat(missing, ",") or "none")
    end
end

mod:hook_safe(
    require("scripts/managers/player/player_game_states/human_input_handler"),
    "pre_update",
    function(self, _, main_t, input)
        presentation.inject_primary_action(self, main_t or 0, input)
        presentation.inject_gameplay_input(self, main_t or 0, input)
    end)

mod:hook_safe(
    require("scripts/managers/player/player_game_states/human_input_handler"),
    "fixed_update",
    function(self, dt, t, frame, input)
        if self ~= presentation.gameplay_input_owner[1] or
                presentation.gameplay_input_owner[2] == nil or
                presentation.gameplay_context.local_input_unit(
                    self, Managers and Managers.player) ~= presentation.gameplay_input_owner[2] then return end
        -- Stock selects its service again for each fixed frame. Ownership can
        -- change after pre_update; cancel before merging history or authoring aim.
        if not presentation.gameplay_context.input_service_enabled(input) then
            controller_observation.gameplay_input_active = false
            controller_observation.gameplay_stick_active = false
            controller_observation.primary_action_injected = false
            presentation.controller_bindings.sample(false, 0, nil, nil, false,
                controller_observation.last_transport_generation, active_game_mode_name())
            -- The cancelled sample raises the grip's cancelled edge; the
            -- claimants only see it if they are finished as on a live frame,
            -- or a holster claim and the skull's held state outlive the
            -- service by a frame.
            local cancelled_grip = presentation.controller_bindings.support_grip
            if presentation.holsters then
                pcall(presentation.holsters.finish_grip, cancelled_grip, true)
            end
            if presentation.item_radial then
                pcall(presentation.item_radial.finish, cancelled_grip, false)
            end
            if presentation.two_hand then presentation.two_hand.clear(true) end
            if presentation.gameplay_ui then presentation.gameplay_ui.sample(false, 0) end
            presentation.communication_input.cancel()
            presentation.push_to_talk.cancel()
            return
        end
        presentation.scan_movement_inventory(self, frame)
        controller_observation.gameplay_stick_active = false
        local gameplay_held = controller_observation.gameplay_input_enabled and
            presentation.controller_bindings.held or 0
        if controller_observation.gameplay_input_active and
                self._action_lookup and self._input_cache then
            local cache_index = self._buffer_index and self:_buffer_index(frame)
            if cache_index then
                local move_x = tonumber(
                    controller_observation.gameplay_movement[0])
                local move_y = tonumber(
                    controller_observation.gameplay_movement[1])
                move_x, move_y = presentation.rotate_controller_movement(
                    move_x, move_y)
                -- Cache references and scalar values avoid three temporary
                -- movement tables on every fixed input frame, even at rest.
                local right_cache = self._input_cache[self._action_lookup.move_right]
                local left_cache = self._input_cache[self._action_lookup.move_left]
                local forward_cache = self._input_cache[self._action_lookup.move_forward]
                local backward_cache = self._input_cache[self._action_lookup.move_backward]
                local existing_x = (tonumber(right_cache and right_cache[cache_index]) or 0) -
                    (tonumber(left_cache and left_cache[cache_index]) or 0)
                local existing_y = (tonumber(forward_cache and forward_cache[cache_index]) or 0) -
                    (tonumber(backward_cache and backward_cache[cache_index]) or 0)
                local stick_active = math.abs(move_x) > 0.0001 or
                    math.abs(move_y) > 0.0001
                controller_observation.gameplay_stick_active = stick_active
                local combined_x = math.max(-1, math.min(
                    1, existing_x + move_x))
                local combined_y = math.max(-1, math.min(
                    1, existing_y + move_y))
                local movement_right, movement_left = math.max(combined_x, 0), math.max(-combined_x, 0)
                local movement_forward, movement_backward = math.max(combined_y, 0), math.max(-combined_y, 0)
                -- A neutral or unavailable VR stick must not claim locomotion
                -- ownership. Leaving the cache untouched preserves keyboard,
                -- gamepad and accessibility inputs sampled by Darktide.
                if stick_active then
                    if right_cache then right_cache[cache_index] = movement_right end
                    if left_cache then left_cache[cache_index] = movement_left end
                    if forward_cache then forward_cache[cache_index] = movement_forward end
                    if backward_cache then backward_cache[cache_index] = movement_backward end
                end
                if type(frame) == "number" and
                        frame - controller_observation.gameplay_locomotion_last_frame >= 60 then
                    controller_observation.gameplay_locomotion_last_frame = frame
                    local local_player = Managers and Managers.player and
                        Managers.player:local_player(1)
                    local player_unit = local_player and local_player.player_unit
                    if player_unit and Unit.alive(player_unit) then
                        local player_position = Unit.world_position(player_unit, 1)
                        local state_extension = ScriptUnit.has_extension(
                            player_unit, "character_state_machine_system")
                        local state_ok, state_name = pcall(function()
                            return state_extension and
                                state_extension:current_state_name() or "missing"
                        end)
                        state_name = state_ok and state_name or "error"
                        if state_name ~=
                                controller_observation.character_state_name then
                            mod:info(
                                "DARKTIDEVR_MOVEMENT state_transition previous=%s current=%s frame=%d left_live=%s right_live=%s",
                                tostring(controller_observation.character_state_name),
                                tostring(state_name), frame,
                                tostring(controller_observation.left_grip_tracking_live),
                                tostring(controller_observation.right_grip_tracking_live))
                            controller_observation.character_state_name =
                                state_name
                        end
                        local movement_rotation, movement_reference =
                            presentation.movement_reference_rotation()
                        local reference_forward = movement_rotation and
                            Quaternion.forward(movement_rotation) or Vector3.zero()
                        mod:info(
                            "DARKTIDEVR_INPUT locomotion frame=%d state=%s reference=%s reference_yaw=%.4f head_yaw=%.4f reference_forward=%.4f,%.4f aim_q=%.4f,%.4f,%.4f,%.4f move=%.3f,%.3f raw_left=%.3f,%.3f raw_right=%.3f,%.3f existing=%.3f,%.3f combined=%.3f,%.3f stick_active=%s tracking_live=%s,%s cache=%.3f,%.3f,%.3f,%.3f player=%.4f,%.4f,%.4f",
                            frame, tostring(state_name),
                            tostring(movement_reference), movement_rotation and
                                Quaternion.yaw(movement_rotation) or 0,
                            controller_observation.gameplay_yaw or 0,
                            Vector3.x(reference_forward),
                            Vector3.y(reference_forward),
                            controller_observation.left_aim_qx or 0,
                            controller_observation.left_aim_qy or 0,
                            controller_observation.left_aim_qz or 0,
                            controller_observation.left_aim_qw or 0,
                            move_x, move_y,
                            controller_observation.left_stick_x,
                            controller_observation.left_stick_y,
                            controller_observation.right_stick_x,
                            controller_observation.right_stick_y,
                            existing_x, existing_y,
                            combined_x, combined_y,
                            tostring(stick_active),
                            tostring(controller_observation.left_grip_tracking_live),
                            tostring(controller_observation.right_grip_tracking_live),
                            movement_right, movement_left,
                            movement_forward, movement_backward,
                            Vector3.x(player_position), Vector3.y(player_position),
                            Vector3.z(player_position))
                    end
                end
                for binding_index = 1,
                        #presentation.gameplay_input_bindings do
                    local binding =
                        presentation.gameplay_input_bindings[binding_index]
                    if bit.band(gameplay_held, binding.mask) ~= 0 then
                        for name_index = 1, #binding.held do
                            local action_index =
                                self._action_lookup[binding.held[name_index]]
                            if action_index and self._input_cache[action_index] then
                                self._input_cache[action_index][cache_index] = true
                            end
                        end
                    end
                end
            end
        end
        -- Finalize the same cached input columns consumed by local simulation
        -- and the stock network sender, after the controller adapter above.
        presentation.online_rules.capture(self, frame, dt, t)
        presentation.apply_keyboard_mouse_roll_input(self, frame)
        if not controller_observation.primary_action_injected then
            return
        end
        local stage = controller_observation.primary_action_stage
        if stage == "press" then
            local action_index = self._action_lookup and
                self._action_lookup.action_one_hold
            local cache_index = self._buffer_index and
                self:_buffer_index(frame)
            if not action_index or not cache_index or not self._input_cache or
                    not self._input_cache[action_index] then
                mod:warning(
                    "DARKTIDEVR_INPUT primary_action blocked reason=missing_hold_cache"
                )
                controller_observation.primary_action_stage = "failed"
                return
            end
            self._input_cache[action_index][cache_index] = true
            local pressed = self:get("action_one_pressed", frame)
            local held = self:get("action_one_hold", frame)
            controller_observation.primary_action_cache_observed = true
            controller_observation.primary_action_cache_frame = frame
            controller_observation.primary_action_stage = "held"
            mod:info(
                "DARKTIDEVR_INPUT primary_action fixed_cache pressed=%s held=%s frame=%s sequence=%d",
                tostring(pressed),
                tostring(held),
                tostring(frame),
                controller_observation.primary_action_sequence
            )
        elseif stage == "release" then
            local released = self:get("action_one_release", frame)
            local held = self:get("action_one_hold", frame)
            controller_observation.primary_action_stage = "complete"
            mod:info(
                "DARKTIDEVR_INPUT primary_action release_cache=%s held=%s frame=%s sequence=%d",
                tostring(released),
                tostring(held),
                tostring(frame),
                controller_observation.primary_action_sequence
            )
        end
    end)

function presentation.log_unit_pose(label, unit, node)
    if not unit or not Unit.alive(unit) then
        mod:info("DARKTIDEVR_WEAPON %s unit=missing", tostring(label))
        return
    end
    local node_index = node or 1
    local ok, error_message = pcall(function()
        local position = Unit.world_position(unit, node_index)
        local rotation = Unit.world_rotation(unit, node_index)
        local yaw, pitch, roll = Quaternion.to_yaw_pitch_roll(rotation)
        mod:info(
            "DARKTIDEVR_WEAPON %s node=%s position=%.4f,%.4f,%.4f ypr=%.4f,%.4f,%.4f",
            tostring(label), tostring(node_index),
            Vector3.x(position), Vector3.y(position), Vector3.z(position),
            yaw, pitch, roll
        )
    end)
    if not ok then
        mod:warning(
            "DARKTIDEVR_WEAPON %s pose_error=%s",
            tostring(label), tostring(error_message))
    end
end

function presentation.scan_movement_inventory(self, fixed_frame)
    if controller_observation.movement_inventory_done or
            (fixed_frame and fixed_frame <
                controller_observation.movement_inventory_last_check_frame + 60) or
            not Mods or not Mods.lua or not Mods.lua.io then
        return
    end
    controller_observation.movement_inventory_last_check_frame =
        fixed_frame or 0
    local flag_path =
        "./../mods/darktidevr/darktidevr_movement_inventory.flag"
    local flag = Mods.lua.io.open(flag_path, "r")
    if not flag then
        return
    end
    local request = flag:read("*all")
    flag:close()
    if not request or not request:match("^%s*scan%s*$") then
        return
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    local player_unit = local_player and local_player.player_unit
    -- HumanInputHandler owns input caches rather than the player unit. Unlike
    -- the weapon/animation extensions it has no reliable `_unit` member, and
    -- the fixed-update frame is not part of every shipped handler signature.
    -- The one-shot file itself provides the necessary throttle.
    if not player_unit or not Unit.alive(player_unit) then
        return
    end
    local consumed = Mods.lua.io.open(flag_path, "w")
    if consumed then
        consumed:write("consumed\n")
        consumed:close()
    end
    controller_observation.movement_inventory_done = true

    local function relevant_name(value)
        return type(value) == "string" and
            (value:find("move", 1, true) or
             value:find("locomotion", 1, true) or
             value:find("position", 1, true) or
             value:find("velocity", 1, true) or
             value:find("teleport", 1, true) or
             value:find("mover", 1, true) or
             value:find("input", 1, true))
    end
    local function collect_keys(value)
        local found = {}
        local seen = {}
        local function visit(candidate)
            if type(candidate) ~= "table" or seen[candidate] then
                return
            end
            seen[candidate] = true
            for key in pairs(candidate) do
                if relevant_name(key) then
                    found[#found + 1] = tostring(key)
                end
            end
        end
        visit(value)
        local mt = type(value) == "table" and getmetatable(value) or nil
        visit(mt)
        visit(mt and mt.__index)
        table.sort(found)
        return #found > 0 and table.concat(found, ",") or "none"
    end
    local function collect_members(value)
        if type(value) ~= "table" then
            return "type=" .. type(value) .. ":" .. tostring(value)
        end
        local found = {}
        local ok, error_message = pcall(function()
            for key, member in pairs(value) do
                local member_type = type(member)
                local rendered = member_type
                if member_type == "number" or member_type == "boolean" or
                        member_type == "string" then
                    rendered = member_type .. ":" .. tostring(member)
                end
                found[#found + 1] = tostring(key) .. "=" .. rendered
                if #found >= 96 then
                    found[#found + 1] = "..."
                    break
                end
            end
        end)
        if not ok then
            return "pairs_error=" .. tostring(error_message)
        end
        table.sort(found)
        return #found > 0 and table.concat(found, ",") or "none"
    end
    local function render_vector(value)
        local ok, rendered = pcall(function()
            return string.format(
                "%.5f,%.5f,%.5f",
                Vector3.x(value), Vector3.y(value), Vector3.z(value))
        end)
        return ok and rendered or "unavailable:" .. tostring(rendered)
    end

    mod:info(
        "DARKTIDEVR_MOVEMENT inventory handler=%s fixed_frame=%s",
        collect_keys(self), tostring(fixed_frame))
    local extension_names = {
        "locomotion_system", "movement_state_machine_system",
        "unit_data_system", "first_person_system", "input_system",
        "weapon_system", "mover_system", "navigation_system"
    }
    for index = 1, #extension_names do
        local name = extension_names[index]
        local ok, extension = pcall(ScriptUnit.has_extension, player_unit, name)
        mod:info(
            "DARKTIDEVR_MOVEMENT extension=%s present=%s keys=%s",
            name, tostring(ok and extension ~= nil),
            ok and extension and collect_keys(extension) or "none")
    end
    local locomotion_extension =
        ScriptUnit.has_extension(player_unit, "locomotion_system")
    if locomotion_extension then
        local component_names = {
            "_locomotion_component",
            "_locomotion_force_translation_component",
            "_locomotion_force_rotation_component",
            "_locomotion_steering_component",
            "_movement_settings_component",
            "_movement_state_component"
        }
        for index = 1, #component_names do
            local component_name = component_names[index]
            local component = locomotion_extension[component_name]
            mod:info(
                "DARKTIDEVR_MOVEMENT component=%s members=%s",
                component_name,
                collect_members(component))
            if type(component) == "table" then
                local storage_names = {
                    "__config", "__data", "__blackboard", "__additional_data"
                }
                for storage_index = 1, #storage_names do
                    local storage_name = storage_names[storage_index]
                    -- Component proxies interpret unknown indexed fields as
                    -- generated schema fields and throw. Inventory metadata
                    -- lives directly on the wrapper, so bypass __index.
                    local storage = rawget(component, storage_name)
                    mod:info(
                        "DARKTIDEVR_MOVEMENT component=%s storage=%s members=%s",
                        component_name, storage_name, collect_members(storage))
                    if type(storage) == "table" then
                        local nested_count = 0
                        for key, member in pairs(storage) do
                            if type(member) == "table" then
                                nested_count = nested_count + 1
                                mod:info(
                                    "DARKTIDEVR_MOVEMENT component=%s storage=%s key=%s nested=%s",
                                    component_name, storage_name, tostring(key),
                                    collect_members(member))
                                if nested_count >= 16 then
                                    break
                                end
                            end
                        end
                    end
                end
                local vector_fields = {
                    "position", "velocity_current", "start_translation",
                    "target_translation", "velocity_wanted"
                }
                for field_index = 1, #vector_fields do
                    local field_name = vector_fields[field_index]
                    if rawget(component, "__config") and
                            rawget(component, "__config")[field_name] then
                        mod:info(
                            "DARKTIDEVR_MOVEMENT component=%s field=%s value=%s",
                            component_name, field_name,
                            render_vector(component[field_name]))
                    end
                end
            end
        end
        local method_names = {
            "_update_movement", "_update_script_driven_hub_movement",
            "_update_script_driven_movement"
        }
        for index = 1, #method_names do
            local method_name = method_names[index]
            local method = locomotion_extension[method_name]
            local info = debug and debug.getinfo and type(method) == "function" and
                debug.getinfo(method, "Snu") or nil
            mod:info(
                "DARKTIDEVR_MOVEMENT method=%s source=%s line=%s params=%s upvalues=%s",
                method_name,
                tostring(info and (info.short_src or info.source) or "unavailable"),
                tostring(info and info.linedefined or "unavailable"),
                tostring(info and info.nparams or "unavailable"),
                tostring(info and info.nups or "unavailable"))
            if info and debug and debug.getupvalue then
                if debug.getlocal then
                    local parameter_names = {}
                    for parameter_index = 1, info.nparams do
                        local parameter_name =
                            debug.getlocal(method, parameter_index)
                        parameter_names[#parameter_names + 1] =
                            tostring(parameter_name)
                    end
                    mod:info(
                        "DARKTIDEVR_MOVEMENT method=%s parameters=%s",
                        method_name, table.concat(parameter_names, ","))
                end
                for upvalue_index = 1, info.nups do
                    local upvalue_name, upvalue =
                        debug.getupvalue(method, upvalue_index)
                    mod:info(
                        "DARKTIDEVR_MOVEMENT method=%s upvalue=%s type=%s members=%s",
                        method_name, tostring(upvalue_name), type(upvalue),
                        collect_members(upvalue))
                end
            end
        end
    end
end

function presentation.refresh_body_follow_mode(t)
    if t < controller_observation.body_follow_last_check_t + 1 or
            not Mods or not Mods.lua or not Mods.lua.io then
        return
    end
    controller_observation.body_follow_last_check_t = t
    local flag_path =
        "./../mods/darktidevr/darktidevr_body_follow_test.flag"
    local flag = Mods.lua.io.open(flag_path, "r")
    -- Play default when the flag is absent; a present file decides.
    local mode = "enabled"
    if flag then
        local request = flag:read("*all")
        flag:close()
        mode = "disabled"
        if request and request:match("^%s*trace%s*$") then
            mode = "trace"
        elseif request and request:match("^%s*enabled%s*$") then
            mode = "enabled"
        end
    end
    local game_mode_name = active_game_mode_name()
    if game_mode_name == "hub" or presentation.online_rules.enabled() or
            not presentation.is_first_person_body_mode(game_mode_name) then
        -- Hub room-scale motion is presentation-only. The HMD and planted-foot
        -- IK lean inside a 25 cm envelope, while the server-authoritative root
        -- and collision capsule remain untouched.
        mode = "disabled"
    end
    if mode ~= controller_observation.body_follow_mode then
        controller_observation.body_follow_mode = mode
        controller_observation.body_follow_last_sequence = head_pose_last_sequence
        controller_observation.body_follow_last_x =
            controller_observation.body_follow_x
        controller_observation.body_follow_last_z =
            controller_observation.body_follow_z
        controller_observation.body_follow_last_position_x = nil
        controller_observation.body_follow_last_position_y = nil
        controller_observation.body_follow_last_position_z = nil
        mod:info(
            "DARKTIDEVR_MOVEMENT body_follow mode=%s source=test_flag",
            mode)
    end
end

function presentation.apply_body_follow_translation(
        unit, dt, t, locomotion_component, steering_component,
        current_position)
    presentation.refresh_body_follow_mode(t)
    if presentation.online_rules.enabled() then return nil end
    local mode = controller_observation.body_follow_mode
    if mode == "disabled" then
        return nil
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    if not local_player or unit ~= local_player.player_unit or
            not Unit.alive(unit) then
        return nil
    end

    local sequence = head_pose_last_sequence
    local body_x = controller_observation.body_follow_x
    local body_z = controller_observation.body_follow_z
    local delta_x = 0
    local delta_z = 0
    if sequence ~= controller_observation.body_follow_last_sequence then
        if sequence > controller_observation.body_follow_last_sequence then
            local pending_x = body_x -
                controller_observation.body_follow_last_x
            local pending_z = body_z -
                controller_observation.body_follow_last_z
            -- Accumulate sub-millimetre tracking noise instead of feeding it
            -- into the collision mover every fixed tick. Slow deliberate
            -- movement is preserved because the applied baseline advances only
            -- after the accumulated horizontal displacement reaches 2 mm.
            if pending_x * pending_x + pending_z * pending_z >= 0.000004 then
                delta_x = pending_x
                delta_z = pending_z
                controller_observation.body_follow_last_x = body_x
                controller_observation.body_follow_last_z = body_z
            end
        end
        controller_observation.body_follow_last_sequence = sequence
    end

    local character_scale =
        presentation.calibrated_character_scale(local_player)
    local world_delta = Vector3.zero()
    local original_velocity = nil
    if delta_x ~= 0 or delta_z ~= 0 then
        -- body_follow and camera_delta are the two complementary parts of one
        -- OpenXR-local displacement. They must therefore use the same
        -- immutable scene basis. The gameplay locomotion rotation can face a
        -- different direction (and changes with animation/steering); using it
        -- here moved the authoritative body diagonally away from the tracked
        -- camera whenever the headset crossed the sliding translation box.
        local body_rotation = active_base_rotation and
            active_base_rotation:unbox() or locomotion_component.rotation
        world_delta =
            Quaternion.right(body_rotation) * (delta_x * character_scale) +
            Quaternion.forward(body_rotation) * (-delta_z * character_scale)
        if mode == "enabled" and dt > 0 then
            -- Normal script-driven locomotion never reads target_translation.
            -- Feed the physical displacement through the exact velocity input
            -- consumed by the mover/collision path for this fixed update only.
            -- Restoring the original steering value after the wrapped call
            -- keeps stick acceleration/deceleration state independent.
            original_velocity = steering_component.velocity_wanted
            steering_component.velocity_wanted =
                original_velocity + world_delta / dt
            controller_observation.body_follow_writes =
                controller_observation.body_follow_writes + 1
        end
    end

    if t >= controller_observation.body_follow_last_log_t + 0.5 then
        local target = steering_component.target_translation
        local velocity = steering_component.velocity_wanted
        local position_dx = 0
        local position_dy = 0
        local position_dz = 0
        if controller_observation.body_follow_last_position_x then
            position_dx = Vector3.x(current_position) -
                controller_observation.body_follow_last_position_x
            position_dy = Vector3.y(current_position) -
                controller_observation.body_follow_last_position_y
            position_dz = Vector3.z(current_position) -
                controller_observation.body_follow_last_position_z
        end
        controller_observation.body_follow_last_position_x =
            Vector3.x(current_position)
        controller_observation.body_follow_last_position_y =
            Vector3.y(current_position)
        controller_observation.body_follow_last_position_z =
            Vector3.z(current_position)
        controller_observation.body_follow_last_log_t = t
        mod:info(
            "DARKTIDEVR_MOVEMENT body_follow mode=%s sequence=%d cumulative=%.5f,%.5f delta=%.5f,%.5f world_delta=%.5f,%.5f,%.5f target=%.5f,%.5f,%.5f velocity=%.5f,%.5f,%.5f position_delta=%.5f,%.5f,%.5f local_move=%.3f,%.3f writes=%d",
            mode, sequence, body_x, body_z, delta_x, delta_z,
            Vector3.x(world_delta), Vector3.y(world_delta),
            Vector3.z(world_delta), Vector3.x(target), Vector3.y(target),
            Vector3.z(target), Vector3.x(velocity), Vector3.y(velocity),
            Vector3.z(velocity), position_dx, position_dy, position_dz,
            steering_component.local_move_x,
            steering_component.local_move_y,
            controller_observation.body_follow_writes)
    end
    return original_velocity
end

mod:hook(
    require(
        "scripts/extension_systems/locomotion/player_unit_locomotion_extension"),
    "_update_script_driven_movement",
    function(func, self, unit, dt, t, locomotion_component,
            steering_component, current_position, calculate_fall_velocity,
            on_ground, mover, ...)
        local original_velocity = presentation.apply_body_follow_translation(
            unit, dt, t, locomotion_component, steering_component,
            current_position)
        local before_x, before_y = Vector3.x(current_position), Vector3.y(current_position)
        local result = func(
            self, unit, dt, t, locomotion_component, steering_component,
            current_position, calculate_fall_velocity, on_ground, mover, ...)
        if presentation.roomscale and result then
            -- PlayerUnitInputExtension delegates frame ownership to its human
            -- reader. A frame read from the extension itself is nil and silently
            -- leaves every collider step unpaid, producing perpetual chase.
            local human_input = self._input_extension and self._input_extension._human_unit_input
            presentation.roomscale.moved(self, unit, human_input and human_input._frame,
                Vector3.x(result) - before_x, Vector3.y(result) - before_y)
        end
        if original_velocity then
            steering_component.velocity_wanted = original_velocity
        end
        return result
    end)

function presentation.scan_named_nodes(label, unit, node_names)
    if not unit or not Unit.alive(unit) then
        return
    end
    local count_ok, count = pcall(Unit.num_scene_graph_items, unit)
    mod:info(
        "DARKTIDEVR_WEAPON unit=%s scene_graph_items=%s",
        tostring(label), tostring(count_ok and count or "unavailable")
    )
    for i = 1, #node_names do
        local node_name = node_names[i]
        if Unit.has_node(unit, node_name) then
            presentation.log_unit_pose(
                tostring(label) .. ":" .. node_name,
                unit,
                Unit.node(unit, node_name))
        end
    end
end

function presentation.scan_body_rig(self, fixed_frame)
    if controller_observation.body_rig_inventory_done or
            (fixed_frame and fixed_frame <
                controller_observation.body_rig_inventory_last_check_frame + 60) or
            not Mods or not Mods.lua or not Mods.lua.io then
        return
    end
    if not fixed_frame then
        -- Callers without a fixed frame still get at most one flag read per
        -- second instead of one per rendered frame.
        local now = os.time()
        if controller_observation.body_rig_inventory_last_check_time == now then
            return
        end
        controller_observation.body_rig_inventory_last_check_time = now
    end
    controller_observation.body_rig_inventory_last_check_frame =
        fixed_frame or 0
    local flag_path =
        "./../mods/darktidevr/darktidevr_body_rig_inventory.flag"
    local flag = Mods.lua.io.open(flag_path, "r")
    if not flag then
        return
    end
    local request = flag:read("*all")
    flag:close()
    if not request or not request:match("^%s*scan%s*$") then
        return
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    local player_unit = local_player and local_player.player_unit
    if not player_unit or self._unit ~= player_unit or
            not Unit.alive(player_unit) then
        return
    end
    local consumed = Mods.lua.io.open(flag_path, "w")
    if consumed then
        consumed:write("consumed\n")
        consumed:close()
    end
    controller_observation.body_rig_inventory_done = true
    local unit_data = ScriptUnit.has_extension(player_unit, "unit_data_system")
    local breed_ok, breed_name = pcall(function()
        return unit_data and unit_data:breed_name()
    end)
    local nodes = {
        "j_hips_handle", "j_hips", "j_spine", "j_spine1", "j_spine2",
        "j_spine3", "j_neck", "j_head", "j_leftshoulder",
        "j_leftarm", "j_leftupperarm", "j_leftforearm", "j_lefthand",
        "j_leftarmroll", "j_leftarmroll1", "j_leftarmroll1_dk",
        "j_leftupperarmroll", "j_leftupperarmroll1",
        "j_leftupperarmroll1_dk", "j_leftforearmroll",
        "j_leftforearmroll1", "j_leftforearmroll1_dk",
        "j_leftforearmroll2", "j_leftforearmroll2_dk",
        "j_left_hand_ik_handle", "j_rightshoulder", "j_rightupperarm",
        "j_rightarm", "j_rightforearm", "j_righthand",
        "j_rightarmroll", "j_rightarmroll1", "j_rightarmroll1_dk",
        "j_rightupperarmroll", "j_rightupperarmroll1",
        "j_rightupperarmroll1_dk", "j_rightforearmroll",
        "j_rightforearmroll1", "j_rightforearmroll1_dk",
        "j_rightforearmroll2", "j_rightforearmroll2_dk",
        "j_right_hand_ik_handle",
        "j_leftupleg", "j_leftleg", "j_leftfoot", "j_rightupleg",
        "j_rightleg", "j_rightfoot", "j_left_foot_ik_handle",
        "j_right_foot_ik_handle", "j_left_foot_orient_handle",
        "j_right_foot_orient_handle"
    }
    local count_ok, count = pcall(Unit.num_scene_graph_items, player_unit)
    mod:info(
        "DARKTIDEVR_IK inventory breed=%s scene_graph_items=%s frame=%s",
        tostring(breed_ok and breed_name or "unavailable"),
        tostring(count_ok and count or "unavailable"),
        tostring(fixed_frame))
    for i = 1, #nodes do
        local name = nodes[i]
        if Unit.has_node(player_unit, name) then
            local node = Unit.node(player_unit, name)
            local parent = Unit.scene_graph_parent(player_unit, node)
            local local_position = Unit.local_position(player_unit, node)
            local world_position = Unit.world_position(player_unit, node)
            mod:info(
                "DARKTIDEVR_IK node name=%s index=%s parent=%s local=%.4f,%.4f,%.4f world=%.4f,%.4f,%.4f",
                name, tostring(node), tostring(parent),
                Vector3.x(local_position), Vector3.y(local_position),
                Vector3.z(local_position), Vector3.x(world_position),
                Vector3.y(world_position), Vector3.z(world_position))
        end
    end
    local constraints = {
        "aim_constraint_target", "look_constraint_target",
        "left_hand_constraint_target", "right_hand_constraint_target"
    }
    for i = 1, #constraints do
        local name = constraints[i]
        local found_ok, target = pcall(
            Unit.animation_find_constraint_target, player_unit, name)
        if found_ok and target ~= nil then
            local pose_ok, pose = pcall(
                Unit.animation_get_constraint_target, player_unit, target)
            if pose_ok and pose then
                local position = Matrix4x4.translation(pose)
                mod:info(
                    "DARKTIDEVR_IK constraint name=%s index=%s position=%.4f,%.4f,%.4f",
                    name, tostring(target), Vector3.x(position),
                    Vector3.y(position), Vector3.z(position))
            else
                mod:info(
                    "DARKTIDEVR_IK constraint name=%s index=%s pose=unavailable",
                    name, tostring(target))
            end
        end
    end
end

presentation.headless_body_slots = {
    "slot_body_face",
    "slot_body_face_tattoo",
    "slot_body_face_scar",
    "slot_body_face_hair",
    "slot_body_face_makeup",
    "slot_body_hair",
    "slot_body_eye_color",
    "slot_body_eye_color_secondary",
    "slot_body_hair_color",
    "slot_body_face_hair_color",
    "slot_gear_head"
}

presentation.companion_gear_slots = {
    slot_companion_gear_full = true,
    slot_companion_body_skin_color = true,
}
presentation.headless_body_hidden_slot_lookup = {
    slot_body_face = true,
    slot_body_face_tattoo = true,
    slot_body_face_scar = true,
    slot_body_face_hair = true,
    slot_body_face_makeup = true,
    slot_body_hair = true,
    slot_body_eye_color = true,
    slot_body_eye_color_secondary = true,
    slot_body_hair_color = true,
    slot_body_face_hair_color = true,
    slot_gear_head = true
}

function presentation.update_body_visibility_gate(frame)
    if frame <
            controller_observation.body_visibility_last_check_frame + 60 then
        return false
    end
    controller_observation.body_visibility_last_check_frame = frame
    local path =
        "./../mods/darktidevr/darktidevr_headless_body.flag"
    local flag = Mods and Mods.lua and Mods.lua.io and
        Mods.lua.io.open(path, "r")
    -- The headless first-person body is the play default; a present flag
    -- still decides. The hub third-person option withdraws it in the hub only.
    local enabled = true
    if flag then
        enabled = flag:read("*all"):match("^%s*enabled%s*$") ~= nil
        flag:close()
    end
    if enabled and (presentation.hub_third_person_active() or
            presentation.cinematic_stereo_active()) then
        -- Stock third-person hub, or a stereo cinematic: no tracked hands,
        -- weapons or headless body over the game's own presentation.
        enabled = false
    end
    local full_body_path =
        "./../mods/darktidevr/darktidevr_full_body_experimental.flag"
    local full_body_flag = Mods and Mods.lua and Mods.lua.io and
        Mods.lua.io.open(full_body_path, "r")
    -- The dev flag only: this is the older headless third-person body, whose
    -- head floats above a body of the character's own height (worn, 17
    -- September, through the option). The "Full body (experimental)" option
    -- now runs the body overlay instead (darktidevr_body_mirror,
    -- Mirror.requested_mode).
    local full_body_experimental = false
    if full_body_flag then
        full_body_experimental =
            full_body_flag:read("*all"):match("^%s*enabled%s*$") ~= nil
        full_body_flag:close()
    end
    if full_body_experimental ~=
            controller_observation.full_body_experimental_enabled then
        controller_observation.full_body_experimental_enabled =
            full_body_experimental
        controller_observation.body_visibility_logged_slots = false
        mod:info(
            "DARKTIDEVR_BODY embodiment=%s source=experimental_flag",
            full_body_experimental and "full_body" or "tracked_arms")
    end
    -- Hub and Psykhanium share one first-person headless-body presentation.
    -- A second hub-only flag allowed the camera and visual body gates to drift
    -- apart, so the headless-body gate now owns both decisions.
    local force_hub_first_person = enabled
    if force_hub_first_person ~=
            controller_observation.force_hub_first_person_enabled then
        controller_observation.force_hub_first_person_enabled =
            force_hub_first_person
        mod:info(
            "DARKTIDEVR_BODY hub_presentation=%s source=headless_body",
            force_hub_first_person and "forced_1p" or "stock_3p")
    end
    if not enabled then
        controller_observation.body_visibility_faulted = false
    end
    enabled = enabled and
        not controller_observation.body_visibility_faulted
    if enabled == controller_observation.body_visibility_enabled then
        return false
    end
    controller_observation.body_visibility_enabled = enabled
    controller_observation.body_visibility_logged_slots = false
    controller_observation.body_visibility_copy_drew = nil
    controller_observation.body_visibility_logged_copy = nil
    controller_observation.body_fade_override_logged = false
    controller_observation.body_camera_anchor_logged = false
    controller_observation.body_eye_anchor_logged = false
    controller_observation.body_eye_anchor_unit = nil
    controller_observation.body_eye_anchor_local_x = nil
    controller_observation.body_eye_anchor_local_y = nil
    controller_observation.body_eye_anchor_local_z = nil
    controller_observation.body_eye_anchor_source = nil
    controller_observation.body_camera_eye_offset_unit = nil
    controller_observation.body_camera_eye_offset_since = nil
    controller_observation.body_camera_eye_offset_x = nil
    controller_observation.body_camera_eye_offset_y = nil
    controller_observation.body_camera_eye_offset_z = nil
    controller_observation.body_ik_neck_unit = nil
    controller_observation.body_ik_neck_generation = nil
    controller_observation.body_ik_neck_baseline_raw = nil
    controller_observation.body_ik_neck_baseline_arc = nil
    controller_observation.body_ik_neck_anchor_unit = nil
    controller_observation.body_ik_neck_anchor_generation = nil
    controller_observation.body_ik_neck_anchor_local = nil
    controller_observation.body_camera_sweep_start_t = nil
    controller_observation.body_camera_sweep_last_bucket = -1
    controller_observation.body_head_visible = not enabled
    controller_observation.body_visual_yaw = nil
    controller_observation.body_visual_yaw_last_t = nil
    controller_observation.body_heading_last_head_yaw = nil
    controller_observation.body_heading_last_motion_t = -math.huge
    controller_observation.body_ik_torso_axis_unit = nil
    controller_observation.body_ik_torso_axis_local = nil
    controller_observation.body_ik_torso_block_reason = false
    controller_observation.body_ik_torso_residual = nil
    mod:info(
        "DARKTIDEVR_BODY visibility=%s source=test_flag",
        enabled and (full_body_experimental and
            "headless_3p" or "tracked_3p_arms") or "stock_1p")
    return true
end

function presentation.is_local_visual_loadout(self)
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    return local_player and local_player.player_unit and
        self._unit == local_player.player_unit
end

function presentation.apply_body_visibility(self, frame, force)
    if not presentation.is_local_visual_loadout(self) then
        return
    end
    local mode = active_game_mode_name()
    local range_mode = presentation.is_first_person_body_mode(mode)
    local active = controller_observation.body_visibility_enabled and
        range_mode
    -- ONE BODY. While the custom-IK copy is drawing the player's body the
    -- stock 3P model is not drawn at all (see the full-body branch below).
    -- Asked here rather than down there because a CHANGE in the answer has to
    -- force a pass: the copy becomes ready some frames after the gate opens,
    -- and waiting out the sixty-frame heartbeat would leave the player
    -- looking at both bodies for the best part of a second each time.
    local copy_draws_body = presentation.body_mirror ~= nil and
        presentation.body_mirror.draws_body ~= nil and
        presentation.body_mirror.draws_body() == true
    -- Observed here, RECORDED below the guards. Recording it here spends the
    -- force on a pass that then returns early -- a cutscene, or a frame before
    -- the equipment exists -- and because the recorded value now matches,
    -- nothing re-forces and the correction waits out the heartbeat it was
    -- written to avoid (review, 19 September).
    if copy_draws_body ~= controller_observation.body_visibility_copy_drew then
        force = true
    end
    if not force and frame <
            controller_observation.body_visibility_last_apply_frame + 60 then
        return
    end
    controller_observation.body_visibility_last_apply_frame = frame
    -- A cutscene hides the real players through the player visibility
    -- extension (snapshot, hide, restore) and its own characters stand in
    -- for them. Forcing the 3P body visible below put the player in the
    -- scene twice. While the extension says hidden, keep the body hidden
    -- and touch nothing else; the stock restore and the next pass bring it
    -- back.
    local stock_visibility = self._unit and Unit.alive(self._unit) and
        ScriptUnit.has_extension(self._unit, "player_visibility_system")
    if stock_visibility and not stock_visibility:visible() then
        if not controller_observation.body_visibility_stock_hidden then
            controller_observation.body_visibility_stock_hidden = true
            mod:info("DARKTIDEVR_BODY stock_hidden=true body_left_hidden=true")
        end
        Unit.set_unit_visibility(self._unit, false, true)
        return
    elseif controller_observation.body_visibility_stock_hidden then
        controller_observation.body_visibility_stock_hidden = false
        mod:info("DARKTIDEVR_BODY stock_hidden=false body_reapplied=true")
    end

    local EquipmentComponent = require(
        "scripts/extension_systems/visual_loadout/equipment_component")
    local equipment = self._equipment
    local inventory = self._inventory_component
    local unit_3p = self._unit
    local unit_1p = self._first_person_unit
    if type(equipment) ~= "table" or not inventory or
            not unit_3p or not Unit.alive(unit_3p) then
        return
    end

    -- Keep the camera genuinely first person. The body is selected through the
    -- equipment answer only (the proven First Person Body architecture), not by
    -- forcing the whole extension into third person and repairing its camera.
    local first_person_extension = self._first_person_extension
    if first_person_extension and active then
        -- Remember the stock flag once per extension so that withdrawing the
        -- gate (the optional third-person hub body) gives the hub its stock
        -- third-person camera back; a cleared flag left it first person.
        if controller_observation.stock_force_third_person_owner ~= first_person_extension then
            controller_observation.stock_force_third_person_owner = first_person_extension
            controller_observation.stock_force_third_person =
                first_person_extension._force_third_person_mode == true
        end
        first_person_extension._force_third_person_mode = false
        first_person_extension._show_1p_equipment = false
        first_person_extension._wants_1p_camera = true
    elseif first_person_extension and
            controller_observation.stock_force_third_person_owner == first_person_extension then
        -- The extension was initialised while the MissionManager hook already
        -- answered false for the hub, so the captured value is not the stock
        -- one; ask the mission again now that the hub option withdraws the
        -- first-person request.
        local mission_manager = Managers and Managers.state and Managers.state.mission
        local stock = controller_observation.stock_force_third_person
        if mission_manager and mission_manager.force_third_person_mode then
            stock = mission_manager:force_third_person_mode() == true
        end
        first_person_extension._force_third_person_mode = stock
        controller_observation.stock_force_third_person_owner = nil
        mod:info("DARKTIDEVR_BODY stock_force_third_person restored=%s captured=%s",
            tostring(stock), tostring(controller_observation.stock_force_third_person))
    end

    -- This is Darktide's stock visual swap, invoked with a visual-only 3P
    -- selection. The gameplay/camera first-person component remains unchanged.
    local visibility_first_person_mode = self._is_in_first_person_mode
    if active then
        visibility_first_person_mode = false
    end
    EquipmentComponent.update_item_visibility(
        equipment,
        inventory.wielded_slot,
        unit_3p,
        unit_1p,
        visibility_first_person_mode,
        self._item_definitions)

    -- The launch presentation uses the undistorted 3P skinned rig, but keeps
    -- only its authored arm mesh and currently wielded 3P equipment.  The
    -- game's 1P rig is deliberately not used: its perspective-authored arms
    -- are compressed and visibly deform when placed in world-space stereo.
    -- Full-body presentation remains available only through the explicit
    -- experimental flag below.
    if active and
            not controller_observation.full_body_experimental_enabled then
        if unit_1p and Unit.alive(unit_1p) then
            Unit.set_unit_visibility(unit_1p, false, true)
        end
        Unit.set_unit_visibility(unit_3p, true, true)
        local visible_arm_units = 0
        local visible_glove_units = 0
        local hidden_body_units = 0
        for slot_name, slot in pairs(equipment) do
            if type(slot_name) == "string" and type(slot) == "table" then
                local slot_unit_3p = slot.unit_3p
                if slot_unit_3p and Unit.alive(slot_unit_3p) then
                    if not controller_observation.body_visibility_logged_slots and
                            slot_name == "slot_gear_upperbody" then
                        local num_meshes = Unit.num_meshes(slot_unit_3p)
                        mod:info(
                            "DARKTIDEVR_ARMS garment_meshes slot=%s count=%d item=%s",
                            slot_name, num_meshes,
                            tostring(slot.item and slot.item.name))
                        for mesh_index = 1, num_meshes do
                            local mesh_ok, mesh = pcall(
                                Unit.mesh, slot_unit_3p, mesh_index)
                            local box_ok, pose, half_extents = false, nil, nil
                            if mesh_ok and mesh then
                                box_ok, pose, half_extents = pcall(Mesh.box, mesh)
                            end
                            local box_position = box_ok and
                                Matrix4x4.translation(pose) or Vector3.zero()
                            mod:info(
                                "DARKTIDEVR_ARMS garment_mesh index=%d mesh=%s box_ok=%s centre=%.4f,%.4f,%.4f half=%.4f,%.4f,%.4f",
                                mesh_index, tostring(mesh), tostring(box_ok),
                                Vector3.x(box_position),
                                Vector3.y(box_position),
                                Vector3.z(box_position),
                                half_extents and Vector3.x(half_extents) or 0,
                                half_extents and Vector3.y(half_extents) or 0,
                                half_extents and Vector3.z(half_extents) or 0)
                        end
                    end
                    local garment = slot_name == "slot_gear_upperbody"
                    local proxy_hidden = presentation.body_proxy and
                        presentation.body_proxy.hides_source_slot(slot_name)
                    -- The companion's cosmetic body and skin colour are items
                    -- in the owner's equipment (slot_companion_*), attached to
                    -- the companion unit, not body parts: hiding them with the
                    -- body made the owner's servo-skull invisible (its
                    -- particle candles stayed). Keep them visible.
                    local companion_gear =
                        presentation.companion_gear_slots[slot_name] == true
                    local show = companion_gear or
                        ((slot_name == "slot_body_arms" or
                        slot_name == inventory.wielded_slot) and
                        not slot.hidden_3p and not proxy_hidden)
                    Unit.flow_event(
                        slot_unit_3p, show and "lua_visible" or "lua_hidden")
                    Unit.set_unit_visibility(slot_unit_3p, show, true)
                    local attachments = slot.attachments_by_unit_3p and
                        slot.attachments_by_unit_3p[slot_unit_3p]
                    if attachments then
                        for i = 1, #attachments do
                            local attachment = attachments[i]
                            if attachment and Unit.alive(attachment) then
                                if not controller_observation.body_visibility_logged_slots and
                                        slot_name == "slot_gear_upperbody" then
                                    local attachment_meshes =
                                        Unit.num_meshes(attachment)
                                    mod:info(
                                        "DARKTIDEVR_ARMS garment_attachment index=%d unit=%s meshes=%d item=%s attachment_item=%s resource=%s",
                                        i, tostring(attachment),
                                        attachment_meshes,
                                        tostring(slot.item_name_by_unit_3p and
                                            slot.item_name_by_unit_3p[attachment]),
                                        tostring(Unit.get_data(
                                            attachment,
                                            "attachment_item_name")),
                                        tostring(Unit.get_data(
                                            attachment, "unit_name")))
                                    for mesh_index = 1, attachment_meshes do
                                        local mesh_ok, mesh = pcall(
                                            Unit.mesh, attachment, mesh_index)
                                        local box_ok, pose, half_extents =
                                            false, nil, nil
                                        if mesh_ok and mesh then
                                            box_ok, pose, half_extents = pcall(
                                                Mesh.box, mesh)
                                        end
                                        local box_position = box_ok and
                                            Matrix4x4.translation(pose) or
                                            Vector3.zero()
                                        mod:info(
                                            "DARKTIDEVR_ARMS garment_attachment_mesh attachment=%d index=%d mesh=%s box_ok=%s centre=%.4f,%.4f,%.4f half=%.4f,%.4f,%.4f",
                                            i, mesh_index, tostring(mesh),
                                            tostring(box_ok),
                                            Vector3.x(box_position),
                                            Vector3.y(box_position),
                                            Vector3.z(box_position),
                                            half_extents and
                                                Vector3.x(half_extents) or 0,
                                            half_extents and
                                                Vector3.y(half_extents) or 0,
                                            half_extents and
                                                Vector3.z(half_extents) or 0)
                                    end
                                end
                                local attachment_item =
                                    slot.item_name_by_unit_3p and
                                    slot.item_name_by_unit_3p[attachment]
                                local glove_attachment = garment and
                                    type(attachment_item) == "string" and
                                    string.find(
                                        attachment_item, "/gear_hands/",
                                        1, true) ~= nil
                                -- Upper-body cosmetics are separate linked
                                -- units. Keep the torso and full sleeve/arm
                                -- attachments hidden, but retain the dedicated
                                -- glove unit. Its hand bones are already copied
                                -- from the tracked proxy below, so it follows
                                -- the controllers without exposing the stock
                                -- shoulder chain.
                                local attachment_show =
                                    (show and not garment) or
                                    (glove_attachment and not proxy_hidden)
                                Unit.flow_event(attachment,
                                    attachment_show and
                                        "lua_visible" or "lua_hidden")
                                Unit.set_unit_visibility(
                                    attachment, attachment_show, true)
                                if glove_attachment then
                                    visible_glove_units =
                                        visible_glove_units + 1
                                end
                            end
                        end
                    end
                    if show then
                        visible_arm_units = visible_arm_units + 1
                    else
                        hidden_body_units = hidden_body_units + 1
                    end
                end
            end
        end
        if not controller_observation.body_visibility_logged_slots then
            controller_observation.body_visibility_logged_slots = true
            mod:info(
                "DARKTIDEVR_BODY tracked_arms applied mode=%s visible_units=%d glove_units=%d hidden_units=%d wielded=%s unit_1p=false",
                tostring(mode), visible_arm_units, visible_glove_units,
                hidden_body_units,
                tostring(inventory.wielded_slot))
        end
        -- A pass was applied, so the flip is recorded here too. Recorded only
        -- past the last return, it stayed nil on this path -- the one every
        -- player is on -- and nil never equals the boolean above: the force
        -- was set on every call and the sixty-frame gate never held (review,
        -- 5 October).
        controller_observation.body_visibility_copy_drew = copy_draws_body
        return
    end

    -- Darktide's native FadeSystem makes player breeds transparent as the
    -- active camera approaches j_spine (human 0.3-0.9 m, ogryn 0.5-1.2 m).
    -- min_fade is a lower bound on the *fade effect* (stealth raises it), not
    -- an opacity floor, so keep it at the stock zero. The range-only update
    -- hook below suppresses camera-proximity fading without deregistering the
    -- unit from the native extension lifecycle.
    local fade_system = Managers and Managers.state and
        Managers.state.extension and
        Managers.state.extension:system("fade_system")
    if fade_system then
        fade_system:set_min_fade(unit_3p, 0)
        if not controller_observation.body_fade_override_logged then
            controller_observation.body_fade_override_logged = true
            mod:info(
                "DARKTIDEVR_BODY fade_override min_fade=0 distant_update=%s",
                tostring(active))
        end
    end

    if not active then
        -- Reassert the stock root-unit selection along with the equipment
        -- selection when the range-only gate is disabled. This keeps rollback
        -- symmetric even if a later engine version changes helper ownership.
        if unit_1p and Unit.alive(unit_1p) then
            Unit.set_unit_visibility(
                unit_1p, self._is_in_first_person_mode, true)
        end
        Unit.set_unit_visibility(
            unit_3p, not self._is_in_first_person_mode, true)
        -- The optional third-person hub body shows the stock character but
        -- not its weapons: their attachment follows the tracked hands, so
        -- they sit wrongly on a stock-animated body.
        if presentation.hub_third_person_active() then
            local hidden_weapon_units = 0
            -- Weapons, curios (attachment slots) and carried items: all are
            -- placed by the tracked-hand rig, not by the stock animation.
            for _, slot_name in ipairs({"slot_primary", "slot_secondary",
                    "slot_attachment_1", "slot_attachment_2", "slot_attachment_3",
                    "slot_pocketable", "slot_pocketable_small", "slot_device",
                    "slot_luggable"}) do
                local slot = equipment[slot_name]
                if type(slot) == "table" then
                    for _, unit in ipairs({slot.unit_3p, slot.unit_1p}) do
                        if unit and Unit.alive(unit) then
                            Unit.set_unit_visibility(unit, false, true)
                            hidden_weapon_units = hidden_weapon_units + 1
                        end
                    end
                end
            end
            if not controller_observation.body_visibility_logged_slots then
                controller_observation.body_visibility_logged_slots = true
                mod:info(
                    "DARKTIDEVR_BODY hub_third_person weapons_hidden=%d wielded=%s",
                    hidden_weapon_units, tostring(inventory.wielded_slot))
            end
        end
        controller_observation.body_visibility_copy_drew = copy_draws_body
        return
    end

    -- The native 3P presentation has already selected the root and stock 3P
    -- slot set. Remove only geometry that can intersect the eye cameras. Do
    -- not force arbitrary slot units visible here: hidden gadgets and
    -- unwielded equipment have independent authored visibility policy.
    local player_visibility = ScriptUnit.has_extension(
        unit_3p, "player_visibility_system")
    local visible_3p_units = 0
    local hidden_3p_units = 0
    local hidden = {}

    -- ONE BODY. While the custom-IK copy is drawing the player's body, the
    -- stock 3P model is not drawn at all -- root hidden with its children,
    -- then the wielded weapon and the companion's gear shown back.
    --
    -- This replaces a hide-LIST that had to name every body slot Fatshark
    -- ships, and never did. Worn, 19 September: "there are two bodies
    -- visible... with no flickering or any changes", and the report says why
    -- -- `hidden_slots=slot_gear_head,slot_body_face visible_3p_units=7`.
    -- Only the head and face were ever hidden here; `slot_body_legs` and
    -- `slot_gear_lowerbody` appear in neither list, so the stock legs were
    -- drawn inside the copy's legs every frame the mode has ever run. The
    -- arms, torso and upperbody were hidden only once the copy took the hand
    -- rig, which is a race the player can see.
    --
    -- The user set the rule: "When there were just gloves, the standard 3p
    -- model was hidden. That should be exactly how it works now... There's no
    -- reason to ever show that 3p model. All we ever show is the new
    -- custom-IK model." So the default is hidden and the exceptions are
    -- named, rather than the other way round: a slot added by a future
    -- Fatshark patch is hidden, not drawn as a second body.
    -- Past every early return, so the flip is recorded only once a pass has
    -- actually been applied.
    controller_observation.body_visibility_copy_drew = copy_draws_body
    if copy_draws_body then
        -- The ROOT stays visible and every slot is hidden by name. The first
        -- cut hid the root with its children in one call, and the weapon
        -- went with it: worn, 19 September, "weapons are invisible". The
        -- weapon unit is linked under the root's hand joint, and showing it
        -- back by its own handle did nothing -- the engine reads a linked
        -- unit as hidden while anything above it is, and Fatshark's own code
        -- never shows a child back under a hidden parent (it shows the root
        -- with children, then hides slots one by one). So this does what the
        -- gloves mode does and has done since the start: root shown, slots
        -- hidden. The root's own mesh has never shown as a stray in that
        -- mode.
        Unit.set_unit_visibility(unit_3p, true, true)
        if unit_1p and Unit.alive(unit_1p) then
            Unit.set_unit_visibility(unit_1p, false, true)
        end
        for slot_name, slot in pairs(equipment) do
            if type(slot_name) == "string" and type(slot) == "table" then
                local slot_unit_3p = slot.unit_3p
                if slot_unit_3p and Unit.alive(slot_unit_3p) then
                    -- The weapon is placed by the tracked hand rig and is the
                    -- one thing on the stock model the player is meant to
                    -- see. The companion's gear hangs off the servo-skull,
                    -- not off the player, and hiding it with the body made
                    -- the skull invisible once already.
                    local show = presentation.companion_gear_slots[slot_name] == true or
                        (slot_name == inventory.wielded_slot and not slot.hidden_3p)
                    Unit.flow_event(
                        slot_unit_3p, show and "lua_visible" or "lua_hidden")
                    Unit.set_unit_visibility(slot_unit_3p, show, true)
                    local attachments = slot.attachments_by_unit_3p and
                        slot.attachments_by_unit_3p[slot_unit_3p]
                    if attachments then
                        for i = 1, #attachments do
                            local attachment = attachments[i]
                            if attachment and Unit.alive(attachment) then
                                Unit.flow_event(
                                    attachment,
                                    show and "lua_visible" or "lua_hidden")
                                Unit.set_unit_visibility(attachment, show, true)
                            end
                        end
                    end
                    if show then
                        visible_3p_units = visible_3p_units + 1
                    else
                        hidden[#hidden + 1] = slot_name
                        hidden_3p_units = hidden_3p_units + 1
                    end
                end
            end
        end
    end

    -- The copy is not up yet (or has gone): the older headless presentation,
    -- which keeps the stock body and takes its head off, so the player has a
    -- body rather than none while the profile spawns.
    for slot_name, slot in pairs(copy_draws_body and {} or equipment) do
        if type(slot_name) == "string" and type(slot) == "table" then
            local slot_unit_3p = slot.unit_3p
            if slot_unit_3p and Unit.alive(slot_unit_3p) then
                if presentation.headless_body_hidden_slot_lookup[slot_name] or
                        presentation.body_proxy and
                        presentation.body_proxy.hides_source_slot(slot_name) then
                    local proxy_hidden = presentation.body_proxy and
                        presentation.body_proxy.hides_source_slot(slot_name)
                    local show_head = not proxy_hidden and
                        controller_observation.body_head_visible and
                        not slot.hidden_3p
                    Unit.flow_event(
                        slot_unit_3p,
                        show_head and "lua_visible" or "lua_hidden")
                    Unit.set_unit_visibility(slot_unit_3p, show_head, true)
                    local attachments = slot.attachments_by_unit_3p and
                        slot.attachments_by_unit_3p[slot_unit_3p]
                    if attachments then
                        for i = 1, #attachments do
                            local attachment = attachments[i]
                            if attachment and Unit.alive(attachment) then
                                Unit.flow_event(
                                    attachment,
                                    show_head and "lua_visible" or
                                        "lua_hidden")
                                Unit.set_unit_visibility(
                                    attachment, show_head, true)
                            end
                        end
                    end
                    if show_head then
                        visible_3p_units = visible_3p_units + 1
                    else
                        hidden[#hidden + 1] = slot_name
                        hidden_3p_units = hidden_3p_units + 1
                    end
                elseif slot.hidden_3p then
                    hidden_3p_units = hidden_3p_units + 1
                else
                    visible_3p_units = visible_3p_units + 1
                end
            end
        end
    end

    -- One line for the handover, not the twenty-line slot dump again: a copy
    -- that flaps -- a spawn failing repeatedly, a mode poll toggling on the
    -- boundary -- would otherwise turn this into a log storm (review, 19
    -- September). The dump still happens once, the first time through.
    if controller_observation.body_visibility_logged_copy ~= copy_draws_body then
        controller_observation.body_visibility_logged_copy = copy_draws_body
        mod:info(
            "DARKTIDEVR_BODY one_body copy_draws_body=%s hidden_slots=%s visible_3p_units=%d wielded=%s",
            tostring(copy_draws_body),
            #hidden > 0 and table.concat(hidden, ",") or "none",
            visible_3p_units, tostring(inventory.wielded_slot))
    end
    if not controller_observation.body_visibility_logged_slots then
        local slot_names = {}
        for slot_name, slot in pairs(equipment) do
            if type(slot_name) == "string" and type(slot) == "table" and
                    (slot.unit_1p or slot.unit_3p) then
                slot_names[#slot_names + 1] = slot_name
            end
        end
        table.sort(slot_names)
        for i = 1, #slot_names do
            local slot_name = slot_names[i]
            local slot = equipment[slot_name]
            local item = slot.item
            mod:info(
                "DARKTIDEVR_BODY slot=%s item=%s unit_1p=%s unit_3p=%s wielded=%s hide_unit=%s hidden_3p=%s attach=%s wielded_attach=%s unwielded_attach=%s",
                slot_name,
                tostring(item and item.name),
                tostring(slot.unit_1p and Unit.alive(slot.unit_1p) or false),
                tostring(slot.unit_3p and Unit.alive(slot.unit_3p) or false),
                tostring(slot_name == inventory.wielded_slot),
                tostring(slot.hide_unit_in_slot == true),
                tostring(slot.hidden_3p),
                tostring(item and item.attach_node),
                tostring(item and item.wielded_attach_node),
                tostring(item and item.unwielded_attach_node))
        end
        controller_observation.body_visibility_logged_slots = true
        mod:info(
            "DARKTIDEVR_BODY headless_3p applied copy_draws_body=%s mode=%s force_engine_3p=%s player_visible=%s hidden_slots=%s visible_3p_units=%d hidden_3p_units=%d unit_1p=%s wielded=%s",
            tostring(copy_draws_body),
            tostring(mode),
            tostring(first_person_extension and
                first_person_extension._force_third_person_mode),
            tostring(player_visibility and player_visibility:visible()),
            #hidden > 0 and table.concat(hidden, ",") or "none",
            visible_3p_units,
            hidden_3p_units,
            tostring(unit_1p and Unit.alive(unit_1p) or false),
            tostring(inventory.wielded_slot))
    end
end

function presentation.scan_weapon_inventory(self, fixed_frame)
    if controller_observation.weapon_inventory_done or not fixed_frame or
            fixed_frame <
                controller_observation.weapon_inventory_last_check_frame + 60 or
            not Mods or not Mods.lua or not Mods.lua.io then
        return
    end
    controller_observation.weapon_inventory_last_check_frame = fixed_frame
    local flag_path =
        "./../mods/darktidevr/darktidevr_weapon_inventory.flag"
    local flag = Mods.lua.io.open(flag_path, "r")
    if not flag then
        return
    end
    local request = flag:read("*all")
    flag:close()
    if not request or not request:match("^%s*scan%s*$") then
        return
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    if not local_player or self._unit ~= local_player.player_unit then
        return
    end
    local consumed = Mods.lua.io.open(flag_path, "w")
    if consumed then
        consumed:write("consumed\n")
        consumed:close()
    end
    local slot_name = self._inventory_component and
        self._inventory_component.wielded_slot
    local weapon = slot_name and self._weapons and self._weapons[slot_name]
    local template = weapon and weapon.weapon_template
    local weapon_unit = weapon and weapon.weapon_unit
    local visual_loadout = self._visual_loadout_extension
    controller_observation.weapon_inventory_done = true
    mod:info(
        "DARKTIDEVR_WEAPON inventory slot=%s template=%s weapon_unit_alive=%s first_person_unit_alive=%s",
        tostring(slot_name), tostring(template and template.name),
        tostring(weapon_unit and Unit.alive(weapon_unit) or false),
        tostring(self._first_person_unit and
            Unit.alive(self._first_person_unit) or false)
    )
    presentation.log_unit_pose("weapon_root", weapon_unit, 1)
    presentation.log_unit_pose("first_person_root", self._first_person_unit, 1)
    local candidate_nodes = {
        "j_righthand",
        "j_lefthand",
        "j_right_hand",
        "j_left_hand",
        "j_rightweaponattach",
        "j_leftweaponattach",
        "j_right_hand_ik_handle",
        "j_left_hand_ik_handle",
        "fx_right_hand",
        "fx_left_hand",
        "fx_overheat"
    }
    presentation.scan_named_nodes(
        "first_person", self._first_person_unit, candidate_nodes)
    presentation.scan_named_nodes("weapon", weapon_unit, candidate_nodes)
    if visual_loadout and slot_name then
        local _, _, attachments_by_unit_1p =
            visual_loadout:unit_and_attachments_from_slot(slot_name)
        local attachment_index = 0
        if type(attachments_by_unit_1p) == "table" then
            for _, attachments in pairs(attachments_by_unit_1p) do
                if type(attachments) == "table" then
                    for i = 1, #attachments do
                        attachment_index = attachment_index + 1
                        local attachment = attachments[i]
                        presentation.log_unit_pose(
                            "attachment_1p_" .. tostring(attachment_index) ..
                                "_root",
                            attachment,
                            1)
                        presentation.scan_named_nodes(
                            "attachment_1p_" .. tostring(attachment_index),
                            attachment,
                            candidate_nodes)
                    end
                end
            end
        end
        mod:info(
            "DARKTIDEVR_WEAPON attachment_1p_count=%d",
            attachment_index)
    end
    if template and type(template.fx_sources) == "table" and visual_loadout then
        for source_key, node_name in pairs(template.fx_sources) do
            local unit_1p, node_1p =
                visual_loadout:unit_and_node_from_node_name(
                    slot_name, node_name)
            mod:info(
                "DARKTIDEVR_WEAPON fx_source=%s node_name=%s resolved_1p=%s node=%s",
                tostring(source_key), tostring(node_name),
                tostring(unit_1p and Unit.alive(unit_1p) or false),
                tostring(node_1p)
            )
            if unit_1p and node_1p then
                presentation.log_unit_pose(
                    "fx:" .. tostring(source_key), unit_1p, node_1p)
            end
        end
    end
end

function presentation.vector_distance(left, right)
    local x = Vector3.x(left) - Vector3.x(right)
    local y = Vector3.y(left) - Vector3.y(right)
    local z = Vector3.z(left) - Vector3.z(right)
    return math.sqrt(x * x + y * y + z * z)
end

function presentation.rotate_vector(rotation, value)
    return Quaternion.right(rotation) * Vector3.x(value) +
        Quaternion.forward(rotation) * Vector3.y(value) +
        Quaternion.up(rotation) * Vector3.z(value)
end

function presentation.inverse_quaternion(rotation)
    local x, y, z, w = Quaternion.to_elements(rotation)
    return Quaternion.from_elements(-x, -y, -z, w)
end

function presentation.vector_cross(left, right)
    return Vector3(
        Vector3.y(left) * Vector3.z(right) -
            Vector3.z(left) * Vector3.y(right),
        Vector3.z(left) * Vector3.x(right) -
            Vector3.x(left) * Vector3.z(right),
        Vector3.x(left) * Vector3.y(right) -
            Vector3.y(left) * Vector3.x(right))
end

function presentation.vector_dot(left, right)
    return Vector3.x(left) * Vector3.x(right) +
        Vector3.y(left) * Vector3.y(right) +
        Vector3.z(left) * Vector3.z(right)
end

function presentation.align_vectors_rotation(from, to)
    local from_length = Vector3.length(from)
    local to_length = Vector3.length(to)
    if from_length < 0.000001 or to_length < 0.000001 then
        return nil
    end
    local source = from / from_length
    local destination = to / to_length
    local dot = math.max(-1, math.min(1,
        presentation.vector_dot(source, destination)))
    if dot > 0.999999 then
        return Quaternion.from_elements(0, 0, 0, 1)
    end
    local axis = presentation.vector_cross(source, destination)
    local axis_length = Vector3.length(axis)
    if axis_length < 0.000001 then
        axis = presentation.vector_cross(source, Vector3.up())
        axis_length = Vector3.length(axis)
        if axis_length < 0.000001 then
            axis = presentation.vector_cross(source, Vector3(1, 0, 0))
            axis_length = Vector3.length(axis)
        end
    end
    if axis_length < 0.000001 then
        return nil
    end
    return Quaternion.axis_angle(axis / axis_length, math.acos(dot))
end

-- Extract the signed twist component of the world-space delta from one
-- orientation to another around a fixed axis. Projecting the delta
-- quaternion's vector part onto the axis is the standard swing/twist
-- decomposition and avoids selecting an arbitrary palm basis near a
-- singular pose.
function presentation.signed_twist_angle(from, to, axis)
    local axis_length = Vector3.length(axis)
    if axis_length < 0.000001 then
        return nil
    end
    local normal = axis / axis_length
    local delta = Quaternion.multiply(
        to, presentation.inverse_quaternion(from))
    local x, y, z, w = Quaternion.to_elements(delta)
    local sine = x * Vector3.x(normal) + y * Vector3.y(normal) +
        z * Vector3.z(normal)
    local length = math.sqrt(sine * sine + w * w)
    if length < 0.000001 then
        return nil
    end
    local angle = 2 * math.atan2(sine / length, w / length)
    while angle > math.pi do
        angle = angle - 2 * math.pi
    end
    while angle < -math.pi do
        angle = angle + 2 * math.pi
    end
    return angle
end

function presentation.quaternion_angle_error(left, right)
    local lx, ly, lz, lw = Quaternion.to_elements(left)
    local rx, ry, rz, rw = Quaternion.to_elements(right)
    local dot = math.abs(lx * rx + ly * ry + lz * rz + lw * rw)
    return 2 * math.acos(math.max(-1, math.min(1, dot)))
end

-- Freeze a hub interaction panel in the same body-relative coordinates used
-- by tracked controllers. The clean camera is the game-world pose of the
-- immutable OpenXR recenter; applying its inverse here is the exact inverse of
-- controller_grip_target(), rather than an independent world/XR transform.
function presentation.capture_vendor_anchor(view_name, interactee_unit)
    if not active or not interactee_unit or not Unit.alive(interactee_unit) or
            not controller_observation.body_anchor_qw then
        return false, "stereo_or_pose_unavailable"
    end
    local marker_node = Unit.has_node(interactee_unit,
        "ui_interaction_marker") and
        Unit.node(interactee_unit, "ui_interaction_marker") or 1
    local marker_position = Unit.world_position(interactee_unit, marker_node)
    local anchor_position = Vector3(
        controller_observation.body_anchor_x,
        controller_observation.body_anchor_y,
        controller_observation.body_anchor_z)
    local anchor_rotation = Quaternion.from_elements(
        controller_observation.body_anchor_qx,
        controller_observation.body_anchor_qy,
        controller_observation.body_anchor_qz,
        controller_observation.body_anchor_qw)
    local from_camera = marker_position - anchor_position
    local dx = Vector3.x(from_camera)
    local dy = Vector3.y(from_camera)
    local horizontal_distance = math.sqrt(dx * dx + dy * dy)
    if horizontal_distance < 0.25 or horizontal_distance > 10 then
        return false, "interaction_distance_out_of_range"
    end

    -- Pull the two-metre board slightly toward the player so it occupies the
    -- interaction space in front of the NPC instead of intersecting its mesh.
    local horizontal_direction = Vector3(
        dx / horizontal_distance,
        dy / horizontal_distance,
        0)
    local panel_position = marker_position - horizontal_direction * 0.25
    local panel_world_rotation = Quaternion.look(
        horizontal_direction,
        Vector3.up())
    local inverse_anchor = presentation.inverse_quaternion(anchor_rotation)
    local body_position = presentation.rotate_vector(
        inverse_anchor,
        panel_position - anchor_position)
    local body_rotation = Quaternion.normalize(Quaternion.multiply(
        inverse_anchor,
        panel_world_rotation))
    local anchor = presentation.vendor_anchor
    anchor.x = Vector3.x(body_position)
    anchor.y = Vector3.y(body_position)
    anchor.z = Vector3.z(body_position)
    anchor.qx, anchor.qy, anchor.qz, anchor.qw =
        Quaternion.to_elements(body_rotation)
    anchor.valid = true
    anchor.view_name = view_name
    anchor.revision = anchor.revision + 1
    mod:info(
        "DARKTIDEVR_PRESENTATION world_anchor captured view=%s revision=%d body_pos=%.3f,%.3f,%.3f",
        tostring(view_name),
        anchor.revision,
        anchor.x,
        anchor.y,
        anchor.z
    )
    return true, "captured"
end

function presentation.scene_graph_root(unit, node)
    local current = node
    local parent = Unit.scene_graph_parent(unit, current)
    local depth = 0
    while parent ~= nil and depth < 256 do
        current = parent
        parent = Unit.scene_graph_parent(unit, current)
        depth = depth + 1
    end
    return current, depth
end

function presentation.controller_grip_target()
    -- Disabled controllers are ignored wherever they are tracked, as are enabled
    -- ones for a few seconds after keyboard or mouse use.
    if presentation.controllers_suppressed() or not controller_observation.right_grip_usable or
            not controller_observation.body_anchor_qw then
        return nil, nil
    end
    local anchor_position = Vector3(
        controller_observation.body_anchor_x,
        controller_observation.body_anchor_y,
        controller_observation.body_anchor_z)
    local anchor_rotation = Quaternion.from_elements(
        controller_observation.body_anchor_qx,
        controller_observation.body_anchor_qy,
        controller_observation.body_anchor_qz,
        controller_observation.body_anchor_qw)
    local grip_position = Vector3(
        controller_observation.right_grip_x,
        controller_observation.right_grip_y,
        controller_observation.right_grip_z)
    local grip_rotation = Quaternion.from_elements(
        controller_observation.right_grip_qx,
        controller_observation.right_grip_qy,
        controller_observation.right_grip_qz,
        controller_observation.right_grip_qw)
    local target_position = anchor_position +
        presentation.rotate_vector(anchor_rotation, grip_position)
    local target_rotation = Quaternion.multiply(anchor_rotation, grip_rotation)
    return target_position, target_rotation
end

function presentation.left_controller_grip_target()
    if presentation.controllers_suppressed() or not controller_observation.left_grip_usable or
            not controller_observation.body_anchor_qw then
        return nil, nil
    end
    local anchor_position = Vector3(
        controller_observation.body_anchor_x,
        controller_observation.body_anchor_y,
        controller_observation.body_anchor_z)
    local anchor_rotation = Quaternion.from_elements(
        controller_observation.body_anchor_qx,
        controller_observation.body_anchor_qy,
        controller_observation.body_anchor_qz,
        controller_observation.body_anchor_qw)
    local grip_position = Vector3(
        controller_observation.left_grip_x,
        controller_observation.left_grip_y,
        controller_observation.left_grip_z)
    local grip_rotation = Quaternion.from_elements(
        controller_observation.left_grip_qx,
        controller_observation.left_grip_qy,
        controller_observation.left_grip_qz,
        controller_observation.left_grip_qw)
    return anchor_position +
            presentation.rotate_vector(anchor_rotation, grip_position),
        Quaternion.multiply(anchor_rotation, grip_rotation)
end

-- Retarget physical tracking into the selected Darktide body. Human world
-- scale and runtime IPD remain exactly headset-native; standing calibration
-- changes only the local third-person presentation below. Ogryn are the one
-- intentional world-scale exception: their authored body is substantially
-- larger, so tracked translation and IPD scale together to preserve that
-- fantasy without introducing an eye/world-scale disagreement.
function presentation.calibrated_character_scale(local_player)
    if not local_player then
        return 1, "player_unavailable"
    end
    local archetype = local_player:archetype_name()
    local profile_ok, profile = pcall(function()
        return local_player:profile()
    end)
    profile = profile_ok and profile or nil
    -- Game 1.13 keeps the height on the profile itself; 1.12 kept it under
    -- `personal`. Read only there, this was nil on 1.13 and the scale fell
    -- back to the middle of the breed's range.
    local profile_scale = profile and (tonumber(profile.character_height) or
        (profile.personal and tonumber(profile.personal.character_height)))
    local is_ogryn = archetype == "ogryn"
    local breeds = require("scripts/settings/breed/breeds")
    local breed_name = profile and profile.archetype and
        profile.archetype.breed
    local breed = breed_name and breeds[breed_name]
    local range = breed and breed.size_variation_range
    local range_min = range and tonumber(range[1]) or
        (is_ogryn and 0.9 or 0.95)
    local range_max = range and tonumber(range[2]) or
        (is_ogryn and 0.925 or 1.08)
    profile_scale = math.max(range_min, math.min(
        range_max, profile_scale or (range_min + range_max) * 0.5))
    local authored_eye_height = breed and breed.heights and
        tonumber(breed.heights.default) or
        (is_ogryn and 2.2 / 0.9125 or 1.65 / 1.015)
    local target_eye_height = authored_eye_height * profile_scale
    local result = mod.darktidevr_calibration and
        mod.darktidevr_calibration.result or mod:get("vr_calibration_v1")
    local source_eye_height = result and not result.seated and
        tonumber(result.floor_eye_height)
    if not is_ogryn then
        local desired_visual_scale = source_eye_height and
            source_eye_height / authored_eye_height or profile_scale
        desired_visual_scale = math.max(0.7, math.min(
            1.4, desired_visual_scale))
        return 1, "human_native_world_scale",
            authored_eye_height * desired_visual_scale, source_eye_height
    end
    if source_eye_height and source_eye_height >= 0.2 then
        return math.max(0.7, math.min(
            1.8, target_eye_height / source_eye_height)),
            "standing_calibration", target_eye_height, source_eye_height
    end
    local percentile = range_max > range_min and
        (profile_scale - range_min) / (range_max - range_min) or 0.5
    local human_scale = 0.95 + percentile * (1.08 - 0.95)
    local human_eye_height = 1.65 / 1.015 * human_scale
    return target_eye_height / human_eye_height,
        "profile_relative_fallback", target_eye_height, nil
end

-- Human calibration overrides only the local spawned presentation. The game
-- height helper accepts arbitrary scales; the narrow limits live in character
-- creation/backend data. The calibration module uses that official in-range
-- backend path first. Applying only the residual wider scale here leaves the
-- fixed locomotion mover, broadphase,
-- first-person height, and network profile untouched. This is deliberately a
-- client-only visual stretch/compression for unusually short or tall players.
-- Ogryn retain their selected native profile scale; their larger tracked-space
-- ratio is handled above.
function presentation.apply_calibrated_body_height(world, unit, local_player)
    if not local_player or local_player:archetype_name() == "ogryn" then
        return true, "native_ogryn"
    end
    local result = mod.darktidevr_calibration and
        mod.darktidevr_calibration.result or mod:get("vr_calibration_v1")
    local source_eye_height = result and not result.seated and
        tonumber(result.floor_eye_height)
    if not source_eye_height or source_eye_height < 0.2 then
        return true, "standing_height_unavailable"
    end
    local profile_ok, profile = pcall(function()
        return local_player:profile()
    end)
    local breeds = require("scripts/settings/breed/breeds")
    local breed_name = profile_ok and profile and profile.archetype and
        profile.archetype.breed
    local breed = breed_name and breeds[breed_name]
    local authored_eye_height = breed and breed.heights and
        tonumber(breed.heights.default)
    if not authored_eye_height or authored_eye_height <= 0 then
        return true, "breed_height_unavailable"
    end
    local desired_scale = math.max(0.7, math.min(
        1.4, source_eye_height / authored_eye_height))
    local state = controller_observation.body_calibrated_height
    if state and state.unit == unit and
            math.abs(state.scale - desired_scale) < 0.0001 then
        return true, "calibrated"
    end
    Unit.set_local_scale(unit, 1, Vector3(
        desired_scale, desired_scale, desired_scale))
    World.update_unit_and_children(world, unit)
    controller_observation.body_calibrated_height = {
        unit = unit,
        scale = desired_scale
    }
    controller_observation.body_calibration_retarget = nil
    controller_observation.body_eye_anchor_unit = nil
    controller_observation.body_camera_eye_offset_unit = nil
    -- And the wait it started. A height calibration is the likeliest cause of
    -- a SECOND capture, and a second capture that inherits the first one's
    -- timer is overdue on its first frame: it waives MAX_EYE_CAPTURE_PITCH and
    -- bakes whatever pitch the player is holding into the height.
    controller_observation.body_camera_eye_offset_since = nil
    mod:info(
        "DARKTIDEVR_CALIBRATION body_height breed=%s authored_eye_m=%.4f floor_eye_m=%.4f visual_scale=%.4f client_only=true collision_scale=1 clamp=0.70,1.40",
        tostring(breed_name), authored_eye_height, source_eye_height,
        desired_scale)
    return true, "calibrated"
end

-- Visual body height/world scale is resolved first. The residual below changes
-- only authored upper-limb bone lengths needed to fit the live scaled skeleton;
-- it cannot change IPD, head translation, collision, or controller targets.
function presentation.apply_calibrated_arm_length(world, unit)
    local result = mod.darktidevr_calibration and
        mod.darktidevr_calibration.result or mod:get("vr_calibration_v1")
    if not result or not result.t_pose or not unit or
            not Unit.alive(unit) then
        return true, 1, "calibration_unavailable"
    end
    local cache = controller_observation.body_calibration_retarget
    if cache and cache.unit == unit and cache.result == result then
        local changed = false
        for _, record in pairs(cache.nodes) do
            local desired = record.authored:unbox() * cache.residual
            if presentation.vector_distance(
                    Unit.local_position(unit, record.node), desired) >
                    0.00001 then
                Unit.set_local_position(unit, record.node, desired)
                changed = true
            end
        end
        if changed then
            World.update_unit_and_children(world, unit)
        end
        return true, cache.residual, cache.reason
    end
    if cache and cache.unit == unit and cache.result ~= result then
        -- A repeat calibration must start from the authored limb lengths, not
        -- compound a new residual on top of the previous calibration.
        for _, record in pairs(cache.nodes) do
            Unit.set_local_position(unit, record.node,
                record.authored:unbox())
        end
        World.update_unit_and_children(world, unit)
    end
    local source_reach = 0
    local source_count = 0
    for _, sample_side in ipairs({ "left", "right" }) do
        local hand = result.t_pose[sample_side]
        if hand then
            local head = result.t_pose.head
            local dx = hand[1] - head[1]
            local dy = hand[2] - head[2]
            local dz = hand[3] - head[3]
            source_reach = source_reach + math.sqrt(
                dx * dx + dy * dy + dz * dz)
            source_count = source_count + 1
        end
    end
    if source_count == 0 then
        return true, 1, "source_reach_unavailable"
    end
    source_reach = source_reach / source_count
    local names = {
        left = { "j_leftarm", "j_leftforearm", "j_lefthand" },
        right = { "j_rightarm", "j_rightforearm", "j_righthand" }
    }
    for _, record in pairs(names) do
        for i = 1, #record do
            if not Unit.has_node(unit, record[i]) then
                return false, 1, "target_nodes_unavailable"
            end
        end
    end
    local function position(name)
        return Unit.world_position(unit, Unit.node(unit, name))
    end
    local left_arm = presentation.vector_distance(
        position(names.left[1]), position(names.left[2])) +
        presentation.vector_distance(
            position(names.left[2]), position(names.left[3]))
    local right_arm = presentation.vector_distance(
        position(names.right[1]), position(names.right[2])) +
        presentation.vector_distance(
            position(names.right[2]), position(names.right[3]))
    local shoulder_width = presentation.vector_distance(
        position(names.left[1]), position(names.right[1]))
    local current_arm_length = (left_arm + right_arm) * 0.5
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    local height_scale = presentation.calibrated_character_scale(local_player)
    local desired_arm_length = math.max(0.2,
        source_reach * height_scale - shoulder_width * 0.5)
    local forward_required = 0
    local forward_count = 0
    -- Calibration schema 4 no longer captures an arms-forward pose; only
    -- older schema 3 results carry forward_pose, so this stays optional.
    if result.forward_pose and result.forward_pose.head and
            controller_observation.body_anchor_qw then
        local model_eye = presentation.body_camera_anchor(unit)
        local anchor_rotation = Quaternion.from_elements(
            controller_observation.body_anchor_qx,
            controller_observation.body_anchor_qy,
            controller_observation.body_anchor_qz,
            controller_observation.body_anchor_qw)
        if model_eye then
            for _, sample_side in ipairs({ "left", "right" }) do
                local hand = result.forward_pose[sample_side]
                if hand then
                    local head = result.forward_pose.head
                    local source_delta = Vector3(
                        hand[1] - head[1], hand[2] - head[2],
                        hand[3] - head[3]) * height_scale
                    local target = model_eye + presentation.rotate_vector(
                        anchor_rotation, source_delta)
                    forward_required = forward_required +
                        presentation.vector_distance(
                            position(names[sample_side][1]), target)
                    forward_count = forward_count + 1
                end
            end
        end
    end
    if forward_count > 0 then
        forward_required = forward_required / forward_count
    end
    -- T-pose span owns skeletal limb length. The forward sample measures the
    -- extra scapular/shoulder reach needed at runtime; using it to elongate
    -- both arm bones produced visibly stretched 1.25x limbs. Retain a narrow
    -- safety range around the authored proportions and let the live shoulder
    -- solver absorb forward reach before the two-bone arm solve.
    local residual = math.max(0.90, math.min(1.10,
        desired_arm_length / current_arm_length))
    local scaled_nodes = {}
    for _, record in pairs(names) do
        for i = 2, 3 do
            local node = Unit.node(unit, record[i])
            scaled_nodes[#scaled_nodes + 1] = {
                node = node,
                authored = Vector3Box(Unit.local_position(unit, node))
            }
        end
    end
    cache = {
        unit = unit,
        result = result,
        residual = residual,
        reason = "calibrated",
        source_reach = source_reach,
        current_arm_length = current_arm_length,
        desired_arm_length = desired_arm_length,
        height_scale = height_scale,
        nodes = scaled_nodes
    }
    controller_observation.body_calibration_retarget = cache
    mod:info(
        "DARKTIDEVR_CALIBRATION retarget source_reach_m=%.4f forward_required_m=%.4f current_arm_m=%.4f desired_arm_m=%.4f shoulder_width_m=%.4f height_scale=%.4f arm_bone_scale=%.4f",
        source_reach, forward_required,
        current_arm_length, desired_arm_length,
        shoulder_width, height_scale, residual)
    for _, record in pairs(cache.nodes) do
        Unit.set_local_position(unit, record.node,
            record.authored:unbox() * residual)
    end
    World.update_unit_and_children(world, unit)
    return true, residual, cache.reason
end

-- Controller body poses are already relative to the immutable OpenXR head
-- recenter origin. Map them through the matching clean game-camera anchor.
-- Adding that complete relative pose to the *live* avatar head double-counts
-- the tracked head displacement and can put the requested wrist beyond the
-- arm's reach, where the two-bone solver necessarily clamps it.
function presentation.body_ik_controller_grip_target(unit, side)
    if not unit or not Unit.alive(unit) or
            not controller_observation.body_anchor_qw or
            not Unit.has_node(unit, "j_head") then
        return nil
    end
    local is_left = side == "left"
    if is_left and not controller_observation.left_grip_usable then
        return nil
    end
    if not is_left and not controller_observation.right_grip_usable then
        return nil
    end
    local grip_position = is_left and Vector3(
        controller_observation.left_grip_x,
        controller_observation.left_grip_y,
        controller_observation.left_grip_z) or Vector3(
        controller_observation.right_grip_x,
        controller_observation.right_grip_y,
        controller_observation.right_grip_z)
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    local height_scale = presentation.calibrated_character_scale(local_player)
    -- Grip and camera poses share the bridge's sliding recenter space. Do not
    -- add cumulative body_follow in the hub: its gameplay root is intentionally
    -- stationary, and adding the excess to only presentation breaks their
    -- relative alignment at the moving envelope boundary.
    local grip_rotation = is_left and Quaternion.from_elements(
        controller_observation.left_grip_qx,
        controller_observation.left_grip_qy,
        controller_observation.left_grip_qz,
        controller_observation.left_grip_qw) or Quaternion.from_elements(
        controller_observation.right_grip_qx,
        controller_observation.right_grip_qy,
        controller_observation.right_grip_qz,
        controller_observation.right_grip_qw)
    local anchor_rotation = Quaternion.from_elements(
        controller_observation.body_anchor_qx,
        controller_observation.body_anchor_qy,
        controller_observation.body_anchor_qz,
        controller_observation.body_anchor_qw)
    local anchor_position = Vector3(
        controller_observation.body_anchor_x,
        controller_observation.body_anchor_y,
        controller_observation.body_anchor_z)
    local source_target = anchor_position +
        presentation.rotate_vector(anchor_rotation, grip_position)
    local target_position = anchor_position +
        (source_target - anchor_position) * height_scale
    return target_position, Quaternion.normalize(Quaternion.multiply(
        anchor_rotation, grip_rotation))
end

-- In keyboard and mouse play the mouse owns the aim while it or the keyboard is
-- in use, so a controller lying on the desk that drifts in and out of tracking
-- cannot take over where the weapon points. After a few idle seconds a tracked
-- controller aims again.
function presentation.controller_aim_target()
    if presentation.controllers_suppressed() or not controller_observation.right_aim_usable or
            not controller_observation.body_anchor_qw or
            not controller_observation.right_aim_qw then
        return nil, nil
    end
    local anchor_position = Vector3(
        controller_observation.body_anchor_x,
        controller_observation.body_anchor_y,
        controller_observation.body_anchor_z)
    local anchor_rotation = Quaternion.from_elements(
        controller_observation.body_anchor_qx,
        controller_observation.body_anchor_qy,
        controller_observation.body_anchor_qz,
        controller_observation.body_anchor_qw)
    local aim_position = Vector3(
        controller_observation.right_aim_x,
        controller_observation.right_aim_y,
        controller_observation.right_aim_z)
    local aim_rotation = Quaternion.from_elements(
        controller_observation.right_aim_qx,
        controller_observation.right_aim_qy,
        controller_observation.right_aim_qz,
        controller_observation.right_aim_qw)
    return anchor_position +
            presentation.rotate_vector(anchor_rotation, aim_position),
        Quaternion.multiply(anchor_rotation, aim_rotation)
end

function presentation.left_controller_aim_target()
    if presentation.controllers_suppressed() or not controller_observation.left_aim_usable or
            not controller_observation.body_anchor_qw or
            not controller_observation.left_aim_qw then
        return nil, nil
    end
    local anchor_position = Vector3(
        controller_observation.body_anchor_x,
        controller_observation.body_anchor_y,
        controller_observation.body_anchor_z)
    local anchor_rotation = Quaternion.from_elements(
        controller_observation.body_anchor_qx,
        controller_observation.body_anchor_qy,
        controller_observation.body_anchor_qz,
        controller_observation.body_anchor_qw)
    local aim_position = Vector3(
        controller_observation.left_aim_x,
        controller_observation.left_aim_y,
        controller_observation.left_aim_z)
    local aim_rotation = Quaternion.from_elements(
        controller_observation.left_aim_qx,
        controller_observation.left_aim_qy,
        controller_observation.left_aim_qz,
        controller_observation.left_aim_qw)
    return anchor_position +
            presentation.rotate_vector(anchor_rotation, aim_position),
        Quaternion.multiply(anchor_rotation, aim_rotation)
end

function presentation.weapon_aim_target(role)
    local side = presentation.weapon_hand_roles.physical(role)
    local position, rotation
    if side == "left" then position, rotation = presentation.left_controller_aim_target()
    elseif side == "right" then position, rotation = presentation.controller_aim_target()
    else return end
    -- The dominant hand aims every weapon and item with the same pitch, on either side.
    if role == "dominant" and presentation.gun_aim then
        local player = Managers.player and Managers.player:local_player(1)
        rotation = presentation.gun_aim.aim(player and player.player_unit, rotation)
    end
    return position, rotation
end

-- The player's standing eye height above the floor, in physical metres, from
-- the shared head pose; nil when the viewer has not measured it.
function presentation.physical_eye_height()
    local value = head_pose_values and tonumber(head_pose_values[24])
    if value and value >= 0.8 and value <= 2.4 then return value end
end

-- The latest shared head pose as published by the viewer, unconverted:
-- OpenXR local-space position (x, y, z), orientation (qx, qy, qz, qw) and the
-- floor eye height. For the pose trace recorder; nil before the first read.
function presentation.head_pose_raw(out)
    if not head_pose_values then return nil end
    for i = 0, 6 do out[i + 1] = tonumber(head_pose_values[i]) end
    out[8] = tonumber(head_pose_values[24])
    return out
end

function presentation.weapon_grip_target(role)
    local side = presentation.weapon_hand_roles.physical(role)
    if side == "left" then return presentation.left_controller_grip_target() end
    if side == "right" then return presentation.controller_grip_target() end
end

-- A world point moved so that, placed by the field of view the viewer
-- submits, it lands where it is seen in the magnified image the game renders.
-- The magnification is about the rendered head's forward, so the point is
-- taken into that frame, moved across the view only, and put back. Returns
-- the point unchanged when there is no zoom, no head rotation or no eye.
-- THE RETICLE STAYS ON THE SURFACE IT MARKS.
--
-- This correction is off. It is kept, tested and reachable through
-- `darktidevr_zoom_aim_correction.flag`, because the reasoning behind it is
-- not wrong in itself -- but what it does to the reticle is.
--
-- It takes the raycast's hit point and turns it outward about the eye by the
-- magnification, so that it lands where the magnified IMAGE shows the
-- surface. That is coherent for a mark floating in the view. It is wrong for
-- a mark that has to sit ON geometry, because turning the point about the eye
-- takes it off the surface it was measured on. Against a floor seen at a
-- shallow angle a few centimetres perpendicular to the view is a long way
-- along the floor, and if the turn is toward the surface the point goes
-- UNDER it. The displacement is proportional to how far off-axis the target
-- is, so it grows with range.
--
-- Which is exactly what was reported, in the user's own terms: "the reticule
-- is rendering further into objects than it should be", "definitely
-- proportional rather than fixed", and "this issue didn't exist before we
-- added the zoom" -- before the zoom this function returned the point
-- unchanged on its magnification guard, the reticle sat on the hit point and
-- it was right. Turning the zoom on turned this on with it.
--
-- Six candidates were ruled out inside the reticle transport before this,
-- and the transport was never at fault: `head_distance_m=13.0104` against
-- the game's `anchor_distance_m=13.0112` says the viewer draws the quad
-- exactly where the game asks. The game was asking for the wrong point.
--
-- The magnification does leave a real residue -- the world renders through a
-- frustum 4.3% narrower than the one submitted, so it appears that much
-- nearer than the quad. That is the size of thing nobody reported for the
-- months the zoom did not exist, and it is not worth moving the reticle off
-- the geometry to chase.
function presentation.zoom_corrected_aim_point(world_point)
    -- The switch is read here rather than in a helper: the tooling tests load
    -- a marker-bounded SLICE of this chunk that begins at this function, so a
    -- helper above it does not exist when they run (19 September).
    if presentation.zoom_aim_correction_flag == nil then
        local io_api = Mods and Mods.lua and Mods.lua.io
        local file = io_api and io_api.open(
            "./../mods/darktidevr/darktidevr_zoom_aim_correction.flag", "r")
        if file then file:close() end
        -- Absent means OFF: the flag arms the correction for a comparison
        -- against a viewer that does not carry the zoom.
        presentation.zoom_aim_correction_flag = file ~= nil
    end
    -- OFF by default, and the reason is that its premise stopped being true.
    -- This correction exists because "the viewer submits the runtime's own
    -- field of view unchanged -- that is what makes it a zoom". It does not
    -- any more: the magnification reaches the viewer and it submits the
    -- zoomed frustum, so the reticle is already composited through the same
    -- projection the world was rendered in and needs no moving. Left on it
    -- would push the point outward by about (m-1) of its off-axis angle and
    -- shrink its range on top -- roughly 1.5 degrees of reticle error at
    -- m=1.15 and ten degrees off centre, in the very feature being tested
    -- (review, 19 September).
    --
    -- The flag arms it again for an A/B rather than deleting it, because the
    -- arithmetic is still right for a viewer that does not carry the zoom.
    if presentation.zoom_aim_correction_flag ~= true then return world_point end
    local magnification = tonumber(presentation.ads_zoom_applied)
    if not world_point or not magnification or magnification <= 1.0001 or
            not controller_observation.head_aim_qw then
        return world_point
    end
    local eye = presentation.eye_pose(nil)
    if not eye then return world_point end
    local head = Quaternion.from_elements(controller_observation.head_aim_qx,
        controller_observation.head_aim_qy, controller_observation.head_aim_qz,
        controller_observation.head_aim_qw)
    local v = Quaternion.rotate(Quaternion.inverse(head), world_point - eye)
    -- Darktide axes: +y is forward, so +x and +z are the two across the view
    -- and +y is the depth passed in third.
    --
    -- All THREE returns are used. The depth comes back changed now, because
    -- the correction turns the ray and then puts it back to its original
    -- length -- and taking two of the three and reusing the original depth
    -- silently undoes that, which is exactly what this line did until the
    -- reticle's own test caught it.
    local across_x, across_z, depth = presentation.projection_math.magnified_target(
        Vector3.x(v), Vector3.z(v), Vector3.y(v), magnification)
    -- The angular correction above puts the point where it is SEEN. It
    -- preserves the range while doing it, which leaves the point at the depth
    -- the unmagnified world would put it -- and the world in the sights is
    -- not unmagnified. The range has to come in by the same factor or the
    -- reticle verges behind the surface it marks: see Projection.zoomed_range
    -- for why, and why this is the half of the fault that six measurements
    -- inside this path could not have found.
    -- The range from the three components rather than through Vector3.length:
    -- this function is sliced into the tooling tests, whose Vector3 is a plain
    -- table with no helpers on it, and reaching for one there is a nil call
    -- rather than a wrong answer (online_reticle, 19 September).
    local range = math.sqrt(across_x * across_x + depth * depth + across_z * across_z)
    local wanted = presentation.projection_math.zoomed_range(range, magnification)
    local shrink = (range > 1e-6 and wanted ~= range) and (wanted / range) or 1
    return eye + Quaternion.rotate(head,
        Vector3(across_x * shrink, depth * shrink, across_z * shrink))
end

function presentation.publish_gameplay_aim_state(active, hit, distance, world_point)
    if not ui_native_capture or
            not ui_native_capture.dtvr_set_gameplay_aim_state then
        return false
    end
    -- Keyboard and mouse aim has no hand ray for the viewer to extend, so it
    -- always sends the world-depth target point, in every aim mode.
    local keyboard_mouse = presentation.keyboard_mouse_enabled()
    if active and world_point and (keyboard_mouse or presentation.online_rules.enabled()) then
        local publish = presentation.native_gameplay_aim_target
        local sequence = controller_observation.body_anchor_pose_sequence or 0
        if not publish or sequence <= 0 then
            -- An old capture DLL cannot represent the stock-origin target.
            -- Clear the overlay instead of silently drawing a different ray.
            ui_native_capture.dtvr_set_gameplay_aim_state(0, 0, 0)
            return false
        end
        local anchor = Vector3(controller_observation.body_anchor_x,
            controller_observation.body_anchor_y, controller_observation.body_anchor_z)
        local rotation = Quaternion.from_elements(controller_observation.body_anchor_qx,
            controller_observation.body_anchor_qy, controller_observation.body_anchor_qz,
            controller_observation.body_anchor_qw)
        -- Full mouselook tilts the rendered room about the published anchor;
        -- express the point in that tilted frame so it lands where it is seen.
        local view_pitch = keyboard_mouse and presentation.keyboard_mouse_view_pitch() or 0
        if view_pitch ~= 0 then
            rotation = Quaternion.multiply(rotation, Quaternion.axis_angle(Vector3.right(), view_pitch))
        end
        -- The aim zoom renders a narrower cone across the same angle, so
        -- everything off the view's centre sits further out in the image than
        -- the field of view the viewer submits says it does. The reticle is
        -- placed by that submitted field of view, so the point has to move
        -- with it -- and about the EYE's forward, which is the axis the zoom
        -- is about. Doing it in the published frame instead is wrong: that
        -- frame is the recentre pose, and every degree of head turn since the
        -- last recentre sits between the two, which displaces a target that is
        -- dead centre and needs no correction at all (review, 18 September).
        world_point = presentation.zoom_corrected_aim_point(world_point)
        local player = Managers.player:local_player(1)
        local scale = presentation.calibrated_character_scale(player)
        local point = Quaternion.rotate(Quaternion.inverse(rotation),world_point-anchor)/scale
        -- Why the reticle sits further away than the thing it marks.
        --
        -- The offset and the distance are both divided by the character's
        -- visual scale, and the viewer puts them back with a RIGID transform
        -- (resolve_gameplay_aim_target -> math::transform_point) which has no
        -- scale in it. If that division is not matched somewhere else in the
        -- transport, the reticle lands 1/scale further along the ray than the
        -- hit -- at 0.9718 that is 2.9%, which aiming down at the ground a few
        -- metres away puts under the surface.
        --
        -- Logged rather than changed: the zoom correction was the obvious
        -- suspect and turned out to be far too small at percent=3 to matter,
        -- and this is the next candidate rather than a conclusion. On entry
        -- into the sights and sparsely after.
        if presentation.ads_active == true and
                (presentation.reticle_scale_logged or 0) < 20 and
                (presentation.reticle_scale_sequence or 0) + 120 <= (sequence or 0) then
            presentation.reticle_scale_logged = (presentation.reticle_scale_logged or 0) + 1
            presentation.reticle_scale_sequence = sequence or 0
            -- THE RATIO. The error is proportional to the distance aimed,
            -- not a fixed offset (user, 19 September) -- so it is a FACTOR,
            -- and a factor has a number that can be read off rather than
            -- guessed at. Six candidates have been ruled out by measurement
            -- and none of them were multiplicative; this line and the
            -- viewer's `head_distance_m` are the two ends of the one
            -- comparison that names it.
            --
            -- `anchor_distance_m` is the distance from the HEAD to the target
            -- -- which is what the reticle's depth should be -- as against
            -- `raw_distance_m`, which is measured from the weapon along the
            -- aim ray and is a different origin entirely. The viewer places
            -- the reticle from the published OFFSET (resolve_gameplay_aim_target
            -- is a rigid transform of target_point and never reads
            -- distance_metres), so anchor_distance_m is the depth the
            -- transport intends. Divide the viewer's by this one and the
            -- quotient is the fault.
            local anchor_distance = Vector3.length(world_point - anchor)
            mod:info("DARKTIDEVR_AIM reticle_scale raw_distance_m=%.4f published_distance_m=%.4f " ..
                "anchor_distance_m=%.4f point_m=%.4f scale=%.4f zoom=%.4f offset_m=%.4f",
                distance, distance / scale, anchor_distance, Vector3.length(point), scale,
                tonumber(presentation.ads_zoom_applied) or 1,
                distance / scale - distance)
        end
        local result = publish(hit and 1 or 0, math.max(.05,math.min(200,distance/scale)),
            Vector3.x(point), Vector3.z(point), -Vector3.y(point), sequence,
            controller_observation.body_anchor_pose_generation,
            controller_observation.body_anchor_recenter_generation)
        if tonumber(result) ~= 0 then
            ui_native_capture.dtvr_set_gameplay_aim_state(0, 0, 0)
            return false
        end
        return true
    end
    local result = ui_native_capture.dtvr_set_gameplay_aim_state(
        active and 1 or 0,
        hit and 1 or 0,
        active and distance or 0)
    return tonumber(result) == 0
end

function presentation.body_ik_calibrated_wrist_target(
        side, target_position, target_rotation)
    -- The anatomical wrist is a rigid offset from the controller grip on both
    -- sides. Preserve each neutral-pose correction, but rotate the complete
    -- vector in grip space. A body/world residual made the unarmed right glove
    -- slide across the palm when the controller rolled or pointed sideways.
    local out_sign = side == "left" and -1 or 1
    return target_position + Quaternion.right(target_rotation) * (0.03 * out_sign) -
        Quaternion.forward(target_rotation) * 0.04 +
        Quaternion.up(target_rotation) * 0.04
end

function presentation.update_body_ik_trace_gate(fixed_frame)
    if fixed_frame <
            controller_observation.body_ik_trace_last_check_frame + 60 then
        return
    end
    controller_observation.body_ik_trace_last_check_frame = fixed_frame
    local path =
        "./../mods/darktidevr/darktidevr_body_ik_trace.flag"
    local flag = Mods.lua.io.open(path, "r")
    local enabled = false
    if flag then
        enabled = flag:read("*all"):match("^%s*enabled%s*$") ~= nil
        flag:close()
    end
    if enabled ~= controller_observation.body_ik_trace_enabled then
        controller_observation.body_ik_trace_enabled = enabled
        controller_observation.body_capture_trace_sample = 0
        mod:info("DARKTIDEVR_IK trace=%s source=test_flag",
            enabled and "enabled" or "disabled")
    end
end

function presentation.trace_body_arm(unit, side, target_position, emit_log)
    local arm_name = side == "left" and "j_leftarm" or "j_rightarm"
    local forearm_name = side == "left" and
        "j_leftforearm" or "j_rightforearm"
    local hand_name = side == "left" and "j_lefthand" or "j_righthand"
    if not Unit.has_node(unit, arm_name) or
            not Unit.has_node(unit, forearm_name) or
            not Unit.has_node(unit, hand_name) then
        return false, "nodes_missing"
    end
    local shoulder = Unit.world_position(unit, Unit.node(unit, arm_name))
    local elbow = Unit.world_position(unit, Unit.node(unit, forearm_name))
    local wrist = Unit.world_position(unit, Unit.node(unit, hand_name))
    local upper_length = presentation.vector_distance(shoulder, elbow)
    local lower_length = presentation.vector_distance(elbow, wrist)
    local reach = wrist - shoulder
    local bend = elbow - shoulder
    local input = controller_observation.ik_input
    local output = controller_observation.ik_output
    local flags = controller_observation.ik_flags
    input[0], input[1], input[2] =
        Vector3.x(shoulder), Vector3.y(shoulder), Vector3.z(shoulder)
    input[3], input[4], input[5] = Vector3.x(target_position),
        Vector3.y(target_position), Vector3.z(target_position)
    input[6], input[7], input[8] =
        Vector3.x(elbow), Vector3.y(elbow), Vector3.z(elbow)
    input[9], input[10], input[11] =
        Vector3.x(reach), Vector3.y(reach), Vector3.z(reach)
    input[12], input[13], input[14] =
        Vector3.x(bend), Vector3.y(bend), Vector3.z(bend)
    input[15], input[16] = upper_length, lower_length
    local result = ui_native_capture.dtvr_solve_two_bone_ik(
        input, 17, output, 14, flags)
    if result ~= 0 then
        return false, "native_" .. tostring(result)
    end
    local solved_elbow = Vector3(output[0], output[1], output[2])
    local solved_wrist = Vector3(output[3], output[4], output[5])
    if emit_log ~= false then
        mod:info(
            "DARKTIDEVR_IK solve side=%s sequence=%d upper_m=%.4f lower_m=%.4f requested_m=%.4f solved_m=%.4f flags=%d elbow_delta_m=%.4f wrist_target_error_m=%.4f solved_elbow=%.4f,%.4f,%.4f solved_wrist=%.4f,%.4f,%.4f",
            side, controller_observation.last_sequence, upper_length,
            lower_length, tonumber(output[12]), tonumber(output[13]),
            tonumber(flags[0]),
            presentation.vector_distance(elbow, solved_elbow),
            presentation.vector_distance(target_position, solved_wrist),
            Vector3.x(solved_elbow), Vector3.y(solved_elbow),
            Vector3.z(solved_elbow), Vector3.x(solved_wrist),
            Vector3.y(solved_wrist), Vector3.z(solved_wrist))
    end
    return true, "solved", solved_elbow, solved_wrist
end

function presentation.update_body_ik_presentation_gate(fixed_frame)
    if fixed_frame <
            controller_observation.body_ik_presentation_last_check_frame + 60 then
        return
    end
    controller_observation.body_ik_presentation_last_check_frame = fixed_frame
    local path =
        "./../mods/darktidevr/darktidevr_body_ik_presentation.flag"
    local flag = Mods.lua.io.open(path, "r")
    -- Play default when the flag is absent; a present file decides.
    local enabled = true
    if flag then
        enabled = flag:read("*all"):match("^%s*enabled%s*$") ~= nil
        flag:close()
    end
    if not enabled then
        controller_observation.body_ik_presentation_faulted = false
    end
    -- The optional third-person hub body keeps the stock animation; the
    -- tracked-hand IK would pose its arms against it.
    enabled = enabled and
        not controller_observation.body_ik_presentation_faulted and
        not presentation.hub_third_person_active() and
        not presentation.cinematic_stereo_active()
    if enabled ~= controller_observation.body_ik_presentation_enabled then
        controller_observation.body_ik_presentation_enabled = enabled
        controller_observation.body_ik_presentation_block_reason = nil
        controller_observation.body_ik_hand_offsets = {}
        controller_observation.body_ik_hand_anatomy = {}
        controller_observation.body_ik_hand_proxy_pose = {}
        controller_observation.body_ik_hand_proxy_held = {}
        controller_observation.body_ik_shoulder_reach = {}
        controller_observation.body_ik_twist_state = {}
        controller_observation.body_ik_crouch_offset = 0
        controller_observation.body_ik_crouch_last_t = nil
        controller_observation.body_ik_crouch_max_foot_error = 0
        controller_observation.body_ik_crouch_result = "inactive"
        controller_observation.body_ik_neck_unit = nil
        controller_observation.body_ik_neck_generation = nil
        controller_observation.body_ik_neck_baseline_raw = nil
        controller_observation.body_ik_neck_baseline_arc = nil
        controller_observation.body_ik_neck_anchor_unit = nil
        controller_observation.body_ik_neck_anchor_generation = nil
        controller_observation.body_ik_neck_anchor_local = nil
        mod:info("DARKTIDEVR_IK presentation=%s source=test_flag",
            enabled and "enabled" or "disabled")
    end
end

function presentation.apply_body_arm_ik(
        world, unit, side, target_position, target_rotation)
    target_position = presentation.body_ik_calibrated_wrist_target(
        side, target_position, target_rotation)
    local solved, reason, solved_elbow, solved_wrist =
        presentation.trace_body_arm(unit, side, target_position, false)
    if not solved then
        return false, reason
    end
    local arm_name = side == "left" and "j_leftarm" or "j_rightarm"
    local forearm_name = side == "left" and
        "j_leftforearm" or "j_rightforearm"
    local hand_name = side == "left" and "j_lefthand" or "j_righthand"
    local arm_node = Unit.node(unit, arm_name)
    local forearm_node = Unit.node(unit, forearm_name)
    local hand_node = Unit.node(unit, hand_name)
    local arm_parent = Unit.scene_graph_parent(unit, arm_node)
    local forearm_parent = Unit.scene_graph_parent(unit, forearm_node)
    local hand_parent = Unit.scene_graph_parent(unit, hand_node)
    if arm_parent == nil then
        return false, "arm_parent_missing"
    end
    -- The local-rotation solve below is exact only for this authored chain.
    -- Fail closed on a different breed/rig instead of rotating an unrelated
    -- branch or dragging its linked equipment through a bogus transform.
    if forearm_parent ~= arm_node then
        return false, "forearm_parent_mismatch"
    end
    if hand_parent ~= forearm_node then
        return false, "hand_parent_mismatch"
    end

    local shoulder = Unit.world_position(unit, arm_node)
    local elbow = Unit.world_position(unit, forearm_node)
    local wrist = Unit.world_position(unit, hand_node)
    local arm_world = Unit.world_rotation(unit, arm_node)
    local forearm_world = Unit.world_rotation(unit, forearm_node)
    local hand_world = Unit.world_rotation(unit, hand_node)
    local twist_names = side == "left" and {
        "j_leftforearmroll1", "j_leftforearmroll2"
    } or {
        "j_rightforearmroll1", "j_rightforearmroll2"
    }
    local twist_records = {}
    for i = 1, #twist_names do
        local twist_name = twist_names[i]
        if Unit.has_node(unit, twist_name) then
            local twist_node = Unit.node(unit, twist_name)
            twist_records[twist_name] = {
                node = twist_node,
                parent = Unit.scene_graph_parent(unit, twist_node),
                local_rotation = Unit.local_rotation(unit, twist_node)
            }
        end
    end
    if not controller_observation.body_ik_hand_anatomy[side] then
        local middle_name = side == "left" and
            "j_lefthandmiddle1" or "j_righthandmiddle1"
        local index_name = side == "left" and
            "j_lefthandindex1" or "j_righthandindex1"
        local pinky_name = side == "left" and
            "j_lefthandpinky1" or "j_righthandpinky1"
        if Unit.has_node(unit, middle_name) and
                Unit.has_node(unit, index_name) and
                Unit.has_node(unit, pinky_name) then
            local inverse_hand = presentation.inverse_quaternion(hand_world)
            local longitudinal = presentation.rotate_vector(
                inverse_hand,
                Unit.world_position(unit, Unit.node(unit, middle_name)) -
                    wrist)
            local across = presentation.rotate_vector(
                inverse_hand,
                Unit.world_position(unit, Unit.node(unit, index_name)) -
                    Unit.world_position(unit, Unit.node(unit, pinky_name)))
            longitudinal = Vector3.normalize(longitudinal)
            across = Vector3.normalize(across)
            local palm = Vector3.normalize(
                Vector3.cross(across, longitudinal))
            controller_observation.body_ik_hand_anatomy[side] = {
                longitudinal = Vector3Box(longitudinal),
                across = Vector3Box(across),
                palm = Vector3Box(palm)
            }
            mod:info(
                "DARKTIDEVR_IK anatomy_calibration side=%s stage=prewrite longitudinal_local=%.4f,%.4f,%.4f across_local=%.4f,%.4f,%.4f palm_local=%.4f,%.4f,%.4f",
                side,
                Vector3.x(longitudinal), Vector3.y(longitudinal),
                Vector3.z(longitudinal), Vector3.x(across),
                Vector3.y(across), Vector3.z(across), Vector3.x(palm),
                Vector3.y(palm), Vector3.z(palm))
        end
    end
    local arm_delta = presentation.align_vectors_rotation(
        elbow - shoulder, solved_elbow - shoulder)
    if not arm_delta then
        return false, "upper_alignment_invalid"
    end
    local solved_arm_world = Quaternion.multiply(arm_delta, arm_world)
    local solved_arm_local = Quaternion.multiply(
        presentation.inverse_quaternion(
            Unit.world_rotation(unit, arm_parent)),
        solved_arm_world)

    -- Rotating the upper arm also rotates the existing lower-arm basis. Build
    -- that provisional world pose analytically, then apply a second shortest-
    -- arc correction to the solved lower segment.
    local provisional_forearm_world = Quaternion.multiply(
        arm_delta, forearm_world)
    local provisional_lower = presentation.rotate_vector(
        arm_delta, wrist - elbow)
    local forearm_delta = presentation.align_vectors_rotation(
        provisional_lower, solved_wrist - solved_elbow)
    if not forearm_delta then
        return false, "lower_alignment_invalid"
    end
    local solved_forearm_world = Quaternion.multiply(
        forearm_delta, provisional_forearm_world)
    -- Convert the measured, pre-write hand anatomy into the tracked controller
    -- frame rather than assuming mirrored bone axes. Touch's grip +Y points
    -- down the physical handle: the live profile measurement places it 150
    -- degrees from the aim ray. A visible hand's wrist-to-fingertips direction
    -- is therefore -grip-Y, while little-to-index remains grip-forward. The
    -- corresponding palm normal is -grip-X. The source frame absorbs the
    -- rig's actual left/right mirroring and any breed-specific bone basis.
    local anatomy = controller_observation.body_ik_hand_anatomy[side]
    if not anatomy then
        return false, "hand_anatomy_unavailable"
    end
    local source_frame = Quaternion.look(
        anatomy.palm:unbox(), anatomy.across:unbox())
    local target_frame = Quaternion.look(
        Quaternion.right(target_rotation) * -1,
        Quaternion.forward(target_rotation))
    local solved_hand_world = Quaternion.multiply(
        target_frame,
        presentation.inverse_quaternion(source_frame))

    -- A shortest-arc positional solve leaves lower-arm roll unchanged and
    -- forces the hand joint to absorb every degree of controller roll. Recover
    -- that missing axial angle from the calibrated hand basis. Do not put it
    -- on j_*forearm: that control joint starts at the elbow, so doing so makes
    -- the entire forearm rigidly follow the wrist and concentrates the visible
    -- deformation at the elbow. Darktide's human rig supplies the conventional
    -- sibling twist deformers j_*forearmroll1/2. After the reach solve,
    -- distribute the wrist twist according to their authored position
    -- along the elbow-to-wrist segment while leaving the hand effector exact.
    -- Quaternion swing/twist decomposition separates that axial component
    -- from wrist flexion/deviation. Unwrap the signed result against the prior
    -- frame before applying fractional weights; otherwise equivalent +180 and
    -- -180 degree hand orientations would make the deformers snap by 120
    -- degrees at the branch cut.
    local provisional_hand_world = Quaternion.multiply(
        forearm_delta, Quaternion.multiply(arm_delta, hand_world))
    local lower_axis = solved_wrist - solved_elbow
    local roll = presentation.signed_twist_angle(
        provisional_hand_world, solved_hand_world, lower_axis)
    controller_observation.body_ik_twist_state =
        controller_observation.body_ik_twist_state or {}
    local twist_state = controller_observation.body_ik_twist_state[side]
    if roll and twist_state then
        local raw_delta = roll - twist_state.raw
        -- Normal forearm pronation/supination is roughly 75-95 degrees in
        -- either direction. Keep a small allowance, then let the exact hand
        -- joint absorb any impossible excess rather than winding the mesh.
        local twist_limit = math.pi * 5 / 9
        if raw_delta > math.pi then
            raw_delta = raw_delta - 2 * math.pi
        elseif raw_delta < -math.pi then
            raw_delta = raw_delta + 2 * math.pi
        elseif math.abs(raw_delta) > math.pi / 2 then
            -- A tracked wrist cannot rotate 90 degrees in one render frame.
            -- Treat this as a new controller/session/diagnostic phase rather
            -- than carrying the prior phase's accumulated revolution.
            twist_state.continuous = math.max(-twist_limit,
                math.min(twist_limit, roll))
            raw_delta = 0
        end
        twist_state.continuous = math.max(-twist_limit,
            math.min(twist_limit, twist_state.continuous + raw_delta))
        twist_state.raw = roll
        roll = twist_state.continuous
    elseif roll then
        twist_state = {
            raw = roll,
            continuous = math.max(-math.pi * 5 / 9,
                math.min(math.pi * 5 / 9, roll))
        }
        controller_observation.body_ik_twist_state[side] = twist_state
        roll = twist_state.continuous
    end
    local roll_source = "swing_twist"
    if side == "left" then
        controller_observation.body_ik_left_forearm_roll = roll or 0
        controller_observation.body_ik_left_roll_source = roll_source
    else
        controller_observation.body_ik_right_forearm_roll = roll or 0
        controller_observation.body_ik_right_roll_source = roll_source
    end
    local solved_forearm_local = Quaternion.multiply(
        presentation.inverse_quaternion(solved_arm_world),
        solved_forearm_world)
    local solved_hand_local = Quaternion.multiply(
        presentation.inverse_quaternion(solved_forearm_world),
        solved_hand_world)
    Unit.set_local_rotation(unit, arm_node, solved_arm_local)
    Unit.set_local_rotation(unit, forearm_node, solved_forearm_local)
    Unit.set_local_rotation(unit, hand_node, solved_hand_local)
    World.update_unit_and_children(world, unit)

    -- The dedicated glove cosmetic includes vertices weighted to the hand,
    -- forearm and forearm-roll bones. Detaching only j_*hand therefore leaves
    -- its bracer on the stock lower-arm pose and elastically stretches the
    -- glove between two owners. Translate the complete lower-arm subtree by
    -- the residual instead. The upper arm is hidden, so its disconnected elbow
    -- is harmless, while hand, cuff, bracer and roll deformers remain one
    -- rigid controller-owned visual chain beyond the avatar's nominal reach.
    local current_wrist = Unit.world_position(unit, hand_node)
    local forearm_parent_rotation = Unit.world_rotation(unit, forearm_parent)
    local forearm_residual_local = presentation.rotate_vector(
        presentation.inverse_quaternion(forearm_parent_rotation),
        target_position - current_wrist)
    Unit.set_local_position(unit, forearm_node,
        Unit.local_position(unit, forearm_node) + forearm_residual_local)
    World.update_unit_and_children(world, unit)
    local translated_forearm = Unit.world_position(unit, forearm_node)
    controller_observation.body_ik_hand_proxy_pose[side] = {
        position = Vector3Box(Unit.world_position(unit, hand_node)),
        rotation = QuaternionBox(Unit.world_rotation(unit, hand_node)),
        forearm_position = Vector3Box(
            Unit.world_position(unit, forearm_node)),
        forearm_rotation = QuaternionBox(
            Unit.world_rotation(unit, forearm_node))
    }
    if controller_observation.body_ik_hand_proxy_held[side] then
        controller_observation.body_ik_hand_proxy_held[side] = false
        controller_observation.body_ik_hand_proxy_reacquisitions =
            (controller_observation.body_ik_hand_proxy_reacquisitions or 0) + 1
        mod:info(
            "DARKTIDEVR_IK hand_proxy=reacquired side=%s count=%d",
            side, controller_observation.body_ik_hand_proxy_reacquisitions)
    end
    controller_observation.body_ik_hand_proxy_logged =
        controller_observation.body_ik_hand_proxy_logged or {}
    if not controller_observation.body_ik_hand_proxy_logged[side] then
        controller_observation.body_ik_hand_proxy_logged[side] = true
        mod:info(
            "DARKTIDEVR_IK hand_proxy=active side=%s chain_reach_delta_m=%.4f",
            side, presentation.vector_distance(target_position, solved_wrist))
    end

    local lower_length_squared = Vector3.dot(lower_axis, lower_axis)
    local twist_fractions = {}
    local twist_written = 0
    if roll and lower_length_squared > 0.000001 then
        local lower_unit_axis = lower_axis /
            math.sqrt(lower_length_squared)
        for i = 1, #twist_names do
            local twist_name = twist_names[i]
            local twist_record = twist_records[twist_name]
            if twist_record then
                local twist_node = twist_record.node
                local twist_parent = twist_record.parent
                if twist_parent == forearm_node then
                    local authored_position = Unit.world_position(
                        unit, twist_node)
                    local fraction = Vector3.dot(
                        authored_position - translated_forearm, lower_axis) /
                        lower_length_squared
                    fraction = math.max(0, math.min(1, fraction))
                    local inherited_world = Quaternion.multiply(
                        Unit.world_rotation(unit, twist_parent),
                        twist_record.local_rotation)
                    local corrected_world = Quaternion.multiply(
                        Quaternion.axis_angle(
                            lower_unit_axis, roll * fraction),
                        inherited_world)
                    local corrected_local = Quaternion.multiply(
                        presentation.inverse_quaternion(
                            Unit.world_rotation(unit, twist_parent)),
                        corrected_world)
                    Unit.set_local_rotation(
                        unit, twist_node, corrected_local)
                    twist_fractions[#twist_fractions + 1] =
                        string.format("%s:%.3f", twist_name, fraction)
                    twist_written = twist_written + 1
                else
                    twist_fractions[#twist_fractions + 1] =
                        string.format(
                            "%s:parent_%s", twist_name,
                            tostring(twist_parent))
                end
            else
                twist_fractions[#twist_fractions + 1] =
                    twist_name .. ":missing"
            end
        end
        if twist_written > 0 then
            World.update_unit_and_children(world, unit)
        end
    end
    if side == "left" then
        controller_observation.body_ik_left_twist_chain =
            table.concat(twist_fractions, ",")
        controller_observation.body_ik_left_twist_writes = twist_written
    else
        controller_observation.body_ik_right_twist_chain =
            table.concat(twist_fractions, ",")
        controller_observation.body_ik_right_twist_writes = twist_written
    end
    return true, "written",
        presentation.vector_distance(
            Unit.world_position(unit, hand_node), target_position),
        presentation.quaternion_angle_error(
            Unit.world_rotation(unit, hand_node), solved_hand_world)
end

function presentation.solve_body_leg(
        world, unit, side, target_ankle, target_foot_rotation)
    local upper_name = side == "left" and
        "j_leftupleg" or "j_rightupleg"
    local lower_name = side == "left" and "j_leftleg" or "j_rightleg"
    local foot_name = side == "left" and "j_leftfoot" or "j_rightfoot"
    if not Unit.has_node(unit, upper_name) or
            not Unit.has_node(unit, lower_name) or
            not Unit.has_node(unit, foot_name) then
        return false, "nodes_missing", 0
    end
    local upper = Unit.node(unit, upper_name)
    local lower = Unit.node(unit, lower_name)
    local foot = Unit.node(unit, foot_name)
    local upper_parent = Unit.scene_graph_parent(unit, upper)
    if upper_parent == nil or Unit.scene_graph_parent(unit, lower) ~= upper or
            Unit.scene_graph_parent(unit, foot) ~= lower then
        return false, "hierarchy_mismatch", 0
    end
    local hip = Unit.world_position(unit, upper)
    local knee = Unit.world_position(unit, lower)
    local ankle = Unit.world_position(unit, foot)
    local upper_world = Unit.world_rotation(unit, upper)
    local lower_world = Unit.world_rotation(unit, lower)
    local input = controller_observation.ik_input
    local output = controller_observation.ik_output
    local flags = controller_observation.ik_flags
    local reach = ankle - hip
    local bend = knee - hip
    input[0], input[1], input[2] =
        Vector3.x(hip), Vector3.y(hip), Vector3.z(hip)
    input[3], input[4], input[5] =
        Vector3.x(target_ankle), Vector3.y(target_ankle),
        Vector3.z(target_ankle)
    input[6], input[7], input[8] =
        Vector3.x(knee), Vector3.y(knee), Vector3.z(knee)
    input[9], input[10], input[11] =
        Vector3.x(reach), Vector3.y(reach), Vector3.z(reach)
    input[12], input[13], input[14] =
        Vector3.x(bend), Vector3.y(bend), Vector3.z(bend)
    input[15], input[16] =
        presentation.vector_distance(hip, knee),
        presentation.vector_distance(knee, ankle)
    local native_result = ui_native_capture.dtvr_solve_two_bone_ik(
        input, 17, output, 14, flags)
    if native_result ~= 0 then
        return false, "native_" .. tostring(native_result), 0
    end
    local solved_knee = Vector3(output[0], output[1], output[2])
    local solved_ankle = Vector3(output[3], output[4], output[5])
    local upper_delta = presentation.align_vectors_rotation(
        knee - hip, solved_knee - hip)
    if not upper_delta then
        return false, "upper_alignment_invalid", 0
    end
    local solved_upper_world = Quaternion.multiply(upper_delta, upper_world)
    local provisional_lower_world = Quaternion.multiply(
        upper_delta, lower_world)
    local lower_delta = presentation.align_vectors_rotation(
        presentation.rotate_vector(upper_delta, ankle - knee),
        solved_ankle - solved_knee)
    if not lower_delta then
        return false, "lower_alignment_invalid", 0
    end
    local solved_lower_world = Quaternion.multiply(
        lower_delta, provisional_lower_world)
    Unit.set_local_rotation(unit, upper, Quaternion.multiply(
        presentation.inverse_quaternion(
            Unit.world_rotation(unit, upper_parent)),
        solved_upper_world))
    Unit.set_local_rotation(unit, lower, Quaternion.multiply(
        presentation.inverse_quaternion(solved_upper_world),
        solved_lower_world))
    Unit.set_local_rotation(unit, foot, Quaternion.multiply(
        presentation.inverse_quaternion(solved_lower_world),
        target_foot_rotation))
    World.update_unit_and_children(world, unit)
    return true, "written", presentation.vector_distance(
        Unit.world_position(unit, foot), solved_ankle)
end

-- Preserve exact headset translation while allowing the visible avatar to
-- follow a physical crouch. The gameplay root/capsule remains authoritative;
-- only the animated pelvis is lowered. Both legs are solved back to their
-- pre-write ankle positions, planting the feet instead of pushing them through
-- the floor. A small standing dead zone rejects tracking noise, while partial
-- follow leaves room for natural neck/spine compression.
function presentation.neck_compensated_vertical(unit, raw_vertical, scale)
    if not unit or not Unit.alive(unit) or
            not Unit.has_node(unit, "j_neck") then
        return raw_vertical * scale, "neck_missing"
    end
    local head_rotation = Quaternion.from_elements(
        head_pose_values[3], -head_pose_values[5],
        head_pose_values[4], head_pose_values[6])
    local generation = controller_observation.head_recenter_generation
    local needs_capture = controller_observation.body_ik_neck_unit ~= unit or
        controller_observation.body_ik_neck_generation ~= generation or
        controller_observation.body_ik_neck_offset_x == nil
    if needs_capture then
        -- This offset belongs to the tracked player (source skeleton), not
        -- the Darktide avatar (target skeleton). Remove the physical HMD arc
        -- in metres before retargeting the remaining body translation by the
        -- character scale. Character-select calibration will replace these
        -- conservative adult landmarks with the player's measured values.
        local offset = Vector3(0, 0.0805, 0.075)
        local rotated = presentation.rotate_vector(head_rotation, offset)
        controller_observation.body_ik_neck_unit = unit
        controller_observation.body_ik_neck_generation = generation
        controller_observation.body_ik_neck_offset_x = Vector3.x(offset)
        controller_observation.body_ik_neck_offset_y = Vector3.y(offset)
        controller_observation.body_ik_neck_offset_z = Vector3.z(offset)
        controller_observation.body_ik_neck_baseline_raw =
            raw_vertical
        controller_observation.body_ik_neck_baseline_arc = Vector3.z(rotated)
        mod:info(
            "DARKTIDEVR_IK neck_pivot captured generation=%d offset_m=%.4f,%.4f,%.4f source=%s",
            generation, Vector3.x(offset), Vector3.y(offset),
            Vector3.z(offset), "default_physical")
    end
    local offset = Vector3(
        controller_observation.body_ik_neck_offset_x,
        controller_observation.body_ik_neck_offset_y,
        controller_observation.body_ik_neck_offset_z)
    local arc = Vector3.z(presentation.rotate_vector(head_rotation, offset)) -
        controller_observation.body_ik_neck_baseline_arc
    local compensated = (raw_vertical -
        controller_observation.body_ik_neck_baseline_raw - arc) * scale
    controller_observation.body_ik_neck_raw_vertical = raw_vertical
    controller_observation.body_ik_neck_compensated_vertical = compensated
    controller_observation.body_ik_neck_arc_vertical = arc
    return compensated, "written"
end

function presentation.hold_body_hand_proxy(world, unit, side)
    local pose = controller_observation.body_ik_hand_proxy_pose[side]
    local forearm_name = side == "left" and
        "j_leftforearm" or "j_rightforearm"
    local hand_name = side == "left" and "j_lefthand" or "j_righthand"
    if not pose or not pose.forearm_position or
            not Unit.has_node(unit, forearm_name) or
            not Unit.has_node(unit, hand_name) then
        return false
    end
    local forearm_node = Unit.node(unit, forearm_name)
    local forearm_parent = Unit.scene_graph_parent(unit, forearm_node)
    local hand_node = Unit.node(unit, hand_name)
    local hand_parent = Unit.scene_graph_parent(unit, hand_node)
    if forearm_parent == nil or hand_parent ~= forearm_node then
        return false
    end
    local forearm_parent_position =
        Unit.world_position(unit, forearm_parent)
    local inverse_forearm_parent = presentation.inverse_quaternion(
        Unit.world_rotation(unit, forearm_parent))
    Unit.set_local_position(unit, forearm_node, presentation.rotate_vector(
        inverse_forearm_parent,
        pose.forearm_position:unbox() - forearm_parent_position))
    Unit.set_local_rotation(unit, forearm_node, Quaternion.multiply(
        inverse_forearm_parent, pose.forearm_rotation:unbox()))
    World.update_unit_and_children(world, unit)
    local parent_position = Unit.world_position(unit, hand_parent)
    local parent_rotation = Unit.world_rotation(unit, hand_parent)
    local inverse_parent = presentation.inverse_quaternion(parent_rotation)
    Unit.set_local_position(unit, hand_node, presentation.rotate_vector(
        inverse_parent, pose.position:unbox() - parent_position))
    Unit.set_local_rotation(unit, hand_node, Quaternion.multiply(
        inverse_parent, pose.rotation:unbox()))
    World.update_unit_and_children(world, unit)
    controller_observation.body_ik_hand_proxy_held[side] = true
    controller_observation.body_ik_hand_proxy_hold_frames =
        (controller_observation.body_ik_hand_proxy_hold_frames or 0) + 1
    return true
end

-- Wieldable 3P units stay on the authoritative gameplay visual-loadout so
-- Darktide can keep owning attack, charge, reload and weapon-switch state.
-- Their attachment nodes therefore live under the hidden source hands, not
-- the local profile proxy. After the proxy has accepted the tracked/held hand
-- pose, mirror only those two hidden source nodes to it. The visible weapon
-- follows the controller while all item-local animation remains untouched.
function presentation.sync_equipment_hand_pose(
        source_unit, hand_name, target_position, target_rotation)
    if not source_unit or not Unit.alive(source_unit) or not target_position or
            not target_rotation or not Unit.has_node(source_unit, hand_name) then
        return false
    end
    local source_hand = Unit.node(source_unit, hand_name)
    local source_parent = Unit.scene_graph_parent(source_unit, source_hand)
    if source_parent == nil then
        return false
    end
    local parent_position = Unit.world_position(source_unit, source_parent)
    local inverse_parent = presentation.inverse_quaternion(
        Unit.world_rotation(source_unit, source_parent))
    local parent_space_target = presentation.rotate_vector(
        inverse_parent,
        target_position - parent_position)
    -- The gameplay avatar applies its breed/profile scale at the unit root,
    -- while UIProfileSpawner's local proxy root remains 1.0. Convert the
    -- desired world displacement through that uniform source scale before
    -- writing the source hand's parent-local translation. Omitting this
    -- produced an exact scale-proportional 3--6 cm equipment/glove offset.
    local source_root_scale = Vector3.x(Unit.local_scale(source_unit, 1))
    if math.abs(source_root_scale) < 0.001 then
        source_root_scale = 1
    end
    Unit.set_local_position(
        source_unit, source_hand, parent_space_target / source_root_scale)
    Unit.set_local_rotation(
        source_unit, source_hand, Quaternion.multiply(
            inverse_parent, target_rotation))
    return true
end

function presentation.sync_equipment_hand_to_proxy(source_unit, proxy_unit, hand_name)
    if proxy_unit == nil and presentation.body_proxy and presentation.body_proxy.hand_pose then
        -- Body-drawn hands have no glove unit: follow the recorded final pose.
        local side = hand_name == "j_lefthand" and "left" or hand_name == "j_righthand" and "right" or nil
        if not side then return false end
        local position, rotation = presentation.body_proxy.hand_pose(side)
        return presentation.sync_equipment_hand_pose(source_unit, hand_name, position, rotation)
    end
    if not proxy_unit or not Unit.alive(proxy_unit) or not Unit.has_node(proxy_unit,hand_name) then return false end
    local node=Unit.node(proxy_unit,hand_name)
    return presentation.sync_equipment_hand_pose(source_unit,hand_name,
        Unit.world_position(proxy_unit,node),Unit.world_rotation(proxy_unit,node))
end

function presentation.sync_tracked_equipment_hand(source, authored_side, destination,
        proxy, wrist_position, grip_rotation, placed)
    if not placed or (authored_side~='left' and authored_side~='right') or
            (destination~='left' and destination~='right') then return false end
    local name='j_'..authored_side..'hand'
    if authored_side==destination then
        return presentation.sync_equipment_hand_to_proxy(source,proxy,name)
    end
    local rotation=presentation.body_proxy.equipment_hand_rotation(source,authored_side,grip_rotation)
    if not rotation then return false end
    return presentation.sync_equipment_hand_pose(source,name,wrist_position,rotation)
end

function presentation.sync_equipment_hands_to_proxy(
        world, source_unit, proxy_unit)
    if not source_unit or source_unit == proxy_unit or
            not Unit.alive(source_unit) or not Unit.alive(proxy_unit) then
        return false
    end
    local left_synced = presentation.sync_equipment_hand_to_proxy(
        source_unit, proxy_unit, "j_lefthand")
    local right_synced = presentation.sync_equipment_hand_to_proxy(
        source_unit, proxy_unit, "j_righthand")
    local synced = left_synced or right_synced
    if synced then
        World.update_unit_and_children(world, source_unit)
        local position_error = 0
        local angle_error = 0
        local left_position_error = 0
        local right_position_error = 0
        if left_synced then
            local source_hand = Unit.node(source_unit, "j_lefthand")
            local proxy_hand = Unit.node(proxy_unit, "j_lefthand")
            left_position_error = presentation.vector_distance(
                Unit.world_position(source_unit, source_hand),
                Unit.world_position(proxy_unit, proxy_hand))
            position_error = math.max(position_error, left_position_error)
            angle_error = math.max(angle_error,
                presentation.quaternion_angle_error(
                    Unit.world_rotation(source_unit, source_hand),
                    Unit.world_rotation(proxy_unit, proxy_hand)))
        end
        if right_synced then
            local source_hand = Unit.node(source_unit, "j_righthand")
            local proxy_hand = Unit.node(proxy_unit, "j_righthand")
            right_position_error = presentation.vector_distance(
                Unit.world_position(source_unit, source_hand),
                Unit.world_position(proxy_unit, proxy_hand))
            position_error = math.max(position_error, right_position_error)
            angle_error = math.max(angle_error,
                presentation.quaternion_angle_error(
                    Unit.world_rotation(source_unit, source_hand),
                    Unit.world_rotation(proxy_unit, proxy_hand)))
        end
        controller_observation.body_ik_equipment_hand_error = position_error
        controller_observation.body_ik_equipment_hand_angle_error = angle_error
        controller_observation.body_ik_equipment_hand_max_error = math.max(
            controller_observation.body_ik_equipment_hand_max_error or 0,
            position_error)
        controller_observation.body_ik_equipment_hand_max_angle_error = math.max(
            controller_observation.body_ik_equipment_hand_max_angle_error or 0,
            angle_error)
        controller_observation.body_ik_equipment_hand_syncs =
            (controller_observation.body_ik_equipment_hand_syncs or 0) + 1
        -- Partial rigs may sync one hand successfully. The detailed scale
        -- diagnostic requires both source hands and their parents to exist.
        if controller_observation.body_ik_equipment_hand_syncs == 1 and
                left_synced and right_synced then
            local left_parent = Unit.scene_graph_parent(
                source_unit, Unit.node(source_unit, "j_lefthand"))
            local right_parent = Unit.scene_graph_parent(
                source_unit, Unit.node(source_unit, "j_righthand"))
            local source_root_scale = Unit.local_scale(source_unit, 1)
            local proxy_root_scale = Unit.local_scale(proxy_unit, 1)
            local left_parent_scale = Unit.local_scale(source_unit, left_parent)
            local right_parent_scale = Unit.local_scale(source_unit, right_parent)
            mod:info(
                "DARKTIDEVR_ARMS equipment_scale source_root=%.6f,%.6f,%.6f proxy_root=%.6f,%.6f,%.6f left_parent=%.6f,%.6f,%.6f right_parent=%.6f,%.6f,%.6f",
                Vector3.x(source_root_scale), Vector3.y(source_root_scale),
                Vector3.z(source_root_scale), Vector3.x(proxy_root_scale),
                Vector3.y(proxy_root_scale), Vector3.z(proxy_root_scale),
                Vector3.x(left_parent_scale), Vector3.y(left_parent_scale),
                Vector3.z(left_parent_scale), Vector3.x(right_parent_scale),
                Vector3.y(right_parent_scale), Vector3.z(right_parent_scale))
        end
        if controller_observation.body_ik_equipment_hand_syncs == 1 or
                controller_observation.body_ik_equipment_hand_syncs % 600 == 0 then
            mod:info(
                "DARKTIDEVR_ARMS equipment_hand_owner=tracked_proxy item_animation=gameplay_visual_loadout syncs=%d post_error_m=%.6f left_error_m=%.6f right_error_m=%.6f max_error_m=%.6f angle_error_rad=%.6f max_angle_error_rad=%.6f",
                controller_observation.body_ik_equipment_hand_syncs,
                position_error,
                left_position_error,
                right_position_error,
                controller_observation.body_ik_equipment_hand_max_error,
                angle_error,
                controller_observation.body_ik_equipment_hand_max_angle_error)
        end
    end
    return synced
end

function presentation.apply_tracked_arms(unit, sequence, world, anchor_unit)
    presentation.refresh_body_anchor_from_avatar(anchor_unit or unit)
    local left_target, left_rotation =
        presentation.body_ik_controller_grip_target(unit, "left")
    local right_target, right_rotation =
        presentation.body_ik_controller_grip_target(unit, "right")
    if presentation.body_proxy and
            presentation.body_proxy.rigid_hands_active() then
        -- Rigid glove roots still target the anatomical wrist, not the grip
        -- origin embedded inside the Touch controller. Preserve the accepted
        -- grip-relative correction used by the articulated-hand path.
        local rigid_left_target = left_target and
            presentation.body_ik_calibrated_wrist_target(
                "left", left_target, left_rotation)
        local rigid_right_target = right_target and
            presentation.body_ik_calibrated_wrist_target(
                "right", right_target, right_rotation)
        local left_unit, right_unit, rigid_written, left_written, right_written =
            presentation.body_proxy.place_rigid_hands(
                world, rigid_left_target, left_rotation,
                rigid_right_target, right_rotation)
        if rigid_written then
            for side_index=1,2 do
                local authored_side=side_index==1 and 'left' or 'right'
                local role=authored_side=='left' and 'support' or 'dominant'
                local destination=presentation.weapon_hand_roles.physical(role)
                if destination=='left' then
                    presentation.sync_tracked_equipment_hand(anchor_unit,authored_side,destination,
                        left_unit,rigid_left_target,left_rotation,left_written)
                elseif destination=='right' then
                    presentation.sync_tracked_equipment_hand(anchor_unit,authored_side,destination,
                        right_unit,rigid_right_target,right_rotation,right_written)
                end
            end
            World.update_unit_and_children(world, anchor_unit)
            controller_observation.body_ik_presentation_writes =
                controller_observation.body_ik_presentation_writes + 1
            controller_observation.body_ik_presentation_block_reason = nil
        end
        return
    end
    -- Rigid hands use authored joint-to-root transforms. The generic proxy
    -- handle above is the left root, so applying arm-length retargeting before
    -- that branch deforms only the left glove's skinning skeleton.
    local arm_length_ok, _, arm_length_reason =
        presentation.apply_calibrated_arm_length(world, unit)
    if not arm_length_ok then
        controller_observation.body_ik_presentation_block_reason =
            "arm_length_" .. tostring(arm_length_reason)
        return
    end
    local wrote = false
    local max_error = 0
    local max_angle_error = 0
    local block_reason = nil
    if left_target then
        local ok, reason, error_metres, angle_error =
            presentation.apply_body_arm_ik(
                world, unit, "left", left_target, left_rotation)
        wrote = wrote or ok
        block_reason = not ok and "left_" .. tostring(reason) or block_reason
        max_error = math.max(max_error, error_metres or 0)
        max_angle_error = math.max(max_angle_error, angle_error or 0)
    else
        wrote = presentation.hold_body_hand_proxy(
            world, unit, "left") or wrote
    end
    if right_target then
        local ok, reason, error_metres, angle_error =
            presentation.apply_body_arm_ik(
                world, unit, "right", right_target, right_rotation)
        wrote = wrote or ok
        block_reason = not ok and "right_" .. tostring(reason) or block_reason
        max_error = math.max(max_error, error_metres or 0)
        max_angle_error = math.max(max_angle_error, angle_error or 0)
    else
        wrote = presentation.hold_body_hand_proxy(
            world, unit, "right") or wrote
    end
    if wrote then
        presentation.sync_equipment_hands_to_proxy(
            world, anchor_unit, unit)
        controller_observation.body_ik_presentation_writes =
            controller_observation.body_ik_presentation_writes + 1
        controller_observation.body_ik_presentation_max_error = math.max(
            controller_observation.body_ik_presentation_max_error, max_error)
        controller_observation.body_ik_presentation_max_angle_error = math.max(
            controller_observation.body_ik_presentation_max_angle_error,
            max_angle_error)
        block_reason = nil
    end
    if block_reason ~= controller_observation.body_ik_presentation_block_reason then
        controller_observation.body_ik_presentation_block_reason = block_reason
        if block_reason then
            mod:warning(
                "DARKTIDEVR_ARMS presentation_blocked reason=%s",
                block_reason)
        end
    end
    if wrote and controller_observation.body_ik_presentation_update_frame >=
            controller_observation.body_ik_presentation_last_log_frame + 600 then
        controller_observation.body_ik_presentation_last_log_frame =
            controller_observation.body_ik_presentation_update_frame
        mod:info(
            "DARKTIDEVR_ARMS presentation_writes=%d post_error_m=%.6f angle_error_rad=%.6f sequence=%d",
            controller_observation.body_ik_presentation_writes,
            max_error, max_angle_error,
            sequence or controller_observation.last_sequence)
    end
end

function presentation.apply_body_crouch(world, unit)
    local raw_vertical = head_pose_values and
        tonumber(head_pose_values[1]) or 0
    local raw_horizontal_x = head_pose_values and
        tonumber(head_pose_values[0]) or 0
    local raw_horizontal_z = head_pose_values and
        tonumber(head_pose_values[2]) or 0
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    local scale = presentation.calibrated_character_scale(local_player)
    -- The hub body leans by the same sliding-local camera delta. Cumulative
    -- body_follow belongs only to a collision-root transfer, which is disabled
    -- in the public hub.
    raw_horizontal_x, raw_horizontal_z =
        presentation.clamp_hub_head_horizontal(
            raw_horizontal_x * scale, raw_horizontal_z * scale)
    -- Keep about 5 cm of relative descent for natural neck/spine compression;
    -- the remainder follows the tracked head rather than letting the camera
    -- sink into the chest. The 60 cm cap remains inside the measured human
    -- leg-chain reach and permits a deep physical crouch.
    local compensated_vertical = presentation.neck_compensated_vertical(
        unit, raw_vertical, scale)
    local requested = math.min(0.60, math.max(0,
        -compensated_vertical - 0.05))
    local now = Managers and Managers.time and Managers.time:time("main") or 0
    if now >= controller_observation.body_ik_neck_last_log_t + 1 then
        controller_observation.body_ik_neck_last_log_t = now
        mod:info(
            "DARKTIDEVR_IK neck_height raw_m=%.4f arc_m=%.4f compensated_m=%.4f requested_crouch_m=%.4f generation=%d",
            controller_observation.body_ik_neck_raw_vertical or 0,
            controller_observation.body_ik_neck_arc_vertical or 0,
            compensated_vertical, requested,
            controller_observation.head_recenter_generation or 0)
    end
    local last_t = controller_observation.body_ik_crouch_last_t or now
    local dt = math.clamp(now - last_t, 0, 0.1)
    local current = controller_observation.body_ik_crouch_offset or 0
    current = current + (requested - current) *
        (1 - math.exp(-12 * dt))
    if current < 0.0001 and requested == 0 then
        current = 0
    end
    controller_observation.body_ik_crouch_offset = current
    controller_observation.body_ik_crouch_last_t = now
    if presentation.current_game_mode_name() ~= "hub" and current == 0 and
            math.abs(raw_horizontal_x) < 0.0001 and
            math.abs(raw_horizontal_z) < 0.0001 then
        controller_observation.body_ik_crouch_result = "standing"
        return true, "standing", 0
    end
    if not Unit.has_node(unit, "j_hips") then
        return false, "hips_missing", 0
    end
    local hips = Unit.node(unit, "j_hips")
    local hips_parent = Unit.scene_graph_parent(unit, hips)
    if hips_parent == nil then
        return false, "hips_parent_missing", 0
    end
    local targets = {}
    for _, side in ipairs({ "left", "right" }) do
        local foot_name = side == "left" and
            "j_leftfoot" or "j_rightfoot"
        if not Unit.has_node(unit, foot_name) then
            return false, side .. "_foot_missing", 0
        end
        local foot = Unit.node(unit, foot_name)
        targets[side] = {
            position = Vector3Box(Unit.world_position(unit, foot)),
            rotation = QuaternionBox(Unit.world_rotation(unit, foot))
        }
    end
    local anchor_rotation = controller_observation.body_anchor_qw and
        Quaternion.from_elements(
            controller_observation.body_anchor_qx,
            controller_observation.body_anchor_qy,
            controller_observation.body_anchor_qz,
            controller_observation.body_anchor_qw) or
        Unit.world_rotation(unit, 1)
    local tracked_shift =
        Quaternion.right(anchor_rotation) * raw_horizontal_x +
        Quaternion.forward(anchor_rotation) * -raw_horizontal_z +
        Vector3.up() * -current
    local body_shift = tracked_shift
    if presentation.current_game_mode_name() == "hub" and
            Unit.has_node(unit, "j_neck") then
        -- Hub jog animation is allowed to animate gait, but its authored torso
        -- lean must not move the avatar away from the physical head. Capture
        -- the neutral root-to-neck vector once, rebuild that point from the
        -- live locomotion root, then add only tracked lean/crouch. Translating
        -- the hips to this estimated neck pivot leaves the camera authoritative
        -- and the planted-leg solve below absorbs the animation correction.
        local root = 1
        local neck = Unit.node(unit, "j_neck")
        local root_rotation = Unit.world_rotation(unit, root)
        local needs_anchor =
            controller_observation.body_ik_neck_anchor_unit ~= unit or
            controller_observation.body_ik_neck_anchor_generation ~=
                controller_observation.head_recenter_generation or
            not controller_observation.body_ik_neck_anchor_local
        if needs_anchor then
            controller_observation.body_ik_neck_anchor_unit = unit
            controller_observation.body_ik_neck_anchor_generation =
                controller_observation.head_recenter_generation
            controller_observation.body_ik_neck_anchor_local = Vector3Box(
                presentation.rotate_vector(
                    presentation.inverse_quaternion(root_rotation),
                    Unit.world_position(unit, neck) -
                        Unit.world_position(unit, root)))
            mod:info(
                "DARKTIDEVR_IK neck_anchor captured generation=%d source=neutral_root_space",
                controller_observation.head_recenter_generation)
        end
        local neutral_neck = Unit.world_position(unit, root) +
            presentation.rotate_vector(root_rotation,
                controller_observation.body_ik_neck_anchor_local:unbox())
        body_shift = neutral_neck + tracked_shift -
            Unit.world_position(unit, neck)
    end
    if Vector3.length(body_shift) < 0.0001 then
        controller_observation.body_ik_crouch_result = "anchored"
        return true, "anchored", 0
    end
    if Vector3.length(body_shift) >= 0.0001 then
        local local_drop = presentation.rotate_vector(
            presentation.inverse_quaternion(
                Unit.world_rotation(unit, hips_parent)),
            body_shift)
        Unit.set_local_position(
            unit, hips, Unit.local_position(unit, hips) + local_drop)
        World.update_unit_and_children(world, unit)
    end
    local max_error = 0
    for _, side in ipairs({ "left", "right" }) do
        local target = targets[side]
        local ok, reason, error_metres = presentation.solve_body_leg(
            world, unit, side, target.position:unbox(),
            target.rotation:unbox())
        if not ok then
            controller_observation.body_ik_crouch_result =
                side .. "_" .. tostring(reason)
            return false, controller_observation.body_ik_crouch_result,
                max_error
        end
        max_error = math.max(max_error, error_metres or 0)
    end
    controller_observation.body_ik_crouch_max_foot_error = math.max(
        controller_observation.body_ik_crouch_max_foot_error, max_error)
    controller_observation.body_ik_crouch_result = "written"
    return true, "written", max_error
end

-- Render-only body heading: the HMD drives the torso, while controller pitch,
-- roll and yaw remain confined to the independently solved arms/gameplay aim.
-- A 30-degree head/body dead zone with exponential catch-up is the conventional
-- VR full-body compromise: small glances do not shuffle the avatar, but a
-- sustained head turn brings the shoulders around smoothly.
function presentation.apply_body_heading(world, unit)
    local head_yaw = controller_observation.body_head_yaw
    if not head_yaw then
        return
    end
    local now = Managers and Managers.time and Managers.time:time("main") or 0
    local visual_yaw = controller_observation.body_visual_yaw
    if not visual_yaw then
        -- Seeded from the tracked head, not the character root, which turns
        -- with locomotion (animation audit, 16 September, item L).
        visual_yaw = head_yaw
    end
    local prior_head_yaw =
        controller_observation.body_heading_last_head_yaw or head_yaw
    local head_motion = math.abs(math.atan2(
        math.sin(head_yaw - prior_head_yaw),
        math.cos(head_yaw - prior_head_yaw)))
    if head_motion > math.pi / 360 then
        controller_observation.body_heading_last_motion_t = now
    end
    controller_observation.body_heading_last_head_yaw = head_yaw
    local delta = math.atan2(
        math.sin(head_yaw - visual_yaw),
        math.cos(head_yaw - visual_yaw))
    local dead_zone = math.pi / 6
    local desired_yaw = nil
    local convergence = nil
    if controller_observation.gameplay_stick_active then
        -- During artificial locomotion the body should face the travel/head
        -- frame promptly; retaining a large stationary dead zone here makes
        -- strafing/jog animation visibly shear under the tracked upper body.
        desired_yaw = head_yaw
        convergence = 6
    elseif math.abs(delta) > dead_zone then
        desired_yaw = head_yaw - math.sign(delta) * dead_zone
        convergence = 8
    elseif now - controller_observation.body_heading_last_motion_t > 0.75 then
        -- Hybrid avatar-heading behavior: preserve the comfort dead zone for a
        -- glance, then let a stationary body settle unobtrusively underneath
        -- the user's sustained physical heading.
        desired_yaw = head_yaw
        convergence = 0.5
    end
    if desired_yaw then
        local desired_delta = math.atan2(
            math.sin(desired_yaw - visual_yaw),
            math.cos(desired_yaw - visual_yaw))
        local last_t = controller_observation.body_visual_yaw_last_t or now
        local dt = math.clamp(now - last_t, 0, 0.1)
        local alpha = 1 - math.exp(-convergence * dt)
        visual_yaw = visual_yaw + desired_delta * alpha
    end
    -- What this solver just decided, for the body trace. Which branch fired is
    -- the whole answer to "the torso doesn't recentre": `recentre` never
    -- firing means the stillness gate is not being satisfied, `deadzone`
    -- holding means the head is further than 30 degrees round, and `stick`
    -- means artificial locomotion is claiming it at convergence 6.
    local trace = presentation.body_heading_trace
    if not trace then
        trace = {}
        presentation.body_heading_trace = trace
    end
    trace.head_yaw = head_yaw
    trace.visual_yaw = visual_yaw
    trace.delta = delta
    trace.head_motion = head_motion
    trace.still_seconds = now - (controller_observation.body_heading_last_motion_t or now)
    trace.convergence = convergence
    trace.stick = controller_observation.gameplay_stick_active == true
    trace.branch = controller_observation.gameplay_stick_active and "stick" or
        (math.abs(delta) > dead_zone and "deadzone" or
            (desired_yaw and "recentre" or "held"))
    controller_observation.body_visual_yaw = visual_yaw
    controller_observation.body_visual_yaw_last_t = now
    if presentation.current_game_mode_name() == "hub" then
        -- Hub locomotion continuously authors the replicated root orientation.
        -- Writing a second root yaw here made the whole body alternate between
        -- the locomotion and VR poses. Keep the visual target for the downstream
        -- shoulder/spine solve, but leave the root exclusively game-owned.
        return
    end
    local current_yaw = Quaternion.yaw(Unit.local_rotation(unit, 1))
    if math.abs(math.atan2(
            math.sin(visual_yaw - current_yaw),
            math.cos(visual_yaw - current_yaw))) < 0.0001 then
        return
    end
    Unit.set_local_rotation(
        unit, 1, Quaternion.axis_angle(Vector3.up(), visual_yaw))
    World.update_unit_and_children(world, unit)
end

function presentation.align_body_torso_neutral(world, unit)
    if not Unit.has_node(unit, "j_spine2") or
            not Unit.has_node(unit, "j_neck") then
        return false, "torso_nodes_missing"
    end
    local spine = Unit.node(unit, "j_spine2")
    local neck = Unit.node(unit, "j_neck")
    local current = Unit.scene_graph_parent(unit, neck)
    local ancestry_valid = false
    local depth = 0
    while current ~= nil and depth < 64 do
        if current == spine then
            ancestry_valid = true
            break
        end
        current = Unit.scene_graph_parent(unit, current)
        depth = depth + 1
    end
    if not ancestry_valid then
        return false, "spine2_not_neck_ancestor"
    end
    local spine_position = Unit.world_position(unit, spine)
    local torso_axis = Unit.world_position(unit, neck) - spine_position
    if Vector3.length(torso_axis) < 0.001 then
        return false, "torso_axis_degenerate"
    end
    torso_axis = Vector3.normalize(torso_axis)
    if controller_observation.body_ik_torso_axis_unit ~= unit or
            not controller_observation.body_ik_torso_axis_local then
        local root_inverse = presentation.inverse_quaternion(
            Unit.world_rotation(unit, 1))
        controller_observation.body_ik_torso_axis_unit = unit
        controller_observation.body_ik_torso_axis_local = Vector3Box(
            presentation.rotate_vector(root_inverse, torso_axis))
        mod:info(
            "DARKTIDEVR_IK torso_neutral captured axis_local=%.4f,%.4f,%.4f",
            Vector3.x(controller_observation.body_ik_torso_axis_local:unbox()),
            Vector3.y(controller_observation.body_ik_torso_axis_local:unbox()),
            Vector3.z(controller_observation.body_ik_torso_axis_local:unbox()))
        return true, 0
    end
    local target_axis = presentation.rotate_vector(
        Unit.world_rotation(unit, 1),
        controller_observation.body_ik_torso_axis_local:unbox())
    local current_dot = math.max(-1, math.min(
        1, Vector3.dot(torso_axis, target_axis)))
    if current_dot > 0.999999 then
        return true, math.acos(current_dot)
    end
    local correction = presentation.align_vectors_rotation(
        torso_axis, target_axis)
    if not correction then
        return false, "torso_alignment_invalid"
    end
    local spine_parent = Unit.scene_graph_parent(unit, spine)
    if spine_parent == nil then
        return false, "torso_parent_missing"
    end
    local corrected_world = Quaternion.multiply(
        correction, Unit.world_rotation(unit, spine))
    local corrected_local = Quaternion.multiply(
        presentation.inverse_quaternion(
            Unit.world_rotation(unit, spine_parent)),
        corrected_world)
    Unit.set_local_rotation(unit, spine, corrected_local)
    World.update_unit_and_children(world, unit)
    local corrected_axis = Vector3.normalize(
        Unit.world_position(unit, neck) - Unit.world_position(unit, spine))
    local dot = math.max(-1, math.min(
        1, Vector3.dot(corrected_axis, target_axis)))
    return true, math.acos(dot)
end

function presentation.align_body_shoulders(world, unit)
    local spine_name = "j_spine2"
    local left_name = "j_leftarm"
    local right_name = "j_rightarm"
    if not Unit.has_node(unit, spine_name) or
            not Unit.has_node(unit, left_name) or
            not Unit.has_node(unit, right_name) or
            not controller_observation.body_visual_yaw then
        return false, "nodes_or_heading_unavailable"
    end
    local spine = Unit.node(unit, spine_name)
    local left = Unit.node(unit, left_name)
    local right = Unit.node(unit, right_name)
    local function is_ancestor(ancestor, child)
        local current = Unit.scene_graph_parent(unit, child)
        local depth = 0
        while current ~= nil and depth < 64 do
            if current == ancestor then
                return true
            end
            current = Unit.scene_graph_parent(unit, current)
            depth = depth + 1
        end
        return false
    end
    if not is_ancestor(spine, left) or not is_ancestor(spine, right) then
        return false, "spine2_not_common_arm_ancestor"
    end
    local shoulder_right = Vector3.normalize(
        Unit.world_position(unit, right) - Unit.world_position(unit, left))
    local torso_forward = Vector3.normalize(
        Vector3.cross(Vector3.up(), shoulder_right))
    local desired = Quaternion.axis_angle(
        Vector3.up(), controller_observation.body_visual_yaw)
    local error = math.atan2(
        Vector3.dot(torso_forward, Quaternion.right(desired)),
        Vector3.dot(torso_forward, Quaternion.forward(desired)))
    if math.abs(error) < 0.0005 then
        return true, error
    end
    local spine_parent = Unit.scene_graph_parent(unit, spine)
    if spine_parent == nil then
        return false, "spine2_parent_missing"
    end
    local corrected_world = Quaternion.multiply(
        Quaternion.axis_angle(Vector3.up(), error),
        Unit.world_rotation(unit, spine))
    local corrected_local = Quaternion.multiply(
        presentation.inverse_quaternion(
            Unit.world_rotation(unit, spine_parent)),
        corrected_world)
    Unit.set_local_rotation(unit, spine, corrected_local)
    World.update_unit_and_children(world, unit)
    local corrected_shoulder_right = Vector3.normalize(
        Unit.world_position(unit, right) - Unit.world_position(unit, left))
    local corrected_torso_forward = Vector3.normalize(
        Vector3.cross(Vector3.up(), corrected_shoulder_right))
    local residual = math.atan2(
        Vector3.dot(corrected_torso_forward, Quaternion.right(desired)),
        Vector3.dot(corrected_torso_forward, Quaternion.forward(desired)))
    return true, residual
end

-- Distribute near-limit hand-effector pull over the scaled live rig instead of
-- translating a frozen clavicle pose or dumping the correction into spine2.
-- Each arm independently requests forward shoulder travel. Opposing requests
-- cancel at the girdle, so an equal two-hand reach keeps the shoulders square;
-- either arm alone rotates the chest and gains more reach. A small independent
-- clavicle protraction remains available to both arms. The spine weights act as
-- per-bone rotational stiffness, the total yaw and protraction are anatomically
-- bounded, and every distance derives from the currently scaled skeleton.
function presentation.apply_body_shoulder_reach(
        world, unit, left_target, left_rotation, right_target, right_rotation)
    local reach_state = controller_observation.body_ik_shoulder_reach
    if reach_state.unit ~= unit then
        reach_state = { unit = unit, left = 0, right = 0, last_t = nil }
        controller_observation.body_ik_shoulder_reach = reach_state
    end
    if not controller_observation.body_visual_yaw then
        return false, "heading_unavailable"
    end
    local torso_forward = Quaternion.forward(Quaternion.axis_angle(
        Vector3.up(), controller_observation.body_visual_yaw))
    local targets = {
        left = { target = left_target, rotation = left_rotation },
        right = { target = right_target, rotation = right_rotation }
    }
    local desired = { left = 0, right = 0 }
    local records = {}
    local function is_ancestor(ancestor, child)
        local current = Unit.scene_graph_parent(unit, child)
        for _ = 1, 64 do
            if current == ancestor then
                return true
            end
            if current == nil then
                break
            end
            current = Unit.scene_graph_parent(unit, current)
        end
        return false
    end
    for _, side in ipairs({ "left", "right" }) do
        local shoulder_name = side == "left" and
            "j_leftshoulder" or "j_rightshoulder"
        local arm_name = side == "left" and "j_leftarm" or "j_rightarm"
        local forearm_name = side == "left" and
            "j_leftforearm" or "j_rightforearm"
        local hand_name = side == "left" and "j_lefthand" or "j_righthand"
        if not Unit.has_node(unit, shoulder_name) or
                not Unit.has_node(unit, arm_name) or
                not Unit.has_node(unit, forearm_name) or
                not Unit.has_node(unit, hand_name) then
            return false, side .. "_nodes_missing"
        end
        local shoulder_node = Unit.node(unit, shoulder_name)
        local arm_node = Unit.node(unit, arm_name)
        local forearm_node = Unit.node(unit, forearm_name)
        local hand_node = Unit.node(unit, hand_name)
        local shoulder_parent = Unit.scene_graph_parent(unit, shoulder_node)
        if not is_ancestor(shoulder_node, arm_node) or
                shoulder_parent == nil then
            return false, side .. "_hierarchy_mismatch"
        end
        local target = targets[side].target
        local rotation = targets[side].rotation
        local arm_length = 0
        if target and rotation then
            target = presentation.body_ik_calibrated_wrist_target(
                side, target, rotation)
            local arm_position = Unit.world_position(unit, arm_node)
            local elbow_position = Unit.world_position(unit, forearm_node)
            local hand_position = Unit.world_position(unit, hand_node)
            arm_length =
                presentation.vector_distance(arm_position, elbow_position) +
                presentation.vector_distance(elbow_position, hand_position)
            local target_delta = target - arm_position
            local target_distance = Vector3.length(target_delta)
            if arm_length > 0.05 and target_distance > 0.001 then
                local forward_fraction = math.max(0, Vector3.dot(
                    target_delta / target_distance, torso_forward))
                -- Position-based full-body solvers normally begin sharing an
                -- effector pull before a limb reaches its singular straight
                -- pose. Start at 86% extension and permit the shoulder girdle
                -- to contribute up to 18% of this avatar's actual arm length;
                -- the independently bounded clavicle write below supplies the
                -- visible protraction before the arm solver clamps reach.
                desired[side] = math.min(arm_length * 0.18, math.max(
                    0, target_distance - arm_length * 0.86)) *
                    forward_fraction
            end
        end
        records[side] = {
            node = shoulder_node,
            arm = arm_node,
            parent = shoulder_parent,
            arm_length = arm_length or 0,
            authored_local = Unit.local_position(unit, shoulder_node)
        }
    end
    local now = Managers and Managers.time and Managers.time:time("main") or 0
    local dt = math.clamp(now - (reach_state.last_t or now), 0, 0.1)
    local alpha = 1 - math.exp(-14 * dt)
    for _, side in ipairs({ "left", "right" }) do
        local ceiling = records[side].arm_length * 0.18
        local prior = tonumber(reach_state[side]) or 0
        -- This state is presentation-only and anatomically bounded. Never
        -- allow an invalid/stale value to survive an animation-unit or timing
        -- transition and turn into an effectively unbounded shoulder offset.
        if prior ~= prior or prior < 0 or prior > ceiling then
            prior = 0
        end
        reach_state[side] = math.clamp(
            prior + (desired[side] - prior) * alpha, 0, ceiling)
    end
    reach_state.last_t = now
    local left_position = Unit.world_position(unit, records.left.arm)
    local right_position = Unit.world_position(unit, records.right.arm)
    local current_line = right_position - left_position
    local desired_line =
        right_position + torso_forward * reach_state.right -
        (left_position + torso_forward * reach_state.left)
    current_line = current_line - Vector3.up() *
        Vector3.dot(current_line, Vector3.up())
    desired_line = desired_line - Vector3.up() *
        Vector3.dot(desired_line, Vector3.up())
    local girdle_rotation = presentation.align_vectors_rotation(
        current_line, desired_line)
    if not girdle_rotation then
        return false, "shoulder_line_invalid"
    end
    local requested_yaw = math.clamp(
        Quaternion.yaw(girdle_rotation), -20 * math.pi / 180,
        20 * math.pi / 180)
    local chain = {}
    local weights = { j_spine = 0.15, j_spine1 = 0.30, j_spine2 = 0.55 }
    local limits = { j_spine = 3, j_spine1 = 6, j_spine2 = 11 }
    local total_weight = 0
    for _, name in ipairs({ "j_spine", "j_spine1", "j_spine2" }) do
        if Unit.has_node(unit, name) then
            local node = Unit.node(unit, name)
            local parent = Unit.scene_graph_parent(unit, node)
            if parent ~= nil and is_ancestor(node, records.left.arm) and
                    is_ancestor(node, records.right.arm) then
                chain[#chain + 1] = {
                    name = name,
                    node = node,
                    parent = parent,
                    weight = weights[name],
                    limit = limits[name] * math.pi / 180
                }
                total_weight = total_weight + weights[name]
            end
        end
    end
    if #chain == 0 or total_weight <= 0 then
        return false, "common_spine_chain_missing"
    end
    local chain_result = {}
    for i = 1, #chain do
        local record = chain[i]
        local applied_yaw = math.clamp(
            requested_yaw * record.weight / total_weight,
            -record.limit, record.limit)
        local rotated_world = Quaternion.multiply(
            Quaternion.axis_angle(Vector3.up(), applied_yaw),
            Unit.world_rotation(unit, record.node))
        Unit.set_local_rotation(unit, record.node, Quaternion.multiply(
            presentation.inverse_quaternion(
                Unit.world_rotation(unit, record.parent)),
            rotated_world))
        World.update_unit_and_children(world, unit)
        chain_result[#chain_result + 1] = string.format(
            "%s:%.2f", record.name, applied_yaw * 180 / math.pi)
    end
    for _, side in ipairs({ "left", "right" }) do
        local record = records[side]
        local parent_inverse = presentation.inverse_quaternion(
            Unit.world_rotation(unit, record.parent))
        local local_forward = presentation.rotate_vector(
            parent_inverse, torso_forward)
        local prior_offset_key = side .. "_clavicle_offset"
        local prior_written_key = side .. "_clavicle_written"
        local prior_offset = reach_state[prior_offset_key] and
            reach_state[prior_offset_key]:unbox() or Vector3.zero()
        -- Remove the last post-animation offset if the engine has preserved
        -- it, while also tolerating an authored animation pose reset.
        local authored_local = record.authored_local
        local prior_written = reach_state[prior_written_key] and
            reach_state[prior_written_key]:unbox()
        if prior_written and
                Vector3.length(authored_local - prior_written) < 0.0001 then
            authored_local = authored_local - prior_offset
        end
        local clavicle_reach = math.min(
            record.arm_length * 0.08, reach_state[side] * 0.65)
        local offset = local_forward * clavicle_reach
        Unit.set_local_position(unit, record.node,
            authored_local + offset)
        reach_state[prior_offset_key] = Vector3Box(offset)
        reach_state[prior_written_key] = Vector3Box(authored_local + offset)
    end
    World.update_unit_and_children(world, unit)
    local root_scale = Unit.local_scale(unit, 1)
    reach_state.requested_left = desired.left
    reach_state.requested_right = desired.right
    reach_state.applied_yaw = requested_yaw
    reach_state.chain_result = table.concat(chain_result, ",")
    reach_state.character_scale = Vector3.z(root_scale)
    reach_state.left_arm_length = records.left.arm_length
    reach_state.right_arm_length = records.right.arm_length
    reach_state.shoulder_width = Vector3.length(current_line)
    return true, math.max(desired.left, desired.right),
        reach_state.left, reach_state.right
end

function presentation.log_body_hand_basis(
        unit, side, target_position, target_rotation)
    local hand_name = side == "left" and "j_lefthand" or "j_righthand"
    local hand_node = Unit.node(unit, hand_name)
    local hand_position = Unit.world_position(unit, hand_node)
    local hand_rotation = Unit.world_rotation(unit, hand_node)
    local target_right = Quaternion.right(target_rotation)
    local target_forward = Quaternion.forward(target_rotation)
    local target_up = Quaternion.up(target_rotation)
    local hand_right = Quaternion.right(hand_rotation)
    local hand_forward = Quaternion.forward(hand_rotation)
    local hand_up = Quaternion.up(hand_rotation)
    mod:info(
        "DARKTIDEVR_IK basis side=%s target_pos=%.4f,%.4f,%.4f hand_pos=%.4f,%.4f,%.4f target_rfu=%.3f,%.3f,%.3f/%.3f,%.3f,%.3f/%.3f,%.3f,%.3f hand_rfu=%.3f,%.3f,%.3f/%.3f,%.3f,%.3f/%.3f,%.3f,%.3f",
        side,
        Vector3.x(target_position), Vector3.y(target_position),
        Vector3.z(target_position), Vector3.x(hand_position),
        Vector3.y(hand_position), Vector3.z(hand_position),
        Vector3.x(target_right), Vector3.y(target_right),
        Vector3.z(target_right), Vector3.x(target_forward),
        Vector3.y(target_forward), Vector3.z(target_forward),
        Vector3.x(target_up), Vector3.y(target_up), Vector3.z(target_up),
        Vector3.x(hand_right), Vector3.y(hand_right), Vector3.z(hand_right),
        Vector3.x(hand_forward), Vector3.y(hand_forward),
        Vector3.z(hand_forward), Vector3.x(hand_up),
        Vector3.y(hand_up), Vector3.z(hand_up))
    local landmark_names = side == "left" and {
        "j_lefthandindex1", "j_lefthandmiddle1", "j_lefthandring1",
        "j_lefthandpinky1", "j_leftthumb1", "j_lefthandthumb1",
        "j_leftthumb01", "j_lefthandthumb01", "j_leftweaponattach"
    } or {
        "j_righthandindex1", "j_righthandmiddle1", "j_righthandring1",
        "j_righthandpinky1", "j_rightthumb1", "j_righthandthumb1",
        "j_rightthumb01", "j_righthandthumb01", "j_rightweaponattach"
    }
    for i = 1, #landmark_names do
        local name = landmark_names[i]
        if Unit.has_node(unit, name) then
            local position = Unit.world_position(unit, Unit.node(unit, name))
            mod:info(
                "DARKTIDEVR_IK landmark side=%s name=%s position=%.4f,%.4f,%.4f",
                side, name, Vector3.x(position), Vector3.y(position),
                Vector3.z(position))
        end
    end
    local calibration =
        controller_observation.body_ik_hand_anatomy[side]
    if calibration then
        local longitudinal = presentation.rotate_vector(
            hand_rotation, calibration.longitudinal:unbox())
        local across = presentation.rotate_vector(
            hand_rotation, calibration.across:unbox())
        local palm = presentation.rotate_vector(
            hand_rotation, calibration.palm:unbox())
        local aim_offset = side == "left" and 0 or 18
        local values = controller_observation.values
        local anchor_rotation = Quaternion.from_elements(
            controller_observation.body_anchor_qx,
            controller_observation.body_anchor_qy,
            controller_observation.body_anchor_qz,
            controller_observation.body_anchor_qw)
        local aim_rotation = Quaternion.multiply(
            anchor_rotation,
            Quaternion.from_elements(
                values[aim_offset + 3], values[aim_offset + 4],
                values[aim_offset + 5], values[aim_offset + 6]))
        local aim_forward = Quaternion.forward(aim_rotation)
        mod:info(
            "DARKTIDEVR_IK anatomy side=%s palm_to_grip_right=%.4f across_to_grip_forward=%.4f longitudinal_to_grip_up=%.4f grip_up_to_aim_forward=%.4f grip_forward_to_aim_forward=%.4f",
            side,
            Vector3.dot(palm, target_right),
            Vector3.dot(across, target_forward),
            Vector3.dot(longitudinal, target_up),
            Vector3.dot(target_up, aim_forward),
            Vector3.dot(target_forward, aim_forward))
        if QuickDrawer then
            local length = 0.18
            QuickDrawer:line(hand_position,
                hand_position + palm * length, Color.red())
            QuickDrawer:line(hand_position,
                hand_position + across * length, Color.green())
            QuickDrawer:line(hand_position,
                hand_position + longitudinal * length, Color.blue())
        end
    end
end

function presentation.log_body_spine_chain(unit, phase)
    local node_names = {
        "j_hips", "j_spine", "j_spine1", "j_spine2", "j_spine3",
        "j_neck", "j_head", "j_leftarm", "j_rightarm"
    }
    local values = {}
    local root_yaw = Quaternion.yaw(Unit.world_rotation(unit, 1))
    for i = 1, #node_names do
        local name = node_names[i]
        if Unit.has_node(unit, name) then
            local node = Unit.node(unit, name)
            local local_yaw = Quaternion.yaw(Unit.local_rotation(unit, node))
            local world_yaw = Quaternion.yaw(Unit.world_rotation(unit, node))
            values[#values + 1] = string.format(
                "%s=%.2f/%.2f/%.2f",
                name,
                local_yaw * 180 / math.pi,
                world_yaw * 180 / math.pi,
                math.atan2(math.sin(world_yaw - root_yaw),
                    math.cos(world_yaw - root_yaw)) * 180 / math.pi)
        end
    end
    mod:info(
        "DARKTIDEVR_IK spine phase=%s root_deg=%.2f desired_deg=%.2f nodes_local_world_relative=%s",
        phase,
        root_yaw * 180 / math.pi,
        (controller_observation.body_head_yaw or 0) * 180 / math.pi,
        table.concat(values, ","))
end

function presentation.log_body_alignment(unit)
    if not Unit.has_node(unit, "j_leftarm") or
            not Unit.has_node(unit, "j_rightarm") or
            not Unit.has_node(unit, "j_head") or
            not controller_observation.body_head_yaw then
        return
    end
    local left = Unit.world_position(unit, Unit.node(unit, "j_leftarm"))
    local right = Unit.world_position(unit, Unit.node(unit, "j_rightarm"))
    local head = Unit.world_position(unit, Unit.node(unit, "j_head"))
    local shoulder_right = Vector3.normalize(right - left)
    local torso_forward = Vector3.normalize(
        Vector3.cross(Vector3.up(), shoulder_right))
    local desired = Quaternion.axis_angle(
        Vector3.up(), controller_observation.body_head_yaw)
    local desired_forward = Quaternion.forward(desired)
    local desired_right = Quaternion.right(desired)
    local torso_offset = math.atan2(
        Vector3.dot(torso_forward, desired_right),
        Vector3.dot(torso_forward, desired_forward))
    local model_eye, eye_source =
        presentation.body_model_eye_anchor(unit)
    mod:info(
        "DARKTIDEVR_IK alignment torso_offset_deg=%.2f torso_residual_deg=%.3f shoulder_residual_deg=%.3f head=%.4f,%.4f,%.4f model_eye_source=%s model_eye=%.4f,%.4f,%.4f head_to_eye=%.4f,%.4f,%.4f root_yaw=%.4f desired_yaw=%.4f visual_yaw=%.4f",
        torso_offset * 180 / math.pi,
        (controller_observation.body_ik_torso_residual or 0) *
            180 / math.pi,
        (controller_observation.body_ik_shoulder_residual or 0) *
            180 / math.pi,
        Vector3.x(head), Vector3.y(head), Vector3.z(head),
        tostring(eye_source),
        model_eye and Vector3.x(model_eye) or 0,
        model_eye and Vector3.y(model_eye) or 0,
        model_eye and Vector3.z(model_eye) or 0,
        model_eye and Vector3.x(model_eye - head) or 0,
        model_eye and Vector3.y(model_eye - head) or 0,
        model_eye and Vector3.z(model_eye - head) or 0,
        Quaternion.yaw(Unit.local_rotation(unit, 1)),
        controller_observation.body_head_yaw,
        controller_observation.body_visual_yaw or 0)
end

-- Treat the tracked head/neck as a hard full-body IK constraint.  The torso
-- and shoulder solvers below rotate several spine joints; without a pivot
-- correction those rotations also translate the neck, making an otherwise
-- centred camera feel offset whenever one arm asks for extra reach.  Remove a
-- preserved prior-frame correction before sampling the current authored pose,
-- then restore this frame's neck point after all torso/shoulder writes.
function presentation.begin_body_neck_pivot(world, unit)
    if not Unit.has_node(unit, "j_spine") or
            not Unit.has_node(unit, "j_neck") then
        return nil
    end
    local spine = Unit.node(unit, "j_spine")
    local parent = Unit.scene_graph_parent(unit, spine)
    if parent == nil then
        return nil
    end
    local authored = Unit.local_position(unit, spine)
    local prior_written = presentation.body_neck_pivot_written
    local prior_offset = presentation.body_neck_pivot_offset
    if presentation.body_neck_pivot_unit == unit and prior_written and
            prior_offset and presentation.vector_distance(
                authored, prior_written:unbox()) < 0.0001 then
        authored = authored - prior_offset:unbox()
        Unit.set_local_position(unit, spine, authored)
        World.update_unit_and_children(world, unit)
    end
    if presentation.body_neck_pivot_unit ~= unit then
        presentation.body_neck_pivot_unit = unit
        presentation.body_neck_pivot_offset = nil
        presentation.body_neck_pivot_written = nil
    end
    return Vector3Box(Unit.world_position(
        unit, Unit.node(unit, "j_neck"))), spine, parent,
        Vector3Box(authored)
end

function presentation.restore_body_neck_pivot(
        world, unit, target, spine, parent, authored)
    if not target or not spine or parent == nil or not authored then
        return false, "pivot_unavailable", 0
    end
    local neck = Unit.node(unit, "j_neck")
    local world_delta = target:unbox() - Unit.world_position(unit, neck)
    local local_delta = presentation.rotate_vector(
        presentation.inverse_quaternion(Unit.world_rotation(unit, parent)),
        world_delta)
    local authored_position = authored:unbox()
    Unit.set_local_position(unit, spine, authored_position + local_delta)
    World.update_unit_and_children(world, unit)
    presentation.body_neck_pivot_unit = unit
    presentation.body_neck_pivot_offset = Vector3Box(local_delta)
    presentation.body_neck_pivot_written = Vector3Box(
        authored_position + local_delta)
    return true, "written", Vector3.length(
        target:unbox() - Unit.world_position(unit, neck))
end

function presentation.apply_body_ik(unit, sequence, world, anchor_unit)
    controller_observation.body_ik_presentation_update_frame =
        controller_observation.body_ik_presentation_update_frame + 1
    local update_frame =
        controller_observation.body_ik_presentation_update_frame
    presentation.update_body_ik_presentation_gate(update_frame)
    if not controller_observation.body_ik_presentation_enabled then
        return
    end
    local mode = active_game_mode_name()
    if not presentation.is_first_person_body_mode(mode) then
        if controller_observation.body_ik_presentation_block_reason ~=
                "not_first_person_body_mode" then
            controller_observation.body_ik_presentation_block_reason =
                "not_first_person_body_mode"
            mod:info(
                "DARKTIDEVR_IK presentation_blocked reason=not_first_person_body_mode mode=%s",
                tostring(mode))
        end
        return
    end
    if not world or not unit or not Unit.alive(unit) then
        controller_observation.body_ik_presentation_block_reason =
            not world and "world_unavailable" or "unit_unavailable"
        return
    end
    -- Controllers disabled: no tracked arms at all. The gameplay body's stock
    -- animation keeps its hands and weapons, aimed along the mouse, and the
    -- gloves are placed on those wrists; nothing is written back to them.
    -- Independent rigid hands do not inherit the stock skeleton on update.
    -- During an attack, explicitly follow both animated wrists instead of
    -- simply skipping IK and freezing them at their last tracked positions.
    -- Keyboard and mouse play without a tracked controller does the same all
    -- the time, turned onto the mouse aim, so the hands keep the stock idle,
    -- reload, attack and switch animations instead of freezing.
    local keyboard_mouse_hands = presentation.keyboard_mouse_hands()
    if controller_observation.stock_melee_animation_active or keyboard_mouse_hands then
        -- This frame's anchor: the tracked arms and full-body paths refresh it,
        -- this one did not, so displays placed after it used last frame's
        -- (animation audit, 16 September, item D).
        local anchor_owner = anchor_unit or unit
        presentation.refresh_body_anchor_from_avatar(anchor_owner)
        controller_observation.body_ik_presentation_block_reason =
            keyboard_mouse_hands and "keyboard_mouse" or "stock_melee_animation"
        if presentation.body_proxy and presentation.body_proxy.rigid_hands_active() then
            local aim_rotation = keyboard_mouse_hands and presentation.keyboard_mouse_aim_rotation() or
                presentation.controller_aim.melee_visual_rotation(anchor_unit or unit)
            local followed, left_hand, right_hand =
                presentation.body_proxy.follow_gameplay_hands(world, aim_rotation,
                    keyboard_mouse_hands and presentation.keyboard_mouse_hand_offset() or nil,
                    keyboard_mouse_hands and presentation.keyboard_mouse_hand_pivot(anchor_unit or unit) or nil)
            if followed and aim_rotation and anchor_unit then
                presentation.sync_equipment_hand_to_proxy(anchor_unit, left_hand, "j_lefthand")
                presentation.sync_equipment_hand_to_proxy(anchor_unit, right_hand, "j_righthand")
                World.update_unit_and_children(world, anchor_unit)
            end
        end
        return
    end
    -- ONE BODY (19 September). The full-body path below is the older headless
    -- presentation: it solves the crouch, torso, shoulders and arms on the
    -- body proxy's own upper-body rig. While a full-profile copy owns the
    -- body (BodyProxy.set_hand_rig, from the body overlay) the proxy keeps no
    -- units and hands back the gameplay avatar as `unit`, so this path would
    -- run on the avatar itself -- apply_calibrated_body_height would scale
    -- the gameplay unit -- and the copy re-solves all of it anyway from the
    -- recorded wrist poses. The tracked-hands path is what records those
    -- poses, so it is the path with the flag as without it.
    local body_rig = presentation.body_proxy ~= nil and
        presentation.body_proxy.hand_rig_active ~= nil and
        presentation.body_proxy.hand_rig_active() == true
    if not controller_observation.full_body_experimental_enabled or body_rig then
        presentation.apply_tracked_arms(unit, sequence, world, anchor_unit)
        return
    end
    presentation.trace_body_capture_boundary("body_before")
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    presentation.apply_calibrated_body_height(
        world, unit, local_player)
    -- The animation-extension fixed-update signature is not stable across all
    -- game builds. Run the one-shot rig inventory from this proven player-unit
    -- path too, so a nil/moved fixed-frame argument cannot hide skeleton data.
    presentation.scan_body_rig({ _unit = unit }, nil)
    local emit_spine_trace = controller_observation.body_ik_trace_enabled and
        update_frame >=
        controller_observation.body_ik_spine_trace_frame + 60
    if emit_spine_trace then
        controller_observation.body_ik_spine_trace_frame = update_frame
        presentation.log_body_spine_chain(unit, "before")
    end
    presentation.apply_body_heading(world, unit)
    -- A local-only upper-body proxy is allowed to own the visible torso and
    -- arms, but tracking remains anchored to the authoritative gameplay unit.
    -- Never let the proxy replace the camera/recenter reference.
    presentation.refresh_body_anchor_from_avatar(anchor_unit or unit)
    local crouch_ok, crouch_result, crouch_error =
        presentation.apply_body_crouch(world, unit)
    if not crouch_ok then
        controller_observation.body_ik_presentation_block_reason =
            "crouch_" .. tostring(crouch_result)
        return
    end
    local neck_pivot, neck_spine, neck_parent, neck_authored =
        presentation.begin_body_neck_pivot(world, unit)
    local torso_aligned, torso_result =
        presentation.align_body_torso_neutral(world, unit)
    controller_observation.body_ik_torso_residual =
        torso_aligned and torso_result or nil
    local torso_reason = not torso_aligned and tostring(torso_result) or nil
    if torso_reason ~= controller_observation.body_ik_torso_block_reason then
        controller_observation.body_ik_torso_block_reason = torso_reason
        if torso_reason then
            mod:warning(
                "DARKTIDEVR_IK torso_alignment_blocked reason=%s",
                torso_reason)
        else
            mod:info(
                "DARKTIDEVR_IK torso_alignment=active residual_deg=%.3f",
                torso_result * 180 / math.pi)
        end
    end
    local shoulder_aligned, shoulder_result =
        presentation.align_body_shoulders(world, unit)
    controller_observation.body_ik_shoulder_residual =
        shoulder_aligned and shoulder_result or nil
    local shoulder_reason = not shoulder_aligned and
        tostring(shoulder_result) or nil
    if shoulder_reason ~=
            controller_observation.body_ik_shoulder_block_reason then
        controller_observation.body_ik_shoulder_block_reason = shoulder_reason
        if shoulder_reason then
            mod:warning(
                "DARKTIDEVR_IK shoulder_alignment_blocked reason=%s",
                shoulder_reason)
        else
            mod:info(
                "DARKTIDEVR_IK shoulder_alignment=active residual_deg=%.3f",
                shoulder_result * 180 / math.pi)
        end
    end
    local arm_length_ok, _, arm_length_reason =
        presentation.apply_calibrated_arm_length(world, unit)
    if not arm_length_ok then
        controller_observation.body_ik_presentation_block_reason =
            "arm_length_" .. tostring(arm_length_reason)
        return
    end
    local left_target, left_rotation =
        presentation.body_ik_controller_grip_target(
        unit, "left")
    local right_target, right_rotation =
        presentation.body_ik_controller_grip_target(
        unit, "right")
    local shoulder_reach_ok, shoulder_reach_result,
        shoulder_reach_left, shoulder_reach_right =
            presentation.apply_body_shoulder_reach(
                world, unit, left_target, left_rotation,
                right_target, right_rotation)
    local neck_pivot_ok, neck_pivot_result, neck_pivot_error =
        presentation.restore_body_neck_pivot(
            world, unit, neck_pivot, neck_spine, neck_parent,
            neck_authored)
    controller_observation.body_neck_pivot_result = neck_pivot_result
    controller_observation.body_neck_pivot_error = neck_pivot_error
    if not neck_pivot_ok then
        controller_observation.body_ik_presentation_block_reason =
            "neck_pivot_" .. tostring(neck_pivot_result)
        return
    end
    local shoulder_reach_reason = not shoulder_reach_ok and
        tostring(shoulder_reach_result) or nil
    if shoulder_reach_reason ~=
            controller_observation.body_ik_shoulder_reach_reason then
        controller_observation.body_ik_shoulder_reach_reason =
            shoulder_reach_reason
        if shoulder_reach_reason then
            mod:warning(
                "DARKTIDEVR_IK shoulder_reach_blocked reason=%s",
                shoulder_reach_reason)
        else
            mod:info(
                "DARKTIDEVR_IK shoulder_reach=active requested_m=%.4f applied_m=%.4f,%.4f",
                shoulder_reach_result or 0,
                shoulder_reach_left or 0,
                shoulder_reach_right or 0)
        end
    end
    local wrote = false
    local max_error = 0
    local max_angle_error = 0
    local block_reason = nil
    if left_target then
        local ok, reason, error_metres, angle_error =
            presentation.apply_body_arm_ik(
                world, unit, "left", left_target, left_rotation)
        wrote = wrote or ok
        block_reason = not ok and "left_" .. tostring(reason) or block_reason
        max_error = math.max(max_error, error_metres or 0)
        max_angle_error = math.max(max_angle_error, angle_error or 0)
    end
    if right_target then
        local ok, reason, error_metres, angle_error =
            presentation.apply_body_arm_ik(
                world, unit, "right", right_target, right_rotation)
        wrote = wrote or ok
        block_reason = not ok and "right_" .. tostring(reason) or block_reason
        max_error = math.max(max_error, error_metres or 0)
        max_angle_error = math.max(max_angle_error, angle_error or 0)
    end
    if emit_spine_trace then
        presentation.log_body_spine_chain(unit, "after")
    end
    if wrote then
        presentation.sync_equipment_hands_to_proxy(
            world, anchor_unit, unit)
        controller_observation.body_ik_presentation_writes =
            controller_observation.body_ik_presentation_writes + 1
        controller_observation.body_ik_presentation_max_error = math.max(
            controller_observation.body_ik_presentation_max_error, max_error)
        controller_observation.body_ik_presentation_max_angle_error = math.max(
            controller_observation.body_ik_presentation_max_angle_error,
            max_angle_error)
        block_reason = nil
    end
    if block_reason ~= controller_observation.body_ik_presentation_block_reason then
        controller_observation.body_ik_presentation_block_reason = block_reason
        if block_reason then
            mod:warning("DARKTIDEVR_IK presentation_blocked reason=%s",
                block_reason)
        end
    end
    if wrote and update_frame >=
            controller_observation.body_ik_presentation_last_log_frame +
                (controller_observation.body_ik_trace_enabled and 60 or 600) then
        controller_observation.body_ik_presentation_last_log_frame =
            update_frame
        mod:info(
            "DARKTIDEVR_IK presentation_writes=%d post_error_m=%.6f max_post_error_m=%.6f angle_error_rad=%.6f max_angle_error_rad=%.6f forearm_roll_deg=%.2f,%.2f roll_source=%s,%s twist_writes=%s,%s twist_chain=%s|%s crouch_m=%.4f crouch_result=%s crouch_foot_error_m=%.6f max_crouch_foot_error_m=%.6f hub_lean_m=%.4f,%.4f neck_vertical_m=%.4f,%.4f neck_arc_m=%.4f shoulder_request_m=%.4f,%.4f shoulder_applied_m=%.4f,%.4f shoulder_yaw_deg=%.2f shoulder_chain=%s character_scale=%.4f arm_length_m=%.4f,%.4f shoulder_width_m=%.4f sequence=%d",
            controller_observation.body_ik_presentation_writes,
            max_error,
            controller_observation.body_ik_presentation_max_error,
            max_angle_error,
            controller_observation.body_ik_presentation_max_angle_error,
            (controller_observation.body_ik_left_forearm_roll or 0) *
                180 / math.pi,
            (controller_observation.body_ik_right_forearm_roll or 0) *
                180 / math.pi,
            tostring(controller_observation.body_ik_left_roll_source),
            tostring(controller_observation.body_ik_right_roll_source),
            tostring(controller_observation.body_ik_left_twist_writes or 0),
            tostring(controller_observation.body_ik_right_twist_writes or 0),
            tostring(controller_observation.body_ik_left_twist_chain),
            tostring(controller_observation.body_ik_right_twist_chain),
            controller_observation.body_ik_crouch_offset or 0,
            tostring(crouch_result),
            crouch_error or 0,
            controller_observation.body_ik_crouch_max_foot_error or 0,
            controller_observation.hub_head_requested_horizontal or 0,
            controller_observation.hub_head_applied_horizontal or 0,
            controller_observation.body_ik_neck_raw_vertical or 0,
            controller_observation.body_ik_neck_compensated_vertical or 0,
            controller_observation.body_ik_neck_arc_vertical or 0,
            controller_observation.body_ik_shoulder_reach.requested_left or 0,
            controller_observation.body_ik_shoulder_reach.requested_right or 0,
            controller_observation.body_ik_shoulder_reach.left or 0,
            controller_observation.body_ik_shoulder_reach.right or 0,
            (controller_observation.body_ik_shoulder_reach.applied_yaw or 0) *
                180 / math.pi,
            tostring(controller_observation.body_ik_shoulder_reach.chain_result),
            controller_observation.body_ik_shoulder_reach.character_scale or 1,
            controller_observation.body_ik_shoulder_reach.left_arm_length or 0,
            controller_observation.body_ik_shoulder_reach.right_arm_length or 0,
            controller_observation.body_ik_shoulder_reach.shoulder_width or 0,
            sequence or controller_observation.last_sequence)
        if controller_observation.body_ik_trace_enabled and
                left_target and left_rotation then
            presentation.log_body_hand_basis(
                unit, "left", left_target, left_rotation)
        end
        if controller_observation.body_ik_trace_enabled and
                right_target and right_rotation then
            presentation.log_body_hand_basis(
                unit, "right", right_target, right_rotation)
        end
        if controller_observation.body_ik_trace_enabled then
            presentation.log_body_alignment(unit)
        end
    end
    presentation.trace_body_capture_boundary("body_after")
end

function presentation.update_stock_melee_animation_owner(self)
    local slot_name = self._inventory_component and
        self._inventory_component.wielded_slot
    local weapon = slot_name and self._weapons and self._weapons[slot_name]
    local template = weapon and weapon.weapon_template
    local action_component = self._weapon_action_component
    local action_name = action_component and
        action_component.current_action_name or "none"
    local action = template and template.actions and
        template.actions[action_name]
    local kind = action and action.kind
    -- The player's "Melee animations" setting is consulted here rather than
    -- inside uses_stock_melee_animation, which answers the different question
    -- of whether THIS action kind is one the stock animation owns. Keyboard
    -- and mouse takes the same route: this flag is the gate both paths read
    -- (see stock_melee_animation_active).
    local melee_animations = mod.get and mod:get("vr_melee_animations")
    local active = action_name ~= "none" and
        presentation.body_proxy.stock_melee_animation_allowed(
            kind, melee_animations) and
        presentation.body_proxy.uses_stock_melee_animation(
            slot_name, kind, action, template and template.actions)
    if active ~= controller_observation.stock_melee_animation_active or
            (active and action_name ~=
                controller_observation.stock_melee_animation_action) then
        controller_observation.stock_melee_animation_active = active
        controller_observation.stock_melee_animation_action =
            active and action_name or nil
        controller_observation.stock_melee_animation_kind =
            active and kind or nil
        mod:info(
            "DARKTIDEVR_ARMS animation_owner=%s slot=%s action=%s kind=%s",
            active and "stock_melee" or "tracked_proxy",
            tostring(slot_name), tostring(action_name), tostring(kind))
    end
end

function presentation.trace_body_ik(self, fixed_frame)
    if not fixed_frame or not Mods or not Mods.lua or not Mods.lua.io or
            not ui_native_capture then
        return
    end
    presentation.update_body_ik_trace_gate(fixed_frame)
    if not controller_observation.body_ik_trace_enabled or
            fixed_frame < controller_observation.body_ik_trace_last_log_frame + 15 then
        return
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    if not local_player or self._unit ~= local_player.player_unit or
            not Unit.alive(self._unit) then
        return
    end
    local left_target = presentation.body_ik_controller_grip_target(
        self._unit, "left")
    local right_target = presentation.body_ik_controller_grip_target(
        self._unit, "right")
    if not left_target and not right_target then
        return
    end
    controller_observation.body_ik_trace_last_log_frame = fixed_frame
    if left_target then
        presentation.trace_body_arm(self._unit, "left", left_target)
    end
    if right_target then
        presentation.trace_body_arm(self._unit, "right", right_target)
    end
end

function presentation.trace_weapon_pose(self, fixed_frame)
    if not fixed_frame or not Mods or not Mods.lua or not Mods.lua.io then
        return
    end
    if fixed_frame >=
            controller_observation.weapon_pose_trace_last_check_frame + 60 then
        controller_observation.weapon_pose_trace_last_check_frame = fixed_frame
        local flag_path =
            "./../mods/darktidevr/darktidevr_weapon_pose_trace.flag"
        local flag = Mods.lua.io.open(flag_path, "r")
        local enabled = false
        if flag then
            enabled = flag:read("*all"):match("^%s*enabled%s*$") ~= nil
            flag:close()
        end
        if enabled ~= controller_observation.weapon_pose_trace_enabled then
            controller_observation.weapon_pose_trace_enabled = enabled
            mod:info(
                "DARKTIDEVR_WEAPON pose_trace=%s source=test_flag",
                enabled and "enabled" or "disabled")
        end
    end
    if not controller_observation.weapon_pose_trace_enabled or
            fixed_frame <
                controller_observation.weapon_pose_trace_last_log_frame + 15 then
        return
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    if not local_player or self._unit ~= local_player.player_unit or
            not controller_observation.right_grip_usable or
            not controller_observation.body_anchor_qw then
        return
    end
    local first_person_unit = self._first_person_unit
    if not first_person_unit or not Unit.alive(first_person_unit) or
            not Unit.has_node(first_person_unit, "j_righthand") or
            not Unit.has_node(first_person_unit, "j_rightweaponattach") then
        return
    end
    local slot_name = self._inventory_component and
        self._inventory_component.wielded_slot
    local weapon = slot_name and self._weapons and self._weapons[slot_name]
    local weapon_unit = weapon and weapon.weapon_unit
    if not weapon_unit or not Unit.alive(weapon_unit) then
        return
    end
    controller_observation.weapon_pose_trace_last_log_frame = fixed_frame
    local target_position, target_rotation =
        presentation.controller_grip_target()
    local hand_node = Unit.node(first_person_unit, "j_righthand")
    local attach_node = Unit.node(first_person_unit, "j_rightweaponattach")
    local hand_position = Unit.world_position(first_person_unit, hand_node)
    local attach_position = Unit.world_position(first_person_unit, attach_node)
    local weapon_position = Unit.world_position(weapon_unit, 1)
    local target_yaw, target_pitch, target_roll =
        Quaternion.to_yaw_pitch_roll(target_rotation)
    mod:info(
        "DARKTIDEVR_WEAPON pose frame=%s sequence=%d target=%.4f,%.4f,%.4f target_ypr=%.4f,%.4f,%.4f hand=%.4f,%.4f,%.4f attach=%.4f,%.4f,%.4f weapon=%.4f,%.4f,%.4f target_hand_m=%.4f target_weapon_m=%.4f attach_weapon_m=%.6f",
        tostring(fixed_frame), controller_observation.last_sequence,
        Vector3.x(target_position), Vector3.y(target_position),
        Vector3.z(target_position), target_yaw, target_pitch, target_roll,
        Vector3.x(hand_position), Vector3.y(hand_position),
        Vector3.z(hand_position), Vector3.x(attach_position),
        Vector3.y(attach_position), Vector3.z(attach_position),
        Vector3.x(weapon_position), Vector3.y(weapon_position),
        Vector3.z(weapon_position),
        presentation.vector_distance(target_position, hand_position),
        presentation.vector_distance(target_position, weapon_position),
        presentation.vector_distance(attach_position, weapon_position))
end

function presentation.update_weapon_presentation_gate(fixed_frame)
    if fixed_frame <
            controller_observation.weapon_presentation_last_check_frame + 60 then
        return
    end
    controller_observation.weapon_presentation_last_check_frame = fixed_frame
    local flag_path =
        "./../mods/darktidevr/darktidevr_weapon_presentation.flag"
    local flag = Mods.lua.io.open(flag_path, "r")
    local enabled = false
    if flag then
        enabled = flag:read("*all"):match("^%s*enabled%s*$") ~= nil
        flag:close()
    end
    if enabled ~= controller_observation.weapon_presentation_enabled then
        controller_observation.weapon_presentation_enabled = enabled
        controller_observation.weapon_presentation_block_reason = nil
        mod:info(
            "DARKTIDEVR_WEAPON presentation=%s source=test_flag writes=%d",
            enabled and "enabled" or "disabled",
            controller_observation.weapon_presentation_writes)
    end
end

function presentation.author_weapon_pose(self, fixed_frame, world)
    if controller_observation.stock_melee_animation_active then
        return
    end
    if not fixed_frame or not Mods or not Mods.lua or not Mods.lua.io then
        return
    end
    presentation.update_weapon_presentation_gate(fixed_frame)
    if not controller_observation.weapon_presentation_enabled then
        return
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    local mode = active_game_mode_name()
    if not local_player or self._unit ~= local_player.player_unit or
            (mode ~= "shooting_range" and mode ~= "training_grounds") then
        return
    end
    local first_person_unit = self._first_person_unit
    if not first_person_unit or not Unit.alive(first_person_unit) or
            not Unit.has_node(first_person_unit, "j_righthand") then
        return
    end
    local target_position, target_rotation =
        presentation.controller_grip_target()
    if not target_position or not target_rotation then
        return
    end
    local hand_node = Unit.node(first_person_unit, "j_righthand")
    local root_node, root_depth =
        presentation.scene_graph_root(first_person_unit, hand_node)
    local root_position = Unit.world_position(first_person_unit, root_node)
    local root_local_position = Unit.local_position(first_person_unit, root_node)
    local hand_position = Unit.world_position(first_person_unit, hand_node)
    local hand_rotation = Unit.world_rotation(first_person_unit, hand_node)
    local requested_displacement =
        presentation.vector_distance(target_position, hand_position)
    local root_space_error =
        presentation.vector_distance(root_position, root_local_position)
    local block_reason = nil
    if root_space_error > 0.001 then
        block_reason = "parented_root"
    end
    if block_reason then
        if block_reason ~=
                controller_observation.weapon_presentation_block_reason then
            controller_observation.weapon_presentation_block_reason = block_reason
            mod:warning(
                "DARKTIDEVR_WEAPON presentation_blocked reason=%s displacement_m=%.4f root_space_error_m=%.6f sequence=%d",
                block_reason, requested_displacement, root_space_error,
                controller_observation.last_sequence)
        end
        return
    end
    controller_observation.weapon_presentation_block_reason = nil
    -- Synthetic and real controller tracking can place the grip outside the
    -- avatar's reachable envelope. Dropping the write made the weapon snap to
    -- its stock animation for those frames. Clamp only the rendered 1P rig to
    -- a continuous boundary; gameplay aim/origin/reach remain engine-owned.
    local visual_reach_limit = 0.75
    local clamped = requested_displacement > visual_reach_limit
    if clamped then
        target_position = hand_position +
            (target_position - hand_position) *
                (visual_reach_limit / requested_displacement)
        controller_observation.weapon_presentation_clamps =
            controller_observation.weapon_presentation_clamps + 1
    end
    local displacement = math.min(requested_displacement, visual_reach_limit)
    local delta_rotation = Quaternion.multiply(
        target_rotation,
        presentation.inverse_quaternion(hand_rotation))
    local hand_from_root = hand_position - root_position
    local new_root_position = target_position -
        presentation.rotate_vector(delta_rotation, hand_from_root)
    local root_rotation = Unit.world_rotation(first_person_unit, root_node)
    local new_root_rotation = Quaternion.multiply(delta_rotation, root_rotation)
    Unit.set_local_position(first_person_unit, root_node, new_root_position)
    Unit.set_local_rotation(first_person_unit, root_node, new_root_rotation)
    if world then
        World.update_unit_and_children(world, first_person_unit)
    end
    local post_hand_position = Unit.world_position(first_person_unit, hand_node)
    local post_hand_rotation = Unit.world_rotation(first_person_unit, hand_node)
    local post_error =
        presentation.vector_distance(target_position, post_hand_position)
    controller_observation.weapon_presentation_max_post_error = math.max(
        controller_observation.weapon_presentation_max_post_error,
        post_error)
    controller_observation.weapon_presentation_writes =
        controller_observation.weapon_presentation_writes + 1
    if fixed_frame >=
            controller_observation.weapon_presentation_last_log_frame + 60 then
        controller_observation.weapon_presentation_last_log_frame = fixed_frame
        local target_yaw, target_pitch, target_roll =
            Quaternion.to_yaw_pitch_roll(target_rotation)
        local post_yaw, post_pitch, post_roll =
            Quaternion.to_yaw_pitch_roll(post_hand_rotation)
        local slot_name = self._inventory_component and
            self._inventory_component.wielded_slot
        local weapon = slot_name and self._weapons and self._weapons[slot_name]
        local weapon_unit = weapon and weapon.weapon_unit
        local attach_weapon_error = -1
        if weapon_unit and Unit.alive(weapon_unit) and
                Unit.has_node(first_person_unit, "j_rightweaponattach") then
            local attach_position = Unit.world_position(
                first_person_unit,
                Unit.node(first_person_unit, "j_rightweaponattach"))
            attach_weapon_error = presentation.vector_distance(
                attach_position, Unit.world_position(weapon_unit, 1))
        end
        mod:info(
            "DARKTIDEVR_WEAPON presentation_write frame=%s sequence=%d root_node=%s root_depth=%d requested_m=%.4f displacement_m=%.4f clamped=%s clamps=%d post_error_m=%.6f max_post_error_m=%.6f attach_weapon_m=%.6f target_ypr=%.4f,%.4f,%.4f post_ypr=%.4f,%.4f,%.4f root_space_error_m=%.6f writes=%d",
            tostring(fixed_frame), controller_observation.last_sequence,
            tostring(root_node), root_depth, requested_displacement,
            displacement, tostring(clamped),
            controller_observation.weapon_presentation_clamps, post_error,
            controller_observation.weapon_presentation_max_post_error,
            attach_weapon_error,
            target_yaw, target_pitch, target_roll,
            post_yaw, post_pitch, post_roll,
            root_space_error,
            controller_observation.weapon_presentation_writes)
    end
end

mod:hook_safe(
    "PlayerUnitWeaponExtension",
    "fixed_update",
    function(self, _, _, t, fixed_frame)
        presentation.scan_weapon_inventory(self, fixed_frame)
        presentation.trace_weapon_pose(self, fixed_frame)
        if presentation.melee_live_probe then
            presentation.melee_live_probe.fixed_update(self, t, fixed_frame)
        end
        if not controller_observation.primary_action_cache_observed then
            return
        end
        local cache_frame = controller_observation.primary_action_cache_frame
        if not cache_frame or fixed_frame < cache_frame or
                fixed_frame > cache_frame + 30 then
            return
        end
        local local_player = Managers and Managers.player and
            Managers.player:local_player(1)
        if not local_player or self._unit ~= local_player.player_unit then
            return
        end
        local action_component = self._weapon_action_component
        local action_name = action_component and
            action_component.current_action_name
        if not controller_observation.primary_action_weapon_context_logged then
            local slot = self._inventory_component and
                self._inventory_component.wielded_slot
            local weapon = slot and self._weapons and self._weapons[slot]
            local template = weapon and weapon.weapon_template
            controller_observation.primary_action_weapon_context_logged = true
            mod:info(
                "DARKTIDEVR_INPUT primary_action context slot=%s template=%s action=%s frame=%s sequence=%d",
                tostring(slot),
                tostring(template and template.name),
                tostring(action_name),
                tostring(fixed_frame),
                controller_observation.primary_action_sequence
            )
        end
        if action_name and action_name ~= "none" and
                not controller_observation.primary_action_weapon_observed then
            controller_observation.primary_action_weapon_observed = true
            mod:info(
                "DARKTIDEVR_INPUT primary_action weapon_action=%s frame=%s start_t=%.4f sequence=%d",
                tostring(action_name),
                tostring(fixed_frame),
                tonumber(action_component.start_t) or 0,
                controller_observation.primary_action_sequence
            )
        end
        if controller_observation.primary_action_shot_observed then
            return
        end
        local shoot_component = self._action_shoot_component
        local shots = shoot_component and shoot_component.num_shots_fired or 0
        if shots <= 0 or not shoot_component.shooting_rotation then
            return
        end
        local ok, yaw, pitch, roll = pcall(
            Quaternion.to_yaw_pitch_roll,
            shoot_component.shooting_rotation
        )
        if not ok then
            mod:warning(
                "DARKTIDEVR_INPUT primary_action shot_rotation_unavailable=%s",
                tostring(yaw)
            )
            return
        end
        local forward = Quaternion.forward(shoot_component.shooting_rotation)
        local position = shoot_component.shooting_position
        controller_observation.primary_action_shot_observed = true
        mod:info(
            "DARKTIDEVR_INPUT primary_action shot frame=%s shots=%d shooting_ypr=%.4f,%.4f,%.4f shooting_forward=%.4f,%.4f,%.4f shooting_position=%.4f,%.4f,%.4f authored_forward=%.4f,%.4f,%.4f sequence=%d",
            tostring(fixed_frame),
            shots,
            yaw,
            pitch,
            roll,
            Vector3.x(forward),
            Vector3.y(forward),
            Vector3.z(forward),
            Vector3.x(position),
            Vector3.y(position),
            Vector3.z(position),
            controller_observation.downstream_forward_x or 0,
            controller_observation.downstream_forward_y or 0,
            controller_observation.downstream_forward_z or 0,
            controller_observation.primary_action_sequence
        )
    end)

mod:hook_safe(
    "PlayerUnitAnimationExtension",
    "fixed_update",
    function(self, _, _, _, fixed_frame)
        presentation.scan_body_rig(self, fixed_frame)
        presentation.trace_body_ik(self, fixed_frame)
    end)

function presentation.observe_primary_projectile(self, direction, source)
    if not controller_observation.primary_action_cache_observed or
            controller_observation.primary_action_projectile_observed or
            not direction then
        return
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    if not local_player or self._owner_unit ~= local_player.player_unit then
        return
    end
    local ok, x, y, z = pcall(function()
        local length = Vector3.length(direction)
        if length <= 0 then
            return nil
        end
        local normalized = direction / length
        return Vector3.x(normalized), Vector3.y(normalized), Vector3.z(normalized)
    end)
    if not ok or x == nil then
        mod:warning(
            "DARKTIDEVR_INPUT primary_action projectile_direction_unavailable source=%s error=%s",
            tostring(source), tostring(x))
        return
    end
    controller_observation.primary_action_projectile_observed = true
    mod:info(
        "DARKTIDEVR_INPUT primary_action projectile source=%s direction=%.4f,%.4f,%.4f authored_forward=%.4f,%.4f,%.4f sequence=%d",
        tostring(source), x, y, z,
        controller_observation.downstream_forward_x or 0,
        controller_observation.downstream_forward_y or 0,
        controller_observation.downstream_forward_z or 0,
        controller_observation.primary_action_sequence
    )
end

mod:hook_safe(
    "ProjectileUnitLocomotionExtension",
    "switch_to_manual_physics",
    function(self, _, _, direction)
        presentation.observe_primary_projectile(
            self, direction, "manual_physics")
    end)

mod:hook_safe(
    "ProjectileUnitLocomotionExtension",
    "switch_to_true_flight",
    function(self, _, _, direction)
        presentation.observe_primary_projectile(
            self, direction, "true_flight")
    end)

mod:hook_safe(
    "ProjectileUnitLocomotionExtension",
    "switch_to_engine_physics",
    function(self, _, _, velocity)
        presentation.observe_primary_projectile(
            self, velocity, "engine_physics")
    end)

presentation.player_unit_visual_loadout_extension = require(
    "scripts/extension_systems/visual_loadout/player_unit_visual_loadout_extension")

-- Perspectives 1.14 proves that hub first person is selected before the player
-- unit is built: the mission's force-third-person answer is overridden, then
-- the stock first-person extension initializes normally. Do the same here
-- instead of repairing an already-created extension every frame.
-- Called from per-unit first-person hooks every fixed and render update, so
-- the flag file is re-read at most once per second rather than per call.
local hub_first_person_flag_value = false
local hub_first_person_flag_polled_at = nil
function presentation.hub_first_person_requested()
    local now = os.time()
    if hub_first_person_flag_polled_at == now then
        return hub_first_person_flag_value
    end
    hub_first_person_flag_polled_at = now
    local path =
        "./../mods/darktidevr/darktidevr_headless_body.flag"
    local flag = Mods and Mods.lua and Mods.lua.io and Mods.lua.io.open(path, "r")
    if not flag then
        -- Play default: first person in the hub unless the option asks for
        -- the stock third-person body there.
        hub_first_person_flag_value = not presentation.hub_third_person_active()
        return hub_first_person_flag_value
    end
    local text = flag:read("*all")
    flag:close()
    hub_first_person_flag_value = text ~= nil and
        text:match("^%s*enabled%s*$") ~= nil and
        not presentation.hub_third_person_active()
    return hub_first_person_flag_value
end

-- DMF writes mod settings to disk only on a game-state change or a normal
-- exit, so a force-quit after toggling this option lost it. Flush at once.
do
    local previous_setting_changed = mod.on_setting_changed
    mod.on_setting_changed = function(setting_id, ...)
        if previous_setting_changed then previous_setting_changed(setting_id, ...) end
        if setting_id == "hub_third_person" then
            local dmf = rawget(_G, "get_mod") and get_mod("dmf")
            if dmf and dmf.save_unsaved_settings_to_file then
                pcall(dmf.save_unsaved_settings_to_file)
            end
        end
    end
end

-- In-engine cinematics presented in stereo (mod setting, default on): only
-- while the cinematic manager reports a playing cutscene camera; videos and
-- loading screens keep the flat panel.
function presentation.cinematic_stereo_active()
    if mod:get("stereo_cinematics") == false then
        return false
    end
    local cinematic = Managers and Managers.state and Managers.state.cinematic
    if not cinematic or not cinematic.is_playing then
        return false
    end
    local ok, playing = pcall(cinematic.is_playing, cinematic)
    return ok and playing == true
end

-- Optional stock third-person body in the hub (mod setting). Combat modes
-- keep the first-person body regardless.
-- True in the onboarding hub missions, whose game mode reports as
-- prologue_hub before the mod maps it to the hub.
function presentation.onboarding_hub_active()
    local game_mode = Managers and Managers.state and Managers.state.game_mode
    local ok, name = pcall(function() return game_mode:game_mode_name() end)
    return ok and name == "prologue_hub"
end

function presentation.hub_third_person_active()
    if mod:get("hub_third_person") ~= true then
        return false
    end
    if active_game_mode_name() == "hub" then
        return true
    end
    -- The MissionManager hook asks before the game mode exists; the mission
    -- name already identifies the hub then.
    local mission_manager = Managers and Managers.state and Managers.state.mission
    return mission_manager ~= nil and mission_manager.mission_name ~= nil and
        mission_manager:mission_name() == "hub_ship"
end

-- Bounded diagnostic at the actual two-eye submission boundaries. This
-- distinguishes animation reclaim between game frames from a mutation caused
-- by either render submission. It is intentionally active only with the body
-- IK trace flag and genuine stick locomotion, and stops after 90 frame pairs so
-- logging cannot become a persistent performance cost.
function presentation.trace_body_capture_boundary(phase)
    if not controller_observation.body_ik_trace_enabled or
            not controller_observation.gameplay_stick_active then
        return
    end
    if phase == "body_before" then
        controller_observation.body_capture_trace_sample =
            (controller_observation.body_capture_trace_sample or 0) + 1
    end
    local sample = controller_observation.body_capture_trace_sample or 0
    if sample < 1 or sample > 90 then
        return
    end
    local local_player = Managers and Managers.player and
        Managers.player:local_player(1)
    local unit = local_player and local_player.player_unit
    if not unit or not Unit.alive(unit) or
            not Unit.has_node(unit, "j_hips") or
            not Unit.has_node(unit, "j_spine2") or
            not Unit.has_node(unit, "j_neck") then
        return
    end
    local root_position = Unit.world_position(unit, 1)
    local hips = Unit.node(unit, "j_hips")
    local spine = Unit.node(unit, "j_spine2")
    local neck = Unit.node(unit, "j_neck")
    local hips_position = Unit.world_position(unit, hips)
    local spine_position = Unit.world_position(unit, spine)
    local neck_position = Unit.world_position(unit, neck)
    local root_yaw = Quaternion.yaw(Unit.world_rotation(unit, 1))
    local hips_yaw = Quaternion.yaw(Unit.world_rotation(unit, hips))
    local spine_yaw = Quaternion.yaw(Unit.world_rotation(unit, spine))
    local arm_values = {}
    for _, name in ipairs({ "j_leftarm", "j_leftforearm", "j_lefthand",
            "j_rightarm", "j_rightforearm", "j_righthand" }) do
        if Unit.has_node(unit, name) then
            local node = Unit.node(unit, name)
            local position = Unit.world_position(unit, node)
            arm_values[#arm_values + 1] = string.format(
                "%s:%.5f,%.5f,%.5f,%.5f", name,
                Vector3.x(position), Vector3.y(position), Vector3.z(position),
                Quaternion.yaw(Unit.world_rotation(unit, node)))
        end
    end
    mod:info(
        "DARKTIDEVR_IK_CAPTURE sample=%d phase=%s root=%.5f,%.5f,%.5f hips=%.5f,%.5f,%.5f spine=%.5f,%.5f,%.5f neck=%.5f,%.5f,%.5f yaw=%.5f,%.5f,%.5f crouch=%.5f arms=%s",
        sample, phase,
        Vector3.x(root_position), Vector3.y(root_position),
        Vector3.z(root_position), Vector3.x(hips_position),
        Vector3.y(hips_position), Vector3.z(hips_position),
        Vector3.x(spine_position), Vector3.y(spine_position),
        Vector3.z(spine_position), Vector3.x(neck_position),
        Vector3.y(neck_position), Vector3.z(neck_position),
        root_yaw, hips_yaw, spine_yaw,
        controller_observation.body_ik_crouch_offset or 0,
        table.concat(arm_values, "|"))
end

mod:hook(
    require("scripts/managers/mission/mission_manager"),
    "force_third_person_mode",
    function(func, self, ...)
        -- The hub and the onboarding hub missions both force third person
        -- in stock; the first-person body request overrides either.
        if presentation.hub_first_person_requested() and
                (self:mission_name() == "hub_ship" or
                    presentation.onboarding_hub_active()) then
            return false
        end
        return func(self, ...)
    end)

-- HumanGameplay, not PlayerUnitFirstPersonExtension, owns the orientation
-- instances. Its init asks GameModeManager for this class name before creating
-- the objects, so answer with the normal gameplay orientation at that boundary.
mod:hook(
    require("scripts/managers/game_mode/game_mode_manager"),
    "default_player_orientation",
    function(func, self, ...)
        if presentation.hub_first_person_requested() and
                self:game_mode_name() == "hub" then
            return "DefaultPlayerOrientation"
        end
        return func(self, ...)
    end)

-- Hub locomotion remains server-authoritative. The public hub server publishes
-- hub_jog and reconciles any locally predicted walking/sprinting position every
-- network tick. Keep that stock state end-to-end so collision, animation and
-- replication agree. VR still owns camera orientation, 6DoF body following and
-- post-animation IK; mission-style locomotion remains active in gameplay maps.

-- Stock hub_jog converts its cardinal input through first_person.rotation.
-- That shared component is also owned by hub aim/orientation and can retain a
-- stale heading across UI or controller-tracking transitions. Convert only the
-- local VR player's hub movement through the persistent gameplay heading. It
-- comes from the rendered cyclopean pose in Darktide's orientation coordinate
-- system, so shop cameras cannot rotate it and it remains the
-- same frame consumed by interaction-facing checks. The server remains
-- authoritative for acceleration, collision, animation and replication.
function presentation.flat_movement_rotation(yaw)
    local yaw_rotation = Quaternion.from_yaw_pitch_roll(yaw, 0, 0)
    local right = Quaternion.right(yaw_rotation)
    local flat_forward = Vector3.cross(right, Vector3.down())
    return Quaternion.look(flat_forward, Vector3.up())
end

-- The off hand's heading, for off-hand-relative locomotion. The saved setting
-- still stores the literal value "left_hand", so settings written before the
-- handedness work keep working; only what it means moved to a role
-- (docs/phase1/handedness-audit-2026-09-16.md).
function presentation.off_hand_movement_rotation()
    if not presentation.hand_aim_usable("support") then
        return nil
    end
    local _, rotation = presentation.weapon_aim_target("support")
    if not rotation then
        return nil
    end
    -- Derive heading from the projected ray rather than Euler yaw. That keeps
    -- controller roll out of locomotion and rejects the undefined heading when
    -- the hand points almost vertically.
    local forward = Quaternion.forward(rotation)
    local flat_forward = Vector3(
        Vector3.x(forward), Vector3.y(forward), 0)
    if Vector3.length_squared(flat_forward) < 0.0025 then
        return nil
    end
    return Quaternion.look(Vector3.normalize(flat_forward), Vector3.up())
end

function presentation.off_hand_movement_yaw()
    local rotation = presentation.off_hand_movement_rotation()
    return rotation and Quaternion.yaw(rotation) or nil
end

function presentation.movement_reference_rotation()
    if (mod:get("movement_reference") or "head") == "left_hand" then
        local off_hand_rotation = presentation.off_hand_movement_rotation()
        if left_rotation then
            return off_hand_rotation, "left_hand"
        end
        return controller_observation.gameplay_yaw and
            presentation.flat_movement_rotation(
                controller_observation.gameplay_yaw) or nil,
            "head_fallback"
    end
    return controller_observation.gameplay_yaw and
        presentation.flat_movement_rotation(
            controller_observation.gameplay_yaw) or nil, "head"
end

function presentation.movement_reference_yaw()
    local rotation, reference = presentation.movement_reference_rotation()
    return rotation and Quaternion.yaw(rotation) or
        controller_observation.gameplay_yaw, reference
end

function presentation.controller_movement_is_device_axis()
    local player = Managers and Managers.player and Managers.player:local_player(1)
    local unit = player and player.player_unit
    if not unit or not Unit.alive(unit) then return false end
    local extension = ScriptUnit.has_extension(unit, "character_state_machine_system")
    return presentation.gameplay_context.device_axes(extension)
end

function presentation.rotate_controller_movement(x, y)
    if not controller_observation.gameplay_yaw or
            (mod:get("movement_reference") or "head") ~= "left_hand" then
        return x, y
    end
    -- The scanner's minigame consumes `move` as a knob/axis, not locomotion.
    -- Query the current local state; never reuse the throttled diagnostic name.
    -- Player/state lookup can retire before the protected state-name query.
    -- Keep the existing missing-state fallback without aborting input caching.
    local device_ok, device_axis = pcall(presentation.controller_movement_is_device_axis)
    if device_ok and device_axis then return x, y end
    local reference_rotation = presentation.off_hand_movement_rotation()
    if not reference_rotation then
        return x, y
    end
    local local_direction = Vector3(x, y, 0)
    if Vector3.length_squared(local_direction) < 0.00000001 then
        return x, y
    end
    local desired_world = Quaternion.rotate(
        reference_rotation, local_direction)
    local head_local = Quaternion.rotate(
        Quaternion.inverse(presentation.flat_movement_rotation(
            controller_observation.gameplay_yaw)), desired_world)
    return Vector3.x(head_local), Vector3.y(head_local)
end

mod:hook(
    require(
        "scripts/extension_systems/character_state_machine/character_states/player_character_state_hub_jog"),
    "_input_to_move_direction",
    function(func, self, x, y, first_person_component, ...)
        if presentation.hub_first_person_requested() and
                presentation.current_game_mode_name() == "hub" and
                controller_observation.gameplay_yaw then
            local local_direction = Vector3.normalize(Vector3(x, y, 0))
            local movement_rotation = presentation.movement_reference_rotation()
            -- Match stock hub_jog's basis construction exactly. Stingray's
            -- yaw and axis-angle conventions are not interchangeable here.
            return Quaternion.rotate(
                movement_rotation, local_direction)
        end
        return func(self, x, y, first_person_component, ...)
    end)

-- Darktide blends a separate full-body idle layer after the character has
-- stopped. Some variants contain a small lateral step that moves the rendered
-- body away from a stationary physical head. Suppress only that layer for the
-- local VR hub body; the underlying breathing/stance animation and all moving
-- locomotion animation remain authored by the game.
mod:hook(
    require(
        "scripts/extension_systems/aim/third_person_idle_fullbody_animation_control"),
    "update",
    function(func, self, dt, t, ...)
        local local_player = Managers and Managers.player and
            Managers.player:local_player(1)
        if controller_observation.body_visibility_enabled and
                presentation.is_first_person_body_mode(
                    presentation.current_game_mode_name()) and
                local_player and self._unit == local_player.player_unit then
            self._idle_fullbody_value = 0
            if self._idle_fullbody_variable then
                Unit.animation_set_variable(
                    self._unit, self._idle_fullbody_variable, 0)
            end
            return
        end
        return func(self, dt, t, ...)
    end)

-- The hub unit template installs the components and extensions used by normal
-- gameplay walking except for the ledge finder.  Stock walking treats that
-- extension as optional during construction but unconditionally dereferences
-- it in cover peeking and vault input.  Preserve production gameplay movement
-- and animation while disabling only those unavailable traversal features.
mod:hook(
    require("scripts/utilities/player_unit_peeking"),
    "fixed_update",
    function(func, peeking_component, ledge_finder_extension, ...)
        if not ledge_finder_extension then
            peeking_component.peeking_is_possible = false
            peeking_component.in_cover = false
            peeking_component.is_peeking = false
            return
        end
        return func(peeking_component, ledge_finder_extension, ...)
    end)

mod:hook(
    require(
        "scripts/extension_systems/character_state_machine/character_states/utilities/ledge_vaulting"),
    "can_enter",
    function(func, ledge_finder_extension, ...)
        if not ledge_finder_extension then
            return false
        end
        return func(ledge_finder_extension, ...)
    end)

-- First Person Body 1.1.6 establishes the reliable split for rendering an
-- animated 3P body beneath a real 1P camera: lie only about equipment mode.
-- Returning (false, true) makes Darktide run its own 3P visibility/animation
-- pass while the camera tree, orientation and gameplay stay first person.
mod:hook(
    require("scripts/extension_systems/first_person/player_unit_first_person_extension"),
    "_update_first_person_mode",
    function(func, self, t, ...)
        local show_1p_equipment, wants_1p_camera = func(self, t, ...)
        if presentation.hub_first_person_requested() and
                presentation.is_first_person_body_mode(
                    active_game_mode_name()) and
                self._is_local_unit and not self._force_third_person_mode then
            return false, true
        end
        return show_1p_equipment, wants_1p_camera
    end)

-- The Psykhanium onboarding's ensure_player_healthy step waits until
-- is_in_first_person_mode() is true, which reads the equipment flag the
-- first-person body deliberately reports as third person. That stalled the
-- tutorial after the grenade section. Answer that one check from the camera
-- flag instead, for the duration of the step's own condition.
do
    local ok, steps = pcall(require,
        "scripts/extension_systems/training_grounds/training_grounds_steps")
    local extension_class = require(
        "scripts/extension_systems/first_person/player_unit_first_person_extension")
    local step = ok and type(steps) == "table" and steps.ensure_player_healthy
    if step and type(step.condition_func) == "function" and extension_class then
        local original_condition = step.condition_func
        step.condition_func = function(...)
            local original_query = extension_class.is_in_first_person_mode
            extension_class.is_in_first_person_mode = function(self)
                return original_query(self) or self._wants_1p_camera == true
            end
            local results = {pcall(original_condition, ...)}
            extension_class.is_in_first_person_mode = original_query
            if not results[1] then
                error(results[2], 0)
            end
            return unpack(results, 2)
        end
        mod:info("DARKTIDEVR_TRAINING ensure_player_healthy=camera_first_person")
    end
end

-- Preserve FadeSystem ownership/registration but move its observation point
-- far outside the playable world during the normal-off range body diagnostic.
-- This disables camera-proximity fading for the test without risking a stale
-- native registration or a double-unregister during mission teardown.
mod:hook(
    require("scripts/extension_systems/fade/fade_system"),
    "update",
    function(func, self, context, dt, t, ...)
        if controller_observation.body_visibility_enabled and
                presentation.is_first_person_body_mode(
                    active_game_mode_name()) then
            Fade.update(
                self._fade_system,
                Vector3(1000000, 1000000, 1000000))
            return
        end
        return func(self, context, dt, t, ...)
    end)

function presentation.safe_apply_body_visibility(self, frame, force)
    local ok, error_message = pcall(
        presentation.apply_body_visibility, self, frame, force)
    if not ok and controller_observation.body_visibility_enabled then
        controller_observation.body_visibility_enabled = false
        controller_observation.body_visibility_faulted = true
        mod:error(
            "DARKTIDEVR_BODY visibility_disabled reason=lua_error error=%s",
            tostring(error_message))
    end
end

-- Poll the normal-off range test gate after the stock loadout update. This
-- catches both a newly created player unit and late attachment streaming.
mod:hook_safe(
    presentation.player_unit_visual_loadout_extension,
    "update",
    function(self)
        controller_observation.body_visibility_update_frame =
            controller_observation.body_visibility_update_frame + 1
        local frame = controller_observation.body_visibility_update_frame
        local changed = presentation.update_body_visibility_gate(frame)
        presentation.safe_apply_body_visibility(self, frame, changed)
    end)

-- Any later game-driven visibility refresh (weapon swap, attachment spawn or
-- first-person transition) is followed immediately by the visual-only body
-- override. Gameplay remains in first person throughout.
mod:hook_safe(
    presentation.player_unit_visual_loadout_extension,
    "_update_item_visibility",
    function(self)
        if controller_observation.body_visibility_enabled then
            presentation.safe_apply_body_visibility(
                self,
                controller_observation.body_visibility_update_frame,
                true)
        end
    end)

-- Verify that the authored orientation reaches the shared first-person
-- component consumed by weapons, interactions and abilities. Convert engine
-- math values immediately; never retain their transient userdata.
mod:hook_safe(
    require("scripts/extension_systems/first_person/player_unit_first_person_extension"),
    "fixed_update",
    function(self, unit, dt, t, frame)
        if presentation.roomscale then presentation.roomscale.capture_base(unit, frame) end
        if not controller_observation.authoring_enabled or
                not presentation.hand_aim_usable("dominant") or
                controller_observation.last_sequence <
                    controller_observation.downstream_last_sequence + 120 then
            return
        end
        local component = self._first_person_component
        local rotation = component and component.rotation
        if not rotation then
            if not controller_observation.downstream_missing_logged then
                controller_observation.downstream_missing_logged = true
                mod:warning(
                    "DARKTIDEVR_AIM downstream unavailable component=first_person"
                )
            end
            return
        end
        local ok, yaw, pitch, roll = pcall(
            Quaternion.to_yaw_pitch_roll, rotation)
        if not ok then
            if not controller_observation.downstream_missing_logged then
                controller_observation.downstream_missing_logged = true
                mod:warning(
                    "DARKTIDEVR_AIM downstream unavailable rotation=%s",
                    tostring(yaw)
                )
            end
            return
        end
        local forward = Quaternion.forward(rotation)
        controller_observation.downstream_forward_x = Vector3.x(forward)
        controller_observation.downstream_forward_y = Vector3.y(forward)
        controller_observation.downstream_forward_z = Vector3.z(forward)
        controller_observation.downstream_last_sequence =
            controller_observation.last_sequence
        mod:info(
            "DARKTIDEVR_AIM downstream sequence=%d component_ypr=%.4f,%.4f,%.4f forward=%.4f,%.4f,%.4f",
            controller_observation.last_sequence,
            yaw,
            pitch,
            roll,
            Vector3.x(forward),
            Vector3.y(forward),
            Vector3.z(forward)
        )
    end)

-- `update_unit_position` is the production post-animation seam. The game has
-- already restored the stock 1P root, updated animation variables and called
-- `World.update_unit_and_children` before this safe hook runs. Applying the
-- normal-off presentation delta here makes it visible to the render without
-- feeding back into fixed-frame gameplay state.
mod:hook_safe(
    require("scripts/extension_systems/aim/third_person_look_delta_animation_control"),
    "update",
    function(self)
        if not controller_observation.body_ik_presentation_enabled then
            return
        end
        self._look_delta_x = 0
        self._look_delta_y = 0
        if self._look_delta_x_variable then
            Unit.animation_set_variable(
                self._unit, self._look_delta_x_variable, 0)
        end
        if self._look_delta_y_variable then
            Unit.animation_set_variable(
                self._unit, self._look_delta_y_variable, 0)
        end
        if self._world_look_delta_y_variable then
            Unit.animation_set_variable(
                self._unit, self._world_look_delta_y_variable, 0)
        end
    end)

mod:hook_safe(
    require("scripts/extension_systems/aim/third_person_aim_animation_control"),
    "update",
    function(self)
        if not controller_observation.body_ik_presentation_enabled then
            return
        end
        local variable = self._animation_extension:anim_variable_id(
            self._look_direction_anim_var)
        Unit.animation_set_variable(self._unit, variable, 0)
    end)

mod:hook_safe(
    require("scripts/extension_systems/aim/player_unit_aim_extension"),
    "update",
    function(self, unit)
        if not controller_observation.body_ik_presentation_enabled or
                not controller_observation.body_head_yaw or
                not self._aim_constraint_variable or
                not unit or not Unit.alive(unit) then
            return
        end
        local height = self._first_person_extension:
            extrapolated_character_height()
        local root_position = Unit.local_position(unit, 1) +
            height * Vector3.up()
        local controller_rotation
        if presentation.controller_aim then
            if controller_observation.stock_melee_animation_active then
                controller_rotation = presentation.controller_aim.melee_visual_rotation(unit)
            else
                -- A logical expression keeps only one return value in Lua.
                local _, rotation = presentation.controller_aim.target("dominant")
                controller_rotation = rotation
            end
        end
        local target_rotation = controller_rotation or presentation.keyboard_mouse_aim_rotation() or
            Quaternion.axis_angle(Vector3.up(), controller_observation.body_head_yaw)
        local neutral_target = root_position +
            Quaternion.forward(target_rotation) *
                self._aim_contraint_distance
        Unit.animation_set_constraint_target(
            unit, self._aim_constraint_variable, neutral_target)
    end)

mod:hook_safe(
    require("scripts/extension_systems/first_person/player_unit_first_person_extension"),
    "update_unit_position",
    function(self)
        local weapon_start = performance_tick()
        local weapon_extension = self._weapon_extension
        if weapon_extension then
            presentation.update_stock_melee_animation_owner(weapon_extension)
            presentation.author_weapon_pose(
                weapon_extension,
                controller_observation.last_sequence,
                self._world)
        end
        local weapon_end = performance_tick()
        if weapon_start and weapon_end then
            presentation.ik_perf_pending_weapon_ticks =
                weapon_end - weapon_start
        end
    end)

-- PlayerUnitFirstPersonExtension.update_unit_position is invoked from inside
-- PlayerUnitLocomotionExtension.post_update. Darktide then propagates the
-- stock pose through PlayerUnitVisualLoadoutExtension before post_update
-- returns. Solving the body inside the nested first-person call therefore
-- left a second body/attachment authority after our write. Apply body IK once
-- at the outer seam instead: the authoritative locomotion root and stock gait
-- remain intact, while every local skinned body/loadout update has completed
-- before the tracked presentation is published to either eye.
mod:hook_safe(
    require("scripts/extension_systems/locomotion/player_unit_locomotion_extension"),
    "post_update",
    function(self, _, dt, t)
        local presentation_start = performance_tick()
        local local_player = Managers and Managers.player and
            Managers.player:local_player(1)
        local player_unit = local_player and local_player.player_unit
        if not player_unit or self._unit ~= player_unit then
            return
        end
        local proxy_unit = presentation.body_proxy and
            presentation.body_proxy.update(
                self._world,
                player_unit,
                local_player,
                controller_observation.body_visibility_enabled and
                    presentation.is_first_person_body_mode(
                        presentation.current_game_mode_name()),
                dt,
                t,
                not controller_observation.full_body_experimental_enabled)
        local proxy_active = presentation.body_proxy and
            presentation.body_proxy.active() == true or false
        local proxy_changed = presentation.body_proxy_active ~= proxy_active
        presentation.body_proxy_active = proxy_active
        local proxy_ready = proxy_unit and
            presentation.body_proxy.consume_ready_transition()
        if proxy_changed or proxy_ready then
            controller_observation.body_ik_hand_proxy_pose = {}
            controller_observation.body_ik_hand_proxy_held = {}
            local visual_loadout = ScriptUnit.has_extension(
                player_unit, "visual_loadout_system")
            if visual_loadout then
                presentation.safe_apply_body_visibility(
                    visual_loadout,
                    controller_observation.body_visibility_update_frame,
                    true)
            end
            mod:info(
                "DARKTIDEVR_IK visual_proxy=%s mode=%s source=ui_profile authoritative_body=gameplay",
                proxy_active and "active" or "inactive",
                -- "body_rig" names the state the log could not tell apart on
                -- 19 September: the copy owned the hands and the proxy had
                -- spawned its own upper body anyway, and both printed as
                -- `upper_body`.
                presentation.body_proxy ~= nil and
                    presentation.body_proxy.hand_rig_active ~= nil and
                    presentation.body_proxy.hand_rig_active() and "body_rig" or
                controller_observation.full_body_experimental_enabled and
                    "upper_body" or "tracked_hands")
        end
        local ik_start = presentation_start
        local ok, error_message = presentation.frame_profile.section("post.body_ik", pcall,
            presentation.apply_body_ik,
            proxy_unit or player_unit,
            controller_observation.last_sequence,
            self._world,
            player_unit)
        if ok and presentation.gun_aim then
            presentation.frame_profile.section("draw.gun_aim", presentation.gun_aim.update, self._world, player_unit)
        end
        if presentation.weapon_parked_parts then
            presentation.weapon_parked_parts.update(player_unit)
        end
        if presentation.gun_sights then
            presentation.gun_sights.update(player_unit, t)
        end
        -- The scan hologram was placed from the scanner before the hand pose
        -- above moved it; place it again from the scanner in the hand.
        if presentation.scanner_holo then
            presentation.scanner_holo.place(player_unit, t)
        end
        if presentation.attachment_scan then
            presentation.attachment_scan.update(player_unit)
        end
        if presentation.ammo_readout then
            presentation.frame_profile.section("draw.ammo_readout", presentation.ammo_readout.draw, self._world, player_unit)
        end
        if presentation.holster_counts then
            presentation.frame_profile.section("draw.holster_counts", presentation.holster_counts.draw, self._world, player_unit)
        end
        if presentation.wrist_display then
            presentation.frame_profile.section("draw.wrist_display", presentation.wrist_display.draw, self._world, player_unit)
        end
        if presentation.item_radial then
            presentation.frame_profile.section("draw.item_radial", presentation.item_radial.draw, self._world)
        end
        if presentation.forearm_holsters then
            presentation.frame_profile.section("draw.forearm_holsters", presentation.forearm_holsters.update_previews, self._world, player_unit, dt, t)
        end
        if presentation.teammate_status then
            presentation.frame_profile.section("draw.teammate_status", presentation.teammate_status.draw, self._world, player_unit)
        end
        if presentation.rig_scan then
            presentation.rig_scan.update(self._world, player_unit, dt, t)
        end
        if presentation.body_mirror then
            -- Posed HERE, after post.body_ik has refreshed this frame's body
            -- anchor and placed the hands: the copy takes the same frame's
            -- anchor the camera and the weapon take. Between 13:38 and
            -- 14:36 on 19 September it was posed from a WorldManager.update
            -- hook, before the world update, from the previous frame's
            -- anchor; the anchor steps every other frame, so on those
            -- frames the copy stood a step behind the view and on the
            -- others where it should: "one of the two locations is
            -- definitely the right one, the other lags behind". The copy
            -- carries no state machine, so its joints written here are
            -- drawn (the still body at 13:20 was a machine left running).
            presentation.frame_profile.section("draw.body_mirror", presentation.body_mirror.update, self._world, player_unit, dt, t)
        end
        if presentation.pose_trace then
            presentation.pose_trace.sample(player_unit, t)
        end
        local ik_end = performance_tick()
        if presentation_start and ik_start and ik_end and ui_native_capture then
            local weapon_ticks =
                presentation.ik_perf_pending_weapon_ticks or 0
            presentation.ik_perf_pending_weapon_ticks = 0
            presentation.ik_perf_samples =
                (presentation.ik_perf_samples or 0) + 1
            presentation.ik_perf_weapon_ticks =
                (presentation.ik_perf_weapon_ticks or 0) +
                    weapon_ticks
            presentation.ik_perf_body_ticks =
                (presentation.ik_perf_body_ticks or 0) + (ik_end - ik_start)
            presentation.ik_perf_total_ticks =
                (presentation.ik_perf_total_ticks or 0) +
                    weapon_ticks + (ik_end - presentation_start)
            presentation.ik_perf_max_ticks = math.max(
                presentation.ik_perf_max_ticks or 0,
                weapon_ticks + (ik_end - presentation_start))
            if presentation.ik_perf_samples >= 600 then
                local frequency = tonumber(
                    ui_native_capture.dtvr_qpc_frequency())
                if frequency and frequency > 0 then
                    local to_ms = 1000 / frequency /
                        presentation.ik_perf_samples
                    mod:info(
                        "DARKTIDEVR_IK_PERF samples=%d weapon_avg_ms=%.4f body_avg_ms=%.4f total_avg_ms=%.4f total_max_ms=%.4f",
                        presentation.ik_perf_samples,
                        presentation.ik_perf_weapon_ticks * to_ms,
                        presentation.ik_perf_body_ticks * to_ms,
                        presentation.ik_perf_total_ticks * to_ms,
                        presentation.ik_perf_max_ticks * 1000 / frequency)
                end
                presentation.ik_perf_samples = 0
                presentation.ik_perf_weapon_ticks = 0
                presentation.ik_perf_body_ticks = 0
                presentation.ik_perf_total_ticks = 0
                presentation.ik_perf_max_ticks = 0
            end
        end
        if not ok and controller_observation.body_ik_presentation_enabled then
            controller_observation.body_ik_presentation_enabled = false
            controller_observation.body_ik_presentation_faulted = true
            mod:error(
                "DARKTIDEVR_IK presentation_disabled reason=lua_error error=%s",
                tostring(error_message))
        end
    end)

-- ViewInteraction remains the authoritative vendor/facility seam, but shops
-- can be opened remotely. Use the same fixed head-relative panel for every
-- interaction instead of deriving placement from the NPC.
mod:hook_safe(
    require("scripts/extension_systems/interaction/interactions/view_interaction"),
    "_start",
    function(self, _, interactee_unit)
        local ui_interaction = self:_ui_interaction(interactee_unit)
        local manager = Managers and Managers.ui
        if not manager then return end
        local active_ok, view_active =
            pcall(manager.view_active, manager, ui_interaction)
        if not active_ok or not view_active then
            return
        end
        presentation.flat_panel_views[ui_interaction] = true
        presentation.world_menu_views[ui_interaction] = nil
        presentation.world_menu_anchor = nil
        presentation.world_menu_draw_logged = false
        presentation.fullscreen_empty_updates = 0
        presentation.publish_mode(
            5,
            tostring(ui_interaction) .. ":shop_flat_fallback")
    end)

mod:hook(
    require("scripts/managers/ui/ui_manager"),
    "open_view",
    function(func, self, view_name, ...)
        -- Interactive menus must never replace the gameplay world.  Vendor
        -- views commonly request disable_game_world even though their UI can
        -- be rendered into our world-owned panel.  Change that setting before
        -- the view handler performs its transition, not after the freeze has
        -- already occurred.
        local handler = self._view_handler
        local settings = nil
        if handler and handler.settings_by_view_name then
            local ok, value = pcall(
                handler.settings_by_view_name, handler, view_name)
            if ok then
                settings = value
            end
        end
        if settings and settings.disable_game_world == true and
                not presentation.flat_loading_views[view_name] and
                not presentation.non_gameplay_views[view_name] then
            settings.disable_game_world = false
            presentation.world_menu_views[view_name] = true
            mod:info(
                "DARKTIDEVR_WORLD_MENU preserve_world view=%s",
                tostring(view_name))
        end
        -- A Back edge generated before this view opened belongs to the old
        -- screen. Baseline it here so it cannot immediately dismiss a newly
        -- opened training/options view on its first update.
        presentation.consume_menu_back(presentation.read_menu_pointer())
        local result = func(self, view_name, ...)
        presentation.on_view_open(self, view_name)
        return result
    end)

mod:hook_safe(
    require("scripts/managers/ui/ui_manager"),
    "close_view",
    function(self, view_name)
    presentation.on_view_close(self, view_name)
end)

-- Route the complete crafting view family at construction time. CraftingView
-- creates the source renderer before any retained widgets; replace it there,
-- then its children naturally inherit the same resource renderer. No member of
-- the family is allowed to render to the desktop/backbuffer while the spatial
-- board is active.
mod:hook(
    "BaseView",
    "_create_ui_renderer",
    function(func, self, context, ...)
        return func(self, context, ...)
    end)

-- CraftingView.init and CraftingView.draw hard-code `to_screen`. Restore the
-- resource pass after init and bypass only those two hard-coded queue lines;
-- the superclass retains the game's stock update, widget, element and input
-- ordering.
mod:hook(
    require("scripts/ui/views/crafting_view/crafting_view"),
    "init",
    function(func, self, ...)
        return func(self, ...)
    end)

mod:hook(
    require("scripts/ui/views/crafting_view/crafting_view"),
    "draw",
    function(func, self, dt, t, input_service, layer, ...)
        if not ui_menu_resource_redirect_requested or
                not presentation.world_menu_active() then
            return func(self, dt, t, input_service, layer, ...)
        end
        local source_renderer = self._ui_renderer
        local resource_renderer = source_renderer and
            presentation.ensure_menu_resource(source_renderer)
        if not resource_renderer then
            return func(self, dt, t, input_service, layer, ...)
        end

        UIRenderer.clear_render_pass_queue(source_renderer)
        UIRenderer.add_render_pass(
            source_renderer,
            0,
            resource_renderer.base_render_pass,
            true,
            resource_renderer.render_target)
        if not presentation.menu_resource_invalidated_views[self] then
            presentation.menu_resource_invalidated_views[self] = true
            local retained_count =
                presentation.invalidate_retained_widgets(self._widgets) +
                presentation.invalidate_retained_widgets(
                    self._content_widgets)
            mod:info(
                "DARKTIDEVR_MENU_TARGET renderer_swap view=crafting_view retained=%d widgets=%d content=%d",
                retained_count,
                type(self._widgets) == "table" and #self._widgets or 0,
                type(self._content_widgets) == "table" and
                    #self._content_widgets or 0)
        end
        self._ui_renderer = resource_renderer
        local ok, result = pcall(func, self, dt, t, input_service, layer, ...)
        self._ui_renderer = source_renderer
        if not ok then error(result, 0) end
        return result
    end)

-- Interactive fullscreen UI is rendered into one named RGBA resource instead
-- of being recovered from the desktop window. Capturing the window also
-- captured its mono eye mirror; putting that image in both headset eyes made
-- the live stereo world appear to freeze/flicker between mono and stereo.
-- Reusing the view's own Gui keeps retained widgets, engine hotspot geometry,
-- and the exported texture in exactly the same coordinate space. Intercept at
-- UIRenderer rather than BaseView: SystemView and vendor views own specialized
-- draw methods and renderer fields, but all of them converge here.
mod:hook(UIRenderer, "begin_pass", function(func, self, ...)
    if not ui_menu_resource_redirect_requested then
        return func(self, ...)
    end
    if not presentation.world_menu_active() then
        return func(self, ...)
    end
    if self == presentation.menu_resource_renderer then
        return func(self, ...)
    end

    local renderer_name = string.lower(tostring(self.name or ""))
    -- A renderer belonging to a view in the gameplay world still reports the
    -- gameplay World object, so world identity cannot distinguish crafting UI
    -- from scene/HUD rendering. Use the renderer instance captured from the
    -- active view (with its stable name as a construction-time fallback).
    if self ~= presentation.vendor_ui_renderer and
            not string.find(renderer_name, "crafting", 1, true) then
        return func(self, ...)
    end

    local resource_renderer = presentation.ensure_menu_resource(self)
    if not resource_renderer then
        return func(self, ...)
    end

    local states = presentation.menu_resource_pass_states[self]
    if not states then
        states = {}
        presentation.menu_resource_pass_states[self] = states
    end
    local state = {
        base_render_pass = self.base_render_pass,
        render_pass_flag = self.render_pass_flag,
    }
    states[#states + 1] = state

    local ok, result = pcall(function(...)
        local frame_time = Managers.time and Managers.time:time("ui") or 0
        if presentation.menu_resource_clear_time ~= frame_time then
            UIRenderer.clear_render_pass_queue(self)
            UIRenderer.add_render_pass(
                self,
                0,
                resource_renderer.base_render_pass,
                true,
                resource_renderer.render_target
            )
            if presentation.world_menu_target_desktop_probe then
                UIRenderer.add_render_pass(self, 1, "to_screen", false)
            end
            presentation.menu_resource_clear_time = frame_time
        end
        self.base_render_pass = resource_renderer.base_render_pass
        self.render_pass_flag = resource_renderer.render_pass_flag
        -- The resource pass must exist before stock begins its widget pass.
        return func(self, ...)
    end, ...)
    if not ok then
        states[#states] = nil
        self.base_render_pass = state.base_render_pass
        self.render_pass_flag = state.render_pass_flag
        error(result, 0)
    end
    return result
end)

-- SystemView creates its materials and retained widgets against one renderer.
-- Merely changing that renderer's pass-name fields does not migrate those
-- retained draw records. Darktide's own resource-backed grids instead draw
-- with the resource renderer object while registering its pass on the shared
-- Gui. Follow that exact contract for the Escape menu.
mod:hook(
    require("scripts/ui/views/system_view/system_view"),
    "draw",
    function(func, self, ...)
        if not ui_menu_resource_redirect_requested then
            return func(self, ...)
        end
        local dt, _, input_service = ...
        if not presentation.world_menu_active() then
            return func(self, ...)
        end
        local source_renderer = self._ui_default_renderer
        local resource_renderer =
            presentation.ensure_menu_resource(source_renderer)
        if not resource_renderer then
            return func(self, ...)
        end

        UIRenderer.clear_render_pass_queue(source_renderer)
        UIRenderer.add_render_pass(
            source_renderer,
            0,
            resource_renderer.base_render_pass,
            true,
            resource_renderer.render_target)
        if presentation.world_menu_target_desktop_probe then
            UIRenderer.add_render_pass(source_renderer, 1, "to_screen", false)
        end

        if not presentation.menu_resource_invalidated_views[self] then
            presentation.menu_resource_invalidated_views[self] = true
            local retained_count =
                presentation.invalidate_retained_widgets(self._widgets) +
                presentation.invalidate_retained_widgets(
                    self._content_widgets)
            mod:info(
                "DARKTIDEVR_MENU_TARGET renderer_swap view=%s retained=%d widgets=%d content=%d",
                tostring(self.view_name or self.__class_name),
                retained_count,
                type(self._widgets) == "table" and #self._widgets or 0,
                type(self._content_widgets) == "table" and
                    #self._content_widgets or 0)
        end

        self._ui_default_renderer = resource_renderer
        local ok, result = pcall(func, self, ...)
        self._ui_default_renderer = source_renderer
        if not ok then error(result, 0) end

        if presentation.world_menu_target_probe_requested then
            UIRenderer.begin_pass(
                resource_renderer,
                self._ui_scenegraph,
                input_service,
                dt,
                self._render_settings)
            local ui_widget =
                require("scripts/managers/ui/ui_widget")
            local base_widgets = self._widgets or {}
            for i = 1, #base_widgets do
                ui_widget.draw(base_widgets[i], resource_renderer)
            end
            local content_widgets = self._content_widgets or {}
            for i = 1, #content_widgets do
                ui_widget.draw(content_widgets[i], resource_renderer)
            end
            UIRenderer.draw_rect(
                resource_renderer,
                Vector3(0, 0, 10000),
                Vector3(600, 32, 0),
                Color(255, 255, 0, 255))
            UIRenderer.draw_rect(
                resource_renderer,
                Vector3(0, 0, 10001),
                Vector3(32, 600, 0),
                Color(255, 0, 255, 255))
            UIRenderer.end_pass(resource_renderer)
        end
        if presentation.world_menu_target_desktop_probe then
            local width, height = presentation.menu_resource_extent()
            Gui.bitmap(
                source_renderer.gui,
                resource_renderer.render_target_material,
                "render_pass",
                "to_screen",
                Vector3(0, 0, 20000),
                Vector3(width, height, 0),
                Color(255, 255, 255, 255))
        end
        return result
    end)

mod:hook(UIRenderer, "end_pass", function(func, self, ...)
    if not ui_menu_resource_redirect_requested then
        return func(self, ...)
    end
    local states = presentation.menu_resource_pass_states[self]
    local state = states and states[#states] or nil
    if not state then return func(self, ...) end
    local ok, result = pcall(function(...)
        if presentation.world_menu_target_probe_requested then
            -- Opaque L-shaped registration mark. Magenta is the top edge in UI
            -- coordinates; cyan is the left edge. Their presence and orientation
            -- distinguish target/sample failure from a transform-axis failure.
            UIRenderer.draw_rect(
                self,
                Vector3(0, 0, 10000),
                Vector3(600, 32, 0),
                Color(255, 255, 0, 255))
            UIRenderer.draw_rect(
                self,
                Vector3(0, 0, 10001),
                Vector3(32, 600, 0),
                Color(255, 0, 255, 255))
        end
        if presentation.world_menu_target_desktop_probe then
            local resource_renderer = presentation.menu_resource_renderer
            local width, height = presentation.menu_resource_extent()
            Gui.bitmap(
                self.gui,
                resource_renderer.render_target_material,
                "render_pass",
                "to_screen",
                Vector3(0, 0, 20000),
                Vector3(width, height, 0),
                Color(255, 255, 255, 255))
        end
        return func(self, ...)
    end, ...)
    states[#states] = nil
    self.base_render_pass = state.base_render_pass
    self.render_pass_flag = state.render_pass_flag
    if not ok then error(result, 0) end
    return result
end)

-- Keep controller/menu back semantic rather than synthesizing Escape. The
-- engine's top view is authoritative: OptionsView, for example, first closes
-- an expanded setting or moves back a navigation column before closing the
-- view itself. Only the topmost instance may consume a shared button edge.
presentation.hook_legacy_menu(
    "BaseView",
    "update",
    function(func, self, dt, t, input_service, ...)
        local pointer = presentation.read_legacy_menu_pointer()
        if pointer.available and pointer.back_pressed and
                presentation.is_top_menu_view(self) then
            local callback = self.cb_on_back_pressed or
                self.cb_on_close_pressed
            if type(callback) == "function" then
                presentation.consume_menu_back(pointer)
                mod:info(
                    "DARKTIDEVR_MENU_INPUT source_back view=%s sequence=%d",
                    tostring(self.view_name or self.__class_name),
                    pointer.last_sequence)
                callback(self)
            end
        end
        return func(self, dt, t, input_service, ...)
    end)

-- BaseView owns the common full-screen widget draw path used by options and
-- most conventional menus. Resolve the XR ray against those engine-authored
-- widget rectangles before their hotspot pass runs, then use the same
-- force_input_pressed seam as BaseView.trigger_widget_pressed. Subclasses with
-- custom dynamic grids (including SystemView below) retain dedicated hooks.
presentation.hook_legacy_menu(
    "BaseView",
    "_draw_widgets",
    function(func, self, dt, t, input_service, ui_renderer, ...)
        local pointer = presentation.read_legacy_menu_pointer()
        -- Mode 6 presents native landscape pixels, but premium-store widgets
        -- remain authored in Darktide's portrait eye-layout coordinates.
        -- Keep the visible laser/cursor in source pixels and transform only
        -- semantic hotspot tests into the engine canvas.
        -- Gameplay shops render into a landscape Windows client while their
        -- retained widget scenegraphs remain authored in the portrait eye
        -- canvas. Mode 6 changes panel geometry only; semantic hit testing
        -- must still enter that portrait widget space.
        local shop_eye_layout = presentation.mode == 6 or
            (presentation.mode == 5 and
                (presentation.shop_panel_views[self.view_name] or
                    self.view_name == "options_view" or
                    self.view_name == "player_character_options_view" or
                    self.view_name == "crafting_view" or
                    (type(self.view_name) == "string" and
                        string.find(
                            self.view_name, "crafting_", 1, true) == 1)))
        local hit_pointer = shop_eye_layout and
            presentation.vendor_eye_layout_pointer(pointer) or pointer
        local widgets = self._widgets or {}
        local source_widget = nil
        local source_entry = nil
        local modal_dropdown =
            presentation.options_modal_instance == self and
            presentation.options_modal_widget or nil
        local modal_active = modal_dropdown and modal_dropdown.content and
            modal_dropdown.content.exclusive_focus
        for i = #widgets, 1, -1 do
            local widget = widgets[i]
            if pointer.available then
                presentation.clear_widget_hotspot_forces(widget)
            end
            -- OptionsView's dynamic grids own their interaction overlays. In
            -- particular, BaseView must not force a second grid/row hover
            -- behind an expanded dropdown which is already handled by
            -- OptionsView._draw_grid.
            local dynamic_grid_interaction =
                widget and (widget.name == "settings_grid_interaction" or
                    widget.name == "category_grid_interaction" or
                    (widget.name == "grid_interaction" and
                        (presentation.mode == 6 or
                            self.view_name == "inventory_view" or
                            self.view_name == "options_view" or
                            self.view_name ==
                                "player_character_options_view")))
            if not modal_active and not dynamic_grid_interaction and
                    pointer.available and not source_widget and pointer.active and
                    widget then
                local entry = presentation.widget_hotspot_at_pointer(
                    self, widget, hit_pointer)
                if entry then
                    source_widget = widget
                    source_entry = entry
                end
            end
        end
        if pointer.primary_pressed and not source_widget and
                pointer.primary_press_sequence ~=
                    pointer.diagnostic_miss_sequence then
            pointer.diagnostic_miss_sequence =
                pointer.primary_press_sequence
            local diagnostics = {}
            for i = #widgets, 1, -1 do
                local widget = widgets[i]
                local entries = presentation.widget_hotspot_entries(widget)
                for j = #entries, 1, -1 do
                    local entry = entries[j]
                    local hit, geometry =
                        presentation.widget_contains_menu_pointer(
                            self, widget, hit_pointer, entry.style)
                    if geometry and #diagnostics < 32 then
                        diagnostics[#diagnostics + 1] = string.format(
                            "%s:%s:%s:%.1f,%.1f,%.1f,%.1f",
                            tostring(widget.name),
                            tostring(entry.content_id),
                            hit and "hit" or "miss",
                            geometry.left,
                            geometry.top,
                            geometry.width,
                            geometry.height)
                    end
                end
            end
            mod:info(
                "DARKTIDEVR_MENU_INPUT base_source_miss view=%s sequence=%d source=%d,%d/%dx%d pointer=%.1f,%.1f widgets=%s",
                tostring(self.view_name or self.__class_name),
                pointer.last_sequence,
                pointer.x,
                pointer.y,
                pointer.source_width,
                pointer.source_height,
                hit_pointer.x,
                hit_pointer.y,
                #diagnostics > 0 and table.concat(diagnostics, "|") or
                    "none")
        end
        if source_widget and source_entry then
            local hotspot = source_entry.hotspot
            hotspot.force_hover = true
            if pointer.scroll_steps ~= 0 then
                local scroll_grid = nil
                if source_widget.name == "settings_grid_interaction" then
                    scroll_grid = self._settings_content_grid
                elseif source_widget.name == "category_grid_interaction" then
                    scroll_grid = self._category_content_grid
                end
                local scrolled, reason = presentation.scroll_menu_grid(
                    scroll_grid, pointer.scroll_steps)
                if scrolled then
                    mod:info(
                        "DARKTIDEVR_MENU_INPUT options_source_scroll widget=%s steps=%d sequence=%d",
                        tostring(source_widget.name),
                        pointer.scroll_steps,
                        pointer.last_sequence)
                    presentation.consume_menu_scroll(pointer)
                else
                    pointer.scroll_diagnostic_keys =
                        pointer.scroll_diagnostic_keys or {}
                    local role = scroll_grid == self._settings_content_grid and
                        "settings" or
                        (scroll_grid == self._category_content_grid and
                            "category" or "other")
                    local key = tostring(pointer.scroll_sequence) .. ":" ..
                        role .. ":" .. tostring(scroll_grid)
                    if not pointer.scroll_diagnostic_keys[key] then
                        pointer.scroll_diagnostic_keys[key] = true
                        local length = scroll_grid and
                            scroll_grid.scroll_length and
                            scroll_grid:scroll_length() or -1
                        mod:info(
                            "DARKTIDEVR_MENU_INPUT options_scroll_skipped widget=%s role=%s reason=%s length=%s",
                            tostring(source_widget.name),
                            role,
                            tostring(reason),
                            tostring(length))
                    end
                end
            end
            if pointer.primary_pressed then
                hotspot.force_input_pressed = true
                presentation.consume_menu_primary(pointer)
                mod:info(
                    "DARKTIDEVR_MENU_INPUT base_source_activate view=%s widget=%s sequence=%d source=%d,%d/%dx%d",
                    tostring(self.view_name or self.__class_name),
                    tostring(source_widget.name) .. ":" ..
                        tostring(source_entry.content_id),
                    pointer.last_sequence,
                    pointer.x,
                    pointer.y,
                    pointer.source_width,
                    pointer.source_height)
            end
        end
        return func(self, dt, t, input_service, ui_renderer, ...)
    end)

-- InventoryView owns a private grid; the full-grid catcher in BaseView must
-- not consume the button edge intended for these item hotspots.
presentation.hook_legacy_menu("InventoryView", "_draw_grid",
    function(func, self, dt, t, input_service, ui_renderer, ...)
        if presentation.mode ~= 5 then
            return func(self, dt, t, input_service, ui_renderer, ...)
        end
        local pointer = presentation.read_legacy_menu_pointer()
        local hit_pointer = presentation.vendor_eye_layout_pointer(pointer)
        local interaction = self._widgets_by_name.grid_interaction.content.hotspot
        local previous_hover = interaction.is_hover
        if pointer.active then interaction.is_hover = true end
        for _, widget in ipairs(self._grid_widgets or {}) do
            if pointer.available then presentation.clear_widget_hotspot_forces(widget) end
            if pointer.active and self._grid and self._grid:is_widget_visible(widget) then
                local entry = presentation.widget_hotspot_at_pointer(self, widget, hit_pointer)
                if entry and not entry.hotspot.disabled then
                    entry.hotspot.force_hover = true
                    if pointer.primary_pressed then
                        entry.hotspot.force_input_pressed = true
                        presentation.consume_menu_primary(pointer)
                        mod:info("DARKTIDEVR_MENU_INPUT inventory_item_activate widget=%s",
                            tostring(widget.name))
                    end
                end
            end
        end
        local draw_input = pointer.active and input_service:null_service() or input_service
        local ok, result = pcall(func, self, dt, t, draw_input, ui_renderer, ...)
        interaction.is_hover = previous_hover
        if not ok then error(result, 0) end
        return result
    end)

-- OptionsView draws its category and settings widgets through two custom
-- UIWidgetGrid passes before BaseView draws its static chrome. Arm the exact
-- visible grid widget before that pass, and consume the edge only after a hit
-- so stacked views cannot steal it merely by reading the shared sample.
presentation.hook_legacy_menu(
    "OptionsView",
    "_draw_grid",
    function(func, self, grid, widgets, interaction_widget, dt, t,
            input_service, ...)
        if ui_native_capture and
                ui_native_capture.dtvr_arm_options_menu_capture then
            ui_native_capture.dtvr_arm_options_menu_capture()
        end
        local pointer = presentation.read_legacy_menu_pointer()
        local hit_pointer = presentation.vendor_eye_layout_pointer(pointer)
        presentation.update_slider_drag(self, hit_pointer)
        local source_widget = nil
        local source_entry = nil
        if pointer.available then
            for i = 1, #widgets do
                presentation.clear_widget_hotspot_forces(widgets[i])
            end
        end
        if pointer.active then
            -- OptionsView already owns the authoritative modal selection.
            -- Do not infer it by scanning content.exclusive_focus: stale flags
            -- can exist on more than one widget while a dynamic grid rebuilds.
            local focused_dropdown = nil
            local selected_widget = self._selected_settings_widget
            if presentation.is_dropdown_widget(selected_widget) then
                for i = 1, #widgets do
                    if widgets[i] == selected_widget then
                        focused_dropdown = selected_widget
                        break
                    end
                end
            end
            local function consider_widget(widget)
                local visible = not grid or
                    grid:is_widget_visible(widget)
                if visible then
                    if widget == focused_dropdown then
                        presentation.log_focused_dropdown_geometry(
                            self, widget, hit_pointer)
                    end
                    presentation.log_slider_geometry(
                        self, widget, hit_pointer)
                end
                local entry = visible and
                    presentation.widget_hotspot_at_pointer(
                        self, widget, hit_pointer,
                        widget == focused_dropdown)
                if entry then
                    source_widget = widget
                    source_entry = entry
                    return true
                end
                return false
            end
            if focused_dropdown then
                -- Exclusive focus is also visual/modal ownership. Its option
                -- passes are drawn over later grid rows, so they must receive
                -- the ray before (and instead of) widgets geometrically behind
                -- the expanded list.
                consider_widget(focused_dropdown)
                presentation.options_modal_instance = self
                presentation.options_modal_widget = focused_dropdown
            else
                if presentation.options_modal_instance == self then
                    presentation.options_modal_instance = nil
                    presentation.options_modal_widget = nil
                end
                for i = #widgets, 1, -1 do
                    if consider_widget(widgets[i]) then
                        break
                    end
                end
            end
        end
        local interaction_hotspot =
            presentation.widget_hotspot(interaction_widget)
        if pointer.available and interaction_hotspot then
            -- This is a grid-sized input catcher, not the row under the ray.
            -- Forcing it hovered alongside source_widget makes the grid's first
            -- entry (Audio in the current options layout) look hovered too.
            interaction_hotspot.force_hover = false
        end
        if pointer.scroll_steps ~= 0 and pointer.active and
                interaction_widget then
            local interaction_hit =
                presentation.widget_contains_menu_pointer(
                    self, interaction_widget, hit_pointer)
            if interaction_hit then
                local scrolled, reason = presentation.scroll_menu_grid(
                    grid, pointer.scroll_steps)
                if scrolled then
                    presentation.consume_menu_scroll(pointer)
                    mod:info(
                        "DARKTIDEVR_MENU_INPUT options_grid_scroll grid=%s steps=%d sequence=%d",
                        tostring(interaction_widget.name),
                        pointer.scroll_steps,
                        pointer.last_sequence)
                else
                    mod:info(
                        "DARKTIDEVR_MENU_INPUT options_grid_scroll_skipped grid=%s steps=%d reason=%s",
                        tostring(interaction_widget.name),
                        pointer.scroll_steps,
                        tostring(reason))
                end
            end
        end
        if source_widget and source_entry then
            local hotspot = source_entry.hotspot
            hotspot.force_hover = true
            if pointer.primary_pressed then
                local started_slider = false
                local opening_dropdown = false
                if presentation.is_slider_widget(source_widget) then
                    started_slider = presentation.begin_slider_drag(
                        self, source_widget, hit_pointer)
                elseif presentation.is_dropdown_widget(source_widget) and
                        source_entry.content_id == "hotspot" and
                        source_widget ~= self._selected_settings_widget then
                    -- Opening through the ordinary pressed_callback makes the
                    -- same physical trigger edge visible to OptionsView as a
                    -- native left_pressed click-away on its following update.
                    -- Defer only the native coordinator call until that edge
                    -- has drained. Modal ownership thereafter remains the
                    -- engine's authoritative _selected_settings_widget.
                    presentation.dropdown_open_pending = {
                        instance = self,
                        widget_name = source_widget.name,
                        frames = 2,
                    }
                    opening_dropdown = true
                end
                if not started_slider and not opening_dropdown then
                    hotspot.force_input_pressed = true
                    if presentation.is_dropdown_widget(source_widget) and
                            string.match(
                                source_entry.content_id,
                                "^option_hotspot_%d+$") then
                        presentation.dropdown_close_pending = {
                            instance = self,
                            -- The option's on_pressed bit is consumed by the
                            -- next blueprint update. The hook-safe update below
                            -- also runs once at the end of this current update,
                            -- so two ticks are required before closing focus.
                            frames = 2,
                        }
                    end
                end
                presentation.consume_menu_primary(pointer)
                mod:info(
                    "DARKTIDEVR_MENU_INPUT options_source_activate widget=%s hotspot=%s sequence=%d source=%d,%d/%dx%d",
                    tostring(source_widget.name),
                    tostring(source_entry.content_id),
                    pointer.last_sequence,
                    pointer.x,
                    pointer.y,
                    pointer.source_width,
                    pointer.source_height)
            end
        end
        return func(self, grid, widgets, interaction_widget, dt, t,
            input_service, ...)
    end)

-- A cursor dropdown normally releases exclusive focus from the engine mouse
-- edge. XR supplies the option pressed edge directly, so close focus only
-- after the following blueprint update has applied the selected value.
mod:hook_safe("OptionsView", "update", function(self)
    if presentation.using_native_menu_input() then return end
    local open_pending = presentation.dropdown_open_pending
    if open_pending and open_pending.instance == self then
        open_pending.frames = open_pending.frames - 1
        if open_pending.frames <= 0 then
            if type(self._set_exclusive_focus_on_grid_widget) == "function" then
                self:_set_exclusive_focus_on_grid_widget(
                    open_pending.widget_name)
            end
            presentation.dropdown_open_pending = nil
            mod:info(
                "DARKTIDEVR_MENU_INPUT dropdown_focus_opened source=xr widget=%s",
                tostring(open_pending.widget_name))
        end
    end
    local pending = presentation.dropdown_close_pending
    if not pending or pending.instance ~= self then
        return
    end
    pending.frames = pending.frames - 1
    if pending.frames <= 0 then
        if type(self._set_exclusive_focus_on_grid_widget) == "function" then
            self:_set_exclusive_focus_on_grid_widget(nil)
        end
        presentation.dropdown_close_pending = nil
        mod:info("DARKTIDEVR_MENU_INPUT dropdown_focus_closed source=xr")
    end
end)

-- The current hub build opens its system menu through the preloaded SystemView
-- instance without reliably traversing the UIManager lifecycle used by other
-- views. Keep this class seam, but publish the same single captured-client
-- mode-5 policy as character select and shops. The former mode-4 publication
-- raced the general mode-5 classifier and produced black/horizontal/flickering
-- menu generations.
mod:hook_safe(
    require("scripts/ui/views/system_view/system_view"),
    "on_enter",
    function(self)
    presentation.active_menu_view_instance = self
    presentation.world_menu_anchor = nil
    presentation.world_menu_draw_logged = false
    -- SystemView creates a dedicated overlay viewport whose only purpose is
    -- to shade/blur the desktop back buffer.  It is not menu content and it
    -- acts on player1 only, so remove it while leaving the actual menu
    -- renderer alive for offscreen capture.
    if self._ui_background_renderer and
            type(self._destroy_background) == "function" then
        self:_destroy_background()
    end
    local input_fields = {}
    for key, value in pairs(self) do
        if string.find(string.lower(tostring(key)), "input", 1, true) then
            input_fields[#input_fields + 1] = tostring(key) .. ":" .. type(value)
        end
    end
    table.sort(input_fields)
    mod:info(
        "DARKTIDEVR_MENU_INPUT system_view fields=%s",
        #input_fields > 0 and table.concat(input_fields, ",") or "none")
    presentation.fullscreen_empty_updates = 0
    presentation.world_menu_views.system_view = nil
    presentation.flat_panel_views.system_view = true
    presentation.publish_mode(5, "SystemView.on_enter:native_window_panel")
    -- Focused command tracing is diagnostic-only now that the stock menu PSO
    -- and completed swapchain boundary are known.
    presentation.system_view_trace_pending =
        ui_menu_trace_requested and true or nil
    presentation.system_view_trace_phase = nil
    presentation.system_view_trace_frames = nil
end)

mod:hook(
    require("scripts/ui/views/system_view/system_view"),
    "on_exit",
    function(func, self, ...)
    -- Finish the engine close before retiring the captured-client panel. The
    -- compositor retains the last valid stereo pair until the restored
    -- gameplay generation supplies a pose-synchronised replacement.
    local result = func(self, ...)
    presentation.active_menu_view_instance = nil
    presentation.active_menu_input_service = nil
    presentation.system_view_hovered_widget = nil
    presentation.system_view_source_widget = nil
    presentation.system_view_trace_pending = nil
    presentation.system_view_trace_seen = nil
    presentation.system_view_trace_phase = nil
    presentation.system_view_trace_frames = nil
    presentation.flat_panel_views.system_view = nil
    presentation.world_menu_views.system_view = nil
    if ui_native_capture then
        ui_native_capture.dtvr_set_focused_trace_phase(0)
    end
    presentation.fullscreen_empty_updates = 0
    presentation.destroy_menu_resource()
    -- A child view may still be open when SystemView exits. Let the full
    -- remaining stack choose its mode instead of briefly forcing gameplay.
    presentation.reconcile_fullscreen_views(Managers.ui)
    return result
end)

mod:hook_safe(
    require("scripts/ui/views/system_view/system_view"),
    "update",
    function(_, _, _, input_service)
        presentation.active_menu_input_service = input_service
        if ui_menu_trace_requested and
                not presentation.system_view_trace_seen and ui_native_capture then
            presentation.system_view_trace_seen = true
            presentation.system_view_trace_pending = nil
            presentation.system_view_trace_phase = 1
            presentation.system_view_trace_frames = 4
            local marker_result = ui_native_capture.dtvr_enable_marker_log()
            local trace_result =
                ui_native_capture.dtvr_set_focused_trace_phase(1)
            mod:info(
                "DARKTIDEVR_MENU_TRACE started_update frames=%d marker_result=%s trace_result=%s",
                presentation.system_view_trace_frames,
                tostring(marker_result),
                tostring(trace_result))
        end
        local trace_frames = presentation.system_view_trace_frames
        if trace_frames and presentation.system_view_trace_phase == 1 then
            trace_frames = trace_frames - 1
            presentation.system_view_trace_frames = trace_frames
            if trace_frames <= 0 then
                presentation.system_view_trace_frames = nil
                presentation.system_view_trace_phase = nil
                if ui_native_capture then
                    ui_native_capture.dtvr_set_focused_trace_phase(0)
                end
                mod:info("DARKTIDEVR_MENU_TRACE stopped reason=frame_budget")
            end
        end
    end)

-- SystemView owns a dynamic grid outside BaseView._widgets. Resolve the XR
-- source pixel before its hotspot pass and arm only the matching callback on
-- the same atomic pointer/button sample.
presentation.hook_legacy_menu(
    "SystemView",
    "_draw_widgets",
    function(func, self, dt, t, input_service, ui_renderer, ...)
        presentation.system_view_hovered_widget = nil
        presentation.system_view_source_widget = nil
        local pointer = presentation.read_legacy_menu_pointer()
        -- SystemView is captured through a landscape client panel, but its
        -- retained grid remains authored in the portrait eye canvas just like
        -- StoreView. Keep the laser visible in panel pixels and transform only
        -- semantic hotspot tests.
        local hit_pointer = presentation.vendor_eye_layout_pointer(pointer)
        local widgets = self._content_widgets or {}
        for i = 1, #widgets do
            local widget = widgets[i]
            local hotspot = widget and widget.content and
                widget.content.hotspot
            local source_hit =
                presentation.widget_contains_menu_pointer(
                    self, widget, hit_pointer)
            if pointer.available and hotspot then
                hotspot.force_hover = false
            end
            if source_hit and hotspot and not hotspot.disabled and
                    not presentation.system_view_source_widget then
                presentation.system_view_source_widget = widget
                hotspot.force_hover = true
                if pointer.scroll_steps ~= 0 and
                        presentation.scroll_menu_grid(
                            self._content_grid, pointer.scroll_steps) then
                    mod:info(
                        "DARKTIDEVR_MENU_INPUT source_scroll widget=%s steps=%d sequence=%d",
                        tostring(widget.name),
                        pointer.scroll_steps,
                        pointer.last_sequence)
                    presentation.consume_menu_scroll(pointer)
                end
                if pointer.primary_pressed then
                    hotspot.force_input_pressed = true
                    presentation.consume_menu_primary(pointer)
                    mod:info(
                        "DARKTIDEVR_MENU_INPUT source_activate widget=%s sequence=%d source=%d,%d/%dx%d",
                        tostring(widget.name),
                        pointer.last_sequence,
                        pointer.x,
                        pointer.y,
                        pointer.source_width,
                        pointer.source_height)
                end
            end
        end
        local result = func(self, dt, t, input_service, ui_renderer, ...)
        local inventory_requested = false
        local inventory_path =
            "./../mods/darktidevr/darktidevr_hotspot_inventory.flag"
        if Mods and Mods.lua and Mods.lua.io and
                t >= (presentation.hotspot_inventory_last_poll_t or
                    -math.huge) + 0.25 then
            presentation.hotspot_inventory_last_poll_t = t
            local flag = Mods.lua.io.open(inventory_path, "r")
            if flag then
                local request = flag:read("*all")
                flag:close()
                inventory_requested = request and
                    string.find(request, "scan", 1, true) ~= nil
                if inventory_requested then
                    local consumed = Mods.lua.io.open(inventory_path, "w")
                    if consumed then
                        consumed:write("consumed\n")
                        consumed:close()
                    end
                end
            end
        end
        for i = 1, #widgets do
            local widget = widgets[i]
            local hotspot = widget and widget.content and
                widget.content.hotspot
            local source_hit, geometry =
                presentation.widget_contains_menu_pointer(
                    self, widget, hit_pointer)
            if inventory_requested and hotspot then
                local fields = {}
                for key, value in pairs(hotspot) do
                    local lower = string.lower(tostring(key))
                    if type(value) == "boolean" or
                            string.find(lower, "hover", 1, true) or
                            string.find(lower, "focus", 1, true) or
                            string.find(lower, "press", 1, true) or
                            string.find(lower, "select", 1, true) then
                        fields[#fields + 1] =
                            tostring(key) .. "=" .. tostring(value)
                    end
                end
                table.sort(fields)
                mod:info(
                    "DARKTIDEVR_MENU_INPUT hotspot widget=%s index=%d text=%s fields=%s source_hit=%s geometry=%s",
                    tostring(widget.name),
                    i,
                    tostring(widget.content.text),
                    table.concat(fields, ","),
                    tostring(source_hit),
                    geometry and string.format(
                        "pointer=%.1f,%.1f rect=%.1f,%.1f,%.1f,%.1f source=%d,%d/%dx%d",
                        geometry.pointer_x,
                        geometry.pointer_y,
                        geometry.left,
                        geometry.top,
                        geometry.width,
                        geometry.height,
                        pointer.x,
                        pointer.y,
                        pointer.source_width,
                        pointer.source_height) or "unavailable")
            end
            if hotspot and hotspot.is_hover and not hotspot.disabled and
                    not presentation.system_view_hovered_widget then
                presentation.system_view_hovered_widget = widget
            end
        end
        return result
    end)

-- CraftingView inherits _draw_widgets before this mod installs its hooks.  The
-- engine's class helper materializes inherited methods on the derived class,
-- so hooking VendorInteractionViewBase produced no live calls in crafting.
-- Hook the concrete class that owns the active draw dispatch instead.
function presentation.vendor_eye_layout_pointer(pointer)
    if not pointer or not pointer.active or pointer.source_width <= 0 or
            pointer.source_height <= 0 then
        return pointer
    end
    return setmetatable({
        x = pointer.x * ui_eye_target_width / pointer.source_width,
        y = pointer.y * ui_eye_target_height / pointer.source_height,
        source_width = ui_eye_target_width,
        source_height = ui_eye_target_height,
        layout_width = ui_eye_target_width,
        layout_height = ui_eye_target_height,
    }, { __index = pointer })
end

function presentation.draw_vendor_landing_widgets(
        func, self, dt, t, input_service, ui_renderer, render_settings, ...)
    if presentation.mode ~= 5 and presentation.mode ~= 6 then
        return func(
            self, dt, t, input_service, ui_renderer, render_settings, ...)
    end
    local pointer = presentation.read_legacy_menu_pointer()
    local hit_pointer = presentation.vendor_eye_layout_pointer(pointer)
    local widgets = self._button_widgets or {}
    presentation.vendor_landing_hook_logged =
        presentation.vendor_landing_hook_logged or {}
    if not presentation.vendor_landing_hook_logged[self.view_name] then
        presentation.vendor_landing_hook_logged[self.view_name] = true
        mod:info(
            "DARKTIDEVR_MENU_INPUT vendor_landing_hook view=%s widgets=%d",
            tostring(self.view_name), #widgets)
    end
    local source_widget = nil
    for i = 1, #widgets do
        local widget = widgets[i]
        local hotspot = widget and widget.content and widget.content.hotspot
        local source_hit = presentation.widget_contains_menu_pointer(
            self, widget, hit_pointer)
        -- This view can outlive the XR ray for a frame while presentation
        -- ownership changes. Always drain our previous semantic hover instead
        -- of leaving a landing button latched until another pointer sample.
        if hotspot then
            hotspot.force_hover = false
            hotspot.force_input_pressed = false
        end
        if source_hit and hotspot and not hotspot.disabled and
                not source_widget then
            source_widget = widget
            hotspot.force_hover = true
            if pointer.primary_pressed then
                hotspot.force_input_pressed = true
                presentation.consume_menu_primary(pointer)
                mod:info(
                    "DARKTIDEVR_MENU_INPUT vendor_landing_activate view=%s widget=%s sequence=%d source=%d,%d/%dx%d",
                    tostring(self.view_name), tostring(widget.name),
                    pointer.last_sequence, pointer.x, pointer.y,
                    pointer.source_width, pointer.source_height)
            end
        end
    end
    local draw_input = pointer.available and input_service and
        input_service:null_service() or input_service
    return func(
        self, dt, t, draw_input, ui_renderer, render_settings, ...)
end

presentation.hook_legacy_menu(
    require("scripts/ui/views/contracts_background_view/contracts_background_view"),
    "_draw_widgets",
    function(func, self, dt, t, input_service, ui_renderer, render_settings, ...)
        return presentation.draw_vendor_landing_widgets(
            func, self, dt, t, input_service, ui_renderer, render_settings, ...)
    end)

presentation.hook_legacy_menu(
    require("scripts/ui/views/credits_vendor_background_view/credits_vendor_background_view"),
    "_draw_widgets",
    function(func, self, dt, t, input_service, ui_renderer, render_settings, ...)
        return presentation.draw_vendor_landing_widgets(
            func, self, dt, t, input_service, ui_renderer, render_settings, ...)
    end)

presentation.hook_legacy_menu(
    require("scripts/ui/views/cosmetics_vendor_background_view/cosmetics_vendor_background_view"),
    "_draw_widgets",
    function(func, self, dt, t, input_service, ui_renderer, render_settings, ...)
        return presentation.draw_vendor_landing_widgets(
            func, self, dt, t, input_service, ui_renderer, render_settings, ...)
    end)

presentation.hook_legacy_menu(
    require("scripts/ui/views/barber_vendor_background_view/barber_vendor_background_view"),
    "_draw_widgets",
    function(func, self, dt, t, input_service, ui_renderer, render_settings, ...)
        return presentation.draw_vendor_landing_widgets(
            func, self, dt, t, input_service, ui_renderer, render_settings, ...)
    end)

presentation.hook_legacy_menu(
    require("scripts/ui/views/crafting_view/crafting_view"),
    "_draw_widgets",
    function(func, self, dt, t, input_service, ui_renderer, render_settings, ...)
        -- Flat-interactive crafting views deliberately do not join
        -- world_menu_views: their temporary presentation is the same native
        -- window panel used by character select.  Requiring
        -- world_menu_active() here therefore disabled the semantic input path
        -- for every mode-5 shop even though its panel and pointer were live.
        if presentation.mode ~= 5 and presentation.mode ~= 6 then
            return func(self, dt, t, input_service, ui_renderer, render_settings, ...)
        end
        local pointer = presentation.read_legacy_menu_pointer()
        local widgets = self._button_widgets or {}
        if not presentation.vendor_widget_hook_logged then
            presentation.vendor_widget_hook_logged = true
            mod:info(
                "DARKTIDEVR_MENU_INPUT vendor_widget_hook class=%s widgets=%d",
                tostring(self.__class_name or self.view_name),
                #widgets)
        end
        local hit_pointer = presentation.vendor_eye_layout_pointer(pointer)
        local source_widget = nil
        local source_entry = nil
        for i = #widgets, 1, -1 do
            local widget = widgets[i]
            if pointer.available then
                presentation.clear_widget_hotspot_forces(widget)
            end
            if pointer.active and not source_widget and widget then
                local entry = presentation.widget_hotspot_at_pointer(
                    self, widget, hit_pointer)
                if entry and not entry.hotspot.disabled then
                    source_widget = widget
                    source_entry = entry
                end
            end
            if not pointer.active and pointer.primary_pressed and
                    not source_widget and widget then
                local entries = presentation.widget_hotspot_entries(widget)
                for j = #entries, 1, -1 do
                    if entries[j].hotspot.is_hover and
                            not entries[j].hotspot.disabled then
                        source_widget = widget
                        source_entry = entries[j]
                        break
                    end
                end
            end
        end
        if pointer.primary_pressed and not source_widget and
                pointer.primary_press_sequence ~=
                    pointer.vendor_diagnostic_miss_sequence then
            pointer.vendor_diagnostic_miss_sequence =
                pointer.primary_press_sequence
            local diagnostics = {}
            for i = #widgets, 1, -1 do
                local widget = widgets[i]
                local entries = presentation.widget_hotspot_entries(widget)
                for j = #entries, 1, -1 do
                    local entry = entries[j]
                    local hit, geometry =
                        presentation.widget_contains_menu_pointer(
                            self, widget, hit_pointer, entry.style)
                    if geometry and #diagnostics < 24 then
                        diagnostics[#diagnostics + 1] = string.format(
                            "%s:%s:%s:%.1f,%.1f,%.1f,%.1f",
                            tostring(widget.name),
                            tostring(entry.content_id),
                            hit and "hit" or "miss",
                            geometry.left,
                            geometry.top,
                            geometry.width,
                            geometry.height)
                    end
                end
            end
            mod:info(
                "DARKTIDEVR_MENU_INPUT vendor_source_miss class=%s sequence=%d source=%d,%d/%dx%d widgets=%s",
                tostring(self.__class_name or self.view_name),
                pointer.last_sequence,
                pointer.x,
                pointer.y,
                pointer.source_width,
                pointer.source_height,
                #diagnostics > 0 and table.concat(diagnostics, "|") or
                    "none")
        end
        if source_widget and source_entry then
            source_entry.hotspot.force_hover = true
            if pointer.primary_pressed then
                source_entry.hotspot.force_input_pressed = true
                presentation.consume_menu_primary(pointer)
                mod:info(
                    "DARKTIDEVR_MENU_INPUT vendor_option_activate widget=%s sequence=%d source=%d,%d/%dx%d",
                    tostring(source_widget.name),
                    pointer.last_sequence,
                    pointer.x,
                    pointer.y,
                    pointer.source_width,
                    pointer.source_height)
            end
        end
        local result = func(
            self, dt, t, input_service, ui_renderer, render_settings, ...)
        if pointer.primary_pressed and not pointer.available and
                not source_widget then
            for i = #widgets, 1, -1 do
                local widget = widgets[i]
                local entries = presentation.widget_hotspot_entries(widget)
                for j = #entries, 1, -1 do
                    local hotspot = entries[j].hotspot
                    if hotspot.is_hover and not hotspot.disabled and
                            type(hotspot.pressed_callback) == "function" then
                        presentation.consume_menu_primary(pointer)
                        hotspot.pressed_callback()
                        mod:info(
                            "DARKTIDEVR_MENU_INPUT vendor_option_callback widget=%s sequence=%d source=%d,%d/%dx%d",
                            tostring(widget.name),
                            pointer.last_sequence,
                            pointer.x,
                            pointer.y,
                            pointer.source_width,
                            pointer.source_height)
                        return result
                    end
                end
            end
        end
        return result
    end)

presentation.hook_legacy_menu(
    require("scripts/ui/view_elements/view_element_grid/view_element_grid"),
    "_draw_grid",
    function(func, self, dt, t, ui_renderer, input_service, render_settings, ...)
        -- See VendorInteractionViewBase._draw_widgets above.  Mode 5 is the
        -- authoritative gate for the temporary flat shop panel; a world-menu
        -- owner is neither expected nor desired on this path.
        if presentation.mode ~= 5 and presentation.mode ~= 6 then
            return func(self, dt, t, ui_renderer, input_service, render_settings, ...)
        end
        local pointer = presentation.read_legacy_menu_pointer()
        local hit_pointer = presentation.vendor_eye_layout_pointer(pointer)
        local widgets = self._grid_widgets or {}
        local source_widget = nil
        local source_entry = nil
        for i = #widgets, 1, -1 do
            local widget = widgets[i]
            if pointer.available then
                presentation.clear_widget_hotspot_forces(widget)
            end
            if pointer.active and not source_widget and widget and
                    widget.content and widget.content.visible ~= false and
                    (not self._grid or self._grid:is_widget_visible(widget)) then
                local entry = presentation.widget_hotspot_at_pointer(
                    self, widget, hit_pointer)
                if entry and not entry.hotspot.disabled then
                    source_widget = widget
                    source_entry = entry
                end
            end
            if not pointer.active and pointer.primary_pressed and
                    not source_widget and widget and widget.content and
                    widget.content.visible ~= false then
                local entries = presentation.widget_hotspot_entries(widget)
                for j = #entries, 1, -1 do
                    if entries[j].hotspot.is_hover and
                            not entries[j].hotspot.disabled then
                        source_widget = widget
                        source_entry = entries[j]
                        break
                    end
                end
            end
        end
        local interaction_widget = self._widgets_by_name and
            self._widgets_by_name.grid_interaction
        local interaction_hotspot = interaction_widget and
            interaction_widget.content and interaction_widget.content.hotspot
        local previous_interaction_force_hover = interaction_hotspot and
            interaction_hotspot.force_hover
        local previous_interaction_is_hover = interaction_hotspot and
            interaction_hotspot.is_hover
        if pointer.active and interaction_hotspot then
            interaction_hotspot.force_hover = true
            interaction_hotspot.is_hover = true
        end
        if source_widget and source_entry then
            source_entry.hotspot.force_hover = true
            if pointer.scroll_steps ~= 0 and self._grid then
                local scrolled = presentation.scroll_menu_grid(
                    self._grid, pointer.scroll_steps)
                if scrolled then
                    presentation.consume_menu_scroll(pointer)
                end
            end
            if pointer.primary_pressed then
                source_entry.hotspot.force_input_pressed = true
                presentation.consume_menu_primary(pointer)
                mod:info(
                    "DARKTIDEVR_MENU_INPUT element_grid_activate widget=%s sequence=%d source=%d,%d/%dx%d",
                    tostring(source_widget.name),
                    pointer.last_sequence,
                    pointer.x,
                    pointer.y,
                    pointer.source_width,
                    pointer.source_height)
            end
        end
        local result = func(
            self, dt, t, ui_renderer, input_service, render_settings, ...)
        if pointer.primary_pressed and not pointer.available and
                not source_widget then
            for i = #widgets, 1, -1 do
                local widget = widgets[i]
                local entries = presentation.widget_hotspot_entries(widget)
                for j = #entries, 1, -1 do
                    local hotspot = entries[j].hotspot
                    if hotspot.is_hover and not hotspot.disabled and
                            type(hotspot.pressed_callback) == "function" then
                        presentation.consume_menu_primary(pointer)
                        hotspot.pressed_callback()
                        mod:info(
                            "DARKTIDEVR_MENU_INPUT element_grid_callback widget=%s sequence=%d source=%d,%d/%dx%d",
                            tostring(widget.name),
                            pointer.last_sequence,
                            pointer.x,
                            pointer.y,
                            pointer.source_width,
                            pointer.source_height)
                        break
                    end
                end
                if not pointer.primary_pressed then
                    break
                end
            end
        end
        if interaction_hotspot then
            interaction_hotspot.force_hover = previous_interaction_force_hover
            interaction_hotspot.is_hover = previous_interaction_is_hover
        end
        return result
end)

-- Premium StoreView owns a private card grid and draws it before BaseView's
-- conventional widget list. The generic hook can only see the full-grid input
-- catcher, so resolve and arm the actual item hotspot at this class seam.
presentation.hook_legacy_menu(
    require("scripts/ui/views/store_view/store_view"),
    "_draw_grid",
    function(func, self, dt, t, input_service, ...)
        if presentation.mode ~= 6 then
            return func(self, dt, t, input_service, ...)
        end
        local pointer = presentation.read_legacy_menu_pointer()
        -- The published panel/laser remain native landscape, but live Store
        -- card rectangles are retained in the portrait eye scenegraph.
        local hit_pointer = presentation.vendor_eye_layout_pointer(pointer)
        local widgets = self._grid_widgets or {}
        local source_widget = nil
        local source_entry = nil
        for i = #widgets, 1, -1 do
            local widget = widgets[i]
            if pointer.available then
                presentation.clear_widget_hotspot_forces(widget)
            end
            if pointer.active and not source_widget and widget and
                    widget.content and widget.content.visible ~= false then
                local entry = presentation.widget_hotspot_at_pointer(
                    self, widget, hit_pointer)
                if entry and not entry.hotspot.disabled then
                    source_widget = widget
                    source_entry = entry
                end
            end
        end
        local interaction_widget = self._widgets_by_name and
            self._widgets_by_name.grid_interaction
        local interaction_hotspot = interaction_widget and
            interaction_widget.content and interaction_widget.content.hotspot
        local previous_force_hover = interaction_hotspot and
            interaction_hotspot.force_hover
        local previous_is_hover = interaction_hotspot and
            interaction_hotspot.is_hover
        if pointer.active and interaction_hotspot then
            interaction_hotspot.force_hover = true
            -- StoreView samples is_hover before it begins the pass that
            -- applies force_hover. Publish focus for this same atomic input
            -- edge so the real card is not force-disabled on the trigger
            -- frame.
            interaction_hotspot.is_hover = true
        end
        if source_widget and source_entry then
            source_entry.hotspot.force_hover = true
            if pointer.primary_pressed then
                source_entry.hotspot.force_input_pressed = true
                presentation.consume_menu_primary(pointer)
                mod:info(
                    "DARKTIDEVR_MENU_INPUT store_grid_activate widget=%s sequence=%d source=%d,%d/%dx%d",
                    tostring(source_widget.name),
                    pointer.last_sequence,
                    pointer.x,
                    pointer.y,
                    pointer.source_width,
                    pointer.source_height)
            end
        end
        -- The stock Windows cursor is normalized through the hidden render
        -- extent and otherwise remains a second, offset hover owner. While an
        -- XR ray is active, let the semantic force-hover owner above drive the
        -- real card without competing native hover state.
        local draw_input_service = pointer.active and
            input_service:null_service() or input_service
        local result = func(self, dt, t, draw_input_service, ...)
        if interaction_hotspot then
            interaction_hotspot.force_hover = previous_force_hover
            interaction_hotspot.is_hover = previous_is_hover
        end
        return result
    end)

mod:hook_safe("CameraManager", "_update_camera", function(self, _, _, viewport_name)
    if viewport_name ~= primary_viewport_name then
        return
    end

    local ok, error_message = pcall(update_stereo, self)

    if not ok then
        failed = true
        requested = false
        pcall(teardown)
        mod:error("DARKTIDEVR_STEREO failed_closed error=%s", tostring(error_message))
    end
end)

function presentation.world_marker_screen_position(camera, world_position)
    local screen, distance = Camera.world_to_screen(camera, world_position)
    local scale = presentation.render_visibility_scale or 1
    if scale ~= 1 then
        -- Visibility FOV widening is canceled by a render post-projection
        -- transform. CPU marker projection must use that same final mapping.
        -- Camera.world_to_screen defaults to the window backbuffer extent.
        local width, height = Application.back_buffer_size()
        screen = Vector3(
            width * 0.5 + (screen.x - width * 0.5) * scale,
            height * 0.5 + (screen.y - height * 0.5) * scale,
            screen.z)
    end
    return screen, distance
end

mod:hook("HudElementWorldMarkers", "_convert_world_to_screen_position",
    function(func, self, camera, world_position, ...)
        if not active or not stereo_world_markers_requested or not camera then
            return func(self, camera, world_position, ...)
        end
        local screen, distance = presentation.world_marker_screen_position(
            camera, world_position)
        return screen.x, screen.y, distance
    end)

-- Stock _apply_scale eases mutable sizes, offsets and pivots on each draw.
-- Replay must reuse the first eye's result rather than advance it a second time.
mod:hook("HudElementWorldMarkers", "_apply_scale", function(func, self, widget, scale, ...)
    if world_marker_reprojecting then
        return
    end
    return func(self, widget, scale, ...)
end)

-- A wide screen-space popup drawn at each eye's projected anchor keeps the
-- same pixel width in both eyes, but one pixel spans a different angle in each
-- eye at large eccentricity, so its far edge lands at different depths. Give
-- each eye the horizontal scale under which the widget spans the same world
-- extent: project the anchor and a point one reference length to its right
-- (in the head's frame) through both eye cameras and take this eye's share.
local marker_eye_reference_length = 0.25
function presentation.marker_eye_horizontal_scale(camera, other_camera, world_position)
    if not camera or not other_camera or not world_position or
            not presentation.lod_primary_camera then
        return 1
    end
    local head_rotation = ScriptCamera.local_rotation(presentation.lod_primary_camera)
    local right = Quaternion.right(head_rotation)
    local offset_position = world_position + right * marker_eye_reference_length
    local function width(eye_camera)
        local anchor_screen = presentation.world_marker_screen_position(eye_camera, world_position)
        local edge_screen = presentation.world_marker_screen_position(eye_camera, offset_position)
        return math.abs(Vector3.x(edge_screen) - Vector3.x(anchor_screen))
    end
    local this_width = width(camera)
    local other_width = width(other_camera)
    local mean = (this_width + other_width) * 0.5
    if this_width ~= this_width or mean ~= mean or mean < 1e-3 then
        return 1
    end
    return math.max(0.8, math.min(1.25, this_width / mean))
end

-- The interaction popup hangs its boxes off a pivot at the marker; scaling
-- the box widths about that pivot for one eye's draw converges the far edge.
local interaction_popup_nodes = {"background", "description_box", "extra_info_background"}
function presentation.scale_interaction_popup(interaction, factor, render_scale)
    local scenegraph = interaction._ui_scenegraph
    if not scenegraph or factor == 1 then
        return nil
    end
    local saved = {}
    for _, id in ipairs(interaction_popup_nodes) do
        local node = scenegraph[id]
        if node and node.size and type(node.size[1]) == "number" then
            saved[#saved + 1] = {node.size, node.size[1]}
            node.size[1] = node.size[1] * factor
        end
    end
    UIScenegraph.update_scenegraph(scenegraph, render_scale)
    return saved
end
function presentation.restore_interaction_popup(interaction, saved, render_scale)
    if not saved then
        return
    end
    for _, entry in ipairs(saved) do
        entry[1][1] = entry[2]
    end
    UIScenegraph.update_scenegraph(interaction._ui_scenegraph, render_scale)
end
function presentation.interaction_popup_anchor(interaction)
    local data = interaction and interaction._active_presentation_data
    local marker = data and data.marker
    return marker and marker.position and Vector3Box.unbox(marker.position) or nil
end

-- World-marker widgets: scale their pass sizes, offsets and pivots on x for
-- one eye's draw. Text passes keep their box (wrapping must not differ per
-- eye); only their offset moves.
function presentation.scale_marker_widgets(instance, camera, other_camera, exclude)
    local saved = {}
    for _, markers in pairs(instance._markers_by_type or {}) do
        for i = 1, #markers do
            local marker = markers[i]
            if marker.draw and marker.position and marker.widget and
                    not (exclude and exclude[marker.widget]) then
                local factor = presentation.marker_eye_horizontal_scale(
                    camera, other_camera, Vector3Box.unbox(marker.position))
                if factor ~= 1 then
                    for _, pass_style in pairs(marker.widget.style) do
                        if type(pass_style) == "table" then
                            local text = pass_style.font_size ~= nil or pass_style.font_type ~= nil
                            for _, key in ipairs(text and {"offset"} or {"size", "texture_size", "area_size", "offset", "pivot"}) do
                                local value = pass_style[key]
                                if type(value) == "table" and type(value[1]) == "number" then
                                    saved[#saved + 1] = {value, value[1]}
                                    value[1] = value[1] * factor
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return saved
end
function presentation.restore_marker_widgets(saved)
    for _, entry in ipairs(saved) do
        entry[1][1] = entry[2]
    end
end

local function prepare_binocular_clamped_offsets(instance, inverse_scale)
    local offsets = {}
    if not head_render_frusta or not inverse_scale or inverse_scale == 0 then
        return offsets
    end

    -- Match apply_runtime_recentered_projection: these are rotated symmetric
    -- cameras, not raw asymmetric runtime projections. Clamp in shared head
    -- angles, then project relative to each camera's optical centre.
    local aspect = ui_eye_target_width / ui_eye_target_height
    local primary = runtime_recentered_eye(head_render_frusta[1], aspect)
    local replay = runtime_recentered_eye(head_render_frusta[2], aspect)
    local left_min = primary.horizontal_center - primary.horizontal_half
    local left_max = primary.horizontal_center + primary.horizontal_half
    local right_min = replay.horizontal_center - replay.horizontal_half
    local right_max = replay.horizontal_center + replay.horizontal_half
    local overlap_min = math.max(left_min, right_min)
    local overlap_max = math.min(left_max, right_max)
    if overlap_min >= overlap_max then
        return offsets
    end

    local root_size = UIScenegraph.size_scaled(
        instance._ui_scenegraph,
        "screen"
    )
    local root_width = root_size[1] * RESOLUTION_LOOKUP.scale
    local root_height = root_size[2] * RESOLUTION_LOOKUP.scale
    if root_width <= 0 or root_height <= 0 then
        return offsets
    end

    for _, markers in pairs(instance._markers_by_type) do
        for i = 1, #markers do
            local marker = markers[i]
            local angle = marker.angle
            if marker.draw and angle then
                local offset = marker.widget.offset
                local original_x = offset[1]
                local original_y = offset[2]
                local pixel_x = original_x / inverse_scale
                local stock_horizontal_clamp = marker.is_clamped and
                    (math.abs(angle) < 0.001 or
                        math.abs(math.abs(angle) - math.pi) < 0.001)
                local overlap_width = overlap_max - overlap_min
                local projected_tangent = primary.horizontal_center + math.atan(
                    (2 * pixel_x / root_width - 1) *
                        math.tan(primary.horizontal_half))
                local pair_clamped_left = projected_tangent < overlap_min
                local pair_clamped_right = projected_tangent > overlap_max
                local allow_clamp = marker.template.screen_clamp and
                    not marker.block_screen_clamp
                if not allow_clamp and
                        (pair_clamped_left or pair_clamped_right) then
                    -- Preserve the template's offscreen policy. Previously
                    -- non-clamping markers piled up at the primary eye's
                    -- wider edge, but stock culling removed them on the other
                    -- side before this draw hook could run. Cull at the shared
                    -- boundary for both eyes; normal calculation refreshes
                    -- marker.draw next frame.
                    marker.draw = false
                elseif stock_horizontal_clamp or pair_clamped_left or
                        pair_clamped_right then
                    local clamped_left = stock_horizontal_clamp and
                        pixel_x < root_width * 0.5 or pair_clamped_left
                    local shared_tangent
                    if stock_horizontal_clamp then
                        local margin_fraction = clamped_left and
                            pixel_x / root_width or
                            (root_width - pixel_x) / root_width
                        margin_fraction = math.max(
                            0,
                            math.min(margin_fraction, 0.25)
                        )
                        shared_tangent = clamped_left and
                            overlap_min + overlap_width * margin_fraction or
                            overlap_max - overlap_width * margin_fraction
                    else
                        -- A marker can remain inside the first eye's stock
                        -- frustum after it has already left the other eye.
                        -- Switch both draws to a shared overlap-edge position
                        -- at that point, with a small centre inset so the
                        -- marker does not straddle the physical eye boundary.
                        local overlap_inset = overlap_width * 0.02
                        shared_tangent = clamped_left and
                            overlap_min + overlap_inset or
                            overlap_max - overlap_inset
                    end
                    local left_x = (0.5 + 0.5 * math.tan(
                        shared_tangent - primary.horizontal_center) /
                        math.tan(primary.horizontal_half)) *
                        root_width * inverse_scale
                    -- A pinned marker represents one direction. Reproject
                    -- that full ray between optical frames: copying Y while
                    -- correcting only horizontal angles diverges under pitch
                    -- and increasingly oblique viewing directions.
                    local primary_ray = Vector3(
                        (2 * left_x / (root_width * inverse_scale) - 1) *
                            math.tan(primary.horizontal_half),
                        1,
                        (2 * original_y / (root_height * inverse_scale) - 1) *
                            math.tan(primary.vertical_fov * 0.5))
                    local replay_ray = Quaternion.rotate(
                        presentation.inverse_quaternion(replay.rotation),
                        Quaternion.rotate(primary.rotation, primary_ray))
                    local right_x = (0.5 + 0.5 * replay_ray.x / replay_ray.y /
                        math.tan(replay.horizontal_half)) * root_width * inverse_scale
                    local right_y = (0.5 + 0.5 * replay_ray.z / replay_ray.y /
                        math.tan(replay.vertical_fov * 0.5)) * root_height * inverse_scale
                    offsets[marker] = {
                        original_x = original_x,
                        original_y = original_y,
                        left_x = left_x,
                        right_x = right_x,
                        y = right_y
                    }
                    -- The first draw must also use the shared angular clamp.
                    -- A numerically identical texture coordinate in both
                    -- eyes is not binocular because the runtime eye frusta
                    -- are asymmetric.
                    offset[1] = left_x
                end
            end
        end
    end
    return offsets
end

mod:hook(
    "HudElementWorldMarkers",
    "_draw_markers",
    function(func, self, dt, t, input_service, ui_renderer, render_settings, ...)
        local capture = active and stereo_world_markers_requested and
            not presentation.marker_reprojection_probe_disabled and
            not world_marker_reprojecting
        local inverse_scale = ui_renderer.inverse_scale or
            render_settings.inverse_scale or 1
        local binocular_offsets = nil
        if capture then
            binocular_offsets = prepare_binocular_clamped_offsets(
                self,
                inverse_scale
            )
        end

        if capture then
            -- Unclamped markers whose passes the world route covers draw on
            -- a plane through their anchor; clamped ones and the rest keep
            -- the per-eye 2D route below.
            local plane_widgets = nil
            if presentation.marker_plane_enabled() then
                plane_widgets = {}
                presentation.marker_atlas.begin_frame(t)
                local routed, fallback = 0, 0
                for marker_type, markers in pairs(self._markers_by_type or {}) do
                    for i = 1, #markers do
                        local marker = markers[i]
                        if marker.draw and marker.position and marker.widget then
                            local scope, reason
                            if marker.is_clamped then
                                reason = "clamped"
                            else
                                local admitted, why = presentation.marker_world.admits(marker.widget)
                                if admitted then
                                    scope, reason = presentation.marker_plane_scope(ui_renderer,
                                        Vector3Box.unbox(marker.position), self._player_camera, t,
                                        marker_type)
                                else
                                    reason = why
                                end
                            end
                            if scope then
                                plane_widgets[marker.widget] = scope
                                routed = routed + 1
                            else
                                fallback = fallback + 1
                                presentation.marker_plane_note(reason)
                            end
                        end
                    end
                end
                presentation.marker_plane_report(routed, fallback)
            end
            presentation.marker_plane_widgets = plane_widgets
            presentation.marker_world.end_dump_frame()
        end

        local result
        if capture or world_marker_reprojecting then
            -- Each eye draws the marker widgets under its own horizontal scale
            -- so wide badges span one world extent in both eyes.
            local eye_camera = self._player_camera
            local other_camera = world_marker_reprojecting and
                presentation.lod_primary_camera or presentation.lod_right_camera
            local function draw_scaled(...)
                local saved = presentation.scale_marker_widgets(self, eye_camera, other_camera,
                    presentation.marker_plane_widgets)
                local results = {pcall(func, ...)}
                presentation.restore_marker_widgets(saved)
                if not results[1] then error(results[2], 0) end
                return unpack(results, 2)
            end
            result = presentation.marker_metrics.draw(ui_renderer, "markers", self,
                t, world_marker_reprojecting and 2 or 1,
                capture and presentation.marker_gui.draw or nil, draw_scaled,
                self, dt, t, input_service, ui_renderer, render_settings, ...)
        else
            result = func(self, dt, t, input_service, ui_renderer, render_settings, ...)
        end

        if capture then
            world_markers_context = {
                instance = self,
                dt = dt,
                t = t,
                input_service = input_service,
                ui_renderer = ui_renderer,
                render_settings = render_settings,
                -- UIRenderer.end_pass clears this transient field before the
                -- level-world submission hook runs, so retain the scalar now.
                inverse_scale = inverse_scale,
                binocular_offsets = binocular_offsets
            }
            world_markers_context.render_settings =
                presentation.marker_gui.snapshot_settings(render_settings)
        end

        return result
    end
)

-- The interaction prompt (for example "[F] Inspect Operative") is a separate
-- HUD element, but its scenegraph pivot is copied from the active world-marker
-- widget. Capture its left-eye primitives into the same removable set and
-- replay it after the marker pivot has been reprojected for the right eye.
mod:hook(
    "HudElementInteraction",
    "_draw_widgets",
    function(func, self, dt, t, input_service, ui_renderer, render_settings, ...)
        local capture = active and stereo_world_markers_requested and
            not presentation.marker_reprojection_probe_disabled and
            not world_marker_reprojecting
        if capture then
            local presentation = self._active_presentation_data
            if presentation and presentation.marker then
                -- HudElementInteraction copies its pivot during update, while
                -- HudElementWorldMarkers can project the source marker later
                -- in the same frame. Refresh at the draw boundary so the
                -- normal left-eye draw and the right-eye replay both consume
                -- a marker coordinate produced for their own camera.
                self:_update_interaction_hud_position(0, t)
                UIScenegraph.update_scenegraph(
                    self._ui_scenegraph,
                    render_settings.scale
                )
            end
        end

        local result
        local plane_scope = nil
        if capture and presentation.marker_plane_enabled() then
            local anchor = presentation.interaction_popup_anchor(self)
            local markers_element = Managers.ui and Managers.ui._hud and
                Managers.ui._hud.element and Managers.ui._hud:element("HudElementWorldMarkers")
            plane_scope = anchor and presentation.marker_plane_scope(ui_renderer, anchor,
                markers_element and markers_element._player_camera, t,
                "hud_interaction_popup") or nil
            if plane_scope and plane_scope.surface == "atlas" then
                -- Worn: on the plane the popup sits high against its marker
                -- (still on the per-eye route); lower it by a fraction of
                -- the popup's own background height.
                local size = self:scenegraph_size("background")
                local drop = size and size[2] * (ui_renderer.scale or 1) *
                    presentation.interaction_popup_drop or 0
                plane_scope.origin_y = plane_scope.origin_y - drop
            end
            presentation.interaction_plane_t = plane_scope and t or nil
            presentation.interaction_plane_scope = plane_scope
        elseif world_marker_reprojecting and presentation.interaction_plane_t == t then
            local replay_scope = presentation.interaction_plane_scope
            if not replay_scope or replay_scope.surface ~= "screen" then
                -- The world surface already serves both eyes.
                return nil
            end
            return presentation.marker_metrics.draw(ui_renderer, "interaction", self,
                t, 2, nil,
                function(...) return presentation.marker_world.draw(replay_scope, "right", func, ...) end,
                self, dt, t, input_service, ui_renderer, render_settings, ...)
        end
        if plane_scope then
            result = presentation.marker_metrics.draw(ui_renderer, "interaction", self,
                t, 1, presentation.marker_gui.draw,
                function(...) return presentation.marker_world.draw(plane_scope, "left", func, ...) end,
                self, dt, t, input_service, ui_renderer, render_settings, ...)
        elseif capture or world_marker_reprojecting then
            -- The popup's boxes take this eye's horizontal scale about the
            -- marker pivot, so their far edge converges in stereo.
            local eye_camera = world_marker_reprojecting and
                presentation.lod_right_camera or presentation.lod_primary_camera
            local other_camera = world_marker_reprojecting and
                presentation.lod_primary_camera or presentation.lod_right_camera
            local anchor = presentation.interaction_popup_anchor(self)
            local factor = anchor and presentation.marker_eye_horizontal_scale(
                eye_camera, other_camera, anchor) or 1
            local render_scale = render_settings and render_settings.scale
            local function draw_scaled(...)
                local saved = presentation.scale_interaction_popup(self, factor, render_scale)
                local results = {pcall(func, ...)}
                presentation.restore_interaction_popup(self, saved, render_scale)
                if not results[1] then error(results[2], 0) end
                return unpack(results, 2)
            end
            result = presentation.marker_metrics.draw(ui_renderer, "interaction", self,
                t, world_marker_reprojecting and 2 or 1,
                capture and presentation.marker_gui.draw or nil, draw_scaled,
                self, dt, t, input_service, ui_renderer, render_settings, ...)
        else
            result = func(self, dt, t, input_service, ui_renderer, render_settings, ...)
        end

        if capture then
            interaction_hud_context = {
                instance = self,
                dt = dt,
                t = t,
                input_service = input_service,
                ui_renderer = ui_renderer,
                render_settings = render_settings
            }
            interaction_hud_context.render_settings =
                presentation.marker_gui.snapshot_settings(render_settings)
        end

        return result
    end
)

-- The hand the tag ray leaves: the off hand while it points (the tag gesture),
-- otherwise the weapon hand, as VR tagging has always done.
function presentation.tag_role()
    if not presentation.tag_gesture then return "dominant" end
    local ok, role = pcall(presentation.tag_gesture.role)
    return ok and role or "dominant"
end

mod:hook("HudElementSmartTagging", "_find_raycast_targets",
    function(func, self, force_update_targets, ...)
        local aim = presentation.controller_aim
        local role = presentation.tag_role()
        -- Pointing with the off hand: let the stock path run. It calls
        -- force_update_smart_tag_targets, which darktidevr_controller_aim
        -- hooks and runs through this same role, so the trace leaves the
        -- pointing hand. The override below exists only for the weapon hand,
        -- whose reticle is already traced and cached; there is no cached
        -- reticle for the off hand, and using the weapon's would mean the
        -- gesture changed nothing at all.
        if role ~= "dominant" then return func(self, force_update_targets, ...) end
        local position, rotation = aim.target(role)
        if not position or not rotation then return func(self, force_update_targets, ...) end
        local point, unit = aim.cached_reticle_target()
        local player_unit = self._parent:player_unit()
        local extension = unit and Unit.alive(unit) and ScriptUnit.has_extension(unit,"smart_tag_system")
        if not extension or not extension:can_tag(player_unit) then unit = nil end
        return {unit=unit,static_hit_position=point}
    end)

mod:hook("HudElementSmartTagging", "_find_world_marker_target",
    function(func, self, ui_renderer, render_settings, ...)
        -- The marker hover follows the same hand as the tag above.
        local aim_position, aim_rotation = presentation.controller_aim.target(presentation.tag_role())
        local simulation_aim = presentation.online_rules.simulation_aim_active(self._parent:player_unit())
        if not simulation_aim and (not aim_position or not aim_rotation) then
            return func(self, ui_renderer, render_settings, ...)
        end
        -- The stock screen-centre hover test overrides the controller ray.
        -- Use the same smart-targeting result as the actual tag action.
        Managers.event:trigger("request_world_markers_list",
            callback(self, "_cb_world_markers_list_request"))
        local data = self:_find_raycast_targets(false)
        local marker = data and data.unit and self:_find_marker_by_unit(data.unit)
        local distance = marker and marker.widget and marker.widget.content.distance
        if marker and distance and self:_is_marker_valid_for_tagging(
                self._parent:player_unit(), marker, distance) then
            return marker, distance
        end
        return nil, math.huge
    end)

function presentation.draw_tag_prompt(self, dt, t, input_service, ui_renderer, render_settings)
    local data = self._active_interaction_data
    local marker = data and data.marker
    if not marker or not marker.widget or marker.deleted then return end
    local widget = self._interaction_line_widget
    local offset = widget.offset
    local x, y = offset[1], offset[2]
    offset[1], offset[2] = marker.widget.offset[1] + 50, marker.widget.offset[2] + 50
    local ok, err = pcall(require("scripts/managers/ui/ui_widget").draw, widget, ui_renderer)
    offset[1], offset[2] = x, y
    if not ok then error(err, 0) end
end

mod:hook("HudElementSmartTagging", "_draw_active_interaction_line",
    function(func, self, dt, t, input_service, ui_renderer, render_settings, ...)
        if not active or not stereo_world_markers_requested or
                presentation.marker_reprojection_probe_disabled then
            return func(self, dt, t, input_service, ui_renderer, render_settings, ...)
        end
        if world_marker_reprojecting then
            if presentation.tag_plane_t == t then
                local replay_scope = presentation.tag_plane_scope
                if not replay_scope or replay_scope.surface ~= "screen" then return end
                return presentation.marker_metrics.draw(ui_renderer, "tag", self, t, 2,
                    nil, function(...) return presentation.marker_world.draw(replay_scope, "right",
                        presentation.draw_tag_prompt, ...) end,
                    self, dt, t, input_service, ui_renderer, render_settings)
            end
            return presentation.marker_metrics.draw(ui_renderer, "tag", self, t, 2,
                nil, presentation.draw_tag_prompt,
                self, dt, t, input_service, ui_renderer, render_settings)
        end
        presentation.tag_hud_context = {instance=self,t=t,input_service=input_service,
            ui_renderer=ui_renderer,
            render_settings=presentation.marker_gui.snapshot_settings(render_settings)}
        local data = self._active_interaction_data
        local marker = data and data.marker
        local plane_scope = nil
        if marker and marker.position and not marker.is_clamped and
                presentation.marker_plane_enabled() then
            local markers_element = Managers.ui and Managers.ui._hud and
                Managers.ui._hud.element and Managers.ui._hud:element("HudElementWorldMarkers")
            plane_scope = presentation.marker_plane_scope(ui_renderer,
                Vector3Box.unbox(marker.position),
                markers_element and markers_element._player_camera, t, "hud_tag_prompt")
        end
        presentation.tag_plane_t = plane_scope and t or nil
        presentation.tag_plane_scope = plane_scope
        if plane_scope then
            return presentation.marker_metrics.draw(ui_renderer, "tag", self, t, 1,
                presentation.marker_gui.draw,
                function(...) return presentation.marker_world.draw(plane_scope, "left",
                    presentation.draw_tag_prompt, ...) end,
                self, dt, t, input_service, ui_renderer, render_settings)
        end
        return presentation.marker_metrics.draw(ui_renderer, "tag", self, t, 1,
            presentation.marker_gui.draw, presentation.draw_tag_prompt,
            self, dt, t, input_service, ui_renderer, render_settings)
    end)

local function enqueue_world_markers_for_camera(camera)
    local context = world_markers_context
    if not presentation.marker_gui.can_replay(context, Managers.ui._hud,
            Managers.time:time("main")) then
        world_markers_context = nil
        interaction_hud_context = nil
        presentation.tag_hud_context = nil
        return false
    end
    if not context or not camera then
        return false
    end

    local instance = context.instance
    local original_camera = instance._player_camera
    if not original_camera or original_camera == camera then
        return false
    end

    -- The normal HUD update already stored a world position and left-eye
    -- screen coordinate for every marker. Apply only the projection delta for
    -- the right eye. This avoids replaying lifetime, raycast, animation and
    -- template-update side effects outside their normal update scope.
    local inverse_scale = context.inverse_scale
    local adjusted_offsets = {}
    for _, markers in pairs(instance._markers_by_type) do
        for i = 1, #markers do
            local marker = markers[i]
            if marker.draw and marker.position then
                local world_position = Vector3Box.unbox(marker.position)
                local offset = marker.widget.offset
                local binocular = context.binocular_offsets and
                    context.binocular_offsets[marker]
                adjusted_offsets[#adjusted_offsets + 1] = {
                    offset = offset,
                    x = binocular and binocular.original_x or offset[1],
                    y = binocular and binocular.original_y or offset[2]
                }

                if binocular then
                    offset[1] = binocular.right_x
                    offset[2] = binocular.y
                else
                    local left_screen = presentation.world_marker_screen_position(
                        original_camera,
                        world_position
                    )
                    local right_screen = presentation.world_marker_screen_position(
                        camera,
                        world_position
                    )
                    offset[1] = offset[1] +
                        (right_screen.x - left_screen.x) * inverse_scale
                    offset[2] = offset[2] +
                        (right_screen.y - left_screen.y) * inverse_scale
                end
            end
        end
    end

    instance._player_camera = camera

    context.render_settings.start_layer = instance._draw_layer
    UIRenderer.begin_pass(
        context.ui_renderer,
        instance._ui_scenegraph,
        context.input_service,
        0,
        context.render_settings
    )
    world_marker_reprojecting = true
    instance:_draw_markers(
        0,
        context.t,
        context.input_service,
        context.ui_renderer,
        context.render_settings
    )
    world_marker_reprojecting = false
    UIRenderer.end_pass(context.ui_renderer)

    local interaction_context = interaction_hud_context
    if interaction_context and (interaction_context.t ~= context.t or
            interaction_context.instance._parent ~= instance._parent) then
        interaction_context = nil
    end
    if interaction_context then
        local interaction = interaction_context.instance
        local presentation = interaction._active_presentation_data
        if presentation and presentation.marker then
            -- The marker widget currently contains the right-eye coordinate.
            -- Rebuild only the dependent interaction pivot, then enqueue the
            -- interaction widgets through their normal draw implementation.
            interaction:_update_interaction_hud_position(
                0,
                interaction_context.t
            )
            UIScenegraph.update_scenegraph(
                interaction._ui_scenegraph,
                interaction_context.render_settings.scale
            )
            UIRenderer.begin_pass(
                interaction_context.ui_renderer,
                interaction._ui_scenegraph,
                interaction_context.input_service,
                0,
                interaction_context.render_settings
            )
            world_marker_reprojecting = true
            interaction:_draw_widgets(
                0,
                interaction_context.t,
                interaction_context.input_service,
                interaction_context.ui_renderer,
                interaction_context.render_settings
            )
            world_marker_reprojecting = false
            UIRenderer.end_pass(interaction_context.ui_renderer)
        end
    end
    local tag_context = presentation.tag_hud_context
    if tag_context and tag_context.t == context.t then
        local tag = tag_context.instance
        UIRenderer.begin_pass(tag_context.ui_renderer, tag._ui_scenegraph,
            tag_context.input_service, 0, tag_context.render_settings)
        world_marker_reprojecting = true
        tag:_draw_active_interaction_line(0, tag_context.t, tag_context.input_service,
            tag_context.ui_renderer, tag_context.render_settings)
        world_marker_reprojecting = false
        UIRenderer.end_pass(tag_context.ui_renderer)
    end
    instance._player_camera = original_camera

    -- Gui draw commands retain the positions passed above. Restore Darktide's
    -- left-eye widget state for the next normal HUD update and for any code
    -- that inspects markers after rendering.
    for i = 1, #adjusted_offsets do
        local saved = adjusted_offsets[i]
        saved.offset[1] = saved.x
        saved.offset[2] = saved.y
    end

    if interaction_context then
        local interaction = interaction_context.instance
        local presentation = interaction._active_presentation_data
        if presentation and presentation.marker then
            interaction:_update_interaction_hud_position(
                0,
                interaction_context.t
            )
            UIScenegraph.update_scenegraph(
                interaction._ui_scenegraph,
                interaction_context.render_settings.scale
            )
        end
    end
    return true
end

mod:hook(
    "UIWorldSpawner",
    "create_viewport",
    function(func, self, camera_unit, viewport_name, viewport_type,
            viewport_layer, shading_environment, shading_callback,
            render_targets, ...)
        local key = tostring(self._world_name) .. ":" .. tostring(viewport_name)

        if not observed_ui_viewports[key] then
            observed_ui_viewports[key] = true
            mod:info(
                "DARKTIDEVR_UI_VIEWPORT world=%s viewport=%s type=%s layer=%s",
                tostring(self._world_name),
                tostring(viewport_name),
                tostring(viewport_type),
                tostring(viewport_layer)
            )
        end

        local target_main_menu = ui_stereo_requested and
            ui_offscreen_requested and
            ui_offscreen_primary_requested and
            not presentation.flat_panel_views.main_menu_view and
            self._world_name == "ui_main_menu_world" and
            viewport_name == "ui_main_menu_world_viewport"

        if target_main_menu then
            assert(ensure_ui_native_hooks() and refresh_xr_render_extent(),
                "menu eye targets require the active OpenXR render extent")
            destroy_ui_offscreen_resources()
            ui_left_output_target = create_eye_render_target(
                "darktidevr_left_eye_output",
                ui_eye_target_width,
                ui_eye_target_height
            )
            ui_left_render_target = create_eye_render_target(
                "darktidevr_left_eye_final",
                ui_eye_target_width,
                ui_eye_target_height
            )
            render_targets = eye_render_target_mapping(
                ui_left_output_target,
                ui_left_render_target
            )
            viewport_type = "default_with_alpha"
        end

        local result = func(
            self,
            camera_unit,
            viewport_name,
            viewport_type,
            viewport_layer,
            shading_environment,
            shading_callback,
            render_targets, ...
        )

        local target_main_menu_viewport =
            self._world_name == "ui_main_menu_world" and
            viewport_name == "ui_main_menu_world_viewport"

        if ui_native_observer_requested and target_main_menu_viewport then
            if ensure_ui_native_hooks() then
                local marker_result = ui_native_capture.dtvr_enable_marker_log()

                if marker_result ~= 0 then
                    mod:warning("DARKTIDEVR_STEREO marker_log code=%d", marker_result)
                end

                if ui_table4_alias_probe_requested then
                    ui_native_capture.dtvr_enable_table4_alias()
                end

                if ui_candidate_instance_clamp_requested then
                    local clamp_result =
                        ui_native_capture.dtvr_enable_candidate_instance_clamp()
                    mod:info(
                        "DARKTIDEVR_STEREO candidate_instance_clamp enabled result=%d",
                        tonumber(clamp_result)
                    )
                end

                if ui_candidate_table4_probe_requested then
                    local alias_result =
                        ui_native_capture.dtvr_enable_candidate_table4_alias()
                    local clamp_result =
                        ui_native_capture.dtvr_enable_candidate_instance_clamp()
                    mod:info(
                        "DARKTIDEVR_STEREO candidate_table4 enabled alias=%d clamp=%d",
                        tonumber(alias_result),
                        tonumber(clamp_result)
                    )
                end
            end
        end

        if target_main_menu then

            local native_ready = true
            if ui_native_capture_requested then
                native_ready = enable_ui_native_capture()
            end

            if native_ready and ui_present_capture_requested then
                native_ready = ensure_ui_native_hooks()
                if native_ready then
                    ui_native_capture.dtvr_enable_present_capture()
                end
            end

            local ok = native_ready
            local error_message = native_ready and nil or
                "native capture hooks unavailable"
            if native_ready then
                ok, error_message = pcall(setup_ui_stereo, self)
            end

            if not ok then
                mod:error(
                    "DARKTIDEVR_STEREO ui_setup_failed error=%s",
                    tostring(error_message)
                )
            end
        end


        return result
    end
)

mod:hook_safe("UIWorldSpawner", "_update_camera", function(self)
    if self == ui_stereo_spawner then
        local ok, error_message = pcall(apply_ui_eye_offsets, self)

        if not ok then
            mod:error(
                "DARKTIDEVR_STEREO ui_update_failed error=%s",
                tostring(error_message)
            )
            ui_stereo_spawner = nil
            ui_stereo_world = nil
            ui_stereo_right_viewport = nil
        end
    end
end)

local function update_ui_offscreen_trace()
    if not ui_offscreen_trace_requested or ui_offscreen_trace_complete or
            not ui_offscreen_active or not ui_native_capture then
        return
    end

    ui_offscreen_trace_frame = ui_offscreen_trace_frame + 1
    if ui_offscreen_trace_frame == ui_offscreen_trace_warmup_frames then
        local result = ui_native_capture.dtvr_set_focused_trace_phase(1)
        mod:info(
            "DARKTIDEVR_STEREO offscreen_trace sample_start result=%d",
            tonumber(result)
        )
    elseif ui_offscreen_trace_frame ==
            ui_offscreen_trace_warmup_frames +
                4 then
        ui_native_capture.dtvr_set_focused_trace_phase(0)
        ui_offscreen_trace_complete = true
        mod:info(
            "DARKTIDEVR_STEREO offscreen_trace complete records=%d",
            tonumber(ui_native_capture.dtvr_focused_trace_count())
        )
    end
end

-- Level stories can animate the menu camera after UIWorldSpawner.update. Copy
-- the final primary pose at the last reliable boundary before the world is
-- submitted, so the duplicate cannot lag or remain at its creation pose.
mod:hook(ScriptWorld, "render", function(func, world, ...)
    if presentation.render_world_census then presentation.render_world_census.observe(world) end
    if presentation.hud_panel then presentation.hud_panel.observe_render(world) end
    -- The body copy read again after the engine's render call, whichever
    -- of the branches below makes it (darktidevr_body_mirror
    -- check_after_render, 19 September): the original is wrapped once here.
    if presentation.body_mirror and presentation.body_mirror.check_after_render then
        local original_render = func
        func = function(rendered_world, ...)
            local results = {original_render(rendered_world, ...)}
            pcall(presentation.body_mirror.check_after_render, rendered_world)
            return unpack(results)
        end
    end
    -- The drawn body at the render boundary, after the engine's own world
    -- update: a read-only check of whether anything moved the copy since it
    -- was posed before that update
    -- (darktidevr_body_mirror, 19 September). At the top of the hook, for
    -- every world: the 12:22 worn run had it inside the native-capture
    -- branch below, which this configuration never takes, so zero checks
    -- read as a clean result. The module answers only for its own world.
    if presentation.body_mirror and presentation.body_mirror.check_before_render then
        pcall(presentation.body_mirror.check_before_render, world)
    end
    if world == ui_stereo_world and ui_stereo_spawner then
        local ui_mark = presentation.frame_profile.begin()
        update_ui_alternating_full()
        update_ui_full_origin_ab()
        update_ui_rect_matrix()
        update_ui_rect_trace()
        update_ui_focused_ab_trace()
        update_ui_offscreen_trace()
        local ok, error_message = pcall(apply_ui_eye_offsets, ui_stereo_spawner)

        if not ok then
            mod:error(
                "DARKTIDEVR_STEREO ui_pre_render_sync_failed error=%s",
                tostring(error_message)
            )
        end
        presentation.frame_profile.finish("render.ui_stereo_sync", ui_mark)
    end

    if world == active_world and active and ui_native_capture_active and
            ui_native_capture then
        if presentation.body_proxy then
            presentation.body_proxy.check_rigid_hands_before_render()
        end
        presentation.update_performance_pass_trace()
        local primary = ScriptWorld.viewport(world, primary_viewport_name)
        local right = ScriptWorld.viewport(world, right_viewport_name)
        local first = primary
        local second = right
        local first_eye = 0
        local second_eye = 1
        if presentation.reverse_eye_order_probe_requested then
            first = right
            second = primary
            first_eye = 1
            second_eye = 0
        end
        if not first or not second then
            -- During a scene transition (the second entry into the
            -- Psykhanium, for one) the world renders before its player
            -- viewports exist; activating a nil viewport is a Lua crash in
            -- ScriptWorld. Let stock render the world alone this frame.
            if not presentation.viewport_pair_missing_logged then
                presentation.viewport_pair_missing_logged = true
                mod:info("DARKTIDEVR_STEREO viewport_pair=missing primary=%s right=%s action=stock_render",
                    tostring(primary ~= nil), tostring(right ~= nil))
            end
            return func(world, ...)
        end
        presentation.viewport_pair_missing_logged = nil

        if ui_native_sync_requested and not ui_native_sync_initialized then
            ui_native_capture.dtvr_reset_eye_capture_tags()
            ui_native_sync_initialized = true
        end

        ScriptWorld.activate_viewport(world, first)
        ScriptWorld.deactivate_viewport(world, second)
        if ui_reset_dlss_each_eye_requested then
            Application.reset_dlss()
        end
        local left_target = tonumber(
            ui_native_capture.dtvr_boundary_eye_capture_count(first_eye)
        ) + 1
        report_native_capture_result(arm_eye_capture(first_eye))
        presentation.trace_body_capture_boundary("before_left")
        local pair_start = performance_tick()
        local left_start = pair_start
        local result = func(world, ...)
        local left_end = performance_tick()
        presentation.trace_body_capture_boundary("after_left")
        if ui_direct_swapchain_capture_requested then
            report_native_capture_result(
                ui_native_capture.dtvr_capture_armed_swapchain_eye(first_eye)
            )
        elseif ui_native_sync_requested then
            wait_for_eye_capture(first_eye, left_target)
        end

        ScriptWorld.deactivate_viewport(world, first)
        ScriptWorld.activate_viewport(world, second)
        -- With the same-frame stream reuse (melee swing add-on) the second
        -- eye draws the first eye's world state; a right-eye replay would only
        -- land a frame late on top of the left one (doubled door labels).
        if stereo_world_markers_requested and
                not presentation.same_frame_reuse_active then
            local marker_ok, marker_result = pcall(
                function()
                    presentation.marker_gui.hide()
                    if not presentation.marker_reprojection_probe_disabled then
                        enqueue_world_markers_for_camera(
                            ScriptViewport.camera(second)
                        )
                    end
                end
            )
            if not marker_ok then
                -- A failed replay must not leave later normal draws routed
                -- through the reprojection path.
                world_marker_reprojecting = false
                stereo_world_markers_requested = false
                mod:error(
                    "DARKTIDEVR_STEREO marker_reprojection_failed error=%s",
                    tostring(marker_result)
                )
            end
        end
        if ui_reset_dlss_each_eye_requested then
            Application.reset_dlss()
        end
        local right_target = tonumber(
            ui_native_capture.dtvr_boundary_eye_capture_count(second_eye)
        ) + 1
        report_native_capture_result(arm_eye_capture(second_eye))
        local right_start = performance_tick()
        if not render_eye_from_prepared_frame(
                world, first, second) then
            func(world, ...)
        end
        local right_end = performance_tick()
        presentation.trace_body_capture_boundary("after_right")
        if ui_direct_swapchain_capture_requested then
            report_native_capture_result(
                ui_native_capture.dtvr_capture_armed_swapchain_eye(second_eye)
            )
        elseif ui_native_sync_requested then
            wait_for_eye_capture(second_eye, right_target)
        end

        -- Restore the normal active set for update code outside this hook.
        ScriptWorld.activate_viewport(world, primary)
        record_render_timings(
            "gameplay",
            left_start and left_end and left_end - left_start or nil,
            right_start and right_end and right_end - right_start or nil,
            pair_start and right_end and right_end - pair_start or nil
        )
        report_native_observer()
        return result
    end

    if world == ui_stereo_world and ui_stereo_spawner and
            ui_native_capture_active and ui_native_capture then
        local primary = ui_stereo_spawner._viewport
        local right = ui_stereo_right_viewport

        if ui_native_sync_requested and not ui_native_sync_initialized then
            ui_native_capture.dtvr_reset_eye_capture_tags()
            ui_native_sync_initialized = true
        end

        ScriptWorld.activate_viewport(world, primary)
        ScriptWorld.deactivate_viewport(world, right)
        if ui_reset_dlss_each_eye_requested then
            Application.reset_dlss()
        end
        local left_target = tonumber(
            ui_native_capture.dtvr_boundary_eye_capture_count(0)
        ) + 1
        report_native_capture_result(arm_eye_capture(0))
        local pair_start = performance_tick()
        local left_start = pair_start
        local result = func(world, ...)
        local left_end = performance_tick()
        if ui_direct_swapchain_capture_requested then
            report_native_capture_result(
                ui_native_capture.dtvr_capture_armed_swapchain_eye(0)
            )
        elseif ui_native_sync_requested then
            wait_for_eye_capture(0, left_target)
        end

        ScriptWorld.deactivate_viewport(world, primary)
        ScriptWorld.activate_viewport(world, right)
        if ui_reset_dlss_each_eye_requested then
            Application.reset_dlss()
        end
        local right_target = tonumber(
            ui_native_capture.dtvr_boundary_eye_capture_count(1)
        ) + 1
        report_native_capture_result(arm_eye_capture(1))
        local right_start = performance_tick()
        if not render_eye_from_prepared_frame(
                world, primary, right) then
            func(world, ...)
        end
        local right_end = performance_tick()
        if ui_direct_swapchain_capture_requested then
            report_native_capture_result(
                ui_native_capture.dtvr_capture_armed_swapchain_eye(1)
            )
        elseif ui_native_sync_requested then
            wait_for_eye_capture(1, right_target)
        end
        ScriptWorld.activate_viewport(world, primary)

        record_render_timings(
            "character_select",
            left_start and left_end and left_end - left_start or nil,
            right_start and right_end and right_end - right_start or nil,
            pair_start and right_end and right_end - pair_start or nil
        )

        report_native_observer()
        return result
    end

    -- Render each eye as its own world submission. Rendering both active
    -- viewports in a single submission lets view-dependent lighting, decals,
    -- and culling state from one eye leak into or be omitted from the other.
    -- Stingray accepts two submissions of this UI world in the same frame;
    -- keep a guarded fallback so a future engine update cannot take the game
    -- down if that contract changes.
    if world == ui_stereo_world and ui_stereo_spawner and
            ui_sequential_render_requested then
        local primary = ui_stereo_spawner._viewport
        local right = ui_stereo_right_viewport

        ScriptWorld.deactivate_viewport(world, right)
        ScriptWorld.activate_viewport(world, primary)
        local left_ok, left_result = pcall(func, world, ...)

        ScriptWorld.deactivate_viewport(world, primary)
        ScriptWorld.activate_viewport(world, right)
        local right_ok, right_error = pcall(func, world, ...)

        -- Restore the normal active set for update code outside this hook.
        ScriptWorld.activate_viewport(world, primary)

        if not left_ok or not right_ok then
            ui_sequential_render_requested = false
            ScriptWorld.activate_viewport(world, right)
            mod:error(
                "DARKTIDEVR_STEREO sequential_render_failed left=%s right=%s error=%s/%s",
                tostring(left_ok),
                tostring(right_ok),
                left_ok and "none" or tostring(left_result),
                right_ok and "none" or tostring(right_error)
            )

            if not left_ok then
                return func(world, ...)
            end
        end

        return left_result
    end

    if world == ui_stereo_world and ui_stereo_spawner and
            ui_double_render_probe_requested then
        local primary = ui_stereo_spawner._viewport
        local right = ui_stereo_right_viewport
        mod:info("DARKTIDEVR_STEREO double_render step=deactivate_right")
        local activation_ok, activation_error = pcall(
            ScriptWorld.deactivate_viewport,
            world,
            right
        )

        if not activation_ok then
            mod:error("DARKTIDEVR_STEREO double_render deactivate_right=%s", tostring(activation_error))
        end

        mod:info("DARKTIDEVR_STEREO double_render step=render_left")
        local left_ok, left_result = pcall(func, world, ...)
        mod:info(
            "DARKTIDEVR_STEREO double_render render_left_ok=%s error=%s",
            tostring(left_ok),
            left_ok and "none" or tostring(left_result)
        )
        mod:info("DARKTIDEVR_STEREO double_render step=switch_to_right")
        local switch_left_ok, switch_left_error = pcall(
            ScriptWorld.deactivate_viewport,
            world,
            primary
        )
        local switch_right_ok, switch_right_error = pcall(
            ScriptWorld.activate_viewport,
            world,
            right
        )
        mod:info(
            "DARKTIDEVR_STEREO double_render switch_ok=%s/%s error=%s/%s",
            tostring(switch_left_ok),
            tostring(switch_right_ok),
            tostring(switch_left_error),
            tostring(switch_right_error)
        )
        mod:info("DARKTIDEVR_STEREO double_render step=render_right")
        local right_ok, right_result = pcall(func, world, ...)
        mod:info(
            "DARKTIDEVR_STEREO double_render render_right_ok=%s error=%s",
            tostring(right_ok),
            right_ok and "none" or tostring(right_result)
        )

        pcall(ScriptWorld.activate_viewport, world, primary)
        apply_ui_direct_sbs_rects(primary, right)
        ui_double_render_probe_requested = false

        return left_result
    end

    local result = func(world, ...)
    report_native_observer()

    return result
end)

mod:hook_safe("UIWorldSpawner", "destroy", function(self)
    if self == ui_stereo_spawner then
        ui_stereo_spawner = nil
        ui_stereo_world = nil
        ui_stereo_right_viewport = nil
        ui_base_vertical_fov = nil
    end
end)

mod:hook("MainMenuView", "draw", function(func, self, dt, t, input_service, layer, ...)
    if ui_offscreen_active and ui_left_render_target and ui_right_render_target then
        if not ui_compositor_package_loaded then
            if not ui_compositor_package_id and not ui_compositor_package_failed and
                    Managers.package then
                local function on_loaded()
                    ui_compositor_package_loaded = true
                    mod:info("DARKTIDEVR_STEREO compositor_package_loaded")
                end
                local ok, package_id = pcall(
                    Managers.package.load,
                    Managers.package,
                    ui_compositor_package,
                    ui_compositor_package_reference,
                    on_loaded
                )

                if ok then
                    ui_compositor_package_id = package_id
                    mod:info("DARKTIDEVR_STEREO compositor_package_requested")
                else
                    ui_compositor_package_failed = true
                    mod:error(
                        "DARKTIDEVR_STEREO compositor_package_failed error=%s",
                        tostring(package_id)
                    )
                end
            end

            return
        end

        local gui = self._ui_renderer.gui

        UIRenderer.clear_render_pass_queue(self._ui_renderer)
        UIRenderer.add_render_pass(self._ui_renderer, 1, "to_screen", false)

        if not ui_left_material then
            local material = Gui.create_material(
                gui,
                ui_compositor_material,
                GuiMaterialFlag.GUI_RENDER_PASS_LAYER
            )
            Material.set_resource(
                material,
                "source",
                false and
                    ui_left_output_target or ui_left_render_target
            )
            ui_left_material = { gui = gui, material = material }
        end

        if not ui_right_material then
            local material = Gui.create_material(
                gui,
                ui_compositor_material,
                GuiMaterialFlag.GUI_RENDER_PASS_LAYER
            )
            Material.set_resource(material, "source", ui_right_render_target)
            ui_right_material = { gui = gui, material = material }
        end

        local width, height = Application.back_buffer_size()
        local half_width = width * 0.5
        -- Preserve one source row per destination row for the band-control
        -- probe. The desktop client crops the excess instead of resampling
        -- 2304 source rows into its 2135-row client area.
        local composite_height = ui_eye_target_height
        local composite_layer = (layer or 0) + 1000
        -- The blur-mask shader derives its default UVs from screen position.
        -- Explicit local UVs are therefore required when placing two complete
        -- render targets side by side; otherwise each half samples only the
        -- corresponding half of its source texture.
        local white = Color(255, 255, 255, 255)
        local bitmap_options = {
            color = white,
            render_pass = "to_screen",
            snap_pixel_positions = false
        }
        Gui2.bitmap_uv(
            gui,
            ui_left_material.material,
            0,
            Vector2(0, 0),
            Vector2(1, 1),
            Vector3(0, 0, composite_layer),
            Vector3(half_width, composite_height, 0),
            bitmap_options
        )
        Gui2.bitmap_uv(
            gui,
            ui_right_material.material,
            0,
            Vector2(0, 0),
            Vector2(1, 1),
            Vector3(half_width, 0, composite_layer),
            Vector3(half_width, composite_height, 0),
            bitmap_options
        )
        return
    end

    if main_menu_ui_hidden then
        return
    end

    return func(self, dt, t, input_service, layer, ...)
end)

mod:command("dtvr_billboard_readback", "Capture three candidate billboard draws in census mode", function()
    local ok, result = pcall(function() return ui_native_capture.dtvr_begin_billboard_draw_readback() end)
    mod:echo("DARKTIDEVR_BILLBOARD_READBACK ok=%s result=%s (0=armed, 1=already used, 2=census/hooks required)",
        tostring(ok), tostring(result))
end)

mod:command(
    "dtvr_ui_native_capture_on",
    "Disabled unsafe mid-frame native capture experiment",
    function()
        mod:error("Mid-frame capture is disabled; use the Present-boundary producer")
    end
)

mod:command(
    "dtvr_ui_native_capture_off",
    "Return to direct SBS rendering (native hooks remain inert)",
    function()
        ui_native_capture_requested = false
        ui_native_capture_active = false
        teardown_ui_stereo()
        mod:echo("DARKTIDEVR_STEREO native_capture=off")
    end
)

mod:command(
    "dtvr_present_capture_on",
    "Publish the direct SBS halves as shared D3D12 eye textures",
    function()
        if ensure_ui_native_hooks() then
            ui_present_capture_requested = true
            ui_native_capture.dtvr_enable_present_capture()
            mod:echo("DARKTIDEVR_STEREO present_capture=on")
        end
    end
)

mod:command(
    "dtvr_present_capture_off",
    "Stop publishing shared D3D12 eye textures",
    function()
        ui_present_capture_requested = false
        if ui_native_capture then
            ui_native_capture.dtvr_disable_present_capture()
        end
        mod:echo("DARKTIDEVR_STEREO present_capture=off")
    end
)

mod:command(
    "dtvr_ui_offscreen_on",
    "Use independent full-origin render targets after the next menu-world creation",
    function()
        ui_offscreen_requested = true
        mod:echo("Independent eye render targets armed for the next menu-world creation")
    end
)

mod:command(
    "dtvr_ui_offscreen_off",
    "Use the direct side-by-side back-buffer path after the next menu-world creation",
    function()
        ui_offscreen_requested = false
        mod:echo("Direct SBS rendering armed for the next menu-world creation")
    end
)

mod:command(
    "dtvr_ui_stereo_on",
    "Arm the unsafe character-select synchronized-stereo experiment",
    function()
        ui_stereo_requested = true
        mod:echo("Character-select stereo experiment armed for the next viewport creation")
    end
)

mod:command(
    "dtvr_ui_stereo_off",
    "Disarm character-select stereo and restore its mono viewport",
    function()
        ui_stereo_requested = false
        local ok, error_message = pcall(teardown_ui_stereo)

        if not ok then
            mod:error(
                "DARKTIDEVR_STEREO ui_teardown_failed error=%s",
                tostring(error_message)
            )
        end
    end
)

mod:command(
    "dtvr_ui_coincident_eyes_on",
    "Place both character-select eye cameras at the exact same pose",
    function()
        ui_eye_separation = 0

        if ui_stereo_spawner then
            apply_ui_eye_offsets(ui_stereo_spawner)
        end

        mod:echo("Character-select cameras are coincident for eye-diff diagnostics")
    end
)

mod:command(
    "dtvr_ui_coincident_eyes_off",
    "Restore the character-select cameras to 64 mm separation",
    function()
        ui_eye_separation = half_ipd * 2

        if ui_stereo_spawner then
            apply_ui_eye_offsets(ui_stereo_spawner)
        end

        mod:echo("Character-select camera separation restored to 64 mm")
    end
)

mod:command("dtvr_ui_hide_on", "Hide the character-select UI for stereo inspection", function()
    main_menu_ui_hidden = true
    mod:echo("Character-select UI hidden")
end)

mod:command("dtvr_ui_hide_off", "Restore the character-select UI", function()
    main_menu_ui_hidden = false
    mod:echo("Character-select UI restored")
end)

mod:command("dtvr_stereo_on", "Enable the guarded same-tick stereo probe", function()
    failed = false
    requested = true
    mod:echo("DarktideVR stereo probe armed; waiting for the player1 viewport")
end)

mod:command("dtvr_stereo_off", "Disable the stereo probe and restore mono", function()
    requested = false
    local ok, error_message = pcall(teardown)

    if not ok then
        mod:error("DARKTIDEVR_STEREO teardown_failed error=%s", tostring(error_message))
    end

    mod:echo("DarktideVR stereo probe disabled")
end)

mod:command(
    "dtvr_enter_psykhanium",
    "Enter the single-player Psykhanium through the normal training-ground UI",
    function()
        presentation.psykhanium.stage = "open_training_view"
        presentation.psykhanium.deadline = math.huge
        presentation.psykhanium.last_error = nil
        mod:echo("DARKTIDEVR_PSYKHANIUM armed")
    end
)

mod:command(
    "dtvr_psykhanium_status",
    "Report the guarded Psykhanium-entry state machine",
    function()
        mod:echo(
            "DARKTIDEVR_PSYKHANIUM stage=%s error=%s",
            tostring(presentation.psykhanium.stage),
            tostring(presentation.psykhanium.last_error)
        )
    end
)

presentation.render_world_census = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_render_world_census"
).install(mod, function(world)
    if world == active_world and active then return "gameplay" end
    if world == ui_stereo_world and ui_stereo_spawner then return "stereo_ui" end
    return "other"
end)

mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_calibration"
).install(mod, controller_observation, function()
    if not ui_native_capture or not head_pose_values or
            not head_pose_sequence or
            presentation.read_head_pose() ~= 0 then
        return nil
    end
    controller_observation.head_recenter_generation = math.floor(
        tonumber(head_pose_values[23]) + 0.5)
    return head_pose_values
end, function()
    if not ui_native_capture or not controller_observation.values or
            ui_native_capture.dtvr_read_controller_state(
                controller_observation.values,
                controller_observation.tracking_flags,
                controller_observation.buttons,
                controller_observation.sequence,
                controller_observation.timestamp_ns) ~= 0 then
        return false
    end
    local timestamp_ns = tonumber(controller_observation.timestamp_ns[0])
    local frequency = tonumber(ui_native_capture.dtvr_qpc_frequency())
    local age_ns = math.huge
    if frequency > 0 then
        age_ns = tonumber(ui_native_capture.dtvr_qpc_ticks()) *
            1000000000 / frequency - timestamp_ns
    end
    local fresh = age_ns >= -5000000 and age_ns <= 100000000
    controller_observation.left_grip_tracking_live = fresh and
        bit.band(tonumber(controller_observation.tracking_flags[1]), 3) == 3
    controller_observation.right_grip_tracking_live = fresh and
        bit.band(tonumber(controller_observation.tracking_flags[3]), 3) == 3
    controller_observation.left_grip_x =
        tonumber(controller_observation.values[7])
    controller_observation.left_grip_y =
        tonumber(controller_observation.values[8])
    controller_observation.left_grip_z =
        tonumber(controller_observation.values[9])
    controller_observation.right_grip_x =
        tonumber(controller_observation.values[25])
    controller_observation.right_grip_y =
        tonumber(controller_observation.values[26])
    controller_observation.right_grip_z =
        tonumber(controller_observation.values[27])
    controller_observation.left_trigger =
        tonumber(controller_observation.values[14])
    controller_observation.right_trigger =
        tonumber(controller_observation.values[32])
    return true
end)

presentation.projection_math = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_projection_math"
)
presentation.body_proxy = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_body_proxy"
)
presentation.body_proxy_active = false

presentation.melee_live_probe = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_melee_live_probe"
).install(mod, presentation, controller_observation, active_game_mode_name)

presentation.melee_preview = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_melee_preview_display"
).install(mod, presentation, controller_observation)

mod.update = function()
    presentation.melee_preview.update()
    if presentation.viewer then
        presentation.viewer.update()
    end
    if presentation.session_control then
        presentation.session_control.update()
    end
end

presentation.hud_panel = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_hud_panel"
)
presentation.hud_panel.mirror_width = ui_mirror_client_width
presentation.hud_panel.mirror_height = ui_mirror_client_height
presentation.read_desktop_mirror = function()
    local values = presentation.hud_mirror_values
    if not ui_native_capture or not values or ui_native_capture.dtvr_read_mirror_cursor(values,5) ~= 0 then return end
    return tonumber(values[0]),tonumber(values[1]),tonumber(values[2]),tonumber(values[3]),values[4] ~= 0
end
presentation.hud_panel.read_mirror = presentation.read_desktop_mirror
presentation.hud_panel.install(mod)
presentation.crosshair_feedback_module = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_crosshair_feedback")
presentation.crosshair_feedback = presentation.crosshair_feedback_module.install(
    mod,presentation,controller_observation)
presentation.weapon_charge_display = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_weapon_charge_display"
).install(mod,presentation,controller_observation)
presentation.gameplay_ui = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_gameplay_ui_input"
).install(mod, function()
    local player = Managers and Managers.player and Managers.player:local_player(1)
    return player and player.player_unit
end)

presentation.controller_aim = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_controller_aim"
)
presentation.controller_aim.install(
    mod, presentation, controller_observation)

presentation.projectile_visual = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_projectile_visual"
).install(mod, presentation)
mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_weapon_sound"
).install(mod, presentation, controller_observation, active_game_mode_name)
presentation.ranged_evidence = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_ranged_evidence"
).install(mod, presentation)
-- Dead or hogtied and watching a teammate, stock shows that player's own
-- first-person camera. In VR that is another person's head on yours; the
-- stock observer camera instead follows the watched unit in third person
-- when first-person spectating is off, with the orientation from the local
-- player's own look input as in the hub.
mod:hook_require("scripts/managers/player/player_game_states/camera_handler", function(class)
    mod:hook_safe(class, "init", function(self)
        if presentation.gameplay_context.game_mode_name(Managers and Managers.state and
                Managers.state.game_mode) ~= "hub" and
                mod:get("spectate_third_person") ~= false then
            self._first_person_spectating_mode = false
            mod:info("DARKTIDEVR_CAMERA spectating=third_person source=option")
        end
    end)
    -- Hub third person eases a movement pull-back out and an idle close-in
    -- in over time. A menu stops the character, so the close-in ran on
    -- behind it and the camera came back somewhere else when the menu was
    -- opened mid-ease. Hold both eases (no elapsed time) while a menu is up.
    mod:hook(class, "_update_hub_camera_variables", function(func, self, dt, ...)
        if presentation.mode == 5 or presentation.mode == 6 then
            dt = 0
        end
        return func(self, dt, ...)
    end)
end)

-- The scanner display view (auspex scans, generator and decode minigames)
-- links its screen texture to the auspex unit it was opened for, the
-- first-person device model. The mod hides first-person units and shows the
-- third-person ones, whose screen therefore stayed blank. Link the same
-- texture to every third-person unit of the equipped slots that carries the
-- display mesh, and unlink with the view. Logged so the next worn run shows
-- which unit the view was given and how many third-person screens exist.
-- Cutscenes and videos skip on a held right trigger. The stock views take
-- `skip_cinematic_hold` (Space, gamepad A) for half a second after
-- `on_skip_pressed`; in VR neither key reaches them. The trigger arms the
-- press on its rising edge and answers the hold while it stays down. The
-- legend's badge reads Hold RT through the prompt aliases.
local cinematic_skip = {down = false}
function presentation.cinematic_skip_trigger()
    -- Cutscenes and videos run on flat screens, where gameplay no longer
    -- refreshes controller_observation.right_trigger: read the state directly.
    local trigger
    if presentation.read_controller_triggers then
        local ok, _, right = pcall(presentation.read_controller_triggers)
        trigger = ok and right or nil
    else
        trigger = tonumber(controller_observation.right_trigger)
    end
    if not trigger or presentation.controllers_disabled() then
        cinematic_skip.down = false
        return nil, false
    end
    local down = trigger >= 0.55
    local pressed = down and not cinematic_skip.down
    cinematic_skip.down = down
    return down, pressed
end
local function cinematic_skip_input(input_service, down)
    if not down or not input_service then return input_service end
    local proxy = {}
    function proxy:get(action)
        if action == "skip_cinematic_hold" or action == "skip_cinematic" then
            return true
        end
        return input_service:get(action)
    end
    return setmetatable(proxy, {__index = function(_, key)
        local value = input_service[key]
        if type(value) == "function" then
            return function(_, ...) return value(input_service, ...) end
        end
        return value
    end})
end
mod:hook_require("scripts/ui/views/cutscene_view/cutscene_view", function(class)
    mod:hook_safe(class, "on_enter", function() cinematic_skip.down = false end)
    mod:hook(class, "update", function(func, self, dt, t, input_service, ...)
        local down, pressed = presentation.cinematic_skip_trigger()
        if down == nil then return func(self, dt, t, input_service, ...) end
        if pressed and self.on_skip_pressed then
            self:on_skip_pressed()
            mod:info("DARKTIDEVR_CINEMATIC skip_pressed view=cutscene")
        end
        return func(self, dt, t, cinematic_skip_input(input_service, down), ...)
    end)
end)
mod:hook_require("scripts/ui/views/video_view/video_view", function(class)
    mod:hook_safe(class, "on_enter", function() cinematic_skip.down = false end)
    mod:hook(class, "update", function(func, self, dt, t, input_service, ...)
        local down, pressed = presentation.cinematic_skip_trigger()
        if down == nil then return func(self, dt, t, input_service, ...) end
        if pressed then
            -- The stock legend appears on the first key or mouse press and the
            -- hold then counts; the trigger does both.
            local context = self._context
            if context and context.allow_skip_input then
                self._show_skip = true
            end
            self._skip_pressed = true
            mod:info("DARKTIDEVR_CINEMATIC skip_pressed view=video")
        end
        return func(self, dt, t, cinematic_skip_input(input_service, down), ...)
    end)
end)

-- The title screen ("press Space to continue") also continues on either
-- trigger. Gameplay refreshes the trigger values only while stereo runs, so
-- read the controller state directly here. A trigger already down when the
-- screen opens must be released first.
do
    local title_trigger = {down = true}
    -- Both trigger values and the A button, or nil when the controller state
    -- is unavailable. Read directly: gameplay refreshes the trigger values
    -- only while stereo gameplay runs, not on flat screens or in menus.
    local function read_triggers()
        if not ui_native_capture or not controller_observation.values or
                not ui_native_capture.dtvr_read_controller_state or
                ui_native_capture.dtvr_read_controller_state(
                    controller_observation.values,
                    controller_observation.tracking_flags,
                    controller_observation.buttons,
                    controller_observation.sequence,
                    controller_observation.timestamp_ns) ~= 0 then
            return nil
        end
        -- buttons[0] is the left hand, buttons[1] the right; bit 0 is the
        -- primary button (X, A), bit 1 the secondary (Y, B).
        return tonumber(controller_observation.values[14]) or 0,
            tonumber(controller_observation.values[32]) or 0,
            tonumber(controller_observation.buttons[0]) or 0,
            tonumber(controller_observation.buttons[1]) or 0
    end
    presentation.read_controller_triggers = read_triggers
    -- The controller buttons a menu hotkey can answer to
    -- (darktidevr_menu_input.lua, MenuInput.menu_buttons).
    function presentation.read_menu_buttons()
        if presentation.controllers_disabled() then return nil end
        local ok, left, right, left_buttons, right_buttons = pcall(read_triggers)
        if not ok or not right then return nil end
        return {x = bit.band(left_buttons, 1) ~= 0, y = bit.band(left_buttons, 2) ~= 0,
            a = bit.band(right_buttons, 1) ~= 0, rt = right >= 0.55,
            both_triggers = right >= 0.55 and (tonumber(left) or 0) >= 0.55}
    end
    local function title_triggers_down()
        local left, right = read_triggers()
        if not left then return nil end
        return left >= 0.55 or right >= 0.55
    end

    -- The end of mission screen's continue (RT) and stay-in-party vote (Y)
    -- are menu hotkeys: MenuInput.menu_buttons answers them in every menu.
    mod:hook_require("scripts/ui/views/title_view/title_view", function(class)
        mod:hook_safe(class, "on_enter", function() title_trigger.down = true end)
        mod:hook(class, "update", function(func, self, dt, t, input_service, ...)
            if not self._continue_triggered and not self.closing_view and self._continue then
                local ok, down = pcall(title_triggers_down)
                if ok and down ~= nil then
                    if down and not title_trigger.down then
                        self:_continue()
                        mod:info("DARKTIDEVR_TITLE continue source=trigger")
                    end
                    title_trigger.down = down
                end
            end
            return func(self, dt, t, input_service, ...)
        end)
    end)
end

-- The local player's companion units (the Skitarii servo-skull): alive,
-- distance from the player and mesh visibility, for the invisible-skull report.
local function companion_trace_arm()
    if mod.companion_trace_armed then return end
    mod.companion_trace_armed = true
    local function watched(unit)
        local spawn = Managers.state and Managers.state.player_unit_spawn
        local player = Managers.player and Managers.player:local_player(1)
        if not spawn or not player or not unit then return false end
        local ok, owner = pcall(spawn.owner, spawn, unit)
        return ok and owner == player and unit ~= player.player_unit
    end
    for _, name in ipairs({"set_unit_visibility", "set_visibility",
            "set_mesh_visibility", "flow_event"}) do
        local original = Unit[name]
        if type(original) == "function" then
            Unit[name] = function(unit, ...)
                if watched(unit) then
                    local args = {}
                    for i = 1, select("#", ...) do args[i] = tostring((select(i, ...))) end
                    mod:info("DARKTIDEVR_COMPANION trace Unit.%s(%s)\n%s", name,
                        table.concat(args, ", "), debug.traceback())
                end
                return original(unit, ...)
            end
        end
    end
    mod:info("DARKTIDEVR_COMPANION trace armed")
end

mod:command("dtvr_companion", "Log the local player's companion units (add show, trace)", function(action)
    if action == "trace" then
        companion_trace_arm()
        mod:echo("DARKTIDEVR_COMPANION trace armed: visibility calls on your companions are logged with tracebacks")
    end
    local player = Managers.player and Managers.player:local_player(1)
    local unit = player and player.player_unit
    local spawner = unit and Unit.alive(unit) and
        ScriptUnit.has_extension(unit, "companion_spawner_system")
    local units = spawner and spawner.companion_units and spawner:companion_units()
    if not units or #units == 0 then
        mod:echo("DARKTIDEVR_COMPANION none")
        mod:info("DARKTIDEVR_COMPANION none")
        return
    end
    if action == "show" then
        for i = 1, #units do
            local companion = units[i]
            if companion and Unit.alive(companion) then
                local a = pcall(Unit.set_unit_visibility, companion, true, true)
                local b = pcall(Unit.set_visibility, companion, "main", true)
                local c = pcall(Unit.flow_event, companion, "lua_visible")
                local line = string.format("DARKTIDEVR_COMPANION show %d unit_visibility=%s group_main=%s flow_visible=%s",
                    i, tostring(a), tostring(b), tostring(c))
                mod:echo(line)
                mod:info(line)
            end
        end
    end
    local origin = Unit.world_position(unit, 1)
    local visibility = ScriptUnit.has_extension(unit, "player_visibility_system")
    local first_person = ScriptUnit.has_extension(unit, "first_person_system")
    local ok_fp, in_first_person = pcall(function()
        return first_person and first_person:is_in_first_person_mode()
    end)
    for i = 1, #units do
        local companion = units[i]
        local alive = companion and Unit.alive(companion)
        local distance = alive and Vector3.distance(Unit.world_position(companion, 1), origin)
        local meshes = -1
        local group_main = "n/a"
        if alive then
            local ok, count = pcall(Unit.num_meshes, companion)
            meshes = ok and count or -1
            local ok_group, has_group = pcall(Unit.has_visibility_group, companion, "main")
            group_main = ok_group and tostring(has_group) or "n/a"
        end
        local line = string.format(
            "DARKTIDEVR_COMPANION %d/%d alive=%s distance=%s meshes=%d visibility_group_main=%s player_visible=%s first_person=%s",
            i, #units, tostring(alive), distance and string.format("%.2f", distance) or "nil",
            meshes, group_main, tostring(visibility and visibility:visible()),
            tostring(ok_fp and in_first_person))
        mod:echo(line)
        mod:info(line)
    end
end)

mod:hook_require("scripts/ui/views/scanner_display_view/scanner_display_view", function(class)
    local slots = {"slot_device", "slot_pocketable", "slot_pocketable_small",
        "slot_primary", "slot_secondary"}
    local function display_material(unit)
        if not unit or not Unit.alive(unit) then return nil end
        local ok, mesh = pcall(Unit.mesh, unit, "auspex_scanner_display")
        if not ok or not mesh then return nil end
        local material_ok, material = pcall(Mesh.material, mesh, "auspex_scanner_display")
        return material_ok and material or nil
    end
    local function third_person_displays(self)
        local found = {}
        local player = Managers and Managers.player and Managers.player:local_player(1)
        local unit = player and player.player_unit
        local loadout = unit and Unit.alive(unit) and
            ScriptUnit.has_extension(unit, "visual_loadout_system")
        if not loadout then return found end
        for _, slot_name in ipairs(slots) do
            local ok, unit_3p = pcall(loadout.unit_3p_from_slot, loadout, slot_name)
            if ok and unit_3p then
                local candidates = {unit_3p}
                local slot = loadout._equipment and loadout._equipment[slot_name]
                local attachments = slot and slot.attachments_by_unit_3p and
                    slot.attachments_by_unit_3p[unit_3p]
                for i = 1, #(attachments or {}) do candidates[#candidates + 1] = attachments[i] end
                for _, candidate in ipairs(candidates) do
                    if candidate ~= self._auspex_unit and display_material(candidate) then
                        found[#found + 1] = candidate
                    end
                end
            end
        end
        return found
    end
    mod:hook_safe(class, "_link_material", function(self)
        local renderer = self._offscreen_ui_renderer
        local render_target = renderer and renderer.render_target
        if not render_target then return end
        self._darktidevr_linked_3p = self._darktidevr_linked_3p or {}
        local units = third_person_displays(self)
        for _, unit in ipairs(units) do
            if not self._darktidevr_linked_3p[unit] then
                local ok, err = pcall(Material.set_resource, display_material(unit), "source", render_target)
                if ok then self._darktidevr_linked_3p[unit] = true end
                mod:info("DARKTIDEVR_SCANNER link_3p unit=%s ok=%s%s", tostring(unit),
                    tostring(ok), ok and "" or (" error=" .. tostring(err)))
            end
        end
        if not self._darktidevr_scanner_logged then
            self._darktidevr_scanner_logged = true
            mod:info("DARKTIDEVR_SCANNER view=%s auspex_unit=%s third_person_displays=%d",
                tostring(self.view_name), tostring(self._auspex_unit), #units)
        end
    end)
    mod:hook_safe(class, "_unlink_material", function(self)
        for unit in pairs(self._darktidevr_linked_3p or {}) do
            local material = display_material(unit)
            if material then pcall(Material.set_texture, material, "source", nil) end
        end
        self._darktidevr_linked_3p = nil
    end)
end)

-- Dev check, on F7 and /dtvr_scanner_test: open the scanner display on the
-- equipped device without a mission interface. Defined at top level: the
-- keybind must resolve before the scanner view has ever been required.
-- The auspex is not part of any loadout: a scanning zone or a decoding
-- interaction equips it into slot_device and removes it afterwards. The
-- check does the same when the slot is empty, with the catalogue's auspex
-- scanner item (the item id lives in level data, so it is found by name).
local function scanner_test_item()
    local ok, MasterItems = pcall(require, "scripts/backend/master_items")
    if not ok or not MasterItems then return nil end
    local direct = MasterItems.get_item and MasterItems.get_item("content/items/devices/auspex_scanner")
    if direct then return direct end
    local cached = MasterItems.get_cached and MasterItems.get_cached() or {}
    local chosen
    for name, item in pairs(cached) do
        if type(name) == "string" and name:find("auspex", 1, true) and
                not name:find("_map", 1, true) and type(item) == "table" and type(item.slots) == "table" then
            for _, slot in ipairs(item.slots) do
                if slot == "slot_device" and (not chosen or name < chosen.name) then
                    chosen = item
                end
            end
        end
    end
    return chosen
end
-- The mirror key: your character's copy standing ahead of you, facing you,
-- in the Psykhanium (user, 17 September).
mod.toggle_body_mirror = function()
    local mirror = presentation.body_mirror
    local state = mirror and mirror.toggle_mirror and mirror.toggle_mirror()
    if state == nil then
        mod:echo("The body mirror works in the Psykhanium.")
    else
        mod:echo(state and "Body mirror on (a moment to spawn)." or "Body mirror off.")
    end
end
mod.toggle_scanner_test = function()
    local manager = Managers and Managers.ui
    if not manager then return end
    -- The Psykhanium is a local server with no scanning zones of its own, so
    -- the check may equip the auspex there. Missions, SoloPlay or Fatshark's
    -- servers, hand it out through their own zones and interactions.
    local mode = presentation.gameplay_context.game_mode_name(
        Managers.state and Managers.state.game_mode)
    if mode ~= "shooting_range" and mode ~= "training_grounds" then
        mod:echo("The scanner check works in the Psykhanium; missions equip the auspex themselves.")
        return
    end
    local player = Managers.player and Managers.player:local_player(1)
    local unit = player and player.player_unit
    local PlayerUnitVisualLoadout = require(
        "scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")
    local t = Managers.time and Managers.time:time("gameplay") or 0
    if manager:view_active("scanner_display_view") then
        manager:close_view("scanner_display_view")
        if mod.scanner_test_equipped and unit and Unit.alive(unit) then
            local unit_data = ScriptUnit.has_extension(unit, "unit_data_system")
            local inventory = unit_data and unit_data:read_component("inventory")
            pcall(function()
                if inventory and inventory.wielded_slot == "slot_device" then
                    PlayerUnitVisualLoadout.wield_previous_weapon_slot(inventory, unit, t)
                end
                PlayerUnitVisualLoadout.unequip_item_from_slot(unit, "slot_device", t)
            end)
        end
        mod.scanner_test_equipped = nil
        mod:echo("Scanner display closed.")
        return
    end
    local loadout = unit and Unit.alive(unit) and
        ScriptUnit.has_extension(unit, "visual_loadout_system")
    if not loadout then
        mod:echo("No player unit; the scanner check needs a spawned character.")
        return
    end
    local slot = loadout._equipment and loadout._equipment.slot_device
    local auspex = slot and (slot.unit_1p or slot.unit_3p)
    if not auspex then
        local item = scanner_test_item()
        if not item then
            mod:echo("No auspex item in the catalogue; try inside a scanning zone.")
            return
        end
        local ok, err = pcall(function()
            PlayerUnitVisualLoadout.equip_item_to_slot(unit, item, "slot_device", nil, t)
            PlayerUnitVisualLoadout.wield_slot("slot_device", unit, t)
        end)
        if not ok then
            mod:echo("Equipping the auspex failed: " .. tostring(err))
            return
        end
        mod.scanner_test_equipped = true
        slot = loadout._equipment and loadout._equipment.slot_device
        auspex = slot and (slot.unit_1p or slot.unit_3p)
        if not auspex then
            mod:echo("Auspex equipped (" .. tostring(item.name) .. ") but its unit is not up yet; press F7 again.")
            return
        end
    end
    local world = Managers.world and Managers.world:world("level_world")
    local ok, err = pcall(manager.open_view, manager, "scanner_display_view", nil, nil, nil, nil, {
        device_owner_unit = unit, minigame_type = "none", minigame_extension = nil,
        auspex_unit = auspex, wwise_world = world and Managers.world:wwise_world(world)})
    mod:echo(ok and "Scanner display opened; the screen on the device in your hand should show it. F7 again closes it."
        or ("Scanner display failed: " .. tostring(err)))
end
if mod.command then
    mod:command("dtvr_scanner_test",
        "Open or close the scanner display on the equipped device (also on the F7 keybind)",
        function() mod.toggle_scanner_test() end)
end

presentation.scanner_holo = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_scanner_holo"
).install(mod)
-- Psykhanium check for the scan hologram: hands out the auspex and stands in
-- for a scanning zone, so holding the scan shows the hologram without a mission.
-- The player brings the scanner out with their own device button: a wield
-- written from a command did not take (the next LT blocked with the weapon).
mod.toggle_scan_test = function()
    local holo = presentation.scanner_holo
    local player = Managers.player and Managers.player:local_player(1)
    local unit = player and player.player_unit
    local PlayerUnitVisualLoadout = require(
        "scripts/extension_systems/visual_loadout/utilities/player_unit_visual_loadout")
    local t = Managers.time and Managers.time:time("gameplay") or 0
    if holo.test_zone then
        holo.test_zone = false
        local unit_data = unit and Unit.alive(unit) and ScriptUnit.has_extension(unit, "unit_data_system")
        local inventory = unit_data and unit_data:read_component("inventory")
        if mod.scan_test_equipped and inventory and inventory.wielded_slot ~= "slot_device" then
            local ok, err = pcall(PlayerUnitVisualLoadout.unequip_item_from_slot, unit, "slot_device", t)
            if not ok then mod:info("DARKTIDEVR_SCANNER_HOLO test_unequip_failed=%s", tostring(err)) end
            mod.scan_test_equipped = nil
            mod:echo("Scan hologram check off.")
        else
            mod:echo("Scan hologram check off. Switch to a weapon to put the scanner away; it stays in your device slot until you leave.")
        end
        return
    end
    local mode = presentation.gameplay_context.game_mode_name(
        Managers.state and Managers.state.game_mode)
    if mode ~= "shooting_range" and mode ~= "training_grounds" then
        mod:echo("The scan hologram check works in the Psykhanium; missions have real scanning zones.")
        return
    end
    local loadout = unit and Unit.alive(unit) and ScriptUnit.has_extension(unit, "visual_loadout_system")
    if not loadout then
        mod:echo("No player unit; the scan hologram check needs a spawned character.")
        return
    end
    -- The scanning auspex uses the scanner_equip template. The F7 display
    -- check's auspex_scanner is the decoding device, which the game marks
    -- not player-wieldable, so the scanner button could not bring it out.
    local slot = loadout._equipment and loadout._equipment.slot_device
    if not (slot and slot.item and slot.item.weapon_template == "scanner_equip") then
        local ok_items, MasterItems = pcall(require, "scripts/backend/master_items")
        local item
        for name, candidate in pairs(ok_items and MasterItems.get_cached() or {}) do
            if type(candidate) == "table" and candidate.weapon_template == "scanner_equip" and
                    (not item or name < item.name) then
                item = candidate
            end
        end
        if not item then
            mod:echo("No scanning auspex (scanner_equip) in the catalogue.")
            return
        end
        mod:info("DARKTIDEVR_SCANNER_HOLO test_item=%s", tostring(item.name))
        local ok, err = pcall(PlayerUnitVisualLoadout.equip_item_to_slot, unit, item, "slot_device", nil, t)
        if not ok then
            mod:echo("Equipping the auspex failed: " .. tostring(err))
            return
        end
        mod.scan_test_equipped = true
    end
    holo.test_zone = true
    mod:echo("Scan hologram check on: bring out the scanner with your scanner button (default Y), then hold LT. The hologram should sit just above the scanner. Run /dtvr_scan_test again to finish.")
end
if mod.command then
    mod:command("dtvr_scan_test",
        "Psykhanium: bring out the auspex and stand in for a scanning zone to check the scan hologram",
        function() mod.toggle_scan_test() end)
end

presentation.gun_aim = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_gun_aim"
).install(mod, presentation)
presentation.body_frame = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_body_frame"
).install(mod, presentation, controller_observation)
-- ANIMATED LEGS (19 September): the drawn body's copy runs the game's own
-- third-person state machine for the wielded weapon and is fed the same
-- INPUTS the game feeds the avatar -- the wield that picks the machine and
-- every third-person animation event -- so its legs walk from the same
-- clips, evaluated on its own skeleton, with nothing read from the
-- avatar's pose. The per-frame move speed is mirrored in the module. Each
-- hook forwards only for the local player's extension.
mod:hook_safe(
    require("scripts/extension_systems/animation/player_unit_animation_extension"),
    "inventory_slot_wielded",
    function(self, weapon_template)
        if presentation.body_mirror and presentation.body_mirror.wielded and
                Managers.player and Managers.player:local_player(1) and
                self._unit == Managers.player:local_player(1).player_unit then
            presentation.body_mirror.wielded(weapon_template)
        end
    end)
for _, method in ipairs({"anim_event", "anim_event_with_variable_float",
        "anim_event_with_variable_floats", "anim_event_with_variable_int"}) do
    mod:hook_safe(
        require("scripts/extension_systems/animation/player_unit_animation_extension"),
        method,
        function(self, event_name, ...)
            if presentation.body_mirror and presentation.body_mirror.forward_anim_event and
                    Managers.player and Managers.player:local_player(1) and
                    self._unit == Managers.player:local_player(1).player_unit then
                presentation.body_mirror.forward_anim_event(event_name, method, ...)
            end
        end)
end

presentation.body_mirror = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_body_mirror"
).install(mod, presentation)
-- After the bodies, so it can see all of them.
presentation.arm_census = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_arm_census"
).install(mod, presentation)
presentation.rig_scan = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_rig_scan"
).install(mod, presentation)
presentation.forearm_holsters_module = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_forearm_holsters")
presentation.forearm_holsters = presentation.forearm_holsters_module.install(mod, presentation)
presentation.skull_throw = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_skull_throw"
).install(mod, presentation)
presentation.wrist_display = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_wrist_display"
).install(mod, presentation, controller_observation)
presentation.holster_counts = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_holster_counts"
).install(mod, presentation)
presentation.teammate_status = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_teammate_status"
).install(mod, presentation)
presentation.sight_ads = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_sight_ads"
).install(mod, presentation, controller_observation)
presentation.gun_sights = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_gun_sights"
).install(mod, presentation)
presentation.weapon_parked_parts = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_weapon_parked_parts"
).install(mod, presentation)
presentation.weapon_stabilization = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_weapon_stabilization"
).install(mod, presentation, controller_observation)
mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_options_layout"
).install(mod)
presentation.weapon_assist = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_weapon_assist"
).install(mod,presentation,controller_observation)
-- Controller vibration (option vr_haptics_mode, default off): an older capture
-- library without the export drops every pulse.
presentation.haptics = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_haptics"
).install(mod, presentation, function(hands, amplitude, duration_ms, frequency_hz)
    if not ui_native_capture or
            not presentation.native_export(ui_native_capture, "dtvr_request_haptic_v1") then
        return false
    end
    return tonumber(ui_native_capture.dtvr_request_haptic_v1(
        hands, amplitude, duration_ms, frequency_hz)) == 0
end)
presentation.two_hand = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_two_hand_support"
).install(mod, presentation, controller_observation)
presentation.holsters = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_holsters"
).install(mod, presentation, controller_observation)
presentation.reach_interact = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_reach_interact"
).install(mod, presentation)
-- The module itself is kept: its claim-slot rule is shared (presentation.claim_yields).
presentation.item_radial_module = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_item_radial")
presentation.item_radial = presentation.item_radial_module.install(
    mod, presentation, controller_observation)
presentation.weapon_inspect = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_weapon_inspect"
).install(mod, presentation)
-- Optional add-on: melee by swinging the weapon hand. Loaded only when
-- darktidevr_melee_swing.lua is present; without it nothing changes.
do
    local io_api = Mods and Mods.lua and Mods.lua.io
    local file = io_api and io_api.open(
        "./../mods/darktidevr/scripts/mods/darktidevr/darktidevr_melee_swing.lua", "r")
    if file then
        file:close()
        local ok, addon = pcall(mod.io_dofile, mod,
            "darktidevr/scripts/mods/darktidevr/darktidevr_melee_swing")
        if ok and type(addon) == "table" and addon.install then
            presentation.melee_swing = addon.install(mod, presentation, controller_observation)
            mod:info("DARKTIDEVR_MELEE_SWING addon loaded")
        end
    end
end
presentation.comms_gesture = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_comms_gesture"
).install(mod, presentation)
presentation.tag_gesture = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_tag_gesture"
).install(mod, presentation)
presentation.ammo_readout = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_ammo_readout"
).install(mod, presentation, controller_observation)
presentation.attachment_scan = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_attachment_scan"
).install(mod, presentation)
presentation.pose_trace = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_pose_trace"
).install(mod, presentation, controller_observation)

mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_grenade_aim"
).install(mod, presentation.controller_aim, presentation.online_rules.preview_pose)

mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_combat_direction"
).install(mod, presentation.controller_aim)

-- World-surface markers: each marker's stock widget is drawn onto a plane
-- through its anchor on a world GUI, one surface for both eyes. See
-- darktidevr_marker_world.lua. Option `marker_plane`; `/dtvr_marker_plane`.
-- The module places no hooks: the marker GUI owns the renderer destroy hook
-- and the marker metrics own the draw hooks; both call into it.
presentation.marker_plane_module = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_marker_plane"
)
presentation.marker_world = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_marker_world"
)
presentation.hud_panel.set_mirror(presentation.marker_world.mirror)
do
    local bor = rawget(_G, "bit_or") or (rawget(_G, "bit") and bit.bor)
    presentation.marker_world.configure({
        UIRenderer = UIRenderer, Vector2 = Vector2, Vector3 = Vector3,
        Color = Color, Gui = Gui, Gui2 = Gui2, World = World, Matrix4x4 = Matrix4x4,
        Material = Material, profile = presentation.frame_profile,
        UIFonts = require("scripts/managers/ui/ui_fonts"),
        log = function(line) mod:info(line) end,
        material_flags = function(renderer, flags)
            local settings = renderer.render_settings
            if settings and bor then
                flags = flags and bor(flags, settings.material_flags or 0) or
                    settings.material_flags
            end
            if renderer.render_pass_flag and bor then
                flags = bor(flags or 0, GuiMaterialFlag.GUI_RENDER_PASS_LAYER)
            end
            return flags
        end,
    })
end
-- Per-pass material handles are tied to the renderer's 2D GUI; the world
-- surface needs their names to make its own instances.
mod:hook(UIRenderer, "create_material", function(func, self, material_name, retained_mode, ...)
    local handle = func(self, material_name, retained_mode, ...)
    presentation.marker_world.note_material(handle, material_name)
    return handle
end)
-- A widget pass's material belongs to the GUI of the renderer that first drew
-- it. The HUD panel and the marker atlas draw stock widgets through their own
-- renderers, so the stock destroy at mission exit can hand another GUI's
-- handle to the HUD renderer: "bad argument #2 to 'destroy_material'
-- (Material expected, got userdata)" from HudElementInteraction's widgets,
-- a Lua error and a crash dump on every quit after using interactions (worn,
-- 15 September evening). A failed destroy is logged once and skipped; the GUI
-- that owns the material releases it with its world. Root cause still open.
mod:hook(UIRenderer, "destroy_material", function(func, self, material, retained_mode, ...)
    local ok, err = pcall(func, self, material, retained_mode, ...)
    if not ok and not presentation.destroy_material_logged then
        presentation.destroy_material_logged = true
        mod:warning("DARKTIDEVR_UI destroy_material_skipped renderer=%s error=%s",
            tostring(self and self.name), tostring(err))
    end
end)
-- Values set on those handles (material values, ui_scale), replayed on the
-- marker atlas's own instances.
for _, setter in ipairs({"set_scalar", "set_vector2", "set_vector3", "set_vector4",
        "set_texture", "set_resource"}) do
    if Material[setter] then
        mod:hook(Material, setter, function(func, handle, key, ...)
            presentation.marker_world.note_value(setter, handle, key, ...)
            return func(handle, key, ...)
        end)
    end
end
presentation.marker_atlas = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_marker_atlas"
)
presentation.marker_atlas_api = {
    Managers = Managers, UIRenderer = UIRenderer, Renderer = Renderer, World = World,
    ScriptWorld = ScriptWorld, Gui = Gui, Gui2 = Gui2, Material = Material,
    Matrix4x4 = Matrix4x4, Vector2 = Vector2, Vector3 = Vector3, Color = Color,
    log = function(line) mod:info(line) end, profile = presentation.frame_profile,
}
presentation.marker_atlas.configure(presentation.marker_atlas_api)
-- Hand overlays (ammo counter, wrist display, holster labels) in front of
-- the scene: their own atlas, shown from the camera update below.
presentation.hand_overlay = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_hand_overlay"
).install(mod, presentation, presentation.marker_atlas, presentation.marker_atlas_api)
presentation.marker_gui = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_marker_gui"
)
presentation.marker_gui.install(mod, UIRenderer, presentation.marker_world.destroy)
presentation.marker_metrics = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_marker_metrics"
).install(mod, UIRenderer, presentation.marker_world.route)
presentation.marker_plane_flip = false
presentation.interaction_popup_drop = 1 / 3
local marker_plane_log = {reported = false, reasons = {}}
function presentation.marker_plane_enabled()
    return mod:get("marker_plane") ~= false and presentation.marker_world ~= nil
end
function presentation.marker_plane_note(reason)
    reason = tostring(reason)
    marker_plane_log.reasons[reason] = (marker_plane_log.reasons[reason] or 0) + 1
end
function presentation.marker_plane_report(routed, fallback)
    presentation.marker_plane_counts = {routed = routed, fallback = fallback}
    if routed > 0 and not marker_plane_log.reported then
        marker_plane_log.reported = true
        mod:info("DARKTIDEVR_MARKER_PLANE first_frame routed=%d fallback=%d flip=%s",
            routed, fallback, tostring(presentation.marker_plane_flip))
    end
end
-- The plane for one anchor as seen from the shared head centre, with the
-- anchor's screen position in the primary eye as the pixel origin. Screen
-- pixels the stock widget draws relative to that origin land on the plane
-- at the size the primary projection gives them at the anchor's distance.
function presentation.marker_plain(v)
    return {x = Vector3.x(v), y = Vector3.y(v), z = Vector3.z(v)}
end
-- The head's frame for the marker plane: the centre between the eyes, its
-- right and up as plain tables, and the tangent of one primary pixel.
-- Every marker in a frame asks for the same one, so it is computed once per
-- frame and phase and shared; the HUD draw and the camera update are
-- separate phases because the cameras move between them. The key is the
-- frame-quantised launch clock (and `t` where the caller has one), so a new
-- frame never sees the last frame's head. Plane.create copies what it is
-- given, so sharing is safe (profile doc: render.marker_scope).
presentation.marker_head_frames = {}
function presentation.marker_head_frame(phase, left, right, t)
    local stamp = Application.time_since_launch()
    local cached = presentation.marker_head_frames[phase]
    if cached and cached.stamp == stamp and cached.t == t and cached.left == left and
            cached.right == right then
        return cached
    end
    local center = (ScriptCamera.local_position(left) + ScriptCamera.local_position(right)) * 0.5
    local rotation = ScriptCamera.local_rotation(left)
    local back_width, height = Application.back_buffer_size()
    if not presentation.marker_pixel_spaces_logged then
        presentation.marker_pixel_spaces_logged = true
        local lookup = rawget(_G, "RESOLUTION_LOOKUP") or {}
        mod:info("DARKTIDEVR_MARKER pixel_spaces back_buffer=%sx%s lookup=%sx%s scale=%s eye_target=%dx%d",
            tostring(back_width), tostring(height), tostring(lookup.width), tostring(lookup.height),
            tostring(lookup.scale), ui_eye_target_width, ui_eye_target_height)
    end
    local frame = {stamp = stamp, t = t, left = left, right = right,
        center = presentation.marker_plain(center),
        right_axis = presentation.marker_plain(Quaternion.right(rotation)),
        up = presentation.marker_plain(Quaternion.up(rotation)),
        tangent = 2 * math.tan(Camera.vertical_fov(left) * 0.5) /
            (height * (presentation.render_visibility_scale or 1))}
    presentation.marker_head_frames[phase] = frame
    return frame
end
-- The scope body, a named function so no closure is built per marker per
-- frame; called under pcall by marker_plane_scope_untimed.
function presentation.marker_plane_scope_body(ui_renderer, anchor, camera, t, left, right,
        claimant)
    local head = presentation.marker_head_frame("hud", left, right, t)
    local geometry, reason = presentation.marker_world.geometry(
        presentation.marker_plane_module, presentation.marker_plain(anchor), head.center,
        head.right_axis, head.up, head.tangent, presentation.marker_plane_flip)
    if not geometry then return nil, reason end
    local surface = presentation.marker_world.state.surface
    local ps = geometry.pixel_size
    if surface == "atlas" then
        -- Stock 2D draw into an atlas cell; the quad is drawn at the
        -- camera update (presentation.marker_atlas_frame).
        local atlas = presentation.marker_atlas
        if not atlas.ensure(ui_renderer.world) then return nil, "atlas" end
        local screen = presentation.world_marker_screen_position(camera, anchor)
        local x, y = atlas.claim(t, presentation.marker_plain(anchor))
        if not x then return nil, y end
        return {renderer = ui_renderer, surface = "atlas", atlas = atlas,
            atlas_x = x, atlas_y = y,
            -- Which claimant this cell is for -- a marker type, the
            -- interaction popup or the tag prompt -- so the extents
            -- instrument can size a cell against each of them separately.
            -- Deliberately NOT defaulted: a scope with no claimant is a call
            -- site that forgot to name itself, and it must show up as "?"
            -- rather than quietly joining somebody else's measurement.
            claimant = claimant,
            origin_x = Vector3.x(screen), origin_y = Vector3.y(screen),
            pixel_size = ps, distance = geometry.distance}
    end
    local x_axis = Vector3(geometry.right.x * ps, geometry.right.y * ps, geometry.right.z * ps)
    local y_axis = Vector3(geometry.up.x * ps, geometry.up.y * ps, geometry.up.z * ps)
    if surface == "screen" then
        -- Each eye's projection of the plane into the overlay GUI: the
        -- anchor's screen position and the screen vectors of one plane
        -- pixel along the plane's right and up (measured over 64 pixels
        -- for precision). The overlay's 3D transforms map local x to
        -- screen x and local z to screen y.
        local function eye_frame(eye_camera)
            local s0 = presentation.world_marker_screen_position(eye_camera, anchor)
            local k = 64
            local su = presentation.world_marker_screen_position(eye_camera, anchor + x_axis * k)
            local sv = presentation.world_marker_screen_position(eye_camera, anchor + y_axis * k)
            local eye_tm = Matrix4x4.identity()
            Matrix4x4.set_right(eye_tm, Vector3((Vector3.x(su) - Vector3.x(s0)) / k, 0,
                (Vector3.y(su) - Vector3.y(s0)) / k))
            Matrix4x4.set_up(eye_tm, Vector3((Vector3.x(sv) - Vector3.x(s0)) / k, 0,
                (Vector3.y(sv) - Vector3.y(s0)) / k))
            Matrix4x4.set_forward(eye_tm, Vector3(0, 1, 0))
            Matrix4x4.set_translation(eye_tm, Vector3(Vector3.x(s0), 0, Vector3.y(s0)))
            return {tm = eye_tm, origin_x = Vector3.x(s0), origin_y = Vector3.y(s0)}
        end
        return {renderer = ui_renderer, surface = "screen",
            eyes = {left = eye_frame(camera), right = eye_frame(right)},
            pixel_size = ps, distance = geometry.distance}
    end
    local screen = presentation.world_marker_screen_position(camera, anchor)
    local tm = Matrix4x4.identity()
    Matrix4x4.set_right(tm, Vector3(geometry.right.x, geometry.right.y, geometry.right.z))
    Matrix4x4.set_forward(tm, Vector3(geometry.forward.x, geometry.forward.y, geometry.forward.z))
    Matrix4x4.set_up(tm, Vector3(geometry.up.x, geometry.up.y, geometry.up.z))
    Matrix4x4.set_translation(tm, Vector3(geometry.anchor.x, geometry.anchor.y, geometry.anchor.z))
    local gui = presentation.marker_world.gui_for(ui_renderer)
    return {renderer = ui_renderer, surface = "world", gui = gui, tm = tm,
        origin_x = Vector3.x(screen), origin_y = Vector3.y(screen),
        pixel_size = ps, distance = geometry.distance}
end
function presentation.marker_plane_scope_untimed(ui_renderer, anchor, camera, t, claimant)
    if not presentation.marker_plane_enabled() then return nil, "disabled" end
    local left, right = presentation.lod_primary_camera, presentation.lod_right_camera
    camera = camera or left
    if not left or not right or not camera or not anchor or not ui_renderer or
            not ui_renderer.world then
        return nil, "cameras"
    end
    local ok, scope_or_reason, detail = pcall(presentation.marker_plane_scope_body,
        ui_renderer, anchor, camera, t, left, right, claimant)
    if not ok then
        presentation.marker_plane_note("error")
        if not marker_plane_log.error_logged then
            marker_plane_log.error_logged = true
            mod:warning("DARKTIDEVR_MARKER_PLANE scope_error=%s", tostring(scope_or_reason))
        end
        return nil, "error"
    end
    return scope_or_reason, detail
end
-- The scope is built per widget per frame outside the widget's own section,
-- so it is timed on its own (profile doc).
function presentation.marker_plane_scope(ui_renderer, anchor, camera, t, claimant)
    return presentation.frame_profile.section("render.marker_scope",
        presentation.marker_plane_scope_untimed, ui_renderer, anchor, camera, t, claimant)
end
-- The atlas quad for one recorded anchor: the plane through it as seen from
-- the head centre, faced toward the viewer as the HUD panel faces its quad.
function presentation.marker_atlas_frame(anchor)
    local left, right = presentation.lod_primary_camera, presentation.lod_right_camera
    if not left or not right then return nil end
    local head = presentation.marker_head_frame("camera", left, right, nil)
    local geometry = presentation.marker_world.geometry(presentation.marker_plane_module,
        anchor, head.center, head.right_axis, head.up, head.tangent, false)
    if not geometry then return nil end
    local tm = Matrix4x4.identity()
    Matrix4x4.set_right(tm, Vector3(-geometry.right.x, -geometry.right.y, -geometry.right.z))
    Matrix4x4.set_forward(tm, Vector3(-geometry.forward.x, -geometry.forward.y, -geometry.forward.z))
    Matrix4x4.set_up(tm, Vector3(geometry.up.x, geometry.up.y, geometry.up.z))
    Matrix4x4.set_translation(tm, Vector3(anchor.x, anchor.y, anchor.z))
    return tm, geometry.pixel_size
end
-- Marker widgets mapped to a plane this frame draw through it; the right-eye
-- replay skips them because the world surface already serves both eyes.
mod:hook(require("scripts/managers/ui/ui_widget"), "draw", function(func, widget, ui_renderer, ...)
    local scopes = presentation.marker_plane_widgets
    local scope = scopes and scopes[widget]
    if not scope or scope.renderer ~= ui_renderer then
        return func(widget, ui_renderer, ...)
    end
    if world_marker_reprojecting then
        -- The world surface already serves both eyes; the screen surface
        -- draws the right eye's projection in the replay.
        if scope.surface ~= "screen" then return end
        return presentation.frame_profile.section("render.marker_widget",
            presentation.marker_world.draw, scope, "right", func, widget, ui_renderer, ...)
    end
    return presentation.frame_profile.section("render.marker_widget",
        presentation.marker_world.draw, scope, "left", func, widget, ui_renderer, ...)
end)
mod:command("dtvr_marker_plane",
    "World-surface markers: on, off, flip, surface <atlas|screen|world>, text <slug|rect|2d>, origin <top|bottom>, layer <n>, drop <fraction>, dump, probe, status",
    function(action, mode)
    if action == "on" or action == "off" then
        mod:set("marker_plane", action == "on")
    elseif action == "flip" then
        presentation.marker_plane_flip = not presentation.marker_plane_flip
    elseif action == "surface" then
        local was = presentation.marker_world.state.surface
        local ok, why = presentation.marker_world.set_surface(mode)
        if ok and presentation.marker_world.state.surface ~= was then
            presentation.marker_world.forget_extents("surface")
        end
        if not ok then mod:echo("surface: " .. tostring(why)) end
        if mode ~= "atlas" then pcall(presentation.marker_atlas.destroy) end
    elseif action == "text" then
        local was = presentation.marker_world.state.text_mode
        local ok, why = presentation.marker_world.set_text_mode(mode)
        if ok and presentation.marker_world.state.text_mode ~= was then
            presentation.marker_world.forget_extents("text")
        end
        if not ok then mod:echo("text mode: " .. tostring(why)) end
    elseif action == "origin" then
        local was = presentation.marker_world.state.text_origin
        local ok, why = presentation.marker_world.set_text_origin(mode)
        if ok and presentation.marker_world.state.text_origin ~= was then
            presentation.marker_world.forget_extents("origin")
        end
        if not ok then mod:echo("origin: " .. tostring(why)) end
    elseif action == "layer" then
        local was = presentation.marker_world.state.layer_base
        local ok, why = presentation.marker_world.set_layer_base(mode)
        if ok and presentation.marker_world.state.layer_base ~= was then
            presentation.marker_world.forget_extents("layer")
        end
        if not ok then mod:echo("layer: " .. tostring(why)) end
    elseif action == "dump" then
        presentation.marker_world.set_dump(mode or 1)
        mod:echo("marker plane: logging the routed draws of the next frame(s)")
    elseif action == "drop" then
        local value = tonumber(mode)
        if value and value ~= presentation.interaction_popup_drop then
            presentation.interaction_popup_drop = value
            presentation.marker_world.forget_extents("drop")
        elseif value then
            presentation.interaction_popup_drop = value
        end
        mod:echo("interaction popup drop (fraction of its height): " ..
            tostring(presentation.interaction_popup_drop))
    elseif action == "probe" then
        local on = not presentation.marker_world.state.probe
        presentation.marker_world.set_probe(on)
        mod:echo("marker plane probe (HUD panel material over each bitmap): " .. tostring(on))
    end
    local counts = presentation.marker_plane_counts or {routed = 0, fallback = 0}
    local reasons = {}
    for reason, count in pairs(marker_plane_log.reasons) do
        reasons[#reasons + 1] = reason .. "=" .. count
    end
    table.sort(reasons)
    local line = string.format(
        "DARKTIDEVR_MARKER_PLANE enabled=%s surface=%s flip=%s text=%s origin=%s layer=%s routed=%d fallback=%d reasons=%s errors=%d",
        tostring(presentation.marker_plane_enabled()),
        tostring(presentation.marker_world.state.surface), tostring(presentation.marker_plane_flip),
        tostring(presentation.marker_world.state.text_mode),
        tostring(presentation.marker_world.state.text_origin),
        tostring(presentation.marker_world.state.layer_base),
        counts.routed, counts.fallback, table.concat(reasons, ","),
        presentation.marker_world.state.errors)
    local atlas = presentation.marker_atlas.state
    line = line .. string.format(" atlas_created=%s atlas_failed=%s atlas_shown=%d atlas_skipped=%d",
        tostring(atlas.resource ~= nil), tostring(atlas.failed == true), #atlas.shown,
        presentation.marker_world.state.atlas_skipped or 0)
    mod:echo(line)
    mod:info(line)
end)

presentation.visual_settings = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_visual_settings"
)
presentation.visual_settings.install(mod)

do
    -- Isolated gameplay eye targets are the play default; a present flag
    -- still decides, matching the native module's reading of the same file.
    local flag = Mods.lua.io.open(
        "./../mods/darktidevr/darktidevr_streamline_eye_target_probe.flag", "r")
    local enabled = true
    if flag then
        enabled = flag:read("*all"):match("^%s*enabled%s*$") ~= nil
        flag:close()
    end
    if enabled then
        mod:io_dofile(
            "darktidevr/scripts/mods/darktidevr/darktidevr_eye_targets"
        ).install(mod, ScriptWorld, function()
            -- Between a mission server exit and the hub the head-pose
            -- transport can be silent for the frame that creates the new
            -- player viewport. The eye extent does not change within a
            -- session, so the last known one serves; asserting here was a
            -- Lua crash on the way back to the hub.
            local refreshed = ensure_ui_native_hooks() and refresh_xr_render_extent()
            if not refreshed and not presentation.eye_extent_stale_logged then
                presentation.eye_extent_stale_logged = true
                mod:info("DARKTIDEVR_STEREO eye_targets extent=last_known %dx%d reason=refresh_unavailable",
                    ui_eye_target_width, ui_eye_target_height)
            end
            return ui_eye_target_width, ui_eye_target_height
        end)
    end
end

-- Cinematic subtitles are drawn by the stock constant element onto the flat
-- canvas, which a stereo cinematic never shows. Mirror the current lines to
-- the HUD panel, which draws them at its bottom edge.
mod:hook_safe(
    require("scripts/ui/constant_elements/elements/subtitles/constant_element_subtitles"),
    "update",
    function(self)
        local widgets = self._widgets_by_name
        local primary = widgets and widgets.subtitles and widgets.subtitles.content
        local secondary = widgets and widgets.secondary_subtitles and
            widgets.secondary_subtitles.content
        -- The widget holds a placeholder ("<text>") until a line plays; the
        -- stock draw gate decides whether anything is showing.
        local showing = self._subtitle_enabled and
            (self._line_duration or self._line_currently_playing)
        local text = showing and primary and primary.text or ""
        local secondary_text = showing and secondary and secondary.text or ""
        if secondary_text ~= "" then
            text = text ~= "" and (text .. "\n" .. secondary_text) or secondary_text
        end
        local stereo = presentation.cinematic_stereo_active()
        -- In stereo the stock lines and their background boxes would land
        -- on the HUD panel mid-height; hide them and draw the mirrored text
        -- at the panel's bottom edge with no box. Restore when it ends.
        for _, widget in ipairs({widgets and widgets.subtitles, widgets and widgets.secondary_subtitles}) do
            if widget then
                if stereo then
                    widget.visible = false
                    if widget.content then widget.content.visible = false end
                    widget.darktidevr_hidden = true
                elseif widget.darktidevr_hidden then
                    widget.visible = true
                    if widget.content then widget.content.visible = true end
                    widget.darktidevr_hidden = nil
                end
            end
        end
        if stereo then
            self._draw_letterbox = false
        end
        if presentation.hud_panel then
            presentation.hud_panel.set_subtitle(stereo and text ~= "" and text or nil)
        end
    end)

-- The cutscene overlay HUD element draws the letterbox bars; on the HUD
-- panel they sit across the stereo world, so it stands down in a stereo
-- cinematic.
mod:hook(
    require("scripts/ui/hud/elements/cutscene_overlay/hud_element_cutscene_overlay"),
    "_draw_widgets",
    function(func, self, ...)
        if presentation.cinematic_stereo_active() then
            return
        end
        return func(self, ...)
    end)
-- The scene-to-scene fade is a HUD element as well; on the panel it would
-- fade only the HUD layer, so it stands down in a stereo cinematic.
mod:hook(
    require("scripts/ui/hud/elements/cutscene_fading/hud_element_cutscene_fading"),
    "draw",
    function(func, self, ...)
        if presentation.cinematic_stereo_active() then
            return
        end
        return func(self, ...)
    end)

presentation.viewer = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_viewer"
)
presentation.viewer.install(mod, function()
    return ensure_ui_native_hooks() and ui_native_capture or nil
end)
presentation.session_control = mod:io_dofile(
    "darktidevr/scripts/mods/darktidevr/darktidevr_session_control"
).install(mod)

-- Backstop for the marker atlas's idle release: leaving gameplay (the score
-- screen, or loading) releases what the atlas and the HUD panel's mirrored
-- elements hold before the mission's packages unload.
mod.on_game_state_changed = function(status, state_name)
    -- The game is quitting (window close or the Quit button): StateGame exits
    -- before the gameplay state and long before engine teardown.
    if status == "exit" and state_name == "StateGame" and presentation.prepare_game_exit then
        presentation.prepare_game_exit("state_game_exit")
    end
    if status == "enter" and (state_name == "StateGameScore" or state_name == "StateLoading") then
        if presentation.marker_atlas then pcall(presentation.marker_atlas.destroy) end
        if presentation.hand_overlay then presentation.hand_overlay.destroy() end
        if presentation.hud_panel and presentation.hud_panel.release_mirror_materials then
            pcall(presentation.hud_panel.release_mirror_materials)
        end
        mod:info("DARKTIDEVR_MARKER_ATLAS released reason=state_%s", tostring(state_name))
        if presentation.scanner_holo then
            presentation.scanner_holo.test_zone = false
            mod.scan_test_equipped = nil
        end
        if presentation.ammo_readout then pcall(presentation.ammo_readout.destroy) end
        if presentation.holster_counts then pcall(presentation.holster_counts.destroy) end
        if presentation.wrist_display then pcall(presentation.wrist_display.destroy) end
        if presentation.forearm_holsters then pcall(presentation.forearm_holsters.destroy) end
    if presentation.skull_throw then pcall(presentation.skull_throw.destroy) end
        if presentation.teammate_status then pcall(presentation.teammate_status.destroy) end
        if presentation.rig_scan then pcall(presentation.rig_scan.destroy) end
        if presentation.body_mirror then pcall(presentation.body_mirror.destroy) end
        if presentation.pose_trace then presentation.pose_trace.flush() end
    end
end

-- Every VR-mode exit faulted during engine shutdown (13 and 14 September):
-- a worker thread while the viewer was attached, otherwise after the log
-- ended. Release the stereo presentation while the game's worlds still exist:
-- stop the viewer, turn projection off, destroy the right-eye viewport in its
-- live world (teardown otherwise leaves it to world destruction), then the
-- same cleanup as disabling the mod. Runs once.
function presentation.prepare_game_exit(reason)
    if presentation.game_exit_prepared then return end
    presentation.game_exit_prepared = true
    if presentation.viewer then pcall(presentation.viewer.control, false) end
    local viewport_destroyed = false
    if active_world then
        local ok, destroyed = pcall(function()
            if ScriptWorld.has_viewport(active_world, right_viewport_name) then
                ScriptWorld.destroy_viewport(active_world, right_viewport_name)
                return true
            end
            return false
        end)
        viewport_destroyed = ok and destroyed == true
    end
    local disabled_ok = pcall(mod.on_disabled)
    -- Last: restore the native module's hooked functions (older native builds
    -- lack the export; the call then fails inside pcall).
    local native_ok, native_result = pcall(function()
        return ui_native_capture and tonumber(ui_native_capture.dtvr_prepare_process_exit())
    end)
    mod:info("DARKTIDEVR_EXIT prepared reason=%s right_viewport_destroyed=%s cleanup_ok=%s native_hooks=%s",
        tostring(reason), tostring(viewport_destroyed), tostring(disabled_ok),
        native_ok and tostring(native_result) or "unavailable")
end

mod.on_disabled = function()
    presentation.marker_metrics.stop()
    pcall(presentation.communication_input.cancel)
    presentation.push_to_talk.cancel()
    if presentation.crosshair_feedback then presentation.crosshair_feedback.destroy() end
    if presentation.weapon_charge_display then pcall(presentation.weapon_charge_display.destroy) end
    if presentation.ammo_readout then pcall(presentation.ammo_readout.destroy) end
    if presentation.holster_counts then pcall(presentation.holster_counts.destroy) end
    if presentation.wrist_display then pcall(presentation.wrist_display.destroy) end
    if presentation.forearm_holsters then pcall(presentation.forearm_holsters.destroy) end
    if presentation.skull_throw then pcall(presentation.skull_throw.destroy) end
    if presentation.teammate_status then pcall(presentation.teammate_status.destroy) end
    if presentation.rig_scan then pcall(presentation.rig_scan.destroy) end
    if presentation.body_mirror then pcall(presentation.body_mirror.destroy) end
    requested = false
    ui_stereo_requested = false
    presentation.melee_preview.enabled = false
    presentation.melee_preview.destroy()
    pcall(presentation.hud_panel.set_enabled, false)
    pcall(presentation.marker_gui.destroy_all)
    pcall(presentation.marker_world.destroy_all)
    pcall(presentation.marker_atlas.destroy)
    if presentation.hand_overlay then presentation.hand_overlay.destroy() end
    pcall(teardown)
    pcall(teardown_ui_stereo)
    pcall(destroy_ui_offscreen_resources)
    pcall(presentation.body_proxy.destroy)
end

mod.on_unload = function()
    presentation.marker_metrics.stop()
    pcall(presentation.communication_input.cancel)
    presentation.push_to_talk.cancel()
    if presentation.crosshair_feedback then presentation.crosshair_feedback.destroy() end
    if presentation.weapon_charge_display then pcall(presentation.weapon_charge_display.destroy) end
    if presentation.ammo_readout then pcall(presentation.ammo_readout.destroy) end
    if presentation.holster_counts then pcall(presentation.holster_counts.destroy) end
    if presentation.wrist_display then pcall(presentation.wrist_display.destroy) end
    if presentation.forearm_holsters then pcall(presentation.forearm_holsters.destroy) end
    if presentation.skull_throw then pcall(presentation.skull_throw.destroy) end
    if presentation.teammate_status then pcall(presentation.teammate_status.destroy) end
    if presentation.rig_scan then pcall(presentation.rig_scan.destroy) end
    if presentation.body_mirror then pcall(presentation.body_mirror.destroy) end
    requested = false
    ui_stereo_requested = false
    presentation.melee_preview.enabled = false
    presentation.melee_preview.destroy()
    pcall(presentation.hud_panel.set_enabled, false)
    pcall(presentation.marker_gui.destroy_all)
    pcall(presentation.marker_world.destroy_all)
    pcall(presentation.marker_atlas.destroy)
    if presentation.hand_overlay then presentation.hand_overlay.destroy() end
    pcall(teardown)
    pcall(teardown_ui_stereo)
    pcall(destroy_ui_offscreen_resources)
    pcall(presentation.body_proxy.destroy)
end
