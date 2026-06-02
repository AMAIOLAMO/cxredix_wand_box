local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

--- @module "core.common"
local common = dofile_once(core_path .. "common.lua")

--- @module "core.logger"
local logger = dofile_once(core_path .. "logger.lua")

--- @module "core.wand_attributes"
local WandAttribs = dofile_once(core_path .. "wand_attributes.lua")

--- @class tools.about_page
local M = {
    name = "About",
    is_open = false
}


function M.render_window(imgui, wndbox_state)
    local img = nil

    if imgui.LoadImage then
        img = imgui.LoadImage(root_path .. "vendor/hamis_about.png")
    end

    imgui.Text(
        "Made with Love by CxRedix <3"
    )

    imgui.Text(
        ("Version: %s"):format(common.version)
    )

    local wx, wy = imgui.GetWindowSize()

    local img_ar = img.width / img.height


    local min_dim = math.min(wx, wy)

    if img then
        imgui.Image(img, min_dim / img_ar, min_dim)
    end
end

return M
