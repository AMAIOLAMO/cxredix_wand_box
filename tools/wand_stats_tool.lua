local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

--- @module "core.cx_deck_sync"
local cx_deck_sync = dofile_once(core_path .. "cx_deck_sync.lua")

--- @module "core.cx_action_parse_utils"
local cx_parser = dofile_once(core_path .. "cx_action_parse_utils.lua")

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

local M = {
    name = "Wand Stats",
    is_open = false
}

    
local TIME_UNIT_OPTS = {
    "frames", "in game seconds"
}

local time_unit_used = "frames"

local should_shuffle = false

local cd_frames = 10
local rt_frames = 10

local spells_per_cast = 1

local mana_max = 100
local mana_chrg_spd_secs = 100

local capacity = 26
local spread_degrees = 0

local picked_wand_idx = 1

function M.update_wand_stats(wand_id)
    wand_utils.wand_set_deck_cap(wand_id, capacity)

    wand_utils.wand_set_mana_max(wand_id, mana_max)
    wand_utils.wand_set_mana_charge_speed(wand_id, mana_chrg_spd_secs)

    wand_utils.wand_set_recharge_time_frames(wand_id, rt_frames)
    wand_utils.wand_set_cast_delay_frames(wand_id, cd_frames)

    wand_utils.wand_set_spread_degrees(wand_id, spread_degrees)

    wand_utils.wand_set_spells_per_cast(wand_id, spells_per_cast)
    wand_utils.wand_set_should_shuffle(wand_id, should_shuffle)
end


function M.render_window(imgui, wndbx_state)
    -- local wand_picked_changed, picked_wand_idx = imgui.InputInt(
    --     "##PickedWandIdx", picked_wand_idx
    -- )
    --
    -- imgui.BulletText(
    --     string.format("Picked wand [%d]", picked_wand_idx)
    -- )

    -- TODO: link this with the wand picker above
    local picked_wand_id = wand_utils.get_held_wand_id(
        player_utils.get_first_player_id()
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

    if imgui.CollapsingHeader("Delays") then

        if time_unit_used == "frames" then
            local cd_frames_changed
            cd_frames_changed, cd_frames = imgui.InputInt(
                "Cast Delay(Frames)", cd_frames
            )

            local rt_frames_changed
            rt_frames_changed, rt_frames = imgui.InputInt(
                "Recharge Time(Frames)", rt_frames
            )

        elseif time_unit_used == "in game seconds" then
            local cd_secs_changed, cd_secs = imgui.InputFloat(
                "Cast Delay(Seconds)", frames_to_secs(cd_frames)
            )

            cd_frames = secs_to_frames_floored(cd_secs)

            local rt_secs_changed, rt_secs = imgui.InputFloat(
                "recharge time(seconds)", frames_to_secs(rt_frames)
            )

            rt_frames = secs_to_frames_floored(rt_secs)
        end
    end


    if imgui.CollapsingHeader("Mana") then
        local mana_max_changed
        mana_max_changed, mana_max = imgui.InputInt(
            "Max Mana", mana_max
        )

        if time_unit_used == "in game seconds" then
            local mana_chrg_spd_secs_changed
            mana_chrg_spd_secs_changed, mana_chrg_spd_secs = imgui.InputInt(
                "Mana Charge Speed(Mana / Second)", mana_chrg_spd_secs
            )
        elseif time_unit_used == "frames" then
            local mana_chrg_spd_secs_changed, mana_chrg_spd_frame = imgui.InputInt(
                "Mana Charge Speed(Mana / Frame)",
                secs_to_frames_floored(mana_chrg_spd_secs)
            )

            mana_chrg_spd_secs = frames_to_secs(mana_chrg_spd_frame)
        end
    end

    if imgui.CollapsingHeader("Spells") then
        local should_shuffle_changed
        should_shuffle_changed, should_shuffle = imgui.Checkbox(
            "Should Shuffle", should_shuffle
        )

        local spells_per_cast_changed
        spells_per_cast_changed, spells_per_cast = imgui.InputInt(
            "Spells per Cast", spells_per_cast
        )

        local capacity_changed
        capacity_changed, capacity = imgui.InputInt(
            "Capacity", capacity
        )
        -- TODO: make it a checkbox option to force clamping
        capacity = math.max(capacity, 0)


        local spread_degrees_changed
        -- TODO: allow radians :)

        spread_degrees_changed, spread_degrees = imgui.InputFloat(
            "Spread(degrees)", spread_degrees
        )
    end





    -- Application of stats
    if imgui.Button("Copy wand stats") then
        logger.log_info("Not yet done! Coming soon :)")
    end

    imgui.SameLine()
    if imgui.Button("Update on Wand") then
        M.update_wand_stats(picked_wand_id)
        logger.log_info("picked wand updated")
    end

    imgui.SameLine()
    if imgui.Button("Spawn Wand at Player") then
        logger.log_info("Not yet done! Coming soon :)")
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
