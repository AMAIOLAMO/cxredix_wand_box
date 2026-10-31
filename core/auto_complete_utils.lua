--- @class core.auto_complete_utils
local M = {}
M.__index = M

dofile_once("data/scripts/gun/gun.lua")

-- creates a list of spells from the in game "gun.lua",
-- and returns a list of the form: {"SPELL1", "SPELL2", ...}
-- directly used with auto_complete_spell_list
function M.create_cmp_spell_list()
    local spells = {}

    for i, v in ipairs(actions) do
        table.insert(spells, actions[i].id)
    end

    return spells
end

-- the higher the score, the lower the similarity (negative similarity)
function M.calc_spell_negative_similarity_score(main_str, cmp_str)
    local cmp_count = math.min(#main_str, #cmp_str)

    local score = 0

    main_str = main_str:lower()
    cmp_str = cmp_str:lower()

    for i = 1, cmp_count do
        local a = main_str:sub(i, i)
        local b = cmp_str:sub(i, i)

        score = score + math.abs(a:byte() - b:byte())
    end

    return score
end

-- tries to find a list of spells to auto complete given a spell list of the form:
-- {"SPELL_1", "SPELL_2", "SPELL_3", ...}, and matches it towards the given target_match string
-- Returns a list of spells in the form of { {"SPELL_STR1", <match score>}, {"SPELL_STR2", <match score>}, ... }
function M.auto_complete_spell_list(target_match, spell_list, auto_complete_count)
    local spell_score_pairs = {}

    -- make sure we dont modify the original spell_list
    -- that'll not be very good :P
    for i, v in ipairs(spell_list) do
        spell_score_pairs[i] = {v, M.calc_spell_negative_similarity_score(target_match, v)}
    end

    local auto_complete_list = {}

    -- simple linear algorithm to pick out smallest pairs
    -- worse case scenario: O(auto_complete_count * n) = O(n^2)
    -- where n is the amount of spells, and that auto_complete_count = n(which is probs not at this point)
    -- good enough for this case, the only issue is the scoring function (TODO)
    for i = 1, math.min(auto_complete_count, #spell_score_pairs) do
        local min_idx = 1
        local min_score = spell_score_pairs[min_idx][2]

        -- linear search
        for si, v in ipairs(spell_score_pairs) do
            local score = v[2]

            if score < min_score then
                min_score = score
                min_idx = si
            end
        end

        table.insert(auto_complete_list, spell_score_pairs[min_idx])
        table.remove(spell_score_pairs, min_idx)
    end

    return auto_complete_list
end

return M
