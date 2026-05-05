--- @class cx_action_parse_utils
local M = {}

-- ```
-- The most simplest format is:
-- SPELL_ID1, SPELL_ID2, SPELL_ID3, SPELL_ID1
--
-- this should create 4 spell actions, each utilizing their in game ID name.
--
-- for example:
-- MANA_REDUCE, HEAVY_SHOT, HEAVY_SHOT, HEAVY_BULLET
--
-- this one creates 4 spell actions, one add mana(aka MANA_REDUCE),
-- two heavy shots and one magic bolt (aka HEAVY_BULLET)
--
-- a more complicated format is:
-- SPELL_ID1, SPELL_ID2, 2, 2, 3, 1;
--
-- [SPELL_ID3]: 1, [SPELL_ID4]: 2, [SPELL_ID5]: 3
--
-- we now have two sections, separated by a semicolon ";". first section are the spell ids / spell action alias groups
--
-- the second section denotes any spell action alias groups, so here we aliased "SPELL_ID3" as 1, "SPELL_ID4" as 2,
-- and "SPELL_ID5" as 3.
--
--
-- for example:
-- MANA_REDUCE, MANA_REDUCE, HEAVY_SHOT, HEAVY_SHOT, HEAVY_SHOT, HEAVY_SHOT, HEAVY_SHOT, HEAVY_BULLET
--
-- the above can be shortened into:
--
-- 1, 1, 2, 2, 2, 2, 2, HEAVY_BULLET;
--
-- [MANA_REDUCE]: 1, [HEAVY_SHOT]: 2
--
--
-- Sometimes your spell actions will repeat a bunch of times, and it's very annoying to type them all out, you can
-- instead create alias groups with multiple spell actions:
--
-- for example, this can be shortened into:
-- HEAVY_SHOT, HEAVY_BULLET, HEAVY_SHOT, HEAVY_BULLET, HEAVY_SHOT, HEAVY_BULLET, HEAVY_SHOT, HEAVY_BULLET
--
-- 1, 1, 1, 1;
-- [HEAVY_SHOT, HEAVY_BULLET]: 1
--
-- you can put 1 or more spell actions within the square brackets "[]", separated between ","
--
-- Additional note: spaces and newlines are not necessary / mandatory, you can omit them entirely :)
-- ```

function M.parse_to_action_ids(raw_str)
    local action_ids = {}

    -- remove ALL whitespace
    raw_str = raw_str:gsub("%s+", "")

    -- split into sections
    local sections = {}
    for part in string.gmatch(raw_str, "([^;]+)") do
        table.insert(sections, part)
    end

    local main_section_str = sections[1] or ""
    local alias_section_str = sections[2] -- may be nil

    -- index → {spell1, spell2, ...}
    local action_group_aliases = {}

    -- ONLY parse alias if it exists
    if alias_section_str and alias_section_str ~= "" then
        for group, index in string.gmatch(alias_section_str, "%[([^%]]+)%]:(%d+)") do
            local idx = tonumber(index)

            -- initialize list if not existing
            if not action_group_aliases[idx] then
                action_group_aliases[idx] = {}
            end

            for spell in string.gmatch(group, "([^,]+)") do
                table.insert(action_group_aliases[idx], spell)
            end
        end
    end

    -- parse main section
    for token in string.gmatch(main_section_str, "([^,]+)") do
        local num = tonumber(token)

        if num then
            local alias_group = action_group_aliases[num]

            if alias_group then
                -- expand grouped alias
                for _, spell in ipairs(alias_group) do
                    table.insert(action_ids, spell)
                end
            else

            end
        else
            -- direct spell id
            table.insert(action_ids, token)
        end
    end

    return action_ids
end

return M
