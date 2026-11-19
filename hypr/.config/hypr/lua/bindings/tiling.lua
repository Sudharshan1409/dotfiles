local constants = require("lua.configs.constants")
local KeyCombo = require("lua.configs.functions").KeyCombo

local buttons = constants.buttons

-- --- Window Management ---

-- Close active window
hl.bind(KeyCombo(buttons.mainMod, "C"), hl.dsp.window.close())

-- Toggle floating
hl.bind(KeyCombo(buttons.mainMod, "V"), hl.dsp.window.float({ action = "toggle" }))

-- Toggle fullscreen
hl.bind(KeyCombo(buttons.mainMod, "F"), hl.dsp.window.fullscreen({ action = "toggle" }))

-- Group windows
hl.bind(KeyCombo(buttons.mainMod, "W"), hl.dsp.group.toggle())

-- Toggle split direction
hl.bind(KeyCombo(buttons.mainMod, "T"), hl.dsp.layout("togglesplit"))

-- Toggle pseudotiling
hl.bind(KeyCombo(buttons.mainMod, "P"), hl.dsp.window.pseudo())

-- Smart Picture-in-Picture
hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "P"), hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_pip.sh"))

-- --- Move Windows ---

hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "H"), hl.dsp.window.move({ direction = "l" }))
hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "L"), hl.dsp.window.move({ direction = "r" }))
hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "K"), hl.dsp.window.move({ direction = "u" }))
hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "J"), hl.dsp.window.move({ direction = "d" }))

-- --- Move Focus ---

hl.bind(KeyCombo(buttons.mainMod, "H"), hl.dsp.focus({ direction = "l" }))
hl.bind(KeyCombo(buttons.mainMod, "L"), hl.dsp.focus({ direction = "r" }))
hl.bind(KeyCombo(buttons.mainMod, "K"), hl.dsp.focus({ direction = "u" }))
hl.bind(KeyCombo(buttons.mainMod, "J"), hl.dsp.focus({ direction = "d" }))

-- --- Live Visual MRU Window Switcher (Caelestia Alt+Tab) ---

hl.bind(KeyCombo(buttons.alt, buttons.tab), hl.dsp.global("caelestia:windowSwitcherNext"))
hl.bind(KeyCombo(buttons.alt, buttons.shift, buttons.tab), hl.dsp.global("caelestia:windowSwitcherPrev"))
hl.bind("Alt_L", hl.dsp.global("caelestia:windowSwitcherConfirm"), { non_consuming = true, ignore_mods = true, release = true })
hl.bind("Alt_R", hl.dsp.global("caelestia:windowSwitcherConfirm"), { non_consuming = true, ignore_mods = true, release = true })

-- --- Resize Tiled Windows ---

hl.bind(
	KeyCombo(buttons.mainMod, buttons.alt, "H"),
	hl.dsp.window.resize({ x = -20, y = 0, relative = true }),
	{ repeating = true }
)

hl.bind(
	KeyCombo(buttons.mainMod, buttons.alt, "L"),
	hl.dsp.window.resize({ x = 20, y = 0, relative = true }),
	{ repeating = true }
)

hl.bind(
	KeyCombo(buttons.mainMod, buttons.alt, "K"),
	hl.dsp.window.resize({ x = 0, y = -20, relative = true }),
	{ repeating = true }
)

hl.bind(
	KeyCombo(buttons.mainMod, buttons.alt, "J"),
	hl.dsp.window.resize({ x = 0, y = 20, relative = true }),
	{ repeating = true }
)
