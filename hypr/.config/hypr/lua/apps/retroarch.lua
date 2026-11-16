-- -----------------------------------------------------------------------------
-- RetroArch
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		class = "^com\\.libretro\\.RetroArch$",
	},
	fullscreen = true,
	opacity = "1.0 override 1.0 override",
	idle_inhibit = "fullscreen",
})
