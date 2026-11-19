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

-- Keep internal panel disabled across reloads while docked in clamshell mode
local clamshellFile = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr_clamshell_panel", "r")
if clamshellFile then
    local panel = clamshellFile:read("*l")
    clamshellFile:close()
    if panel and #panel > 0 then
        hl.monitor({ output = panel, disabled = true })
    end
end
require("lua.input")
require("lua.looknfeel")

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/load_monitor_config.sh")
    hl.exec_cmd("hyprctl dispatch workspace 2")
end)

require("lua.apps-config")

