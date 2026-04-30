local M = {}

function M.set_sync_actions(raw_actions_str)
    GlobalsSetValue("cx_wndbx_sync_deck_actions", raw_actions_str)
end

function M.consume_sync()
    local deck_actions = GlobalsGetValue("cx_wndbx_sync_deck_actions")
    GlobalsSetValue("cx_wndbx_sync_deck_actions", "")

    return deck_actions
end

function M.should_sync()
    local deck_actions = GlobalsGetValue("cx_wndbx_sync_deck_actions")

    return deck_actions ~= ""
end

function M.mark_sync_complete_flag()
    GlobalsSetValue("cx_wndbx_sync_complete_flag", "true")
end

function M.is_sync_complete_flag_marked()
    return GlobalsGetValue("cx_wndbx_sync_complete_flag") == "true"
end

function M.clear_sync_complete_flag()
    GlobalsSetValue("cx_wndbx_sync_complete_flag", "")
end

return M
