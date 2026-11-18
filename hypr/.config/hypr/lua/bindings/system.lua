--- Hyprland System Controls ---

local constants = require("lua.configs.constants")
local KeyCombo = require("lua.configs.functions").KeyCombo

local buttons = constants.buttons

-- Session & System Management

-- Exit Hyprland (with confirmation)
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "M"), hl.dsp.exec_cmd("~/.config/hypr/scripts/exit_hyprland.sh"))

-- Reload Hyprland configuration
hl.bind(
	KeyCombo(buttons.mainMod, buttons.ctrl, "R"),
	hl.dsp.exec_cmd(
		'hyprctl reload && notify-send -i "dialog-information" -a "Hyprland" "Hyprland" "Config reloaded successfully!"'
	)
)

-- Lock screen
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "L"), hl.dsp.exec_cmd("caelestia shell lock lock"))

-- Suspend system
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "S"), hl.dsp.exec_cmd("systemctl suspend"))

-- Toggle Keep Awake (idle inhibitor)
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "H"), hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_keep_awake.sh"))

-- Power menu
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "X"), hl.dsp.exec_cmd("caelestia shell drawers toggle session"))

-- Wallpaper & Caelestia Settings
hl.bind(
	KeyCombo(buttons.mainMod, buttons.ctrl, "W"),
	hl.dsp.exec_cmd("caelestia shell wallpaper picker || caelestia shell nexus open")
)
hl.bind(
	KeyCombo(buttons.mainMod, buttons.ctrl, buttons.shift, "W"),
	hl.dsp.exec_cmd("caelestia wallpaper -r ~/.config/backgrounds -n -N")
)
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "comma"), hl.dsp.exec_cmd("caelestia shell nexus open"))

-- Monitor Profile Manager

-- Open monitor profile menu
hl.bind(
	KeyCombo(buttons.mainMod, buttons.ctrl, "D"),
	hl.dsp.exec_cmd("~/.config/hypr/scripts/monitor_profile_manager.sh menu")
)

-- Automatically configure monitor profile
hl.bind(
	KeyCombo(buttons.mainMod, buttons.ctrl, buttons.shift, "D"),
	hl.dsp.exec_cmd("~/.config/hypr/scripts/monitor_profile_manager.sh auto")
)

-- OCR

hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "T"), hl.dsp.exec_cmd("~/.config/hypr/scripts/ocr.sh"))

-- Help Menus

-- Keybinding help
hl.bind(KeyCombo(buttons.mainMod, "slash"), hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinding_menu.sh"))

-- Application-specific help
hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "slash"), hl.dsp.exec_cmd("~/.config/hypr/scripts/app_help.sh"))

-- Utilities

-- Quick calculator
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "C"), hl.dsp.exec_cmd("~/.config/hypr/scripts/calculator.sh"))

-- Process killer
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "P"), hl.dsp.exec_cmd("~/.config/hypr/scripts/process_killer.sh"))

-- Window & Display Modes

-- Movie mode / Solo display
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "M"), hl.dsp.exec_cmd("~/.config/hypr/scripts/movie_mode.sh"))

-- Audio device switcher
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "A"), hl.dsp.exec_cmd("~/.config/hypr/scripts/audio_switcher.sh"))

-- Recording & Focus

-- Screen recorder (stops active recording or opens Caelestia Quick Utilities)
hl.bind(
	KeyCombo(buttons.mainMod, buttons.alt, "R"),
	hl.dsp.exec_cmd("pidof gpu-screen-recorder >/dev/null && caelestia record -c || caelestia shell drawers toggle utilities")
)
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, buttons.shift, "R"), hl.dsp.exec_cmd("caelestia record -sr -c"))

-- Focus mode
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "F"), hl.dsp.exec_cmd("~/.config/hypr/scripts/focus_mode.sh"))
