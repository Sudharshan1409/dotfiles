--- Application Shortcuts ---

local constants = require("lua.configs.constants")
local commands = constants.commands
local apps = constants.apps
local buttons = constants.buttons

local KeyCombo = require("lua.configs.functions").KeyCombo

hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "S"), hl.dsp.exec_cmd("spotify"))
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "D"), hl.dsp.exec_cmd(commands.downloads))
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "B"), hl.dsp.exec_cmd(commands.backgrounds))
--
-- --- Other App-related Shortcuts ---
--
hl.bind(KeyCombo(buttons.mainMod, buttons.rtn), hl.dsp.exec_cmd(apps.terminal))
hl.bind(KeyCombo(buttons.mainMod, "S"), hl.dsp.exec_cmd("~/.config/hypr/scripts/scratchpad_terminal.sh"))
hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "F"), hl.dsp.exec_cmd("~/.config/hypr/scripts/quick_fzf_finder.sh"))
hl.bind(KeyCombo(buttons.mainMod, buttons.space), hl.dsp.exec_cmd(commands.menu))
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "V"), hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard.sh"))
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "B"), hl.dsp.exec_cmd("~/.config/waybar/scripts/launch_bluetooth.sh"))
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "N"), hl.dsp.exec_cmd("caelestia shell drawers toggle sidebar"))
--
-- --- Workspace Overview ---
--
hl.bind(KeyCombo(buttons.mainMod, buttons.grave), hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace_overview.sh"))
