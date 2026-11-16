local constants = require("lua.configs.constants")
local buttons = constants.buttons
local KeyCombo = require("lua.configs.functions").KeyCombo

-- --- Workspace Navigation ---
for i = 1, 10 do
	local key = tostring(i % 10)

	hl.bind(KeyCombo(buttons.mainMod, key), hl.dsp.focus({ workspace = tostring(i) }))
end

-- --- Move Windows to Workspaces ---
for i = 1, 10 do
	local key = tostring(i % 10)

	hl.bind(KeyCombo(buttons.mainMod, buttons.shift, key), hl.dsp.window.move({ workspace = tostring(i) }))
end

-- --- Scroll Through Workspaces ---
hl.bind(KeyCombo(buttons.mainMod, "mouse_down"), hl.dsp.focus({ workspace = "e+1" }), { mouse = true })

hl.bind(KeyCombo(buttons.mainMod, "mouse_up"), hl.dsp.focus({ workspace = "e-1" }), { mouse = true })

-- --- Jump to Previous Workspace ---
hl.bind(KeyCombo(buttons.mainMod, buttons.backspace or "BACKSPACE"), hl.dsp.focus({ workspace = "previous" }))

-- --- Move Current Workspace to Adjacent Monitor ---
for _, direction in ipairs({ "l", "r", "u", "d" }) do
	local key = {
		l = "LEFT",
		r = "RIGHT",
		u = "UP",
		d = "DOWN",
	}

	hl.bind(KeyCombo(buttons.mainMod, buttons.shift, key[direction]), hl.dsp.workspace.move({ monitor = direction }))
end

-- --- Special Workspace (Magic) ---
hl.bind(KeyCombo(buttons.mainMod, "M"), hl.dsp.workspace.toggle_special("Magic"))

hl.bind(
	KeyCombo(buttons.mainMod, buttons.shift, "M"),
	hl.dsp.window.move({ workspace = "special:Magic", follow = false })
)

-- --- Special Workspace (Temp) ---
hl.bind(KeyCombo(buttons.mainMod, "A"), hl.dsp.workspace.toggle_special("Ad-Hoc"))

hl.bind(
	KeyCombo(buttons.mainMod, buttons.shift, "A"),
	hl.dsp.window.move({ workspace = "special:Ad-Hoc", follow = false })
)

-- --- Special Workspace (Entertainment) ---
hl.bind(KeyCombo(buttons.mainMod, "E"), hl.dsp.workspace.toggle_special("Entertainment"))

hl.bind(
	KeyCombo(buttons.mainMod, buttons.shift, "E"),
	hl.dsp.window.move({ workspace = "special:Entertainment", follow = false })
)
