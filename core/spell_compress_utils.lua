--- @class core.spell_compress_utils
local M = {}

-- given a list of spells in the form {"A", "A", "B", "C", ...}
-- the function tries it's best to compress the spells and returns
-- a compressed wand string
function M.compress(spell_ids)
    local spell_group_ids = {}
    local spell_group_ignore = {} -- non nil keys to ignore

    local spell_ids_str = ""
    local spell_group_str = ""

    local GROUP_CHAR_PADDING = 3 -- from: A -> [A]: has more than 3 characters

    -- used for getting unique ids
    local INITIAL_GROUP_ID = 0
    local g_group_id = INITIAL_GROUP_ID

    -- count spells
    local spell_counts = {}
    for i, spell_id in ipairs(spell_ids) do
        if spell_counts[spell_id] == nil then
            spell_counts[spell_id] = 0
        end

        spell_counts[spell_id] = spell_counts[spell_id] + 1
    end

    -- sorted version of spell count, but from the most amount of characters
    -- to least amount within the resulting string
    local spell_id_counts_length_sorted = {}
    for spell_id, spell_count in pairs(spell_counts) do
        table.insert(spell_id_counts_length_sorted, {spell_id, spell_count})
    end

    -- sorts by character length
    table.sort(
        spell_id_counts_length_sorted,
        function (a, b)
            local a_spell_id = a[1]
            local a_spell_count = a[2]

            local b_spell_id = b[1]
            local b_spell_count = b[2]

            -- sort descending from highest character count to lowest
            return #a_spell_id * a_spell_count > #b_spell_id * b_spell_count
        end
    )

    -- populate spell group ids and
    -- see which spells is not worth spell grouping by
    -- comparing the length it compresses
    for i, v in ipairs(spell_id_counts_length_sorted) do
        local spell_id = v[1]
        local spell_count = v[2]

        if spell_count == 1 then
            spell_group_ignore[spell_id] = 0
            goto continue
        end

        local raw_char_length = #spell_id * spell_count

        local group_id_str_len = #tostring(g_group_id)

        local grouped_length = #spell_id + GROUP_CHAR_PADDING + group_id_str_len * (1 + spell_count)

        -- if the original raw char is less than the grouped versions
        -- then we dont need to compress
        if raw_char_length <= grouped_length then
            spell_group_ignore[spell_id] = 0

            goto continue
        end

        -- otherwise we don't ignore the spell group because it shortens
        local group_id_str_comma = ","

        -- first group
        if g_group_id == INITIAL_GROUP_ID then
            group_id_str_comma = ""
        end

        local group_id = g_group_id
        g_group_id = g_group_id + 1

        spell_group_ids[spell_id] = group_id

        spell_group_str = spell_group_str .. group_id_str_comma .. string.format("[%s]:%d", spell_id, group_id)

        ::continue::
    end

    -- reconstruct spell ids
    for i, spell_id in ipairs(spell_ids) do
        local spell_ids_str_comma = ","
        
        -- first spell
        if i == 1 then
            spell_ids_str_comma = ""
        end

        if spell_group_ignore[spell_id] ~= nil then
            -- just retain the original spell_id
            spell_ids_str = spell_ids_str .. spell_ids_str_comma .. spell_id

            goto continue
        end


        -- handle spell groups
        local group_id = spell_group_ids[spell_id]
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
