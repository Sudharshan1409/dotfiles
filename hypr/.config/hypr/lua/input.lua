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

-- -----------------------------------------------------------------------------
-- Universal Copy / Paste / Cut
-- -----------------------------------------------------------------------------

hl.bind("SUPER + C", hl.dsp.send_shortcut({ mods = "CTRL", key = "Insert", window = "" }))

hl.bind("SUPER + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert", window = "" }))

hl.bind("SUPER + X", hl.dsp.send_shortcut({ mods = "CTRL", key = "X", window = "" }))
