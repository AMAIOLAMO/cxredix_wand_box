-- OLD PARSING METHOD :3
-- function cx_deserialize_to_action_ids(raw_str)
--     -- FORMAT:
--     -- SPELL_ID1, SPELL_ID2, 2, 2, 3, 1;
--     --
--     -- SPELL_ID3: 1, SPELL_ID4: 2, SPELL_ID5: 3
--     --
--     -- RESULT:
--     -- should return {"SPELL_ID1", "SPELL_ID2", "SPELL_ID4", "SPELL_ID4", "SPELL_ID5", "SPELL_ID3"}
--     -- you can see the numbers are associated back :)
--     --
--     -- the first section is spell id and associates
--     -- the second section is an optional section where if you have highly repeating
--     -- spells, you can shrink your spell string by compacting them into a number :)
--     --
--     -- If we ignore the second section, it creates a backwards compatible format:
--     --
--     -- SPELL_ID1, SPELL_ID2, SPELL_ID3, SPELL_ID1
--
--     -- still works regardless :D pretty cool!
--
--     local action_ids = {}
--
--     -- remove ALL whitespace (spaces, tabs, newlines)
--     raw_str = raw_str:gsub("%s+", "")
--
--     -- split into sections by ';'
--     local sections = {}
--     for part in string.gmatch(raw_str, "([^;]+)") do
--         table.insert(sections, part)
--     end
--
--     local main_section = sections[1] or ""
--     local cache_section = sections[2]
--
--     -- FORM: [number] = "SPELL_ID"
--     local action_cache = {}
--
--     -- parse cache section (SPELL_ID3:1,SPELL_ID4:2,...)
--     if cache_section and cache_section ~= "" then
--         for pair in string.gmatch(cache_section, "([^,]+)") do
--             local spell, index = pair:match("([^:]+):(%d+)")
--             if spell and index then
--                 action_cache[tonumber(index)] = spell
--             end
--         end
--     end
--
--     -- parse main section
--     for token in string.gmatch(main_section, "([^,]+)") do
--         local num = tonumber(token)
--
--         if num then
--             -- numeric reference → resolve from cache
--             local resolved = action_cache[num]
--             if resolved then
--                 table.insert(action_ids, resolved)
--             end
--         else
--             -- direct spell id
--             table.insert(action_ids, token)
--         end
--     end
--
--     return action_ids
-- end

function cx_parse_wndbx_fmt_to_action_ids(raw_str)
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
    local action_alias_map = {}

    -- ONLY parse alias if it exists
    if alias_section_str and alias_section_str ~= "" then
        for group, index in string.gmatch(alias_section_str, "%[([^%]]+)%]:(%d+)") do
            local idx = tonumber(index)

            -- initialize list if not existing
            if not action_alias_map[idx] then
                action_alias_map[idx] = {}
            end

            for spell in string.gmatch(group, "([^,]+)") do
                table.insert(action_alias_map[idx], spell)
            end
        end
    end

    -- parse main section
    for token in string.gmatch(main_section_str, "([^,]+)") do
        local num = tonumber(token)

        if num then
            local resolved_group = action_alias_map[num]

            if resolved_group then
                -- expand grouped alias
                for _, spell in ipairs(resolved_group) do
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
