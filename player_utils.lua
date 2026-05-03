function get_player_ids()
    return EntityGetWithTag("player_unit")
end

function get_total_player_count()
    return #get_player_ids()
end

function get_player_id(idx)
    return EntityGetWithTag("player_unit")[idx]
end

function get_first_player_id()
    return get_player_id(1)
end

