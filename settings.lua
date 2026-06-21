dofile("data/scripts/lib/mod_settings.lua")

local mod_id = "cxredix_wand_box"
mod_settings_version = 1
mod_settings = {
    {
        category_id = "Style",
        ui_name = "Style settings",
        ui_description = "How should wand box look like?",
        settings = {
            {
                id = "font",
                ui_name = "Font(TEMPORARILY DISABLED)",
                ui_description = "What kind of font should wand box use?",

                value_default = "noita_font",
                values = {
                    {"noita_font", "noita_font"},
                    {"noita_font_1_4x", "noita_font_1_4x"},
                    {"noita_font_1_8x", "noita_font_1_8x"},

                    {"imgui_font", "imgui_font"},
                    {"monospace_font", "monospace_font"},
                    {"glyph_font", "glyph_font"},
                    {"noto_font", "noto_font"}
                },

                scope = MOD_SETTING_SCOPE_RUNTIME,
            },
        },
    },
}

function ModSettingsUpdate(init_scope)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end

