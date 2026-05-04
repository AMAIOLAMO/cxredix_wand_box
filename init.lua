dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")

local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

-- @module core.cx_deck_sync
local cx_deck_sync = dofile_once(core_path .. "cx_deck_sync.lua")

-- @module core.cx_action_parse_utils
dofile_once(core_path .. "cx_action_parse_utils.lua")

-- @module core.player_utils
dofile_once(core_path .. "player_utils.lua")

-- @module core.profile_timer
local ProfileTimer = dofile_once(core_path .. "profile_timer.lua")

-- @module core.wand_utils
dofile_once(core_path .. "wand_utils.lua")

-- @module core.math_utils
local umath = dofile_once(core_path .. "math_utils.lua")

-- @module "tools.wand_helper_tool"
local wand_helper_tool = dofile_once(tools_path .. "wand_helper_tool.lua")

ModLuaFileAppend("data/scripts/gun/gun.lua", core_path .. "gun_deck_handler.lua")

if ModIsEnabled("quant.ew") then
    ModLuaFileAppend(
        "mods/quant.ew/files/api/extra_modules.lua",
        root_path .. "ew_gun_sync_module.lua"
    )
end


local player_pick_marker_id = nil
local player_pick_marker_sprite_id = nil

function OnWorldInitialized()
    -- clear any previous un-synced actions
    cx_deck_sync.consume_sync()
    cx_deck_sync.clear_sync_complete_flag()

    player_pick_marker_id = EntityLoad(root_path .. "vendor/entities/player_marker.xml")

    player_pick_marker_sprite_id = EntityGetFirstComponentIncludingDisabled(
        player_pick_marker_id, "SpriteComponent"
    )

    ComponentSetValue2(player_pick_marker_sprite_id, "alpha", 0)
end

