-- Create or add a window to the current group

local constants = require("lua.configs.constants")
local commands = constants.commands
local apps = constants.apps
local buttons = constants.buttons

local KeyCombo = require("lua.configs.functions").KeyCombo

hl.bind(KeyCombo(buttons.mainMod, "G"), hl.dsp.group.toggle())
hl.bind(KeyCombo(buttons.mainMod, buttons.tab), hl.dsp.group.next())
hl.bind(KeyCombo(buttons.mainMod, buttons.shift, buttons.tab), hl.dsp.group.prev())
hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "G"), hl.dsp.group.lock())
