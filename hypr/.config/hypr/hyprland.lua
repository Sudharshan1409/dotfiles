-- ==============================================================================
-- Hyprland Lua Master Configuration
-- ==============================================================================

local home = os.getenv("HOME") or "/home/sudharshan"

-- Configure Lua module search paths
package.path = home .. "/.config/hypr/?.lua;" .. home .. "/.config/hypr/lua/?.lua;" .. package.path

-- Load modular configuration components
require("mocha")
require("envs")
require("autostart")
require("looknfeel")
require("input")
require("bindings")
require("windows")
require("monitors")
