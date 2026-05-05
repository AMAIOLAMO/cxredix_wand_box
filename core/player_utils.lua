--- @class player_utils
local M = {}

function M.get_player_ids()
    return EntityGetWithTag("player_unit")
end

function M.get_total_player_count()
    return #M.get_player_ids()
end

function M.get_player_id(idx)
    return EntityGetWithTag("player_unit")[idx]
end

function M.get_first_player_id()
    return M.get_player_id(1)
end

return M
