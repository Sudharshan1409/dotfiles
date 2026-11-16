-- -----------------------------------------------------------------------------
-- Webcam overlay for screen recording
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		title = "^WebcamOverlay$",
	},
	float = true,
	pin = true,
})

-- Do not steal focus when it appears
hl.window_rule({
	match = {
		title = "^WebcamOverlay$",
	},
	no_initial_focus = true,
})

-- Do not dim background
hl.window_rule({
	match = {
		title = "^WebcamOverlay$",
	},
	no_dim = true,
})

-- Position bottom-right with margin
hl.window_rule({
	match = {
		title = "^WebcamOverlay$",
	},
	move = {
		"monitor_w-window_w-40",
		"monitor_h-window_h-40",
	},
})
