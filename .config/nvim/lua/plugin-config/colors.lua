-- luacheck: globals vim
local M = {}

function M.changeTheme(color)
	local colors = {
		"gruvbox",
		"nord",
		"onedark",
		"dracula-soft",
	}
	color = color or "dracula-soft"
	vim.cmd("colorscheme " .. color)

	local normal_hl = vim.api.nvim_get_hl_by_name("Normal", true)
	local normal_float_hl = vim.api.nvim_get_hl_by_name("NormalFloat", true)

	normal_hl.background = "none"
	normal_float_hl.background = "none"

	vim.api.nvim_set_hl(0, "Normal", normal_hl)
	vim.api.nvim_set_hl(0, "NormalFloat", normal_float_hl)

	-- Highlight current line with a custom color (dimmer)
	vim.cmd("highlight CursorLine cterm=NONE ctermbg=236 guibg=#2E323C")
end

M.changeTheme()

vim.keymap.set("n", "<leader>cs", "<cmd>lua ColorTheme()<cr>", { noremap = true, silent = true })
