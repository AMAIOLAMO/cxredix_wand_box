--- @class core.spell_compress_utils
local M = {}

-- given a list of spells in the form {"A", "A", "B", "C", ...}
-- the function tries it's best to compress the spells and returns
-- a compressed wand string
function M.compress(spell_ids)
    local spell_group_set = {}
    local spell_counts = {}

    local spell_group_ignore = {} -- non nil keys to ignore

    local spell_ids_str = ""
    local spell_group_str = ""

    local GROUP_CHAR_PADDING = 3 -- from: A -> [A]: has more than 3 characters

    -- used for getting unique ids
    local g_group_id = 0

    -- count spells
    for i, spell_id in ipairs(spell_ids) do
        if spell_counts[spell_id] == nil then
            spell_counts[spell_id] = 0
        end

        spell_counts[spell_id] = spell_counts[spell_id] + 1
    end

    -- see which spells is not worth spell grouping by
    -- comparing the length it compresses
    for spell_id, spell_count in pairs(spell_counts) do
        if spell_count == 1 then
            spell_group_ignore[spell_id] = 0
            goto continue
        end

        local raw_char_length = #spell_id * spell_count

        -- print(string.format("spell: %s, count: %d, total char: %d", spell_str, spell_count, raw_char_length))
        
        -- TODO: for now we assume a constant of length 1
        -- for this algorithm to work, we have to first assign group ids
        -- for each spell based on the higher its frequency and the longer it's string
        -- we assign a shorter group id
        local group_id_str_len = 1

        local grouped_length = #spell_id + GROUP_CHAR_PADDING + group_id_str_len * (1 + spell_count)

        -- if the original raw char is less than the grouped versions
        -- then we dont need to compress
        if raw_char_length <= grouped_length then
            spell_group_ignore[spell_id] = 0
        end

        ::continue::
    end

    -- reconstruct spell ids
    for i, spell_id in ipairs(spell_ids) do
        local spell_ids_str_comma = ","
        
        -- first spell
        if i == 1 then
            spell_ids_str_comma = ""
        end

        -- if the spell occured only once, then there is no need to group them
        -- TODO: this check can be more specific, it can count the amount of
        -- characters it changes and see if the compressed version actually decreases the
        -- amount of characters within the result
        if spell_group_ignore[spell_id] ~= nil then
            if i == 1 then
                comma_str = ""
            end

            -- just retain the original spell_id
            spell_ids_str = spell_ids_str .. spell_ids_str_comma .. spell_id

            goto continue
        end


        -- handle spell groups
        local group_id = spell_group_set[spell_id]
        
        -- if the group is new
        if group_id == nil then
            local comma_str = ","

            -- first group
            if g_group_id == 0 then
                comma_str = ""
            end

            group_id = g_group_id
            g_group_id = g_group_id + 1

            spell_group_set[spell_id] = group_id

            spell_group_str = spell_group_str .. comma_str .. string.format("[%s]:%d", spell_id, group_id)
        end
        -- having group id, we can then replace the string

        spell_ids_str = spell_ids_str .. spell_ids_str_comma .. group_id

        ::continue::
    end

    local result_str = spell_ids_str

    if #spell_group_str ~= 0 then
        result_str = result_str .. ";" .. spell_group_str
    end

    return result_str
end


return M
