--- Application Shortcuts ---

local constants = require("lua.configs.constants")
local commands = constants.commands
local apps = constants.apps
local buttons = constants.buttons

local KeyCombo = require("lua.configs.functions").KeyCombo

hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "S"), hl.dsp.exec_cmd("spotify"))
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "M"), hl.dsp.exec_cmd("caelestia toggle music"))
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "T"), hl.dsp.exec_cmd("caelestia toggle sysmon"))
hl.bind(KeyCombo(buttons.ctrl, buttons.shift, "ESCAPE"), hl.dsp.exec_cmd("caelestia toggle sysmon"))
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "D"), hl.dsp.exec_cmd(commands.downloads))
hl.bind(KeyCombo(buttons.mainMod, buttons.alt, "B"), hl.dsp.exec_cmd(commands.backgrounds))
--
-- --- Shell Drawers & Utilities ---
--
hl.bind(KeyCombo(buttons.mainMod, buttons.rtn), hl.dsp.exec_cmd(apps.terminal))
hl.bind(KeyCombo(buttons.mainMod, "S"), hl.dsp.exec_cmd("~/.config/hypr/scripts/scratchpad_terminal.sh"))
hl.bind(KeyCombo(buttons.mainMod, buttons.shift, "F"), hl.dsp.exec_cmd("~/.config/hypr/scripts/quick_fzf_finder.sh"))
hl.bind(KeyCombo(buttons.mainMod, buttons.space), hl.dsp.exec_cmd(commands.menu))
hl.bind(KeyCombo(buttons.mainMod, "D"), hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"))
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "N"), hl.dsp.exec_cmd("caelestia shell drawers toggle sidebar"))
hl.bind(KeyCombo(buttons.mainMod, buttons.ctrl, "V"), hl.dsp.global("caelestia:clipboardToggle"))
hl.bind(KeyCombo(buttons.mainMod, "period"), hl.dsp.exec_cmd("~/.config/hypr/scripts/emoji_picker.sh"))
--
-- --- Spatial Workspace Overview (Mission Control) ---
--
hl.bind(KeyCombo(buttons.mainMod, buttons.grave), hl.dsp.global("caelestia:workspaceOverviewToggle"))
