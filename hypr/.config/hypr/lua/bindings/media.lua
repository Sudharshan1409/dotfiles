--- Hardware Keys & System Utilities ---

-- Volume & Mute Keys
-- bindel: repeating + locked

local constants = require("lua.configs.constants")
local KeyCombo = require("lua.configs.functions").KeyCombo

local buttons = constants.buttons

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true, locked = true }
)

hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true, locked = true }
)

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Media Playback Controls
-- bindl: locked

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })

hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

-- Display Brightness Keys
-- bindel: repeating + locked

hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("caelestia shell brightness set +5% || brightnessctl -q set +5%"),
	{ repeating = true, locked = true }
)

hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("caelestia shell brightness set 5%- || brightnessctl -q set 5%-"),
	{ repeating = true, locked = true }
)

-- Screenshot Shortcuts

hl.bind("Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_screen_edit.sh"))

hl.bind(KeyCombo(buttons.mainMod, buttons.print), hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_window_edit.sh"))

hl.bind(
	KeyCombo(buttons.mainMod, buttons.shift, buttons.print),
	hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_edit.sh")
)

hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "S"), hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_edit.sh"))
