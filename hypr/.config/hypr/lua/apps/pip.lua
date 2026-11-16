-- -----------------------------------------------------------------------------
-- Picture-in-Picture overlays
-- -----------------------------------------------------------------------------

-- Tag PiP windows by title
hl.window_rule({
	match = {
		title = "(Picture.?in.?[Pp]icture)",
	},
	tag = "+pip",
})

-- Force PiP behavior
hl.window_rule({
	match = { tag = "pip" },
	float = true,
	pin = true,
})

-- Size & aspect ratio
hl.window_rule({
	match = { tag = "pip" },
	size = { 600, 338 },
	keep_aspect_ratio = true,
})

-- Visual cleanup
hl.window_rule({
	match = { tag = "pip" },
	decorate = false,
	opacity = "1.0 override 1.0 override",
})

-- Position: top-right corner with margin
hl.window_rule({
	match = { tag = "pip" },
	move = {
		"monitor_w-window_w-40",
		"monitor_h*0.04",
	},
})