-- use imgui when the function exists
if load_imgui ~= nil then
    function wndbx_log_info(msg)
        GamePrint("[Wand Box]" .. msg)
    end

    local imgui = load_imgui({version="1.21.0", mod="CxRedixWandBox"})

    function imgui_cautious_btn(id)
        imgui.PushStyleColor(imgui.Col.Button, 0.8, 0.45, 0.45)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, 1, 0.6, 0.6)
        imgui.PushStyleColor(imgui.Col.ButtonActive, 0.7, 0.45, 0.45)

        local ret_value = imgui.Button(id)

        imgui.PopStyleColor(3)

        return ret_value
    end


    local load_wand_timer = ProfileTimer.new()

    local wndbx_state = {
        picked_player_idx = 1
    }

    local actions_input_str = ""
    local prev_action_count = -1
    -- local picked_player_idx = 1
    local picked_player_marker_fade_wait_timer = 0

    local prev_frame_real_world_time = GameGetRealWorldTimeSinceStarted()
    local dt_secs = 0

    local wnd_loader_open = true
    -- local wnd_helper_open  = true

    function OnWorldPostUpdate()
        dt_secs = GameGetRealWorldTimeSinceStarted() - prev_frame_real_world_time
        prev_frame_real_world_time = GameGetRealWorldTimeSinceStarted()

        imgui.SetNextWindowSize(800, 400, imgui.Cond.Once)

        if cx_deck_sync.is_sync_complete_flag_marked() then
            cx_deck_sync.clear_sync_complete_flag()

            load_wand_timer:end_append()
        end

        local window_flags = bit.bor(
            imgui.WindowFlags.MenuBar,
            imgui.WindowFlags.NoDocking,
            imgui.WindowFlags.NoSavedSettings,
            imgui.WindowFlags.NoFocusOnAppearing,
            imgui.WindowFlags.NoMove,
            imgui.WindowFlags.NoDecoration,
            imgui.WindowFlags.NoBackground
        )

        local menu_height = imgui.GetFontSize() + 2 * imgui.GetStyle().FramePadding_y

        local vp_width, vp_height = imgui.GetMainViewportSize()

        local vp_work_x, vp_work_y = imgui.GetMainViewportWorkPos()

        local y_padding = 2.5

        local CHAR_WIDTH = 7

        local half_text_width = CHAR_WIDTH * ("CxRedix's Wand Box"):len() * 0.5

        imgui.SetNextWindowViewport(imgui.GetMainViewportID())
        imgui.SetNextWindowPos(
            vp_work_x + vp_width * 0.5 - half_text_width,
            vp_work_y + vp_height - menu_height - y_padding
        )
        imgui.SetNextWindowSize(0, 0)

        if imgui.Begin("Main Window Menu", nil, window_flags) then

            if imgui.BeginMenuBar() then
                if imgui.BeginMenu("CxRedix's Wand Box") then

                    local _
                    _, wnd_loader_open = imgui.MenuItem("Wand Loader", "", wnd_loader_open)

                    _, wand_helper_tool.is_open = imgui.MenuItem(
                        wand_helper_tool.name, "", wand_helper_tool.is_open
                    )

                    imgui.EndMenu()
                end

                imgui.EndMenuBar()
            end
        end

        local _
        _, wnd_loader_open = imgui.Begin("Wand Loader", wnd_loader_open)

        if wnd_loader_open then
            render_wand_loader_window()
        end

        _, wand_helper_tool.is_open = imgui.Begin(
            wand_helper_tool.name, wand_helper_tool.is_open
        )

        if wand_helper_tool.is_open then
            wand_helper_tool.render_window(imgui, wndbx_state)
        end


        -- render marker on player
        local picked_player_id = get_player_id(wndbx_state.picked_player_idx)

        if player_pick_marker_id ~= nil and picked_player_id ~= nil then
            local px, py = EntityGetTransform(picked_player_id)

            local PLAYER_HEAD_MARKER_Y_OFFSET = 20

            local ANIMATION_SPEED = 3

            local AMPLITUDE = 3

            local mx, my = EntityGetTransform(player_pick_marker_id)
    
            -- target position
            local tx = px
            local ty = py - PLAYER_HEAD_MARKER_Y_OFFSET +
                math.sin(GameGetRealWorldTimeSinceStarted() * ANIMATION_SPEED) *
                AMPLITUDE

            local LERP_SPEED = 5

            -- lerping tweening animation hehe :D
            mx = umath.lerpf(mx, tx, dt_secs * LERP_SPEED)
            my = umath.lerpf(my, ty, dt_secs * LERP_SPEED)

            local alpha = ComponentGetValue2(player_pick_marker_sprite_id, "alpha")

            local FADE_SPEED = 3

            if picked_player_marker_fade_wait_timer <= 0 then
                ComponentSetValue2(
                    player_pick_marker_sprite_id,
                    "alpha",
                    umath.lerpf(alpha, 0, dt_secs * FADE_SPEED)
                )
            else
                picked_player_marker_fade_wait_timer =
                    picked_player_marker_fade_wait_timer - dt_secs
            end

            EntitySetTransform(
                player_pick_marker_id,
                mx, my
            )
        end
    end

    function render_wand_loader_window()
        local animated_str = ""
        local animated_char_count = 45

        local sin_value = animated_char_count * (math.sin(GameGetRealWorldTimeSinceStarted() * 1.3) * 0.5 + 0.5)

        -- rounding and shift by 1
        sin_value = math.floor(sin_value + 0.5) + 1

        for i = 1, animated_char_count do
            if i == sin_value then
                animated_str = animated_str .. "^"
            end

            animated_str = animated_str .. "."
        end

        imgui.Text("Put your wand string below " .. animated_str)

        _, actions_input_str = imgui.InputTextMultiline(
            "##Input", actions_input_str,
            -5 * 3, 5 * 50, -- hardcoded size and line height
            imgui.InputTextFlags.EnterReturnsTrue
        )

        -- player picker, only shows up if there are more than 1 player
        -- (are there any edge cases??)
        if get_total_player_count() > 1 then
            imgui.Text(
                string.format("Pick player [%d total]: ", get_total_player_count())
            )
            imgui.SameLine()

            local old_picked_player_idx = wndbx_state.picked_player_idx

            _, wndbx_state.picked_player_idx = imgui.InputInt(
                "##PickedPlayerIdx", wndbx_state.picked_player_idx
            )

            wndbx_state.picked_player_idx = umath.clampi(
                wndbx_state.picked_player_idx, 1, get_total_player_count()
            )

            if old_picked_player_idx ~= wndbx_state.picked_player_idx then
                ComponentSetValue2(
                    player_pick_marker_sprite_id,
                    "alpha",
                    1
                )
                picked_player_marker_fade_wait_timer = 5
            end
        end

        if actions_input_str ~= '' then
            if imgui.Button("Direct sync to wand") then
                local player_id = get_player_id(wndbx_state.picked_player_idx)

                begin_wand_direct_sync(
                    player_id, actions_input_str
                )

                if ModIsEnabled("quant.ew") then
                    wndbx_log_info("Found Entangled Worlds, syncing wand to peers...")
                    -- this should call ONLY on peers, does not include the caller
                    CrossCall("cx_wndbx_current_player_sync_actions", actions_input_str)
                else
                end
            end

            imgui.SameLine()
            if imgui.Button("Load on held wand") then
                begin_held_wand_load(actions_input_str)
            end

            imgui.SameLine()
            if imgui_cautious_btn("Clear") then
                actions_input_str = ''
            end
        end


        -- METRICS --
        local should_render_wand_timer = load_wand_timer:get_total_secs() > 0
        local should_render_action_count = prev_action_count > 0

        local should_render_metrics = should_render_action_count or should_render_action_count

        if should_render_metrics then
            imgui.Separator()

            if imgui.TreeNode("Wand Load Metrics") then

                -- Yes the if checks happens twice, but this is more structured :)
                if should_render_wand_timer then
                    imgui.Bullet()

                    imgui.Text(string.format(
                        "Loaded in %.4f seconds", load_wand_timer:get_total_secs()
                    ))
                end

                if should_render_action_count then
                    imgui.Bullet()

                    imgui.Text(string.format(
                        "Loaded %d spell actions", prev_action_count)
                    )
                end

                imgui.TreePop()
            end
        end

        imgui.End()
    end

    function begin_wand_direct_sync(player_id, actions_str)
        local held_wand_id = get_held_wand_id(player_id)

        if held_wand_id ~= nil then
            wndbx_log_info("Trying to sync")

            load_wand_timer:clear()
            load_wand_timer:begin_append()
            held_wand_deck_direct_sync(player_id, actions_str)

            -- TODO: instead of parsing it, we simply let the wand parse utils to be able to parse
            -- count. counting the number of , then returning the amount of spells :) + 1 (there is an issue)
            -- where it might assume ",," as 1 spell, but that's trivial for now
            local action_ids = cx_parse_wndbx_fmt_to_action_ids(actions_str)

            prev_action_count = #action_ids

            wndbx_log_info("Sync Notified, Wand refresh complete.")
        else
            wndbx_log_info("Player is not holding a wand to directly sync to")
        end
    end

    function begin_held_wand_load(action_str)
        local held_wand = get_held_wand_id(get_player_id(wndbx_state.picked_player_idx))

        if held_wand ~= nil then
            wndbx_log_info("Loading held wand")

            load_wand_timer:clear()
            load_wand_timer:begin_append()

            wand_clear_all_actions(held_wand)

            prev_action_count = wand_append_action_str(held_wand, action_str)

            force_refresh_all_wands_on_player(
                get_player_id(wndbx_state.picked_player_idx)
            )

            load_wand_timer:end_append()

            wndbx_log_info(
                "Wand Load complete, it took: " ..
                tostring(load_wand_timer:get_total_secs())
            )
        else
            wndbx_log_info("Player is not holding a wand, load fail")
        end
    end
else

    local warn_notify_interval_frames = 60 * 4 -- every 4 seconds

    local warn_frames = 0

    function OnWorldPostUpdate()
        if warn_frames <= 0 then
            GamePrint("[Wand Box] Cannot find Noita Dear Imgui, It is either you didn't install it")
            GamePrint("[Wand Box] Or that you didn't put Wand Box mod below Noita Dear Imgui in the mod list :3")
            warn_frames = warn_notify_interval_frames
        end

        warn_frames = warn_frames - 1
    end
end

