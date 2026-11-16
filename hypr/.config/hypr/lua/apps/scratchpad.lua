-- -----------------------------------------------------------------------------
-- Scratchpad terminal (Super + S)
-- -----------------------------------------------------------------------------
-- Toggleable floating Ghostty on a dedicated special workspace.
-- Spawn / toggle logic lives in scripts/scratchpad_terminal.sh.

hl.window_rule({
	match = {
		class = "^(scratchpad-terminal)$",
	},
	workspace = "special:scratch",
	float = true,
	size = { "monitor_w", "monitor_h" },
	center = true,
	opacity = "0.95 0.9",
})
