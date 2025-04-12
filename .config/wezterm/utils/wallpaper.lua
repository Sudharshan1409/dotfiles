local wezterm = require("wezterm")
local h = require("utils/helpers")
local M = {}

M.get_wallpaper = function(dir)
	local wallpapers = {}
	for _, v in ipairs(wezterm.glob(dir)) do
		if not string.match(v, "%.DS_Store$") then
			table.insert(wallpapers, v)
		end
	end
	local wallpaper = h.get_random_entry(wallpapers)
	-- Log the selected wallpaper to a file
	local log_file_path = os.getenv("HOME") .. "/wezterm-wallpaper_log.txt"
	local log_file = io.open(log_file_path, "a")
	if log_file then
		log_file:write(wallpaper .. "\n")
		log_file:close()
	end
	return {
		source = { File = { path = wallpaper } },
		height = "Cover",
		width = "Cover",
		horizontal_align = "Center",
		repeat_x = "Repeat",
		repeat_y = "Repeat",
		opacity = 1,
		-- speed = 200,
	}
end

M.set_nvim_wallpaper = function(dir, name)
	return {
		source = { File = { path = os.getenv("HOME") .. "/.config/wezterm/wallpapers/nvim/" .. name } },
		height = "Cover",
		width = "Cover",
		horizontal_align = "Center",
		repeat_x = "Repeat",
		repeat_y = "Repeat",
		opacity = 1,
		-- speed = 200,
	}
end

M.set_tmux_session_wallpaper = function(value)
	local path = os.getenv("HOME") .. "/.config/wezterm/wallpapers/sessions/" .. value .. ".jpeg"
	print(path)
	return {
		source = { File = { path = path } },
		height = "Cover",
		width = "Cover",
		horizontal_align = "Center",
		repeat_x = "Repeat",
		repeat_y = "Repeat",
		opacity = 1,
		-- speed = 200,
	}
end

return M
