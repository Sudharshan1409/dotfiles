-- -----------------------------------------------------------------------------
-- Cisco apps (AnyConnect, Secure Client, etc.)
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = { class = "(?i).*cisco.*" },
	float = true,
	workspace = "special:Ad-Hoc",
})
