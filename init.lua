dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")

local root_path = "mods/cxredix_wand_box/"
local core_path = root_path .. "core/"
local tools_path = root_path .. "tools/"

-- @module core.cx_deck_sync
local cx_deck_sync = dofile_once(core_path .. "cx_deck_sync.lua")

-- @module "tools.wand_helper_tool"
local wand_helper_tool = dofile_once(tools_path .. "wand_helper_tool.lua")

-- @module "tools.wand_loader_tool"
local wand_loader_tool = dofile_once(tools_path .. "wand_loader_tool.lua")


ModLuaFileAppend("data/scripts/gun/gun.lua", core_path .. "gun_deck_handler.lua")

if ModIsEnabled("quant.ew") then
    ModLuaFileAppend(
        "mods/quant.ew/files/api/extra_modules.lua",
        root_path .. "ew_gun_sync_module.lua"
    )
end

local tools = {
    wand_helper_tool, wand_loader_tool
}


function OnWorldInitialized()
    -- clear any previous un-synced actions
    cx_deck_sync.consume_sync()
    cx_deck_sync.clear_sync_complete_flag()

    for _, tool in ipairs(tools) do
        if tool.on_world_init ~= nil then
            tool.on_world_init()
        end
    end

end

-- use imgui when the function exists
if load_imgui ~= nil then
    local imgui = load_imgui({version="1.21.0", mod="CxRedixWandBox"})

    function imgui_cautious_btn(id)
        imgui.PushStyleColor(imgui.Col.Button, 0.8, 0.45, 0.45)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, 1, 0.6, 0.6)
        imgui.PushStyleColor(imgui.Col.ButtonActive, 0.7, 0.45, 0.45)

        local ret_value = imgui.Button(id)

        imgui.PopStyleColor(3)

        return ret_value
    end


    local wndbx_state = {
        picked_player_idx = 1
    }

    local prev_frame_real_world_time = GameGetRealWorldTimeSinceStarted()
    local dt_secs = 0

    function OnWorldPostUpdate()
        dt_secs = GameGetRealWorldTimeSinceStarted() - prev_frame_real_world_time
        prev_frame_real_world_time = GameGetRealWorldTimeSinceStarted()

        imgui.SetNextWindowSize(800, 400, imgui.Cond.Once)

        local window_flags = bit.bor(
            imgui.WindowFlags.MenuBar,
            imgui.WindowFlags.NoDocking,
            imgui.WindowFlags.NoSavedSettings,
            imgui.WindowFlags.NoFocusOnAppearing,
            imgui.WindowFlags.NoMove,
            imgui.WindowFlags.NoDecoration,
            imgui.WindowFlags.NoBackground
        )

        local menu_height = imgui.GetFontSize() + 2 * imgui.GetStyle().FramePadding_y

        local vp_width, vp_height = imgui.GetMainViewportSize()

        local vp_work_x, vp_work_y = imgui.GetMainViewportWorkPos()

        local y_padding = 2.5

        local CHAR_WIDTH = 7

        local half_text_width = CHAR_WIDTH * ("CxRedix's Wand Box"):len() * 0.5

        imgui.SetNextWindowViewport(imgui.GetMainViewportID())
        imgui.SetNextWindowPos(
            vp_work_x + vp_width * 0.5 - half_text_width,
            vp_work_y + vp_height - menu_height - y_padding
        )
        imgui.SetNextWindowSize(0, 0)

        if imgui.Begin("Main Window Menu", nil, window_flags) then

            if imgui.BeginMenuBar() then
                if imgui.BeginMenu("CxRedix's Wand Box") then

                    for _, tool in ipairs(tools) do
                        local _
                        _, tool.is_open = imgui.MenuItem(
                            tool.name, "", tool.is_open
                        )
                    end

                    imgui.EndMenu()
                end

                imgui.EndMenuBar()
            end
        end

        -- world post update
        for _, tool in ipairs(tools) do
            if tool.on_world_post_update ~= nil then
                tool.on_world_post_update(dt_secs, wndbx_state)
            end
        end

        -- tool render window
        for _, tool in ipairs(tools) do
            if not tool.is_open then
                goto continue
            end

            local should_show
            should_show, tool.is_open = imgui.Begin(
                tool.name, tool.is_open
            )

            if not should_show then
                goto continue
            end

            assert(tool.render_window ~= nil, "Cannot find render_window for tool")
            tool.render_window(imgui, wndbx_state)

            imgui.End()

            ::continue::
        end
    end
else
    local warn_notify_interval_frames = 60 * 4 -- every 4 seconds

    local warn_frames = 0

    function OnWorldPostUpdate()
        if warn_frames <= 0 then
            GamePrint("[Wand Box] Cannot find Noita Dear Imgui, It is either you didn't install it")
            GamePrint("[Wand Box] Or that you didn't put Wand Box mod below Noita Dear Imgui in the mod list :3")
            warn_frames = warn_notify_interval_frames
        end

        warn_frames = warn_frames - 1
    end
end

