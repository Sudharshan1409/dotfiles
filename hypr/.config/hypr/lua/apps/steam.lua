-- -----------------------------------------------------------------------------
-- Steam
-- -----------------------------------------------------------------------------

-- Float all Steam windows
hl.window_rule({
	match = {
		class = "^steam$",
	},
	float = true,
})

-- Center main Steam window
hl.window_rule({
	match = {
		class = "^steam$",
		title = "^Steam$",
	},
	center = true,
})

-- Ensure Steam is always fully opaque
hl.window_rule({
	match = {
		class = "^steam$",
	},
	opacity = "1.0 override 1.0 override",
})

-- Sizes for specific Steam windows
hl.window_rule({
	match = {
		class = "^steam$",
		title = "^Steam$",
	},
	size = { 1100, 700 },
})

hl.window_rule({
	match = {
		class = "^steam$",
		title = "^Friends List$",
	},
	size = { 460, 800 },
})

-- Prevent idle / screen blanking when Steam goes fullscreen (e.g. games)
hl.window_rule({
	match = {
		class = "^steam$",
	},
	idle_inhibit = "fullscreen",
})
