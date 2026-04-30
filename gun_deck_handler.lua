-- appended to data/scripts/gun/gun.lua

dofile_once("mods/cxredix_wand_box/cx_action_parse_utils.lua")
local cx_deck_sync = dofile_once("mods/cxredix_wand_box/cx_deck_sync.lua")

local cx_pxa_old_add_card_to_deck = _add_card_to_deck

local action_id_lookup_cache = {
}

function cx_pxa_update_cache()
    action_id_lookup_cache = {}

    for idx, action in ipairs(actions) do
        action_id_lookup_cache[action.id] = action
    end
end

cx_pxa_update_cache()

-- A very slight optimization of the original, at the cost of twice the amount of memory to store cache
function cx_pxa_new_add_card_to_deck(action_id, inventoryitem_id, uses_remaining, is_identified)
    if action_id_lookup_cache[action_id] == nil then
        cx_pxa_update_cache()
    end

    local action = action_id_lookup_cache[action_id]

    action_clone = {}
    clone_action( action, action_clone )
    action_clone.inventoryitem_id = inventoryitem_id
    action_clone.uses_remaining   = uses_remaining
    action_clone.deck_index       = #deck
    action_clone.is_identified    = is_identified
    -- debug_print( "uses " .. uses_remaining )
    table.insert( deck, action_clone )
end

function _add_card_to_deck(action_id, inventoryitem_id, uses_remaining, is_identified)
    if cx_deck_sync.should_sync() then
        local raw_deck_str = cx_deck_sync.consume_sync()

        GamePrint("Received Sync!")
        GamePrint("Clearing Deck...")
        _clear_deck(false)

        GamePrint("deck cleared, loading...")

        local deck_action_ids = cx_deserialize_to_action_ids(raw_deck_str)
            
        for _, deck_action_id in ipairs(deck_action_ids) do
            cx_pxa_old_add_card_to_deck(deck_action_id, inventoryitem_id, -1, is_identified)
            
            -- This is just a slightly optimized version using cache, only a 1.14 times improvement overall
            -- cx_pxa_new_add_card_to_deck(deck_action_id, inventoryitem_id, -1, is_identified)
        end

        cx_deck_sync.mark_sync_complete_flag()

        GamePrint("Load finished!")

        GlobalsSetValue("cx_pxa_sync_deck_actions", "")
        GlobalsSetValue("cx_pxa_sync_complete_flag", "true")

        return
    end

    cx_pxa_old_add_card_to_deck(action_id, inventoryitem_id, uses_remaining, is_identified)
end

