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

local cd_frames = 10
local rt_frames = 10

local mana_max = 100
local mana_charge_speed = 100

local picked_wand_idx = 1


function M.render_window(imgui, wndbx_state)

    local wand_picked_changed, picked_wand_idx = imgui.InputInt(
        "##PickedWandIdx", picked_wand_idx
    )

    imgui.BulletText(
        string.format("Picked wand [%d]", picked_wand_idx)
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
            "Recharge Time(Seconds)", frames_to_secs(rt_frames)
        )

        rt_frames = secs_to_frames_floored(rt_secs)
    end


    local mana_max_changed
    mana_max_changed, mana_max = imgui.InputInt(
        "Max Mana", mana_max
    )

    local mana_charge_speed_changed
    mana_charge_speed_changed, mana_charge_speed = imgui.InputInt(
        "Mana Charge Speed", mana_charge_speed
    )

    -- Application of stats
    if imgui.Button("Copy wand stats") then

    end

    imgui.SameLine()
    if imgui.Button("Update on Wand") then

    end

    imgui.SameLine()
    if imgui.Button("Spawn Wand at Player") then

    end


    -- Preset loading
    if imgui.Button("Load Preset") then
    end

    imgui.SameLine()
    if imgui.Button("Save Preset") then
    end
end


return M
