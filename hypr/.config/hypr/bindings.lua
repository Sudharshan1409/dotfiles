-- Keybindings and Mouse bindings for Hyprland
local home = os.getenv("HOME") or "/home/sudharshan"
local mainMod = "SUPER"
local terminal = "ghostty"

local downloads = "nautilus " .. home .. "/Downloads"
local backgrounds = "nautilus " .. home .. "/.config/backgrounds"
local userHome = "nautilus " .. home
local menu = "rofi -show drun -show-icons -display-drune 'Apps' -theme " .. home .. "/.config/rofi/launcher-elegant.rasi"

-- ----------------------------------------------------------------------------
-- Application Shortcuts
-- ----------------------------------------------------------------------------
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/scratchpad_terminal.sh"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/quick_fzf_finder.sh"))
hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/clipboard.sh"))
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/launch_bluetooth.sh"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/swaync-client.sh"))
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/workspace_overview.sh"))
hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/workspace_overview.sh"))

-- Quick directory shortcuts ($mainMod + ALT)
hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd(downloads))
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(backgrounds))
hl.bind(mainMod .. " + ALT + H", hl.dsp.exec_cmd(userHome))

-- ----------------------------------------------------------------------------
-- System Controls
-- ----------------------------------------------------------------------------
hl.bind(mainMod .. " + CTRL + M", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/exit_hyprland.sh"))
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd('hyprctl reload && notify-send -i "dialog-information" -a "Hyprland" "Hyprland" "Config reloaded successfully!"'))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/toggle_hypridle.sh"))
hl.bind(mainMod .. " + CTRL + X", hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/power-menu.sh"))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/set_wallpaper.sh"))

hl.bind(mainMod .. " + CTRL + D", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/monitor_profile_manager.sh menu"))
hl.bind(mainMod .. " + CTRL + SHIFT + D", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/monitor_profile_manager.sh auto"))

hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/ocr.sh"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/keybinding_menu.sh"))
hl.bind(mainMod .. " + SHIFT + slash", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/app_help.sh"))

hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/calculator.sh"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/process_killer.sh"))
hl.bind(mainMod .. " + ALT + M", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/movie_mode.sh"))
hl.bind(mainMod .. " + ALT + A", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/audio_switcher.sh"))
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screen_recorder.sh"))
hl.bind(mainMod .. " + ALT + F", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/focus_mode.sh"))

-- ----------------------------------------------------------------------------
-- Window Management & Tiling
-- ----------------------------------------------------------------------------
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + W", function() hl.dispatch("togglegroup") end)
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/toggle_pip.sh"))

-- Move window
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Move focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- MRU Window Switcher (Alt-Tab)
hl.bind("ALT + Tab", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/window_switcher.sh"))

-- Resize tiled windows (repeating)
hl.bind(mainMod .. " + ALT + H", function() hl.dispatch("resizeactive", "-20 0") end, { repeating = true })
hl.bind(mainMod .. " + ALT + L", function() hl.dispatch("resizeactive", "20 0") end,  { repeating = true })
hl.bind(mainMod .. " + ALT + K", function() hl.dispatch("resizeactive", "0 -20") end, { repeating = true })
hl.bind(mainMod .. " + ALT + J", function() hl.dispatch("resizeactive", "0 20") end,  { repeating = true })

-- ----------------------------------------------------------------------------
-- Workspace Navigation & Window Movement
-- ----------------------------------------------------------------------------
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, function() hl.dispatch("workspace", tostring(i)) end)
    hl.bind(mainMod .. " + SHIFT + " .. key, function() hl.dispatch("movetoworkspace", tostring(i)) end)
end

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Ping-pong previous workspace
hl.bind(mainMod .. " + BackSpace", function() hl.dispatch("workspace", "previous") end)

-- Move workspace to adjacent monitor
hl.bind(mainMod .. " + SHIFT + Left",  function() hl.dispatch("movecurrentworkspacetomonitor", "l") end)
hl.bind(mainMod .. " + SHIFT + Right", function() hl.dispatch("movecurrentworkspacetomonitor", "r") end)
hl.bind(mainMod .. " + SHIFT + Up",    function() hl.dispatch("movecurrentworkspacetomonitor", "u") end)
hl.bind(mainMod .. " + SHIFT + Down",  function() hl.dispatch("movecurrentworkspacetomonitor", "d") end)

-- Special Workspaces
hl.bind(mainMod .. " + M",         hl.dsp.workspace.toggle_special("Magic"))
hl.bind(mainMod .. " + SHIFT + M", function() hl.dispatch("movetoworkspacesilent", "special:Magic") end)

hl.bind(mainMod .. " + A",         hl.dsp.workspace.toggle_special("Ad-Hoc"))
hl.bind(mainMod .. " + SHIFT + A", function() hl.dispatch("movetoworkspacesilent", "special:Ad-Hoc") end)

hl.bind(mainMod .. " + E",         hl.dsp.workspace.toggle_special("Entertainment"))
hl.bind(mainMod .. " + SHIFT + E", function() hl.dispatch("movetoworkspacesilent", "special:Entertainment") end)

-- ----------------------------------------------------------------------------
-- Media, Brightness & Screenshot Controls
-- ----------------------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/volume-control.sh up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/volume-control.sh down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/volume-control.sh mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/mic-control.sh mute"),    { locked = true })

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioStop",  hl.dsp.exec_cmd("playerctl stop"),       { locked = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/brightness-control.sh up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(home .. "/.config/waybar/scripts/brightness-control.sh down"), { locked = true, repeating = true })

-- Screenshot shortcuts
hl.bind("Print",                 hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot_screen_edit.sh"))
hl.bind(mainMod .. " + Print",   hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot_window_edit.sh"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot_edit.sh"))
hl.bind(mainMod .. " + SHIFT + S",     hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot_edit.sh"))

-- ----------------------------------------------------------------------------
-- Mouse & Window Dragging
-- ----------------------------------------------------------------------------
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ----------------------------------------------------------------------------
-- Group Management
-- ----------------------------------------------------------------------------
hl.bind(mainMod .. " + G", function() hl.dispatch("togglegroup") end)
hl.bind(mainMod .. " + Tab", function() hl.dispatch("changegroupactive", "f") end)
hl.bind(mainMod .. " + SHIFT + Tab", function() hl.dispatch("changegroupactive", "b") end)
hl.bind(mainMod .. " + SHIFT + G", function() hl.dispatch("lockgroups", "toggle") end)
