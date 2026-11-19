-- local constants = require("lua.constants")
-- local buttons = constants.buttons
-- local KeyCombo = require("lua.functions").KeyCombo

-- -----------------------------------------------------------------------------
-- Keyboard and Mouse Input
-- -----------------------------------------------------------------------------

hl.config({
	input = {
		kb_layout = "us",
		follow_mouse = 1,
		natural_scroll = true,
		repeat_rate = 40,
		repeat_delay = 500,
		sensitivity = 0, -- -1.0 to 1.0, 0 means no modification

		touchpad = {
			natural_scroll = true,
		},
	},
})

-- -----------------------------------------------------------------------------
-- Trackpad Gestures (Hyprland 0.57+)
-- -----------------------------------------------------------------------------

-- 3-finger horizontal swipe: live 1:1 workspace switching
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- 3-finger vertical swipes: Caelestia Launcher (up) & Dashboard (down)
hl.gesture({
	fingers = 3,
	direction = "up",
	action = {
		finish = function()
			hl.exec_cmd("caelestia shell drawers toggle launcher")
		end,
	},
})

hl.gesture({
	fingers = 3,
	direction = "down",
	action = {
		finish = function()
			hl.exec_cmd("caelestia shell drawers toggle dashboard")
		end,
	},
})

-- 4-finger vertical swipes: Quick Utilities (up) & Scratchpad Terminal (down)
hl.gesture({
	fingers = 4,
	direction = "up",
	action = {
		finish = function()
			hl.exec_cmd("caelestia shell drawers toggle utilities")
		end,
	},
})

hl.gesture({
	fingers = 4,
	direction = "down",
	action = {
		finish = function()
			hl.exec_cmd("~/.config/hypr/scripts/scratchpad_terminal.sh")
		end,
	},
})

-- -----------------------------------------------------------------------------
-- Per-Device Configuration
-- -----------------------------------------------------------------------------

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

-- -----------------------------------------------------------------------------
-- Per-app scroll behavior
-- -----------------------------------------------------------------------------

-- NOTE: Hyprland does not support per-window scroll sensitivity rules.
-- You can only set this globally or per-device.

-- windowrule = scroll_touchpad 1.5, match:class ^Alacritty$
-- windowrule = scroll_touchpad 0.2, match:class ^com\.mitchellh\.ghostty$
