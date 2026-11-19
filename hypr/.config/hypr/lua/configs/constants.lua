local commands = {
	downloads = "env -u GTK_THEME nautilus ~/Downloads",
	backgrounds = "env -u GTK_THEME nautilus ~/.config/backgrounds",
	home = "env -u GTK_THEME nautilus ~",
	menu = "caelestia shell drawers toggle launcher",
}

local apps = {
	terminal = "env -u GTK_THEME ghostty",
}

local buttons = {
	mainMod = "SUPER",
	alt = "ALT",
	ctrl = "CTRL",
	rtn = "RETURN",
	shift = "SHIFT",
	space = "SPACE",
	tab = "TAB",
	grave = "GRAVE",
	print = "PRINT",
	mouseLeft = "mouse:272",
	mouseRight = "mouse:273",
}

return {
	commands = commands,
	apps = apps,
	buttons = buttons,
}
