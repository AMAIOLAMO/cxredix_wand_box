-- appended as an extra module for entangled worlds
local M = {}

local ew_api = dofile_once("mods/quant.ew/files/api/ew_api.lua")

local cx_deck_sync = dofile_once("mods/cxredix_wand_box/cx_deck_sync.lua")

dofile_once("mods/cxredix_wand_box/wand_utils.lua")

local rpc = ew_api.new_rpc_namespace("cxredix_wndbx")

rpc.opts_reliable()
-- no need to call on self, as we sync the deck action locally already, we just need
-- to notify all other peers to load the deck in their world
-- rpc.opts_everywhere()

function rpc.sync_deck_actions(peer_id, action_str)
    local player_id = ctx.players[peer_id].entity

    if player_id ~= nil then
        GamePrint(
            string.format("Received sync from peer, calling from peer id: %d", peer_id)
        )

        GamePrint(
            string.format("received action string character count: %d", #action_str)
        )

        GamePrint("Updating deck...")
        cx_deck_sync.set_sync_actions(action_str)
        GamePrint("Deck updated!")

        GamePrint("Forcing wand refresh on peer player...")

        force_refresh_all_wands_on_player(player_id)

        GamePrint("Refresh complete on peer player")
    else
        GamePrint(
            string.format(
                "Received rpc sync deck actions, but the player entity for peer_id %d is nil!",
                peer_id
            )
        )
    end
end

util.add_cross_call("cx_wndbx_sync_actions", function(entity_id, action_str)
    GamePrint(
        string.format(
            "From entity id: %d, to my player entity id: %d, my peer id is: %d",
                entity_id, ctx.my_player.entity, ctx.my_id
        )
    )

    if entity_id == ctx.my_player.entity then
        rpc.sync_deck_actions(ctx.my_id, action_str)
    end
end)




return M
