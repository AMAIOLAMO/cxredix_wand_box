--- @class core.logger
local M = {}


function M.info(msg)
    GamePrint("[Wand Box]" .. msg)
end

function M.info_str_list(list)
    if list == nil or #list == 0 then
        M.info("")
        return
    end
    -- else


    local output = list[1]

    for i = 2, #list do
        output = output .. ", " .. list[i]
    end

    M.info("{" .. output .. "}")
end

return M
