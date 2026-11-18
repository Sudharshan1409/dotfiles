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
dofile(os.getenv("HOME") .. "/.config/hypr/monitors_gen.lua")
require("lua.input")
require("lua.looknfeel")

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/load_monitor_config.sh")
    hl.exec_cmd("hyprctl dispatch workspace 2")
end)

require("lua.apps-config")

