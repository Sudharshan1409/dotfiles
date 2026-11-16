local commands = {
	downloads = "nautilus ~/Downloads",
	backgrounds = "nautilus ~/.config/backgrounds",
	home = "nautilus ~",
	menu = 'rofi -show drun -show-icons -display-drune "Apps" -theme ~/.config/rofi/launcher-elegant.rasi',
}

local apps = {
	terminal = "ghostty",
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
