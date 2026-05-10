local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

--- @module "core.player_utils"
local player_utils = dofile_once(core_path .. "player_utils.lua")

--- @module "core.profile_timer"
local ProfileTimer = dofile_once(core_path .. "profile_timer.lua")

--- @module "core.wand_utils"
local wand_utils = dofile_once(core_path .. "wand_utils.lua")

--- @module "core.math_utils"
local umath = dofile_once(core_path .. "math_utils.lua")

--- @module "core.logger"
local logger = dofile_once(core_path .. "logger.lua")

--- @module "core.wand_attributes"
local WandAttribs = dofile_once(core_path .. "wand_attributes.lua")

--- @class wand_tinker_tool
local M = {
    name = "Wand Tinker",
    is_open = false
}


local TIME_UNIT_OPTS = {
    "frames", "in game seconds"
}

local time_unit_used = "frames"

local wnd_attribs = WandAttribs.new_default()

local should_limit_to_valid_values = true


function M.render_window(imgui, wndbx_state)
    -- local wand_picked_changed, picked_wand_idx = imgui.InputInt(
    --     "##PickedWandIdx", picked_wand_idx
    -- )
    --
    -- imgui.BulletText(
    --     string.format("Picked wand [%d]", picked_wand_idx)
    -- )

    -- TODO: link this with the wand picker above
    local picked_player_id = player_utils.get_first_player_id()
    local picked_wand_id = wand_utils.get_held_wand_id(
        picked_player_id
    )


    if picked_wand_id == nil then
        imgui.Text(
            "Cannot find the specified wand"
        )

        imgui.BulletText("Did you pick the right player?(Picking of players coming soon :D)")
        imgui.BulletText("Is the player currently holding a wand?")
        return
    end

    imgui.BulletText(
        string.format("Applies on held wand of id: %d", picked_wand_id)
    )

    if imgui.BeginCombo("Use time unit", time_unit_used) then
        for _, value in ipairs(TIME_UNIT_OPTS) do
            if imgui.Selectable(value, value == time_unit_used) then
                time_unit_used = value
            end
        end

        imgui.EndCombo()
    end

    local function frames_to_secs(f)
        return f * (1.0 / 60.0)
    end

    local function secs_to_frames_floored(s)
        local frames_frac = s * (60.0 / 1.0)

        return math.floor(frames_frac)
    end

    local should_limit_to_valid_values_changed
    should_limit_to_valid_values_changed, should_limit_to_valid_values = imgui.Checkbox(
        "Limit Values in Valid Range", should_limit_to_valid_values
    )

    if imgui.CollapsingHeader("UI & HUD") then
        local _

        _, wnd_attribs.item_name = imgui.InputText(
            "Wand Name", wnd_attribs.item_name
        )

        _, wnd_attribs.always_use_item_name_in_ui = imgui.Checkbox(
            "Always show wand name in UI", wnd_attribs.always_use_item_name_in_ui
        )

    end


    if imgui.CollapsingHeader("Delays") then

        if time_unit_used == "frames" then
            local cd_frames_changed
            cd_frames_changed, wnd_attribs.cd_frames = imgui.InputInt(
                "Cast Delay(Frames)", wnd_attribs.cd_frames
            )

            local rt_frames_changed
            rt_frames_changed, wnd_attribs.rt_frames = imgui.InputInt(
                "Recharge Time(Frames)", wnd_attribs.rt_frames
            )

        elseif time_unit_used == "in game seconds" then
            local cd_secs_changed, cd_secs = imgui.InputFloat(
                "Cast Delay(Seconds)", frames_to_secs(wnd_attribs.cd_frames)
            )

            wnd_attribs.cd_frames = secs_to_frames_floored(cd_secs)

            local rt_secs_changed, rt_secs = imgui.InputFloat(
                "recharge time(seconds)", frames_to_secs(wnd_attribs.rt_frames)
            )

            wnd_attribs.rt_frames = secs_to_frames_floored(rt_secs)
        end
    end


    if imgui.CollapsingHeader("Mana") then
        local mana_max_changed
        mana_max_changed, wnd_attribs.mana_max = imgui.InputInt(
            "Max Mana", wnd_attribs.mana_max
        )


        if time_unit_used == "in game seconds" then
            local mana_chrg_spd_secs_changed
            mana_chrg_spd_secs_changed, wnd_attribs.mana_chrg_spd_secs = imgui.InputInt(
                "Mana Charge Speed(Mana / Second)", wnd_attribs.mana_chrg_spd_secs
            )

        elseif time_unit_used == "frames" then
            local mana_chrg_spd_secs_changed, mana_chrg_spd_frame = imgui.InputInt(
                "Mana Charge Speed(Mana / Frame)",
                secs_to_frames_floored(wnd_attribs.mana_chrg_spd_secs)
            )

            wnd_attribs.mana_chrg_spd_secs = frames_to_secs(mana_chrg_spd_frame)
        end

    end

    if imgui.CollapsingHeader("Spells") then
        local should_shuffle_changed
        should_shuffle_changed, wnd_attribs.should_shuffle = imgui.Checkbox(
            "Should Shuffle", wnd_attribs.should_shuffle
        )

        local spells_per_cast_changed
        spells_per_cast_changed, wnd_attribs.spells_per_cast = imgui.InputInt(
            "Spells per Cast", wnd_attribs.spells_per_cast
        )

        local capacity_changed
        capacity_changed, wnd_attribs.deck_capacity = imgui.InputInt(
            "Capacity", wnd_attribs.deck_capacity
        )

        local spread_degrees_changed
        -- TODO: allow radians :)

        spread_degrees_changed, wnd_attribs.spread_degrees = imgui.InputFloat(
            "Spread(degrees)", wnd_attribs.spread_degrees
        )

        local proj_spd_multiplier_changed
        proj_spd_multiplier_changed, wnd_attribs.proj_spd_multiplier = imgui.InputFloat(
            "Projectile Speed Multiplier", wnd_attribs.proj_spd_multiplier
        )
    end


    -- limit to valid ranges
    if should_limit_to_valid_values then
        wnd_attribs.mana_max = math.max(wnd_attribs.mana_max, 0)
        wnd_attribs.mana_chrg_spd_secs = math.max(wnd_attribs.mana_chrg_spd_secs, 0)

        wnd_attribs.deck_capacity = math.max(wnd_attribs.deck_capacity, 1)
        wnd_attribs.spells_per_cast = math.max(wnd_attribs.spells_per_cast, 0)
    end




    -- Application of attributes
    if imgui.Button("Copy wand attributes") then
        wnd_attribs = WandAttribs.from_wand_entity(picked_wand_id)

        logger.log_info("Copied picked wand's attributes")
    end

    imgui.SameLine()
    if imgui.Button("Update on Wand") then
        wnd_attribs:apply_to(picked_wand_id)
        logger.log_info("updated picked wand")

        wand_utils.force_refresh_all_wands_on_player(picked_player_id)
        logger.log_info("refreshed wands for player")
    end

    imgui.SameLine()
    if imgui.Button("Spawn Wand at Player") then
        local x, y = EntityGetTransform(picked_player_id)

        local wand_id = wand_utils.spawn_default_wand_at(x, y)
        logger.log_info("Wand Spawned at player")

        wnd_attribs:apply_to(wand_id)
        logger.log_info("Wand attributes applied")
    end


    -- Preset loading
    if imgui.Button("Load Preset") then
        logger.log_info("Not yet done! Coming soon :)")
    end

    imgui.SameLine()
    if imgui.Button("Save Preset") then
        logger.log_info("Not yet done! Coming soon :)")
    end
end


return M
