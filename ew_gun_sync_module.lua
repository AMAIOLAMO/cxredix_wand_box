-- appended as an extra module for entangled worlds
local M = {}

local ew_api = dofile_once("mods/quant.ew/files/api/ew_api.lua")

local cx_deck_sync = dofile_once("mods/cxredix_wand_box/core/cx_deck_sync.lua")

dofile_once("mods/cxredix_wand_box/core/wand_utils.lua")

local rpc = ew_api.new_rpc_namespace("cxredix_wndbx")

rpc.opts_reliable()
-- no need to call on self, as we sync the deck action locally already, we just need
-- to notify all other peers to load the deck in their world
-- rpc.opts_everywhere()

function rpc.sync_current_player_deck_actions(actions_str)
    local rpc_caller_player_data = ew_api.rpc_player_data()

    if rpc_caller_player_data ~= nil then
        local player_id = ew_api.rpc_player_data().entity
        GamePrint("Received sync from peer")

        GamePrint(
            string.format("received action string character count: %d", #actions_str)
        )

        GamePrint("Syncing deck...")

        held_wand_deck_direct_sync(player_id, actions_str)

        GamePrint("Deck synced!")
    else
        GamePrint(
            "Received rpc sync deck actions, but the player entity from caller is nil"
        )
    end
end

util.add_cross_call("cx_wndbx_current_player_sync_actions", function(actions_str)
    rpc.sync_current_player_deck_actions(actions_str)
end)



return M
