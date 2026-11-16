local constants = require("lua.configs.constants")
local KeyCombo = require("lua.configs.functions").KeyCombo

local buttons = constants.buttons
--- Mouse Bindings ---

-- SUPER + Left Mouse Button: Move window
hl.bind(KeyCombo(buttons.mainMod, buttons.mouseLeft), hl.dsp.window.drag(), { mouse = true })

-- SUPER + Right Mouse Button: Resize window
hl.bind(KeyCombo(buttons.mainMod, buttons.mouseRight), hl.dsp.window.resize(), { mouse = true })
