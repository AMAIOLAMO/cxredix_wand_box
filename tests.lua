require("cx_action_parse_utils")

local success_count = 0
local total_count = 0

local function assert_actions_ids_equal(test_name, expected, actual)
    total_count = total_count + 1
    assert(
        #expected == #actual,
        ("[%s] Expected table of length %d But found length %d"):format(
            test_name, #expected, #actual
        )
    )

    for i, action_id in ipairs(expected) do
        assert(
            expected[i] == actual[i],
            ("[%s] Expected element at index [%d] with '%s', but found '%s'"):format(
                test_name, i, expected[i], actual[i]
            )
        )
    end
    
    print(("[%s] OK"):format(test_name))

    success_count = success_count + 1
end


-- local function print_action_ids(tbl)
--     for i, action_id in ipairs(tbl) do
--         print(string.format("[%d] %s", i, action_id))
--     end
-- end

assert_actions_ids_equal(
    "assert empty",
    cx_deserialize_to_action_ids([[]]), {}
)


assert_actions_ids_equal(
    "assert one action",
    cx_deserialize_to_action_ids([[A]]), {"A"}
)


assert_actions_ids_equal(
    "assert many actions, simple format",
    cx_deserialize_to_action_ids([[A, B, C, G, E, A, A, C, B]]),
    { "A", "B", "C", "G", "E", "A", "A", "C", "B" }
)


assert_actions_ids_equal(
    "assert naming conventions",
    cx_deserialize_to_action_ids([[AbCd_123_efg, ___123_ABC, ABC]]),
    {"AbCd_123_efg", "___123_ABC", "ABC"}
)

assert_actions_ids_equal(
    "assert longer names",
    cx_deserialize_to_action_ids([[ABC,GEF, GGGG, GE123_2]]),
    {"ABC", "GEF", "GGGG", "GE123_2"}
)

assert_actions_ids_equal(
    "assert inconsistent spacing",
    cx_deserialize_to_action_ids([[ABC,GEF,              GGGG,     GE123_2]]),
    {"ABC", "GEF", "GGGG", "GE123_2"}
)

assert_actions_ids_equal(
    "assert no spacing",
    cx_deserialize_to_action_ids([[ABC,GEF,GGGG,GE123_2]]),
    {"ABC", "GEF", "GGGG", "GE123_2"}
)

assert_actions_ids_equal(
    "assert new line as spacing",
    cx_deserialize_to_action_ids(
        [[
            ABC
            ,GEF,
            GGGG,
            GE123_2
        ]]
    ),
    {"ABC", "GEF", "GGGG", "GE123_2"}
)

-- old assertion
-- assert_actions_ids_equal(
--     "assert simple alias",
--     cx_deserialize_to_action_ids(
--         [[
--             A,2,C;
--             B: 2
--         ]]
--     ),
--     {"A", "B", "C"}
-- )
--
-- assert_actions_ids_equal(
--     "assert alias weird naming",
--     cx_deserialize_to_action_ids(
--         [[
--             A,2,C;
--             B_123_453894____: 2
--         ]]
--     ),
--     {"A", "B_123_453894____", "C"}
-- )
--
-- assert_actions_ids_equal(
--     "assert multiple alias",
--     cx_deserialize_to_action_ids(
--         [[
--             A, 20, 20, 1, C, 20;
--             B__33123_: 20, G_2: 1
--         ]]
--     ),
--     {"A", "B__33123_", "B__33123_", "G_2", "C", "B__33123_"}
-- )

assert_actions_ids_equal(
    "assert simple alias group",
    cx_deserialize_to_action_ids(
        [[
            A,2,C;
            [B]: 2
        ]]
    ),
    {"A", "B", "C"}
)

assert_actions_ids_equal(
    "assert alias group weird naming",
    cx_deserialize_to_action_ids(
        [[
            A,2,C;
            [B_123_453894____]: 2
        ]]
    ),
    {"A", "B_123_453894____", "C"}
)

assert_actions_ids_equal(
    "assert multiple single alias group",
    cx_deserialize_to_action_ids(
        [[
            A, 20, 20, 1, C, 20;
            [B__33123_]: 20, [G_2]: 1
        ]]
    ),
    {"A", "B__33123_", "B__33123_", "G_2", "C", "B__33123_"}
)

assert_actions_ids_equal(
    "assert multi alias group and single alias group",
    cx_deserialize_to_action_ids(
        [[
            A, 20, 20, 1, C, 20;
            [B, B, C, D]: 20, [G_2]: 1
        ]]
    ),
    {"A", "B", "B", "C", "D", "B", "B", "C", "D", "G_2", "C", "B", "B", "C", "D"}
)

assert_actions_ids_equal(
    "assert multi alias group",
    cx_deserialize_to_action_ids(
        [[
            A, 20, 20, 1, C, 20;
            [B, B, C, D]: 20, [C, G]: 1
        ]]
    ),
    {"A", "B", "B", "C", "D", "B", "B", "C", "D", "C", "G", "C", "B", "B", "C", "D"}
)


print(
    ("Tests success %d, failed %d, total %d")
        :format(success_count, total_count - success_count, total_count)
)

