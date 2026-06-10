--- @class core.imgui_utils
local M = {}

function M.green_button(imgui, id)
    imgui.PushStyleColor(imgui.Col.Button, 0.231, 0.490, 0.309)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, 0.388, 0.670, 0.247)
    imgui.PushStyleColor(imgui.Col.ButtonActive, 0.596, 0.745, 0.466)

    local ret_value = imgui.Button(id)

    imgui.PopStyleColor(3)

    return ret_value
end

function M.cautious_button(imgui, id)
    imgui.PushStyleColor(imgui.Col.Button, 0.8, 0.45, 0.45)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, 1, 0.6, 0.6)
    imgui.PushStyleColor(imgui.Col.ButtonActive, 0.7, 0.45, 0.45)

    local ret_value = imgui.Button(id)

    imgui.PopStyleColor(3)

    return ret_value
end

function M.cautious_small_button(imgui, id)
    imgui.PushStyleColor(imgui.Col.Button, 0.8, 0.45, 0.45)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, 1, 0.6, 0.6)
    imgui.PushStyleColor(imgui.Col.ButtonActive, 0.7, 0.45, 0.45)

    local ret_value = imgui.SmallButton(id)

    imgui.PopStyleColor(3)

    return ret_value
end

return M
