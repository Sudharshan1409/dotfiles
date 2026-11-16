-- -----------------------------------------------------------------------------
-- Browser types (grouping + tagging)
-- -----------------------------------------------------------------------------

-- Chromium-based browsers
hl.window_rule({
	match = {
		class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable|helium)",
	},
	group = "set",
	tag = "+chromium-based-browser",
})

-- Firefox-based browsers
hl.window_rule({
	match = {
		class = "([fF]irefox|zen|librewolf)",
	},
	group = "set",
	tag = "+firefox-based-browser",
})

-- Google Meet windows should float (Chromium only)
hl.window_rule({
	match = {
		class = "^((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable|helium)$",
		title = "^([mM]eet).*$",
	},
	float = true,
})

-- -----------------------------------------------------------------------------
-- Chromium app-mode bug workaround
-- -----------------------------------------------------------------------------

-- Force Chromium-based browsers to tile
hl.window_rule({
	match = {
		tag = "chromium-based-browser",
	},
	tile = true,
})

-- -----------------------------------------------------------------------------
-- Opacity rules
-- -----------------------------------------------------------------------------

-- Subtle opacity for browsers
hl.window_rule({
	match = {
		tag = "chromium-based-browser",
	},
	opacity = "1.0 override 0.97",
})

hl.window_rule({
	match = {
		tag = "firefox-based-browser",
	},
	opacity = "1.0 override 0.97",
})

-- -----------------------------------------------------------------------------
-- Video / conferencing sites — NEVER apply opacity
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		initial_title = "((?i)(?:[a-z0-9-]+\\.)*(youtube\\.com|app\\.zoom\\.us))",
	},
	opacity = "1.0 override 1.0 override",
})
