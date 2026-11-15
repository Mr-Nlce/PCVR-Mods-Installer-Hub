-- Melee by swinging the weapon hand (option "vr_melee_swing", default on).
-- OPTIONAL ADD-ON: the base mod loads this file, its menu section and its
-- texts only when the file is present. Delete it to remove the feature.
--
-- Stock melee is one held input: pressing the primary action starts the
-- windup, letting go early releases a light attack, and holding until the
-- windup's heavy chain time releases a heavy attack. The right trigger does
-- exactly that. This gesture does the same with the controller: a swing of
-- the weapon hand holds the primary action through bindings.forced (the same
-- route the inspect and push-to-talk gestures use), so the game sees an
-- ordinary press and release and every rule of the stock attack chain --
-- combos, stamina, buffering, online authority -- stays the game's own.
--
-- Two modes (option "vr_melee_swing_heavy_mode"):
--   instant (default)   -> every swing is a light attack, released MIN_HOLD
--                          after the swing starts, so the hit lands while the
--                          arm is still moving. Heavies stay on the trigger.
--   big_swing           -> small swing: light, released at its end; big
--                          swing: held until the windup's heavy is ready,
--                          then released (that charge time is the game's).
--
-- "Big" is the distance the hand travelled during the swing or its peak
-- speed. Worn 29 October: real swings peak at 5-8 m/s, so speed alone is a
-- poor heavy signal and its default sits high. The trigger keeps working: the gesture never starts while the
-- primary action is physically held, and stands down while blocking.
--
-- Hand motion is read from the raw tracked grip (tracking space), so stick
-- locomotion and snap turns are not swings. The pure part below is what the
-- tests exercise; the engine part is at the bottom.
local Swing = {}

-- Start a swing at this hand speed (m/s); the swing ends once it falls
-- below END_SPEED. The gap keeps a swing from chattering at the threshold.
Swing.START_SPEED = 2.0
Swing.END_SPEED = 1.0
-- Heavy if the hand travelled at least this far (m) during the swing, or
-- peaked at HEAVY_SPEED (m/s).
Swing.HEAVY_PATH = 0.70
Swing.HEAVY_SPEED = 8.0
-- The press is held at least this long, so the game sees hold then release
-- on separate input frames.
Swing.MIN_HOLD = 0.035
-- A light swing still moving is released as a light this long before the
-- running windup would mature into a heavy (the engine reports the time
-- left). Without that report, after LIGHT_MAX_HOLD (stock heavy chain times
-- are about 0.4 s and up).
Swing.LIGHT_MARGIN = 0.04
Swing.LIGHT_MAX_HOLD = 0.28
-- A heavy is held until the game reports it ready, at most this long.
Swing.HEAVY_MAX_HOLD = 1.5
-- After a release, no new swing for this long, and not before the hand has
-- slowed below END_SPEED: the hand coming back is not a second swing.
Swing.REARM = 0.10
-- Within RETURN_WINDOW of a release, a motion back against the last swing's
-- direction must be RETURN_FACTOR times faster to count: bringing the hand
-- back to guard is not an attack, a deliberate backhand still is.
Swing.RETURN_WINDOW = 0.45
Swing.RETURN_FACTOR = 1.5
Swing.RETURN_COS = -0.3
-- 30 October (worn: "faster please"): MIN_HOLD 0.05->0.035, REARM
-- 0.18->0.10, RETURN_FACTOR 2.0->1.5, WINDOW 0.045->0.035.
-- Speed is measured over this window (s); a sample further than JUMP (m)
-- from the previous one is a tracking jump, not motion, and resets history.
Swing.WINDOW = 0.035
Swing.JUMP = 0.5

local function finite(x) return type(x) == "number" and x == x and math.abs(x) < math.huge end
local function point(v) return type(v) == "table" and finite(v[1]) and finite(v[2]) and finite(v[3]) end
local function distance(a, b)
    return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2)
end

function Swing.new()
    return {phase = "idle", history = {}, calm = true, rearm_at = -math.huge}
end

