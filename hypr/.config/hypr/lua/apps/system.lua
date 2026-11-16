-- -----------------------------------------------------------------------------
-- Floating windows (tag-driven)
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = { tag = "floating-window" },
	float = true,
})

hl.window_rule({
	match = { tag = "floating-window" },
	center = true,
})

hl.window_rule({
	match = { tag = "floating-window" },
	size = { 800, 600 },
})

-- -----------------------------------------------------------------------------
-- Tag windows that should float
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		class = "(blueberry\\.py|Impala|Wiremix|org\\.gnome\\.NautilusPreviewer|com\\.gabm\\.satty|swappy|Omarchy|About|TUI\\.float)",
	},
	tag = "+floating-window",
})

-- Quick FZF Finder (large centered modal)
hl.window_rule({
	match = {
		title = "^(Quick-FZF-Finder)$",
	},
	float = true,
	center = true,
})

hl.window_rule({
	match = {
		class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org\\.gnome\\.Nautilus)",
		title = "^(Open.*Files?|Open [Ff]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to (open|save).*|[Cc]hoose.*)$",
	},
	tag = "+floating-window",
})

-- Calculator always floats
hl.window_rule({
	match = {
		class = "^org\\.gnome\\.Calculator$",
	},
	float = true,
})

-- -----------------------------------------------------------------------------
-- Fullscreen screensaver
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		class = "^Screensaver$",
	},
	fullscreen = true,
})

-- -----------------------------------------------------------------------------
-- Media apps should never be transparent
-- -----------------------------------------------------------------------------

hl.window_rule({
	match = {
		class = "^(zoom|vlc|mpv|org\\.kde\\.kdenlive|com\\.obsproject\\.Studio|com\\.github\\.PintaProject\\.Pinta|imv|org\\.gnome\\.NautilusPreviewer)$",
	},
	opacity = "1.0 override 1.0 override",
})
