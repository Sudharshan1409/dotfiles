-- ============================================================
-- DYNAMIC CAELESTIA PALETTE (FALLBACK TO CATPPUCCIN MOCHA)
-- ============================================================

local ok, scheme = pcall(dofile, (os.getenv("HOME") or "") .. "/.config/hypr/scheme/current.lua")
local active_c1 = ok and scheme and scheme.primary and ("rgba(" .. scheme.primary .. "ee)") or "rgba(cba6f7ee)"
local active_c2 = ok and scheme and scheme.tertiary and ("rgba(" .. scheme.tertiary .. "ee)") or "rgba(89b4faee)"
local inactive_c = ok and scheme and scheme.outlineVariant and ("rgba(" .. scheme.outlineVariant .. "aa)") or "rgba(595959aa)"
local shadow_c = ok and scheme and scheme.shadow and ("rgba(" .. scheme.shadow .. "ee)") or "rgba(1a1a1aee)"

-- ============================================================
-- GENERAL LAYOUT PROPERTIES
-- ============================================================

hl.config({

	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 3,

		col = {
			active_border = {
				colors = {
					active_c1,
					active_c2,
				},
				angle = 45,
			},

			inactive_border = inactive_c,
		},

		layout = "dwindle",
		allow_tearing = false,
	},

	-- ========================================================
	-- DWINDLE LAYOUT
	-- ========================================================

	dwindle = {
		preserve_split = true,
		smart_split = false,
		force_split = 2,
	},

	-- ========================================================
	-- DECORATIONS
	-- ========================================================

	decoration = {
		rounding = 6,

		blur = {
			enabled = true,
			size = 3,
			passes = 3,
		},

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = shadow_c,
		},
	},

	-- ========================================================
	-- GROUP CONFIGURATION
	-- ========================================================

	group = {

		col = {
			border_active = {
				colors = {
					active_c1,
					active_c2,
				},
				angle = 45,
			},

			border_inactive = inactive_c,
		},

		groupbar = {
			font_size = 12,
			font_family = "monospace",

			font_weight_active = "ultraheavy",
			font_weight_inactive = "normal",

			indicator_height = 0,
			indicator_gap = 5,

			height = 22,
			gaps_in = 5,
			gaps_out = 0,

			text_color = "rgb(ffffff)",
			text_color_inactive = "rgba(ffffff90)",

			col = {
				active = "rgba(00000040)",
				inactive = "rgba(00000020)",
			},

			gradients = true,
			gradient_rounding = 0,
			gradient_round_only_edges = false,
		},
	},

	-- ========================================================
	-- XWAYLAND
	-- ========================================================

	xwayland = {
		force_zero_scaling = true,
	},

	-- ========================================================
	-- MISCELLANEOUS
	-- ========================================================

	misc = {
		force_default_wallpaper = 0,
		focus_on_activate = true,

		enable_swallow = true,
		swallow_regex = [[^(com\.mitchellh\.ghostty)$]],
	},
})

-- ============================================================
-- ANIMATION CURVES
-- ============================================================

hl.curve("easeOutQuint", {
	type = "bezier",
	points = {
		{ 0.23, 1 },
		{ 0.32, 1 },
	},
})

hl.curve("easeInOutCubic", {
	type = "bezier",
	points = {
		{ 0.65, 0.05 },
		{ 0.36, 1 },
	},
})

hl.curve("linear", {
	type = "bezier",
	points = {
		{ 0, 0 },
		{ 1, 1 },
	},
})

hl.curve("almostLinear", {
	type = "bezier",
	points = {
		{ 0.5, 0.5 },
		{ 0.75, 1.0 },
	},
})

hl.curve("quick", {
	type = "bezier",
	points = {
		{ 0.15, 0 },
		{ 0.1, 1 },
	},
})

-- ============================================================
-- ANIMATIONS
-- ============================================================

-- Global animations

hl.animation({
	leaf = "global",
	enabled = true,
	speed = 10,
	bezier = "default",
})

-- Border

hl.animation({
	leaf = "border",
	enabled = true,
	speed = 5.39,
	bezier = "easeOutQuint",
})

-- Windows

hl.animation({
	leaf = "windows",
	enabled = true,
	speed = 4.79,
	bezier = "easeOutQuint",
})

-- Window opening

hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 4.1,
	bezier = "easeOutQuint",
	style = "popin 87%",
})

-- Window closing

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 1.49,
	bezier = "linear",
	style = "popin 87%",
})

-- Fade animations

hl.animation({
	leaf = "fadeIn",
	enabled = true,
	speed = 1.73,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fadeOut",
	enabled = true,
	speed = 1.46,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = 3.03,
	bezier = "quick",
})

-- Layer animations

hl.animation({
	leaf = "layers",
	enabled = true,
	speed = 3.81,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "layersIn",
	enabled = true,
	speed = 4,
	bezier = "easeOutQuint",
	style = "fade",
})

hl.animation({
	leaf = "layersOut",
	enabled = true,
	speed = 1.5,
	bezier = "linear",
	style = "fade",
})

hl.animation({
	leaf = "fadeLayersIn",
	enabled = true,
	speed = 1.79,
	bezier = "almostLinear",
})

hl.animation({
	leaf = "fadeLayersOut",
	enabled = true,
	speed = 1.39,
	bezier = "almostLinear",
})

-- Workspace animations were disabled in your original config.

hl.animation({
	leaf = "workspaces",
	enabled = false,
})

-- ============================================================
-- CAELESTIA LAYER RULES
-- ============================================================

-- Let Caelestia handle its own Material 3 QML animations without compositor fade
hl.layer_rule({
	match = {
		namespace = "^caelestia-.*$",
	},
	no_anim = true,
})
