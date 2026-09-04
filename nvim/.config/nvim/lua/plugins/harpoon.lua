-- harpoon allows you to mark and quickly switch between frequently used files. 
-- It enhances productivity by reducing the time spent searching for files 
-- in your project. Key features include marking files, a quick menu for 
-- selection, and direct navigation keys.
-- luacheck: globals vim
return {
	"theprimeagen/harpoon",
	config = function()
		local mark = require("harpoon.mark")
		local ui = require("harpoon.ui")

		vim.keymap.set("n", "<leader>ha", mark.add_file)
		vim.keymap.set("n", "<leader>ho", ui.toggle_quick_menu)
		vim.keymap.set("n", "<leader>hn", ui.nav_next)
		vim.keymap.set("n", "<leader>hp", ui.nav_prev)
	end,
}
