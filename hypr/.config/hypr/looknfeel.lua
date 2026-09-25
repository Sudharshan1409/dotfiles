-- General styling, gaps, borders, layout, animations and decorations
local activeBorderColor = "rgba(33ccffee) rgba(00ff99ee) 45deg"
local inactiveBorderColor = "rgba(595959aa)"

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 3,
        layout = "dwindle",
        allow_tearing = false,
        col = {
            active_border = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
        force_split = 2,
    },

    decoration = {
        rounding = 6,

        blur = {
            enabled = true,
            size = 3,
            passes = 3,
        },

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a,
        },
    },

    group = {
        ["col.border_active"] = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
        ["col.border_inactive"] = "rgba(595959aa)",

        groupbar = {
            font_size = 12,
            font_family = "monospace",
            font_weight_active = "ultraheavy",
            font_weight_inactive = "normal",

            indicator_height = 0,
            indicator_gap = 5,
            height = 22,
            gaps_in = 5,
            gaps_out = 0,

            text_color = "rgb(ffffff)",
            text_color_inactive = "rgba(ffffff90)",
            ["col.active"] = "rgba(00000040)",
            ["col.inactive"] = "rgba(00000020)",

            gradients = true,
            gradient_rounding = 0,
            gradient_round_only_edges = false,
        },
    },

    animations = {
        enabled = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    misc = {
        force_default_wallpaper = 0,
        focus_on_activate = true,
        enable_swallow = true,
        swallow_regex = "^(com\\.mitchellh\\.ghostty)$",
        disable_hyprland_guiutils_check = true,
    },
})

-- Default curves & animations
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = false, speed = 0,    bezier = "ease" })
