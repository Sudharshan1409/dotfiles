-- # ####################################################################################### #
-- #                                                                                         #
-- #  ██╗  ██╗██╗   ██╗██████╗ ██████╗  ██╗      █████╗ ███╗   ██╗██████╗ ██╗  ██╗████████╗  #
-- #  ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗ ██║     ██╔══██╗████╗  ██║██╔══██╗██║  ██║╚══██╔══╝  #
-- #  ███████║ ╚████╔╝ ██████╔╝██████╔╝ ██║     ███████║██╔██╗ ██║██║  ██║███████║   ██║     #
-- #  ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗ ██║     ██╔══██║██║╚██╗██║██║  ██║██╔══██║   ██║     #
-- #  ██║  ██║   ██║   ██║     ██║  ██║ ███████╗██║  ██║██║ ╚████║██████╔╝██║  ██║   ██║     #
-- #  ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝   ╚═╝     #
-- #                                                                                         #
-- # ####################################################################################### #

TERMINAL = "ghostty"

require("mocha")
require("lua.autostart")
require("lua.bindings")
require("lua.windows")
require("lua.envs")
require("lua.input")
require("lua.looknfeel")

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/load_monitor_config.sh")
    hl.exec_cmd("~/.config/hypr/scripts/cache_lockscreen_info.sh")
    hl.exec_cmd("hyprctl dispatch workspace 2")
end)

require("lua.apps-config")