-- Hand speed from a short position history. Pure apart from `state.history`.
-- Returns speed (m/s) and the distance moved since the previous sample.
function Swing.track(state, t, pos)
    local history = state.history
    if not finite(t) or not point(pos) then
        state.history = {}
        return nil, 0
    end
    local last = history[#history]
    if last and (t < last.t or distance(last.pos, pos) > Swing.JUMP) then
        history = {}
        last = nil
    end
    local step = last and distance(last.pos, pos) or 0
    history[#history + 1] = {t = t, pos = {pos[1], pos[2], pos[3]}}
    -- Keep one sample at or beyond the window, for a full-width difference.
    while #history > 2 and t - history[2].t >= Swing.WINDOW do
        table.remove(history, 1)
    end
    state.history = history
    local first = history[1]
    local dt = t - first.t
    if dt < 0.008 then return nil, step end
    return distance(first.pos, pos) / dt, step
end

-- Unit direction of the motion across the history window, or nil.
local function heading(state, pos)
    local first = state.history[1]
    if not first or not point(pos) then return nil end
    local d = {pos[1] - first.pos[1], pos[2] - first.pos[2], pos[3] - first.pos[3]}
    local n = math.sqrt(d[1] ^ 2 + d[2] ^ 2 + d[3] ^ 2)
    if n < 1e-4 then return nil end
    return {d[1] / n, d[2] / n, d[3] / n}
end

local function release(state, t, kind, pos)
    local from = state.start_pos
    state.last_dir = nil
    if from and point(pos) then
        local d = {pos[1] - from[1], pos[2] - from[2], pos[3] - from[3]}
        local n = math.sqrt(d[1] ^ 2 + d[2] ^ 2 + d[3] ^ 2)
        if n > 0.05 then state.last_dir = {d[1] / n, d[2] / n, d[3] / n} end
    end
    state.released_at = t
    state.calm_pos = nil
    state.phase = "idle"
    state.rearm_at = t + Swing.REARM
    state.calm = false
    return kind
end

-- One step. `input` = {t, pos = {x,y,z} or nil, armed = bool,
-- heavy_ready = bool, heavy_path, heavy_speed, start_speed, instant}. Returns the
-- primary action hold for this frame and an event (`heavy_in`, optional:
-- seconds until the running windup matures into a heavy): "start", "heavy"
-- (classified heavy), "light"/"heavy_release"/"cancel" (released), or nil.
function Swing.step(state, input)
    local t = input.t
    if not finite(t) then
        state.phase, state.history = "idle", {}
        return false, nil
    end
    -- Time running backwards (a level change, a new clock): start over.
    if state.last_t and t < state.last_t then
        for key in pairs(state) do state[key] = nil end
        for key, value in pairs(Swing.new()) do state[key] = value end
    end
    state.last_t = t
    local start_speed = finite(input.start_speed) and input.start_speed or Swing.START_SPEED
    local heavy_path = finite(input.heavy_path) and input.heavy_path or Swing.HEAVY_PATH
    local heavy_speed = finite(input.heavy_speed) and input.heavy_speed or Swing.HEAVY_SPEED
    local end_speed = math.min(Swing.END_SPEED, start_speed * 0.6)
    local speed, step = Swing.track(state, t, input.pos)

    if not input.armed then
        -- Disarming mid-swing (trigger pressed, block raised, weapon put
        -- away) lets go at once; the trigger or the game takes it from here.
        local was = state.phase ~= "idle"
        state.phase = "idle"
        state.calm = false
        return false, was and "cancel" or nil
    end

    if state.phase == "idle" then
        if speed and speed < end_speed then
            state.calm = true
            -- Where the hand last rested: the swing's size counts from here,
            -- so the run-up before START_SPEED belongs to the swing.
            state.calm_pos = point(input.pos) and {input.pos[1], input.pos[2], input.pos[3]} or nil
        end
        local needed = start_speed
        if speed and state.last_dir and state.released_at and t - state.released_at < Swing.RETURN_WINDOW then
            local dir = heading(state, input.pos)
            if dir and dir[1] * state.last_dir[1] + dir[2] * state.last_dir[2] +
                    dir[3] * state.last_dir[3] < Swing.RETURN_COS then
                needed = start_speed * Swing.RETURN_FACTOR
            end
        end
        if speed and speed >= needed and state.calm and t >= state.rearm_at then
            state.phase = "swing"
            state.start = t
            -- The swing's direction is measured from where the motion began.
            local first = state.history[1]
            state.start_pos = first and {first.pos[1], first.pos[2], first.pos[3]}
            state.peak = speed
            state.path = state.calm_pos and point(input.pos) and distance(state.calm_pos, input.pos) or 0
            state.heavy = false
            return true, "start"
        end
        return false, nil
    end

    -- "follow": an instant light has gone out and the arm is still moving.
    -- No new swing until it has slowed down.
    if state.phase == "follow" then
        if speed == nil or speed < end_speed then
            state.phase = "idle"
            state.calm = true
            state.calm_pos = point(input.pos) and {input.pos[1], input.pos[2], input.pos[3]} or nil
            state.rearm_at = t + Swing.REARM
        end
        return false, nil
    end

    local held_for = t - state.start
    if state.phase == "swing" then
        state.path = state.path + step
        if speed and speed > state.peak then state.peak = speed end
        if input.instant then
            if held_for >= Swing.MIN_HOLD then
                local kind = release(state, t, "light", input.pos)
                state.phase = "follow"
                return false, kind
            end
            return true, nil
        end
        if not state.heavy and (state.path >= heavy_path or state.peak >= heavy_speed) then
            state.heavy = true
            return true, "heavy"
        end
        local ended = speed == nil or speed < end_speed
        if state.heavy then
            if ended then state.phase = "charge" end
            if input.heavy_ready or held_for >= Swing.HEAVY_MAX_HOLD then
                return false, release(state, t, "heavy_release", input.pos)
            end
            return true, nil
        end
        local deadline
        if finite(input.heavy_in) then
            deadline = input.heavy_in <= Swing.LIGHT_MARGIN
        else
            deadline = held_for >= Swing.LIGHT_MAX_HOLD
        end
        if (ended or deadline or input.heavy_ready) and held_for >= Swing.MIN_HOLD then
            return false, release(state, t, "light", input.pos)
        end
        return true, nil
    end

    -- "charge": a big swing has ended, the windup is maturing into a heavy.
    if input.heavy_ready or held_for >= Swing.HEAVY_MAX_HOLD then
        return false, release(state, t, "heavy_release", input.pos)
    end
    return true, nil
end

-- Touch to interact (30 October, worn: "both grips are taken; just touching
-- an object with the hand for a while would be good, many interactions need
-- the stick held down"). The hand resting on an interactable for DWELL
-- seconds holds the stock interact action until the hand leaves it, the
-- target goes away or MAX_HOLD passes; then not again on that target until
-- the hand has left it. Pure state machine; the engine part is below.
-- Distance from the hand to the target's bounding box (0 inside it).
Swing.TOUCH_RADIUS = 0.30
Swing.TOUCH_LEAVE = 0.50
Swing.TOUCH_DWELL = 0.30
Swing.TOUCH_MAX_HOLD = 10

-- best: {unit=, distance=} nearest interactable to a hand (from the stock
-- search), or nil. held_distance: the hand's distance to the unit being held
-- (measured directly; the stock search stops returning a unit once it is
-- being interacted with -- worn 30 October, every crate let go after one
-- frame). interacting: the stock interactor's is_interacting().
-- Returns hold (bool), focus unit (or nil), event ("press", "release", nil).
Swing.TOUCH_START_WINDOW = 0.5
-- Interactables whose root is within TOUCH_SCAN (m) of a hand are measured;
-- a box with a half extent over TOUCH_BIG_BOX (m) counts by its points.
Swing.TOUCH_SCAN = 3.0
Swing.TOUCH_BIG_BOX = 0.8
function Swing.touch_step(st, t, best, held_distance, interacting)
    if st.holding then
        if interacting then st.started = true end
        local done = (st.started and not interacting) or
            (not st.started and t - st.since > Swing.TOUCH_START_WINDOW)
        local left = not finite(held_distance) or held_distance > Swing.TOUCH_LEAVE
        if done or left or t - st.since > Swing.TOUCH_MAX_HOLD then
            st.holding, st.blocked, st.unit, st.armed_unit = false, st.unit, nil, nil
            return false, nil, done and "done" or "release"
        end
        return true, st.unit, nil
    end
    if st.blocked ~= nil then
        -- No second go on the same unit until the hand has left it (the data
        -- interrogator's minigame starts as its interaction ends; holding on
        -- would have kept the action pressed into it).
        if finite(held_distance) and held_distance <= Swing.TOUCH_LEAVE then
            return false, nil, nil
        end
        st.blocked = nil
    end
    if best and finite(best.distance) and best.distance <= Swing.TOUCH_RADIUS then
        if st.armed_unit ~= best.unit then st.armed_unit, st.armed_at = best.unit, t end
        if t - st.armed_at >= Swing.TOUCH_DWELL then
            st.holding, st.unit, st.since, st.started = true, best.unit, t, false
            return true, best.unit, "press"
        end
        return false, best.unit, nil
    end
    st.armed_unit = nil
    return false, nil, nil
end

-- Add-on presence. The base mod loads this file only when it exists, so
-- the feature is an optional drop-in: without the file nothing changes.
Swing.PATH = "darktidevr/scripts/mods/darktidevr/darktidevr_melee_swing"
Swing.FILE = "./../mods/darktidevr/scripts/mods/darktidevr/darktidevr_melee_swing.lua"

-- Its own section in Mod Options, Darktide VR. NOTHING here may rename a
-- setting_id: those are the saved keys.
function Swing.widgets()
    return {
        setting_id = "melee_swing_options",
        type = "group",
        sub_widgets = {
            {
                setting_id = "vr_melee_swing",
                type = "checkbox",
                default_value = true,
                sub_widgets = {
                    {
                        -- instant: every swing a light at once; big_swing: a
                        -- big swing holds for a heavy (slower by the charge).
                        setting_id = "vr_melee_swing_heavy_mode",
                        type = "dropdown",
                        default_value = "instant",
                        options = {
                            {text = "vr_melee_swing_mode_instant", value = "instant"},
                            {text = "vr_melee_swing_mode_big_swing", value = "big_swing"},
                        },
                    },
                    {
                        -- Delayed render-state release (restart).
                        setting_id = "vr_melee_swing_stream_delay",
                        type = "checkbox",
                        default_value = true,
                        sub_widgets = {
                            {
                                setting_id = "vr_melee_swing_stream_delay_ms", type = "numeric",
                                default_value = 50, range = {20, 200}, decimals_number = 0, step_size_value = 10,
                            },
                        },
                    },
                    {
                        -- Engine particle double-simulation fix (restart).
                        setting_id = "vr_melee_swing_engine_patch_experimental",
                        type = "checkbox",
                        default_value = false,
                    },
                    {
                        -- Touch to interact (restart).
                        setting_id = "vr_melee_swing_touch",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        -- Hide teammates' names (restart).
                        setting_id = "vr_melee_swing_hide_names",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        -- Diagnostic: once-a-second particle census in the log.
                        setting_id = "vr_melee_swing_particle_log",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        -- Melee aims with the head, level; crosshair hidden.
                        setting_id = "vr_melee_swing_head_aim",
                        type = "checkbox",
                        default_value = true,
                    },
                    {
                        -- Hand speed (m/s) that starts an attack.
                        setting_id = "vr_melee_swing_speed", type = "numeric",
                        default_value = 2.0, range = {1.2, 4.0}, decimals_number = 1, step_size_value = 0.1,
                    },
                    {
                        -- Hand travel (cm) that makes the swing a heavy.
                        setting_id = "vr_melee_swing_heavy_size", type = "numeric",
                        default_value = 70, range = {35, 130}, decimals_number = 0, step_size_value = 5,
                    },
                    {
                        -- Peak hand speed (m/s) that makes a swing a heavy
                        -- however short it is.
                        setting_id = "vr_melee_swing_heavy_speed", type = "numeric",
                        default_value = 8.0, range = {3.0, 12.0}, decimals_number = 1, step_size_value = 0.5,
                    },
                },
            },
        },
    }
end

Swing.localization = {
    melee_swing_options = {en = "Melee by swinging"},
    vr_melee_swing = {en = "Melee by swinging your weapon hand"},
    vr_melee_swing_description = {en = "With a melee weapon in hand, swing the controller to attack: a short swing is a light attack, a big swing a heavy attack (held until the heavy is ready, then released). The right trigger still works as before; the swing does nothing while the trigger or block is held."},
    vr_melee_swing_speed = {en = "Swing strength to attack (m/s)"},
    vr_melee_swing_speed_description = {en = "How hard you must swing to attack. Lower: gentler swings attack. Higher: only firm swings attack -- raise it if reaching for holsters or items attacks by mistake. Default 2.0."},
    vr_melee_swing_touch = {en = "Touch to interact (restart to apply)"},
    vr_melee_swing_touch_description = {en = "Rest a hand on a door control, lever, crate, item or downed team mate for a moment and it interacts, held for as long as the hand stays there (for revives and other long interactions). The game still chooses the target and checks its range. The right stick keeps working."},
    vr_melee_swing_hide_names = {en = "Hide teammates' names (restart to apply)"},
    vr_melee_swing_hide_names_description = {en = "Hides the names floating above team mates in missions."},
    vr_melee_swing_stream_delay = {en = "VR crash fix: delayed render-state release (restart to apply)"},
    vr_melee_swing_stream_delay_description = {en = "VR draws the world twice per frame. The game freed and reused the world's render state right away, while the other eye was still drawing from it, which crashed missions (out of memory / ParticleSystem). This keeps released render states for a few frames before the game may reuse them. Patched in memory at start-up for this exact game build only; the game file is not changed."},
    vr_melee_swing_stream_delay_ms = {en = "Crash fix: hold time (ms)"},
    vr_melee_swing_stream_delay_ms_description = {en = "How long a released render state is kept before the game may reuse it. Higher is safer, uses a little more memory. Default 50."},
    vr_melee_swing_engine_patch_experimental = {en = "Experimental engine particle patch (restart; leave off)"},
    vr_melee_swing_engine_patch_experimental_description = {en = "The game simulates particles each time it renders; VR renders twice per frame, so particles were simulated twice and the engine eventually crashed (out of memory). This makes only the first eye simulate them. Applied in memory at start-up for this exact game build only; the game file is not changed."},
    vr_melee_swing_particle_log = {en = "Record particle effects in the log (diagnostic)"},
    vr_melee_swing_particle_log_description = {en = "Once a second, writes which particle effects were created to the game's console log, and flags any effect created at an invalid position. Used to find the effect behind the VR mission crashes. Only in VR."},
    vr_melee_swing_head_aim = {en = "Stock melee aim (follow your head)"},
    vr_melee_swing_head_aim_description = {en = "With a melee weapon in hand, attacks go where you look, as in the flat game: your character no longer turns with every swing of your hand, the attack is not tilted by your wrist, and the crosshair is hidden. Guns keep aiming with your hand."},
    vr_melee_swing_heavy_mode = {en = "Swing attacks"},
    vr_melee_swing_heavy_mode_description = {en = "Instant: every swing is a light attack the moment it starts, so it lands with your arm -- hold the trigger for heavies. Big swing for heavy: a big swing waits until the heavy is charged (about half a second, the game's own charge time) before it lands. Tip: switch off Melee animations (Your body and hands) so the weapon follows only your hand."},
    vr_melee_swing_mode_instant = {en = "Instant (light attacks)"},
    vr_melee_swing_mode_big_swing = {en = "Big swing for heavy"},
    vr_melee_swing_heavy_size = {en = "Swing size for a heavy attack (cm)"},
    vr_melee_swing_heavy_size_description = {en = "How far the hand must travel in one swing for a heavy attack. Lower makes heavies easier. Default 70 cm. Only in Big swing for heavy."},
    vr_melee_swing_heavy_speed = {en = "Swing strength for a heavy attack (m/s)"},
    vr_melee_swing_heavy_speed_description = {en = "A swing this fast is a heavy attack even when it is short. Raise it if quick light swings come out as heavies. Default 8.0. Only in Big swing for heavy."},
}

-- Stereo particle fix (option "vr_melee_swing_engine_patch_experimental", default on;
-- 29 October). Missions in VR crashed inside the engine's ParticleSystem
-- (out of memory asking for 2-235 GB, or an access violation), flat never.
-- Darktide.exe build ts 0x6ad76788: the per-frame particle update (RVA
-- 0x574360) sets byte +0x514 "simulation due" and advances the ping-pong
-- buffers once per frame; GPUVisualizer::render (RVA 0x575cd0) reads that
-- byte and emits + simulates, but never clears it. Stock calls render once
-- per frame (its only caller, 0x47f21b, is the regular branch; shadows take
-- another path), so flat is unaffected. The VR mod renders the world twice
-- per frame, so every particle system emitted and simulated twice against
-- one buffer flip, and its counts ran away. The patch makes the read a
-- read-and-clear (atomic xchg): the first eye simulates, the second eye
-- draws the same particles. Applied in memory only, never to the file, and
-- only when the build and the 11 original bytes match exactly.
Swing.PARTICLE_FIX = {
    timestamp = 0x6ad76788, image_size = 0x290e000,
    site = 0x575cfd, resume = 0x575d08,
    original = {0x44, 0x0f, 0xb6, 0xb9, 0x14, 0x05, 0x00, 0x00, 0x4c, 0x8b, 0xe9},
    -- mov r13,rcx ; xor r15d,r15d ; xchg byte [rcx+0x514],r15b ; jmp resume
    cave = {0x4c, 0x8b, 0xe9, 0x45, 0x31, 0xff, 0x44, 0x86, 0xb9, 0x14, 0x05, 0x00, 0x00, 0xe9},
}

-- Second part (worn 29 October, after the first alone did not hold): the
-- crash reads the particle list of a world render snapshot after it changed
-- under it. Application.render_world calls RenderInterface update_world
-- (RVA 0x2e1350) first, which reuses the current snapshot only when it is
-- this frame's AND every earlier render of it has finished reading it. The
-- second eye is submitted right after the first, which has not run yet, so a
-- second snapshot was built in the same frame while the first eye's jobs
-- still read the first. The patch skips the "finished reading" counters so
-- the frame test alone decides: the second eye renders the first eye's
-- snapshot, the same world state, as stereo should. A new frame still
-- builds a new snapshot; flat (one render per frame) is unchanged.
Swing.SNAPSHOT_FIX = {
    site = 0x2e142e,
    context_start = 0x2e1425,
    context = "83bbb400000001754b488b8bc00000008b4114394118723c8b83e40000003983e8000000722e8b833c01000039834001000072208b839401000039839801000072128b83b0000000398720030000750432c0eb02b001",
    -- jmp 0x2e1467 (the frame test), then nops over the rest of the mov.
    patch = {0xeb, 0x37, 0x90, 0x90, 0x90, 0x90, 0x90},
}

local function hex_bytes(text)
    local out = {}
    for pair in text:gmatch("%x%x") do out[#out + 1] = tonumber(pair, 16) end
    return out
end

-- In-place patch of the snapshot guard. Returns "applied" or why not.
function Swing.apply_snapshot_fix(ffi, C, base)
    local spec = Swing.SNAPSHOT_FIX
    local start = base + spec.context_start
    local expected = hex_bytes(spec.context)
    local offset = spec.site - spec.context_start
    local matches_original, matches_patched = true, true
    for i, byte in ipairs(expected) do
        local index = i - 1
        local actual = start[index]
        if actual ~= byte then matches_original = false end
        local want = byte
        if index >= offset and index < offset + #spec.patch then want = spec.patch[index - offset + 1] end
        if actual ~= want then matches_patched = false end
    end
    if matches_patched then return "already_patched" end
    if not matches_original then return "bytes_mismatch" end
    local site = base + spec.site
    local word = ffi.new("uint8_t[8]")
    for i = 0, 7 do word[i] = site[i] end
    for i, byte in ipairs(spec.patch) do word[i - 1] = byte end
    local old = ffi.new("unsigned long[1]")
    if C.VirtualProtect(site, 8, 0x40, old) == 0 then return "protect_failed" end
    ffi.cast("uint64_t*", site)[0] = ffi.cast("uint64_t*", word)[0]
    C.VirtualProtect(site, 8, old[0], old)
    C.FlushInstructionCache(C.GetCurrentProcess(), site, 8)
    return "applied"
end

-- Returns "applied" or the reason it did not. `C` provides GetModuleHandleA,
-- VirtualAlloc, VirtualProtect, GetCurrentProcess, FlushInstructionCache.
function Swing.apply_particle_fix(ffi, C, base_ptr, skip_snapshot)
    local spec = Swing.PARTICLE_FIX
    if base_ptr == nil then return "no_module" end
    local base = ffi.cast("uint8_t*", base_ptr)
    local nt = ffi.cast("uint32_t*", base + 0x3c)[0]
    local stamp = ffi.cast("uint32_t*", base + nt + 8)[0]
    local size = ffi.cast("uint32_t*", base + nt + 0x50)[0]
    if stamp ~= spec.timestamp or size ~= spec.image_size then
        return string.format("unknown_build ts=%x size=%x", tonumber(stamp), tonumber(size))
    end
    local snapshot = skip_snapshot and "skipped" or Swing.apply_snapshot_fix(ffi, C, base)
    local site = base + spec.site
    for i, byte in ipairs(spec.original) do
        if site[i - 1] ~= byte then
            return "snapshot=" .. snapshot .. " simulate=" ..
                (site[0] == 0xe9 and "already_patched" or "bytes_mismatch")
        end
    end
    local base_addr = tonumber(ffi.cast("uintptr_t", base_ptr))
    local cave
    for step = 1, 4096 do
        local try = base_addr - step * 0x10000
        if try <= 0x10000 then break end
        local p = C.VirtualAlloc(ffi.cast("void*", try), 4096, 0x3000, 0x40)
        if p ~= nil then cave = p; break end
    end
    if cave == nil then return "snapshot=" .. snapshot .. " simulate=no_cave" end
    local cave_addr = tonumber(ffi.cast("uintptr_t", cave))
    local back = (base_addr + spec.resume) - (cave_addr + #spec.cave + 4)
    local jump = cave_addr - (base_addr + spec.site + 5)
    if math.abs(back) >= 2^31 or math.abs(jump) >= 2^31 then
        return "snapshot=" .. snapshot .. " simulate=cave_out_of_range"
    end
    local c = ffi.cast("uint8_t*", cave)
    for i, byte in ipairs(spec.cave) do c[i - 1] = byte end
    ffi.cast("int32_t*", c + #spec.cave)[0] = back
    -- The site's first 5 bytes become `jmp cave`, written as one 8-byte
    -- store; bytes 5..10 are left as they were (the cave resumes after them).
    local word = ffi.new("uint8_t[8]")
    for i = 0, 7 do word[i] = site[i] end
    word[0] = 0xe9
    ffi.cast("int32_t*", word + 1)[0] = jump
    local old = ffi.new("unsigned long[1]")
    if C.VirtualProtect(site, 8, 0x40, old) == 0 then
        return "snapshot=" .. snapshot .. " simulate=protect_failed"
    end
    ffi.cast("uint64_t*", site)[0] = ffi.cast("uint64_t*", word)[0]
    C.VirtualProtect(site, 8, old[0], old)
    C.FlushInstructionCache(C.GetCurrentProcess(), site, 8)
    return "snapshot=" .. snapshot .. " simulate=applied"
end

-- Stereo render sync (option "vr_melee_swing_stereo_sync", default on; 29
-- October, from the crash dumps). Application.render_world first calls
-- RenderInterface update_world (RVA 0x2e1350). It keeps the world's current
-- render state stream only if it is this frame's AND every reader has
-- consumed it; otherwise it builds a new one and hands the old one to
-- stingray::RenderWorld::release_state_stream, which pools it for reuse.
-- VR submits the second eye right after the first, before the render thread
-- has consumed the first eye's stream, so the second eye always built a new
-- stream and released the first while the first eye's particle jobs were
-- still reading it; the pooled stream was then overwritten (float data in a
-- list pointer, 2-235 GB allocations). This patch adds, ONLY for a second
-- call in the same frame, a bounded wait (rdtsc budget) for the engine's own
-- consumed counters before the engine's own unchanged test runs -- so the
-- stream is then reused exactly as the engine allows. A first call in a new
-- frame, i.e. all of flat, runs the original code untouched. Counters for
-- waits / reused / timeouts / ticks sit on the patch page and are logged.
Swing.STEREO_SYNC = {
    site = 0x2e1425,
    cave = "83bbb4000000010f85e10000008b83b00000003987200300000f85cf0000004c8d05da0100004d8d484041ba10000000498b014839f0741a4885c074124983c13041ffca75ea4d8d8810030000eb0349893149ff0049ff41088b8720030000413941200f84970000000f3148c1e2204809d04889c1488b83c00000008b5014395018723e8b83e40000003983e800000072308b833c01000039834001000072228b839401000039839801000072148b87200300004189412049ff400849ff4110eb1cf3900f3148c1e2204809d04829c8493b4020729f49ff401049ff41180f3148c1e2204809d04829c84901401883bbb4000000010f857e132f00e92e132f0049ff402849ff4128e95a132f00",
    update = 0x2e1479, resume = 0x2e142e, frame_test = 0x2e1467,
    rel_update = 0xf7, rel_resume = 0xfc, rel_frame_test = 0x109,
    -- stats: [0] waits [1] reused [2] timeouts [3] ticks [4] budget
    -- [5] forced, then 16 per-world slots of {entry key, waits, reused,
    -- timeouts, frame of the last successful reuse, forced} from [8].
    -- Worn 30 October: a world rendered 3-4 times per frame timed out on
    -- every call after the second (the render thread must finish the whole
    -- previous render), ~21 ms a frame and the unsafe path each time. Once a
    -- stream has been consumed and reused in this frame, later calls in the
    -- same frame reuse it at once (only a never-consumed stream crashed).
    stats = 0x200,
}

-- Returns status, stats pointer (uint64_t[5]: waits, reused, timeouts,
-- ticks, budget) or nil.
function Swing.apply_stereo_sync(ffi, C, base_ptr, budget_ticks)
    if base_ptr == nil then return "no_module" end
    local base = ffi.cast("uint8_t*", base_ptr)
    local nt = ffi.cast("uint32_t*", base + 0x3c)[0]
    local stamp = ffi.cast("uint32_t*", base + nt + 8)[0]
    local size = ffi.cast("uint32_t*", base + nt + 0x50)[0]
    if stamp ~= Swing.PARTICLE_FIX.timestamp or size ~= Swing.PARTICLE_FIX.image_size then
        return string.format("unknown_build ts=%x size=%x", tonumber(stamp), tonumber(size))
    end
    local spec = Swing.STEREO_SYNC
    local expected = hex_bytes(Swing.SNAPSHOT_FIX.context)
    local start = base + Swing.SNAPSHOT_FIX.context_start
    for i, byte in ipairs(expected) do
        if start[i - 1] ~= byte then
            return start[spec.site - Swing.SNAPSHOT_FIX.context_start] == 0xe9 and
                "already_patched" or "bytes_mismatch"
        end
    end
    local base_addr = tonumber(ffi.cast("uintptr_t", base_ptr))
    local cave
    for step = 1, 4096 do
        local try = base_addr - step * 0x10000
        if try <= 0x10000 then break end
        local p = C.VirtualAlloc(ffi.cast("void*", try), 4096, 0x3000, 0x40)
        if p ~= nil then cave = p; break end
    end
    if cave == nil then return "no_cave" end
    local cave_addr = tonumber(ffi.cast("uintptr_t", cave))
    local bytes = hex_bytes(spec.cave)
    local c = ffi.cast("uint8_t*", cave)
    for i, byte in ipairs(bytes) do c[i - 1] = byte end
    local to_update = (base_addr + spec.update) - (cave_addr + spec.rel_update + 4)
    local to_resume = (base_addr + spec.resume) - (cave_addr + spec.rel_resume + 4)
    local to_frame_test = (base_addr + spec.frame_test) - (cave_addr + spec.rel_frame_test + 4)
    local jump = cave_addr - (base_addr + spec.site + 5)
    for _, v in ipairs({to_update, to_resume, to_frame_test, jump}) do
        if math.abs(v) >= 2^31 then return "cave_out_of_range" end
    end
    ffi.cast("int32_t*", c + spec.rel_update)[0] = to_update
    ffi.cast("int32_t*", c + spec.rel_resume)[0] = to_resume
    ffi.cast("int32_t*", c + spec.rel_frame_test)[0] = to_frame_test
    local stats = ffi.cast("uint64_t*", c + spec.stats)
    for i = 0, 8 + 16 * 6 - 1 do stats[i] = 0 end
    stats[4] = budget_ticks
    local site = base + spec.site
    local word = ffi.new("uint8_t[8]")
    for i = 0, 7 do word[i] = site[i] end
    word[0] = 0xe9
    ffi.cast("int32_t*", word + 1)[0] = jump
    local old = ffi.new("unsigned long[1]")
    if C.VirtualProtect(site, 8, 0x40, old) == 0 then return "protect_failed" end
    ffi.cast("uint64_t*", site)[0] = ffi.cast("uint64_t*", word)[0]
    C.VirtualProtect(site, 8, old[0], old)
    C.FlushInstructionCache(C.GetCurrentProcess(), site, 8)
    return "applied", stats
end

-- Delayed stream release (option "vr_melee_swing_stream_delay", default on;
-- 30 October). The wait-based sync above was worn and still crashed: a world
-- drawn 3-4 times a frame timed out and took the unsafe path anyway. Root of
-- it: stingray::RenderWorld::release_state_stream (RVA 0x38e490) resets the
-- released stream AT ONCE (0x602160 frees/shrinks its buffers, zeroes the
-- counts) and pushes it on a LIFO pool, so the very next update_world gets it
-- back and refills it -- while the previous eye's render jobs are still
-- reading it (garbage list counts -> 0.9-235 GB allocations, out of memory).
-- This patch sends the engine's three release calls (main thread 0x2e12ee,
-- 0x2e14e5; render thread 0x2e1d82) to a small FIFO (128 entries) that hands
-- each stream to the real release only after N ms (time from the Windows
-- shared page) or when full. The RenderWorld destructor (0x38c140) first
-- drops that world's entries (it destroys those streams itself). Nothing
-- else changes: flat and VR keep the engine's own logic, only later.
Swing.STREAM_DELAY = {
    release = 0x38e490,
    calls = {0x2e12ee, 0x2e14e5, 0x2e1d82},
    dtor = 0x38c140, dtor_original = "48895c240848896c", dtor_resume = 0x38c145,
    hook = "53565741544883ec284889ce4889d7488d1dea010000b80800fe7f4c8b20b801000000870385c07404f390ebf1817b0c8000000072278b4b08486bc9184c8d83000100004901c8498b08498b5008ff4b0c48ff43284885c97403ff53408b4b08486bc9184c8d83000100004901c8498930498978084d8960108b4308ffc083e07f894308ff430c48ff43188b430c483b43387604488943388b430c85c0743b8b4b0829c183e17f486bc9184c8d83000100004901c84c89e0492b4010483b43107218498b08498b5008ff4b0c48ff43204885c974c3ff5340ebbec703000000004883c428415c5f5e5bc3",
    dtor_hook = "5052415041514c8d05f3000000b80100000041870085c07404f390ebf04d8d8800010000ba80000000493909750b49c7010000000049ff40304983c118ffca75e841c70000000000415941585a5848895c2408e9",
    -- page: 0x000 release hook, 0x100 dtor hook, 0x200 data, 0x300 ring.
    -- data (uint64_t* d = page+0x200): d[1] low/high = head/count, d[2]
    -- delay (100 ns units), d[3] queued, d[4] released late, d[5] released
    -- early (FIFO full), d[6] dropped by world destroy, d[7] max in FIFO,
    -- d[8] address of the real release.
}

-- Returns status, data pointer (uint64_t*) or nil.
function Swing.apply_stream_delay(ffi, C, base_ptr, delay_ms)
    if base_ptr == nil then return "no_module" end
    local base = ffi.cast("uint8_t*", base_ptr)
    local nt = ffi.cast("uint32_t*", base + 0x3c)[0]
    local stamp = ffi.cast("uint32_t*", base + nt + 8)[0]
    local size = ffi.cast("uint32_t*", base + nt + 0x50)[0]
    if stamp ~= Swing.PARTICLE_FIX.timestamp or size ~= Swing.PARTICLE_FIX.image_size then
        return string.format("unknown_build ts=%x size=%x", tonumber(stamp), tonumber(size))
    end
    local spec = Swing.STREAM_DELAY
    local base_addr = tonumber(ffi.cast("uintptr_t", base_ptr))
    for _, call in ipairs(spec.calls) do
        if base[call] ~= 0xe8 or call + 5 + ffi.cast("int32_t*", base + call + 1)[0] ~= spec.release then
            return string.format("bytes_mismatch call %x", call)
        end
    end
    local dtor_bytes = hex_bytes(spec.dtor_original)
    for i, byte in ipairs(dtor_bytes) do
        if base[spec.dtor + i - 1] ~= byte then return "bytes_mismatch dtor" end
    end
    local cave
    for step = 1, 4096 do
        local try = base_addr - step * 0x10000
        if try <= 0x10000 then break end
        local p = C.VirtualAlloc(ffi.cast("void*", try), 4096, 0x3000, 0x40)
        if p ~= nil then cave = p; break end
    end
    if cave == nil then return "no_cave" end
    local cave_addr = tonumber(ffi.cast("uintptr_t", cave))
    if math.abs(cave_addr - base_addr) >= 2^31 - 0x4000000 then return "cave_out_of_range" end
    local c = ffi.cast("uint8_t*", cave)
    for i = 0, 4095 do c[i] = 0 end
    for i, byte in ipairs(hex_bytes(spec.hook)) do c[i - 1] = byte end
    local dt = hex_bytes(spec.dtor_hook)
    for i, byte in ipairs(dt) do c[0x100 + i - 1] = byte end
    ffi.cast("int32_t*", c + 0x100 + #dt)[0] = (base_addr + spec.dtor_resume) - (cave_addr + 0x100 + #dt + 4)
    local d = ffi.cast("uint64_t*", c + 0x200)
    d[2] = math.floor((tonumber(delay_ms) or 50) * 10000)
    d[8] = ffi.cast("uint64_t", base_addr + spec.release)
    local old = ffi.new("unsigned long[1]")
    -- Destructor first (an 8-byte aligned store), then the three call sites
    -- (a 4-byte store each, inside one cache line).
    local site = base + spec.dtor
    local word = ffi.new("uint8_t[8]")
    for i = 0, 7 do word[i] = site[i] end
    word[0] = 0xe9
    ffi.cast("int32_t*", word + 1)[0] = (cave_addr + 0x100) - (base_addr + spec.dtor + 5)
    if C.VirtualProtect(site, 8, 0x40, old) == 0 then return "protect_failed" end
    ffi.cast("uint64_t*", site)[0] = ffi.cast("uint64_t*", word)[0]
    C.VirtualProtect(site, 8, old[0], old)
    C.FlushInstructionCache(C.GetCurrentProcess(), site, 8)
    for _, call in ipairs(spec.calls) do
        local at = base + call
        if C.VirtualProtect(at, 5, 0x40, old) == 0 then return "protect_failed" end
        ffi.cast("int32_t*", at + 1)[0] = cave_addr - (base_addr + call + 5)
        C.VirtualProtect(at, 5, old[0], old)
        C.FlushInstructionCache(C.GetCurrentProcess(), at, 5)
    end
    return "applied", d
end

-- Same-frame stream reuse (with the delayed release; 30 October, dump
-- 9a4dc98e). The delayed release alone still crashed: the corrupt list is in
-- the ParticleSystem render object itself (a job thread, 0x387fa0 ->
-- 0x47e250, count [obj+0x70] = 26.7 M), i.e. the render thread applied the
-- second eye's world update while the first eye's render jobs still walked
-- the particle systems. Fix: once update_world has built a new stream for a
-- world in this frame, every further update_world for that world in the same
-- frame reuses it (no second apply between the eyes; the next frame applies
-- everything). A world whose stream was not built by update_world this frame
-- (e.g. just created) runs the original code -- that case crashed the
-- options menu on 29 October. Worn 30 October (dump b0bb5f09, at the end of
-- the intro cutscene): a first call that reused the engine's own stream left
-- the next call free to build and apply between the eyes. Now ANY earlier
-- update_world for that world in this frame makes the later ones reuse: the
-- first call either built and applied a stream or reused a consumed one,
-- so the stream is always one the engine has applied. Hook A at 0x2e1425 (decision), hook B at
-- 0x2e14b0 (records "built this frame" right after the engine creates it).
Swing.STEREO_REUSE = {
    site_a = 0x2e1425, site_b = 0x2e14b0,
    original_b = "4889461080bf64010000007420",
    hook_a = "8b87200300004c8d05f301000041b920000000493930741a49833800740b4983c01041ffc975eceb3349893041894008eb2a41394008740641894008eb1e83bbb40000000175153983b0000000750df048ff05a9000000e90b142f0083bbb4000000010f8510142f00e9c0132f00",
    hook_b = "488946108b8f200300004c8d056f01000041b920000000493930741c4983380074134983c01041ffc975ecf048ff055d000000eb0f49893041894808f048ff054400000080bf6401000000e9eb132f00",
    -- rel32 fields (page offset -> image RVA they jump to)
    relocs = {{0x58, 0x2e1467}, {0x65, 0x2e1479}, {0x6a, 0x2e142e}, {0xcc, 0x2e14bb}},
    -- page: 0x000 hook A, 0x080 hook B, 0x100 stats (reused, built,
    -- table_full), 0x200 32 slots of {world entry, frame built}.
}

function Swing.apply_stereo_reuse(ffi, C, base_ptr)
    if base_ptr == nil then return "no_module" end
    local base = ffi.cast("uint8_t*", base_ptr)
    local nt = ffi.cast("uint32_t*", base + 0x3c)[0]
    local stamp = ffi.cast("uint32_t*", base + nt + 8)[0]
    local size = ffi.cast("uint32_t*", base + nt + 0x50)[0]
    if stamp ~= Swing.PARTICLE_FIX.timestamp or size ~= Swing.PARTICLE_FIX.image_size then
        return string.format("unknown_build ts=%x size=%x", tonumber(stamp), tonumber(size))
    end
    local spec = Swing.STEREO_REUSE
    local ctx = Swing.SNAPSHOT_FIX
    for i, byte in ipairs(hex_bytes(ctx.context)) do
        if base[ctx.context_start + i - 1] ~= byte then return "bytes_mismatch a" end
    end
    for i, byte in ipairs(hex_bytes(spec.original_b)) do
        if base[spec.site_b + i - 1] ~= byte then return "bytes_mismatch b" end
    end
    local base_addr = tonumber(ffi.cast("uintptr_t", base_ptr))
    local cave
    for step = 1, 4096 do
        local try = base_addr - step * 0x10000
        if try <= 0x10000 then break end
        local p = C.VirtualAlloc(ffi.cast("void*", try), 4096, 0x3000, 0x40)
        if p ~= nil then cave = p; break end
    end
    if cave == nil then return "no_cave" end
    local cave_addr = tonumber(ffi.cast("uintptr_t", cave))
    if math.abs(cave_addr - base_addr) >= 2^31 - 0x4000000 then return "cave_out_of_range" end
    local c = ffi.cast("uint8_t*", cave)
    for i = 0, 4095 do c[i] = 0 end
    for i, byte in ipairs(hex_bytes(spec.hook_a)) do c[i - 1] = byte end
    for i, byte in ipairs(hex_bytes(spec.hook_b)) do c[0x80 + i - 1] = byte end
    for _, r in ipairs(spec.relocs) do
        ffi.cast("int32_t*", c + r[1])[0] = (base_addr + r[2]) - (cave_addr + r[1] + 4)
    end
    local old = ffi.new("unsigned long[1]")
    for _, hook in ipairs({{spec.site_b, 0x80}, {spec.site_a, 0}}) do
        local site = base + hook[1]
        local word = ffi.new("uint8_t[8]")
        for i = 0, 7 do word[i] = site[i] end
        word[0] = 0xe9
        ffi.cast("int32_t*", word + 1)[0] = (cave_addr + hook[2]) - (base_addr + hook[1] + 5)
        if C.VirtualProtect(site, 8, 0x40, old) == 0 then return "protect_failed" end
        ffi.cast("uint64_t*", site)[0] = ffi.cast("uint64_t*", word)[0]
        C.VirtualProtect(site, 8, old[0], old)
        C.FlushInstructionCache(C.GetCurrentProcess(), site, 8)
    end
    return "applied", ffi.cast("uint64_t*", c + 0x100), ffi.cast("uint8_t*", c + 0x180)
end


-- Engine side.
Swing.TEST_FLAG = "./../mods/darktidevr/darktidevr_melee_swing_test.flag"

function Swing.install(mod, presentation, observation)
    local api = {}
    local state = Swing.new()
    local PRIMARY_MASK = 1
    local failures, logged = 0, 0
    local last_template, last_melee = nil, false
    local last_sequence, last_side

    local test_poll, test_enabled = 0, false
    local function test_flag()
        test_poll = test_poll - 1
        if test_poll > 0 then return test_enabled end
        test_poll = 300
        local io_api = Mods and Mods.lua and Mods.lua.io
        local file = io_api and io_api.open(Swing.TEST_FLAG, "r")
        if not file then test_enabled = false; return false end
        local value = file:read("*all"); file:close()
        test_enabled = type(value) == "string" and value:match("^%s*enabled%s*$") ~= nil
        return test_enabled
    end

    function api.enabled()
        local setting = mod.get and mod:get("vr_melee_swing")
        -- Never saved yet: the default, on.
        return setting ~= false or test_flag()
    end

    local function extension(unit, system)
        local script_unit = rawget(_G, "ScriptUnit")
        return script_unit and script_unit.has_extension(unit, system)
    end

    -- Whether a melee weapon is wielded, and whether the running windup has
    -- reached its heavy chain time (read as the haptics' heavy_ready cue is).
    local function weapon_state(unit)
        local weapon = extension(unit, "weapon_system")
        local template = weapon and weapon:weapon_template()
        if template ~= last_template then
            last_template, last_melee = template, false
            local keywords = template and template.keywords
            if type(keywords) == "table" then
                for _, keyword in ipairs(keywords) do
                    if keyword == "melee" then last_melee = true end
                end
            end
        end
        if not last_melee then return false, false end
        local unit_data = extension(unit, "unit_data_system")
        local action = unit_data and unit_data:read_component("weapon_action")
        local settings = action and template.actions and template.actions[action.current_action_name]
        local heavy = settings and settings.kind == "windup" and settings.allowed_chain_actions and
            settings.allowed_chain_actions.heavy_attack
        local scale = tonumber(action and action.time_scale) or 1
        local ready, left = false, nil
        if heavy and type(heavy.chain_time) == "number" and scale > 0 then
            local now = Managers.time:time("gameplay")
            left = heavy.chain_time / scale - (now - action.start_t)
            ready = left <= 0
        end
        return true, ready, left
    end

    local function hand_position(side)
        if presentation.controllers_suppressed and presentation.controllers_suppressed() then return nil end
        local o = observation
        if side == "left" then
            if not o.left_grip_tracking_live then return nil end
            return {o.left_grip_x, o.left_grip_y, o.left_grip_z}
        end
        if not o.right_grip_tracking_live then return nil end
        return {o.right_grip_x, o.right_grip_y, o.right_grip_z}
    end

    local function settings()
        local start = mod.get and tonumber(mod:get("vr_melee_swing_speed"))
        local heavy = mod.get and tonumber(mod:get("vr_melee_swing_heavy_size"))
        local heavy_speed = mod.get and tonumber(mod:get("vr_melee_swing_heavy_speed"))
        local mode = mod.get and mod:get("vr_melee_swing_heavy_mode")
        return start, heavy and heavy / 100 or nil, heavy_speed, mode ~= "big_swing"
    end

    -- `physical` is the native held mask, `mode` the game mode name: the
    -- trigger or block held physically disarms the gesture.
    local function sample(unit, active, t, physical, mode)
        if not active or not unit or not api.enabled() then return nil end
        local bindings = presentation.controller_bindings
        if bindings and bindings.physical_hold and
                (bindings.physical_hold("primary", physical, mode) or
                 bindings.physical_hold("alternate", physical, mode)) then
            return {t = t, armed = false}
        end
        local melee, ready, heavy_in = weapon_state(unit)
        if not melee then return {t = t, armed = false} end
        -- The hand holding the weapon: the right one unless roles say otherwise.
        local side = presentation.weapon_hand_roles and
            presentation.weapon_hand_roles.physical("dominant") or "right"
        if side ~= last_side then state.history = {}; last_side = side end
        -- One sample per new controller pose; a repeated pose is no motion.
        local sequence = observation.last_sequence
        if sequence ~= nil and sequence == last_sequence and state.phase == "idle" then
            return {t = t, armed = true, skip = true}
        end
        last_sequence = sequence
        local start, heavy_path, heavy_speed, instant = settings()
        return {t = t, pos = hand_position(side), armed = true, heavy_ready = ready, heavy_in = heavy_in,
            start_speed = start, heavy_path = heavy_path, heavy_speed = heavy_speed, instant = instant, side = side}
    end

    function api.apply(unit, active, t, physical, mode)
        if api.stereo_sync_report then pcall(api.stereo_sync_report, t) end
        local ok, input = pcall(sample, unit, active, t, physical, mode)
        if not ok then
            failures = failures + 1
            if failures <= 3 then
                mod:warning("DARKTIDEVR_MELEE_SWING error=%s failures=%d",
                    tostring(input):sub(1, 160), failures)
            end
            input = nil
        end
        if input == nil then
            if state.phase ~= "idle" then state = Swing.new() end
            api.holding = false
            return
        end
        if input.skip then
            api.holding = false
            return
        end
        local hold, event = Swing.step(state, input)
        local bindings = presentation.controller_bindings
        if hold and bindings then
            bindings.forced = bit.bor(tonumber(bindings.forced) or 0, PRIMARY_MASK)
        end
        api.holding = hold
        if event then
            if event == "heavy" and presentation.haptics and input.side then
                pcall(presentation.haptics.pulse, input.side, "zone", t)
            end
            if event ~= "start" and logged < 200 then
                logged = logged + 1
                mod:info("DARKTIDEVR_MELEE_SWING %s peak=%.2f path=%.2f held=%.3f",
                    event, tonumber(state.peak) or 0, tonumber(state.path) or 0,
                    state.start and t - state.start or 0)
            end
        end
    end

    -- Stock melee aim (option "vr_melee_swing_head_aim", default on). In
    -- missions the base mod sends the HAND's pointing direction as the
    -- character's aim and the wrist's roll as its roll, also for melee: the
    -- character turns with every swing (it seems to walk sideways while you
    -- strike forward) and hits land with a rolled view the stock game never
    -- produces (the base logs them "damage_verified=false"). With a melee
    -- weapon this sends the head's direction, level (roll 0), and leaves the
    -- sweep stock, so melee aims where you look, as in the flat game. The
    -- crosshair is hidden while a melee weapon is wielded. Guns are untouched.
    local function head_aim_wanted()
        if not api.enabled() then return false end
        local setting = mod.get and mod:get("vr_melee_swing_head_aim")
        return setting ~= false
    end
    local function local_unit()
        local player = Managers and Managers.player and Managers.player:local_player(1)
        local unit = player and player.player_unit
        if unit and Unit.alive(unit) then return unit end
    end
    local function melee_head_aim(unit)
        unit = unit or local_unit()
        if not unit or not head_aim_wanted() then return false end
        local ok, melee = pcall(weapon_state, unit)
        return ok and melee == true
    end
    api.melee_head_aim = melee_head_aim
    local function level_head_pose(unit)
        local position, rotation = presentation.eye_pose(unit)
        if not position or not rotation then return nil end
        local forward = Quaternion.forward(rotation)
        local x, y, z = Vector3.x(forward), Vector3.y(forward), Vector3.z(forward)
        if not (x == x and y == y and z == z) or x * x + y * y < 1e-6 then return nil end
        return position, Quaternion.look(forward, Vector3.up())
    end
    local head_aim_logged = 0
    local in_capture = false
    local original_target = presentation.weapon_aim_target
    if original_target then
        presentation.weapon_aim_target = function(role, ...)
            if in_capture and role == "dominant" then
                local unit = local_unit()
                if unit and melee_head_aim(unit) then
                    local ok, position, rotation = pcall(level_head_pose, unit)
                    if ok and position then
                        head_aim_logged = head_aim_logged + 1
                        if head_aim_logged == 1 then
                            mod:info("DARKTIDEVR_MELEE_SWING head_aim=on roll=0 sweep=stock")
                        end
                        return position, rotation
                    end
                end
            end
            return original_target(role, ...)
        end
    end
    local rules = presentation.online_rules
    if rules and rules.capture then
        local original_capture = rules.capture
        rules.capture = function(...)
            in_capture = true
            local ok, err = pcall(original_capture, ...)
            in_capture = false
            if not ok then error(err, 0) end
        end
    end
    local aim = presentation.controller_aim
    if aim and aim.with_melee_aim then
        local original_melee = aim.with_melee_aim
        aim.with_melee_aim = function(action, func, ...)
            if action and melee_head_aim(action._player_unit) and action._player_unit == local_unit() then
                return func(action, ...)
            end
            return original_melee(action, func, ...)
        end
    end
    -- Crosshair: hidden with a melee weapon in hand (with or without head
    -- aim). A stereo cinematic's own
    -- hide request is kept and combined.
    local feedback = presentation.crosshair_feedback
    local cinematic_hidden, melee_hidden = false, false
    if feedback and feedback.set_hidden and feedback.draw then
        local original_hidden, original_draw = feedback.set_hidden, feedback.draw
        feedback.set_hidden = function(value)
            cinematic_hidden = value == true
            original_hidden(cinematic_hidden or melee_hidden)
        end
        feedback.draw = function(...)
            local want = false
            -- Any melee weapon in hand, head aim or not (worn 30 October:
            -- with the hand aiming the dot still showed).
            local ok, result = pcall(function()
                local unit = local_unit()
                return unit ~= nil and api.enabled() and weapon_state(unit) == true
            end)
            if ok then want = result == true end
            if want ~= melee_hidden then
                melee_hidden = want
                original_hidden(cinematic_hidden or melee_hidden)
            end
            if melee_hidden then return end
            return original_draw(...)
        end
    end

    -- Particle recorder (option "vr_melee_swing_particle_log", default on;
    -- diagnostic, 29 October). Missions in VR crash inside the engine's
    -- ParticleSystem (flat is stable). Once a second this logs which effects
    -- Lua created, and it logs at once any effect created at a non-finite or
    -- absurd position, so the last lines before a crash name the candidates.
    -- Wrapped directly, not through DMF: DMF keeps ONE hook per mod and
    -- function whatever its type, and the base mod already hooks
    -- create_particles (worn 29 October: "Attempting to rehook active hook",
    -- nothing recorded). The wrapper calls the current function (DMF's
    -- dispatcher, so the base hook still runs) and returns its results
    -- unchanged; recording happens afterwards inside a pcall.
    local particle_counts, particle_total, particle_since = {}, 0, nil
    local particle_suspicious = 0
    local function particle_log_wanted()
        local setting = mod.get and mod:get("vr_melee_swing_particle_log")
        return setting ~= false
    end
    local function main_time()
        local time = Managers and Managers.time
        return time and time.has_timer and time:has_timer("main") and time:time("main") or nil
    end
    local function flush_particles(now)
        if particle_total > 0 then
            local names = {}
            for name, count in pairs(particle_counts) do names[#names + 1] = {name, count} end
            table.sort(names, function(a, b) return a[2] > b[2] end)
            local parts = {}
            for i = 1, math.min(#names, 8) do
                parts[#parts + 1] = string.format("%s x%d", tostring(names[i][1]), names[i][2])
            end
            mod:info("DARKTIDEVR_PARTICLES 1s total=%d kinds=%d %s", particle_total, #names, table.concat(parts, ", "))
        end
        particle_counts, particle_total, particle_since = {}, 0, now
    end
    local function record_particle(world, name, position)
        if not particle_log_wanted() or presentation.mode ~= 1 then return end
        local now = main_time()
        if not now then return end
        if not particle_since or now < particle_since then particle_since = now end
        local key = type(name) == "string" and name or tostring(name)
        particle_counts[key] = (particle_counts[key] or 0) + 1
        particle_total = particle_total + 1
        if position ~= nil and particle_suspicious < 50 then
            local ok, x, y, z = pcall(function() return Vector3.x(position), Vector3.y(position), Vector3.z(position) end)
            local bad = not ok or not (x == x and y == y and z == z) or
                math.abs(x) > 100000 or math.abs(y) > 100000 or math.abs(z) > 100000
            if bad then
                particle_suspicious = particle_suspicious + 1
                mod:warning("DARKTIDEVR_PARTICLES suspicious name=%s position=%s,%s,%s",
                    key, tostring(x), tostring(y), tostring(z))
            end
        end
        if now - particle_since >= 1 then flush_particles(now) end
    end
    local world_api = rawget(_G, "World")
    if world_api and type(world_api.create_particles) == "function" and
            not world_api.__darktidevr_particle_recorder then
        local inner = world_api.create_particles
        local function pack(...) return {n = select("#", ...), ...} end
        world_api.create_particles = function(world, name, position, ...)
            local result = pack(inner(world, name, position, ...))
            pcall(record_particle, world, name, position)
            return unpack(result, 1, result.n)
        end
        world_api.__darktidevr_particle_recorder = true
        mod:info("DARKTIDEVR_PARTICLES recorder=installed")
    end

    -- Stereo particle fix: once, at load. EXPERIMENTAL, default off (worn 29
    -- October: the snapshot part crashed the DMF options menu at once -- the
    -- "finished reading" counters also guard render-thread data that is not
    -- built yet; the simulate part alone did not stop the mission crash).
    local delay_data, delay_logged_at, delay_last = nil, nil, nil
    local reuse_stats = nil
    if not (mod.get and mod:get("vr_melee_swing_stream_delay") == false) and
            not (mod.get and mod:get("vr_melee_swing_engine_patch_experimental") == true) then
        local ok, result, data = pcall(function()
            local ffi = Mods and Mods.lua and Mods.lua.ffi
            if not ffi then return "no_ffi" end
            for _, decl in ipairs({
                "void* GetModuleHandleA(const char* name);",
                "void* VirtualAlloc(void* address, size_t size, unsigned long type, unsigned long protect);",
                "int VirtualProtect(void* address, size_t size, unsigned long protect, unsigned long* old);",
                "void* GetCurrentProcess(void);",
                "int FlushInstructionCache(void* process, const void* address, size_t size);",
            }) do pcall(ffi.cdef, decl) end
            local ms = tonumber(mod.get and mod:get("vr_melee_swing_stream_delay_ms")) or 50
            return Swing.apply_stream_delay(ffi, ffi.C, ffi.C.GetModuleHandleA(nil), ms)
        end)
        if ok and data ~= nil then delay_data = data end
        mod:info("DARKTIDEVR_STREAM_DELAY %s", ok and tostring(result) or ("error " .. tostring(result)))
        -- Both eyes may now draw from one stream: GPUVisualizer::render must
        -- emit and simulate once per frame.
        if ok and result == "applied" then
            local ok3, result3, stats3 = pcall(function()
                local ffi = Mods.lua.ffi
                return Swing.apply_stereo_reuse(ffi, ffi.C, ffi.C.GetModuleHandleA(nil))
            end)
            if ok3 and stats3 ~= nil then reuse_stats = stats3 end
            if ok3 and result3 == "applied" then presentation.same_frame_reuse_active = true end
            local ok2, result2 = pcall(function()
                local ffi = Mods.lua.ffi
                return Swing.apply_particle_fix(ffi, ffi.C, ffi.C.GetModuleHandleA(nil), true)
            end)
            mod:info("DARKTIDEVR_STREAM_DELAY simulate_once %s", ok2 and tostring(result2) or ("error " .. tostring(result2)))
        end
    end
    api.stereo_sync_report = function(now)
        if not delay_data or type(now) ~= "number" then return end
        if delay_logged_at and now - delay_logged_at < 2 and now >= delay_logged_at then return end
        delay_logged_at = now
        local queued = tonumber(delay_data[3])
        if delay_last and delay_last == queued then return end
        delay_last = queued
        local hc = tonumber(delay_data[1])
        mod:info("DARKTIDEVR_STREAM_DELAY queued=%d late=%d early=%d dropped=%d in_fifo=%d max=%d",
            queued, tonumber(delay_data[4]), tonumber(delay_data[5]), tonumber(delay_data[6]),
            math.floor(hc / 4294967296), tonumber(delay_data[7]))
        if reuse_stats then
            mod:info("DARKTIDEVR_STREAM_DELAY reuse built=%d reused=%d table_full=%d",
                tonumber(reuse_stats[1]), tonumber(reuse_stats[0]), tonumber(reuse_stats[2]))
        end
    end

    if mod.get and mod:get("vr_melee_swing_engine_patch_experimental") == true then
        local ok, result = pcall(function()
            local ffi = Mods and Mods.lua and Mods.lua.ffi
            if not ffi then return "no_ffi" end
            for _, decl in ipairs({
                "void* GetModuleHandleA(const char* name);",
                "void* VirtualAlloc(void* address, size_t size, unsigned long type, unsigned long protect);",
                "int VirtualProtect(void* address, size_t size, unsigned long protect, unsigned long* old);",
                "void* GetCurrentProcess(void);",
                "int FlushInstructionCache(void* process, const void* address, size_t size);",
            }) do pcall(ffi.cdef, decl) end
            return Swing.apply_particle_fix(ffi, ffi.C, ffi.C.GetModuleHandleA(nil))
        end)
        mod:info("DARKTIDEVR_PARTICLE_FIX %s", ok and tostring(result) or ("error " .. tostring(result)))
    else
        mod:info("DARKTIDEVR_PARTICLE_FIX off (option)")
    end

    -- Touch to interact: replaces the base mod's (withdrawn, grip-based)
    -- reach module. The stock interactor's own near-line search runs along
    -- head -> hand, so it still picks the target and checks range, priority
    -- and state; the touched unit becomes its focus (api.find, called from
    -- the base mod's _find_interaction_object hook) and the interact action
    -- is held through bindings.forced while the hand stays on it.
    if mod.get and mod:get("vr_melee_swing_touch") ~= false and presentation.reach_interact then
        local touch = {state = {}, tick = 0, cached = {}, failures = 0}
        local reach = {}
        function reach.enabled() return true end
        local function vector(value)
            if not value then return nil end
            local ok, x, y, z = pcall(Vector3.to_elements, value)
            if not ok or x ~= x then return nil end
            return {x, y, z}
        end
        -- Hand to the unit's bounding box (0 inside), else to its node.
        local function unit_distance(target, node, hand)
            local best_d
            local ok, pose, half = pcall(Unit.box, target)
            local hv = ok and half and vector(half)
            -- A big box (a lift, a whole console wall) would count a hand
            -- anywhere inside it as touching; those use their points only.
            if hv and (math.abs(hv[1]) > Swing.TOUCH_BIG_BOX or math.abs(hv[2]) > Swing.TOUCH_BIG_BOX or
                    math.abs(hv[3]) > Swing.TOUCH_BIG_BOX) then
                ok = false
            end
            if ok and pose and half then
                local c = vector(Matrix4x4.translation(pose))
                local axes = {vector(Matrix4x4.right(pose)), vector(Matrix4x4.forward(pose)), vector(Matrix4x4.up(pose))}
                local h = vector(half)
                if c and h and axes[1] and axes[2] and axes[3] then
                    local d = {hand[1] - c[1], hand[2] - c[2], hand[3] - c[3]}
                    local sum = 0
                    for i = 1, 3 do
                        local a = axes[i]
                        local len = math.sqrt(a[1] ^ 2 + a[2] ^ 2 + a[3] ^ 2)
                        if len > 0 then
                            local l = (d[1] * a[1] + d[2] * a[2] + d[3] * a[3]) / len
                            local over = math.max(math.abs(l) - math.abs(h[i]), 0)
                            sum = sum + over * over
                        end
                    end
                    best_d = math.sqrt(sum)
                end
            end
            local nodes = {node and node > 0 and node or 1}
            local ok_m, has_m = pcall(Unit.has_node, target, "ui_interaction_marker")
            if ok_m and has_m then nodes[#nodes + 1] = Unit.node(target, "ui_interaction_marker") end
            for _, n in ipairs(nodes) do
                local ok2, p = pcall(Unit.world_position, target, n)
                p = ok2 and vector(p)
                if p then
                    local d = math.sqrt((hand[1] - p[1]) ^ 2 + (hand[2] - p[2]) ^ 2 + (hand[3] - p[3]) ^ 2)
                    if not best_d or d < best_d then best_d = d end
                end
            end
            return best_d
        end
        local function search(extension, unit, eye, hand)
            local dx, dy, dz = hand[1] - eye[1], hand[2] - eye[2], hand[3] - eye[3]
            local len = math.sqrt(dx * dx + dy * dy + dz * dz)
            if len < 0.25 then return nil end
            local component = extension._first_person_component
            if not component or not component.position then return nil end
            local target, node = extension:_find_object_near_line_of_sight(unit, component.position,
                Vector3(dx / len, dy / len, dz / len), true)
            if not target or not Unit.alive(target) then return nil end
            local position
            if node and node > 0 then
                local ok, hit = pcall(Unit.world_position, target, node)
                if ok then position = vector(hit) end
            end
            return {unit = target, node = node or 0, position = position or vector(Unit.world_position(target, 1))}
        end
        -- Only a target the game itself would still accept: the stock
        -- search filters used or despawning pickups, a unit named here skips
        -- that search, and the ammunition interaction then indexed a nil
        -- pickup (worn 31 October, crash 6f1ca63b, ammunition_interaction
        -- .lua:126). So: alive, interactee extension present and active, its
        -- own can_interact true, and for pickups the pickup type still set.
        local function still_valid(target, interactor, extension)
            if not target or not Unit.alive(target) then return false end
            local interactee = ScriptUnit.has_extension(target, "interactee_system")
            if not interactee then return false end
            if interactee.active and not interactee:active() then return false end
            local ok_type, kind = pcall(interactee.interaction_type, interactee)
            if not ok_type or kind == nil or kind == "none" then return false end
            if (kind == "ammunition" or kind == "pickup" or kind == "health" or kind == "grenade" or kind == "pocketable") and
                    Unit.get_data(target, "pickup_type") == nil then
                return false
            end
            -- The interactor's own test (interactee and interactor sides).
            if extension and extension._check_valid_interaction_target then
                local ok, can = pcall(extension._check_valid_interaction_target, extension, target)
                return ok and can == true
            end
            local ok, can = pcall(interactee.can_interact, interactee, interactor)
            return ok and can == true
        end
        -- Every interactable near a hand, not just what the head-to-hand
        -- line search finds first (worn 31 October: items inside an opened
        -- chest, door switches and turret buttons were never chosen).
        local function nearby(extension, interactor, hands)
            local manager = Managers and Managers.state and Managers.state.extension
            local system = manager and manager:system("interactee_system")
            local map = system and system._unit_to_extension_map
            if type(map) ~= "table" then return nil end
            local best
            for target, interactee in pairs(map) do
                if Unit.alive(target) and (not interactee.active or interactee:active()) then
                    local ok, root = pcall(Unit.world_position, target, 1)
                    root = ok and vector(root)
                    if root then
                        for hand, position in pairs(hands) do
                            local dx, dy, dz = root[1] - position[1], root[2] - position[2], root[3] - position[3]
                            if dx * dx + dy * dy + dz * dz < Swing.TOUCH_SCAN * Swing.TOUCH_SCAN then
                                local d = unit_distance(target, 0, position)
                                if d and d <= Swing.TOUCH_LEAVE and (not best or d < best.distance) and
                                        still_valid(target, interactor, extension) then
                                    best = {unit = target, node = 0, distance = d, hand = hand}
                                end
                            end
                        end
                    end
                end
            end
            return best
        end
        local function sample(unit, active, t)
            if not active or not unit or not Unit.alive(unit) or type(t) ~= "number" then
                touch.focus, touch.cached = nil, {}
                Swing.touch_step(touch.state, type(t) == "number" and t or 0, nil)
                return
            end
            local extension = ScriptUnit.has_extension(unit, "interactor_system")
            local eye = extension and presentation.eye_pose and vector(presentation.eye_pose(unit))
            if not eye then touch.focus = nil; return end
            touch.tick = (touch.tick + 1) % 3
            local hands, hand_positions = {}, {}
            for _, hand in ipairs({"right", "left"}) do
                local grip = hand == "right" and presentation.controller_grip_target and
                    presentation.controller_grip_target() or
                    (presentation.left_controller_grip_target and presentation.left_controller_grip_target())
                local position = vector(grip)
                if position then hands[hand] = position; hand_positions[#hand_positions + 1] = position end
            end
            -- The scan every third input frame; between, the cached best is
            -- re-measured against the live hand.
            local best = touch.cached.best
            if touch.tick == 0 or not best or not Unit.alive(best.unit) then
                best = nearby(extension, unit, hands)
                touch.cached.best = best
            elseif hands[best.hand] then
                local d = unit_distance(best.unit, best.node, hands[best.hand])
                best = d and {unit = best.unit, node = best.node, distance = d, hand = best.hand} or nil
            end
            local held = touch.state.unit or touch.state.blocked
            local held_distance
            if held and Unit.alive(held) then
                for _, position in pairs(hand_positions) do
                    local d = unit_distance(held, touch.state.node, position)
                    if d and (not held_distance or d < held_distance) then held_distance = d end
                end
            end
            local interacting = false
            if extension.is_interacting then
                local ok, value = pcall(extension.is_interacting, extension)
                interacting = ok and value == true
            end
            local hold, focus, event = Swing.touch_step(touch.state, t, best, held_distance, interacting)
            if event == "press" then touch.state.node = best.node end
            if focus then
                touch.focus = {unit = focus, node = (hold and touch.state.node) or (best and best.node) or 0, interactor = unit}
            else
                touch.focus = nil
            end
            if hold then
                local bindings = presentation.controller_bindings
                if bindings then bindings.forced = bit.bor(tonumber(bindings.forced) or 0, 8) end
            end
            if event == "press" then
                mod:info("DARKTIDEVR_TOUCH press hand=%s distance_m=%.2f", best.hand, best.distance)
                if presentation.haptics then pcall(presentation.haptics.pulse, best.hand, "zone", t) end
            elseif event then
                mod:info("DARKTIDEVR_TOUCH %s held=%.2fs", event, t - (touch.state.since or t))
            end
        end
        function reach.sample(unit, active, t, support_request)
            local ok, err = pcall(sample, unit, active, t)
            if not ok then
                touch.focus = nil
                touch.failures = touch.failures + 1
                if touch.failures <= 3 then mod:warning("DARKTIDEVR_TOUCH error=%s", tostring(err):sub(1, 160)) end
            end
            return support_request
        end
        function reach.find(extension, unit, chosen)
            local f = touch.focus
            if f and f.interactor == unit and f.unit ~= chosen then
                local ok, valid = pcall(still_valid, f.unit, unit, extension)
                if ok and valid then return f.unit, f.node end
                touch.focus = nil
            end
            return chosen
        end
        function reach.destroy() touch.state, touch.focus, touch.cached = {}, nil, {} end
        presentation.reach_interact = reach
        mod:info("DARKTIDEVR_MELEE_SWING touch_interact on radius=%.2f dwell=%.2f", Swing.TOUCH_RADIUS, Swing.TOUCH_DWELL)
    end

    -- Teammate names: the stock mission nameplate ("nameplate_party") is
    -- drawn transparent, through the base mod's own hook on its template.
    if mod.get and mod:get("vr_melee_swing_hide_names") ~= false and presentation.teammate_status and
            type(presentation.teammate_status.hides_stock_nameplate) == "function" then
        local stock = presentation.teammate_status.hides_stock_nameplate
        presentation.teammate_status.hides_stock_nameplate = function() return true end
        api.restore_nameplates = stock
        mod:info("DARKTIDEVR_MELEE_SWING teammate_names hidden")
    end

    function api.destroy() state = Swing.new() end
    return api
end

return Swing
