-- appended to data/scripts/gun/gun.lua

local cx_wndbx = {
    parser = dofile_once("mods/cxredix_wand_box/core/cx_action_parse_utils.lua"),
    deck_sync = dofile_once("mods/cxredix_wand_box/core/cx_deck_sync.lua"),
    logger = dofile_once("mods/cxredix_wand_box/core/logger.lua"),
    old_add_card_to_deck = _add_card_to_deck
}



function _add_card_to_deck(action_id, inventoryitem_id, uses_remaining, is_identified)
    local cx_deck_sync = cx_wndbx.deck_sync
    local cx_parser = cx_wndbx.parser
    local logger = cx_wndbx.logger
    local old_add_card_to_deck = cx_wndbx.old_add_card_to_deck

    if cx_deck_sync.should_sync() then
        local raw_deck_str = cx_deck_sync.consume_sync()

        logger.log_info("Received Sync!")
        logger.log_info("Clearing Deck...")
        _clear_deck(false)

        logger.log_info("deck cleared, loading...")

        local deck_action_ids = cx_parser.parse_to_action_ids(raw_deck_str)

        for _, deck_action_id in ipairs(deck_action_ids) do
            old_add_card_to_deck(deck_action_id, inventoryitem_id, -1, is_identified)
        end

        cx_deck_sync.mark_sync_complete_flag()

        logger.log_info("Load finished!")

        return
    end

    old_add_card_to_deck(action_id, inventoryitem_id, uses_remaining, is_identified)
end

