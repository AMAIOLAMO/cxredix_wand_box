dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")

local root_path = "mods/cxredix_wand_box/"

local cx_deck_sync = dofile_once(root_path .. "cx_deck_sync.lua")
dofile_once(root_path .. "cx_action_parse_utils.lua")

-- @module profile_timer
local ProfileTimer = dofile_once(root_path .. "profile_timer.lua")

-- @module wand_utils
dofile_once(root_path .. "wand_utils.lua")

ModLuaFileAppend("data/scripts/gun/gun.lua", root_path .. "gun_deck_handler.lua")


function get_players()
    return EntityGetWithTag("player_unit")
end

function get_total_player_count()
    return #get_players()
end

function get_player(idx)
    return EntityGetWithTag("player_unit")[idx]
end

function lerpf(a, b, t)
    return a + (b - a) * t
end

function clampi(v, min_val, max_val)
    assert(
        min_val <= max_val,
        string.format(
            "minimum value %d cannot be bigger than maximum value %d", min_val, max_val
        )
    )
    return math.max(math.min(v, max_val), min_val)
end

function OnWorldInitialized()
    -- clear any previous un-synced actions
    cx_deck_sync.consume_sync()
    cx_deck_sync.clear_sync_complete_flag()
end

-- use imgui when the function exists
if load_imgui ~= nil then
    function wand_loader_log_info(msg)
        GamePrint("[Wand Loader]" .. msg)
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

    -- function imgui_input_int_clamped(id, value, max, min)
    --
    -- end


    local load_wand_timer = ProfileTimer.new()

    local actions_input_str = ""
    local prev_action_count = -1
    local picked_player_idx = 1

    function OnWorldPostUpdate()
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

        local settings_wand_loader_open = ModSettingGet("cxredix_wand_box.enable_wand_loader")
        local new_wand_loader_open = settings_wand_loader_open

        if imgui.Begin("Main Window Menu", nil, window_flags) then

            if imgui.BeginMenuBar() then
                if imgui.BeginMenu("CxRedix's Wand Box") then

                    local _
                    _, new_wand_loader_open = imgui.MenuItem("Wand Loader", "", settings_wand_loader_open)

                    if new_wand_loader_open ~= settings_wand_loader_open then
                        ModSettingSetNextValue(
                            "cxredix_wand_box.enable_wand_loader", new_wand_loader_open, false
                        )
                    end

                    imgui.EndMenu()
                end

                imgui.EndMenuBar()
            end
        end

        if new_wand_loader_open and imgui.Begin("Wand Loader") then
            render_wand_loader_window()
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

        imgui.Text(
            string.format("Pick player [%d total]: ", get_total_player_count())
        )
        imgui.SameLine()

        _, picked_player_idx = imgui.InputInt("##PickedPlayerIdx", picked_player_idx)

        picked_player_idx = clampi(picked_player_idx, 1, get_total_player_count())

        if actions_input_str ~= '' and imgui.Button("Direct sync to wand") then
            begin_wand_direct_sync(actions_input_str)
        end

        imgui.SameLine()
        if actions_input_str ~= '' and imgui.Button("Load on held wand") then
            begin_held_wand_load(actions_input_str)
        end

        imgui.SameLine()
        if actions_input_str ~= '' and imgui_cautious_btn("Clear") then
            actions_input_str = ''
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

    function begin_wand_direct_sync(action_str)
        local held_wand_id = get_held_wand_id(get_player(picked_player_idx))

        if held_wand_id ~= nil then
            wand_loader_log_info("Trying to sync")

            load_wand_timer:clear()
            load_wand_timer:begin_append()

            -- we need to add 1 dummy spell if the wand is empty,
            -- this is due to the fact that if the wand has 0 card actions
            -- as entities in the game, refreshing the wand will not happen.


            wand_clear_all_actions(held_wand_id)
            wand_append_action_str(held_wand_id, "MANA_REDUCE")


            cx_deck_sync.set_sync_actions(action_str)

            -- TODO: instead of parsing it, we simply let the wand parse utils to be able to parse
            -- count. counting the number of , then returning the amount of spells :) + 1 (there is an issue)
            -- where it might assume ",," as 1 spell, but that's trivial for now
            local action_ids = cx_parse_wndbx_fmt_to_action_ids(action_str)

            prev_action_count = #action_ids

            wand_loader_log_info("Sync Notified, forcing wand refresh...")

            all_wand_force_refresh(get_player(picked_player_idx))

            wand_loader_log_info("Wand refresh complete :)")
        else
            wand_loader_log_info("Player is not holding a wand to directly sync to")
        end
    end

    function begin_held_wand_load(action_str)
        local held_wand = get_held_wand_id(get_player(picked_player_idx))

        if held_wand ~= nil then
            wand_loader_log_info("Loading held wand")

            load_wand_timer:clear()
            load_wand_timer:begin_append()

            wand_clear_all_actions(held_wand)

            prev_action_count = wand_append_action_str(held_wand, action_str)

            all_wand_force_refresh(get_player(picked_player_idx))

            load_wand_timer:end_append()

            wand_loader_log_info(
                "Wand Load complete, it took: " ..
                tostring(load_wand_timer:get_total_secs())
            )
        else
            wand_loader_log_info("Player is not holding a wand, load fail")
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

