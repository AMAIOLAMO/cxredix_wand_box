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

dofile_once(core_path .. "logger.lua")

local M = {
    name = "Wand Stats",
    is_open = false
}

function M.render_window(imgui, wndbx_state)
    imgui.Text("Here is wand stats :)")
end


return M
