-- -----------------------------------------------------------------------------
-- JetBrains windows default size
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		class = "(.*jetbrains.*)$",
		title = "^$",
	},
	size = { "monitor_w * 0.5", "monitor_h * 0.5" },
})

-- -----------------------------------------------------------------------------
-- Fix tab dragging (tab titles are just one space)
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		class = "^(.*jetbrains.*)$",
		title = "^\\s$",
	},
	no_initial_focus = true,
})

-- -----------------------------------------------------------------------------
-- Allow dialogs (e.g. "Send usage statistics") to be focusable & clickable
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		class = "^(.*jetbrains.*)$",
		title = "^$",
	},
	no_focus = false,
	no_initial_focus = false,
})
