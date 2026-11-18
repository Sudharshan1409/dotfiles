-- #######################################################################################
-- WINDOW RULES
-- #######################################################################################

-- -----------------------------------------------------------------------------
-- Global behavior
-- -----------------------------------------------------------------------------

-- Suppress maximize requests to keep windows tiled
hl.window_rule({
	match = {
		class = ".*",
	},
	suppress_event = "maximize",
})

-- Default subtle opacity
hl.window_rule({
	match = {
		class = ".*",
	},
	opacity = "0.97 0.9",
})

-- Fix dragging / focus issues with XWayland ghost windows
hl.window_rule({
	match = {
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
		class = "^$",
		title = "^$",
	},
	no_focus = true,
})

-- -----------------------------------------------------------------------------
-- Fix borders / shadows / blur on popups & dialogs
-- -----------------------------------------------------------------------------

-- XDG portal dialogs (Save As / Open File)
hl.window_rule({
	match = {
		class = "^(Xdg-desktop-portal-gtk)$",
	},
	border_size = 0,
	no_shadow = true,
	no_blur = true,
})

-- Brave browser menus & popups (XWayland floating)
hl.window_rule({
	match = {
		class = "^(Brave-browser)$",
		float = true,
		xwayland = true,
	},
	border_size = 0,
	no_shadow = true,
	no_blur = true,
})

-- -----------------------------------------------------------------------------
-- Floating windows
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		class = "^(Rofi|org\\.gnome\\.Calculator|blueberry\\.py|org\\.kde\\.polkit-kde-authentication-agent-1|com\\.cisco\\.secureclient\\.gui|hyprland-share-picker)$",
	},
	float = true,
})

-- System monitor popups (htop, nvtop in Ghostty)
hl.window_rule({
	match = {
		class = "^(com\\.mitchellh\\.ghostty)$",
		title = "^(htop|nvtop)$",
	},
	float = true,
})

-- -----------------------------------------------------------------------------
-- Size & centering for floating windows
-- -----------------------------------------------------------------------------

-- System monitor sizing & centering
hl.window_rule({
	match = {
		class = "^(com\\.mitchellh\\.ghostty)$",
		title = "^(htop|nvtop)$",
	},
	size = { 1400, 900 },
	center = true,
})

-- -----------------------------------------------------------------------------
-- Animations
-- -----------------------------------------------------------------------------

-- Rofi dropdown animation
hl.window_rule({
	match = {
		class = "^Rofi$",
	},
	animation = "slide-down",
})

-- -----------------------------------------------------------------------------
-- Catch invalid empty-class windows
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		class = "^$",
		title = "^$",
	},
	no_blur = true,
})

-- -----------------------------------------------------------------------------
-- App-specific rules
-- -----------------------------------------------------------------------------

-- Import app-specific rules from a separate Lua file.
dofile(os.getenv("HOME") .. "/.config/hypr/lua/apps-config.lua")
