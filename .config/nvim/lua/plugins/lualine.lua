return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		{
			"nvim-tree/nvim-web-devicons",
			opt = true,
		},
		"folke/noice.nvim",
	},
	config = function()
        -- Bubbles config for lualine
-- Author: lokesh-krishna
-- MIT license, see LICENSE for more details.

-- stylua: ignore
local colors = {
    blue   = '#80a0ff',
    cyan   = '#79dac8',
    black  = '#080808',
    white  = '#c6c6c6',
    red    = '#ff5189',
    violet = '#d183e8',
    grey   = '#303030',
}

		local bubbles_theme = {
			normal = {
				a = { fg = colors.black, bg = colors.violet },
				b = { fg = colors.white, bg = colors.grey },
				c = { fg = colors.black, bg = colors.black },
			},

			insert = { a = { fg = colors.black, bg = colors.blue } },
			visual = { a = { fg = colors.black, bg = colors.cyan } },
			replace = { a = { fg = colors.black, bg = colors.red } },

			inactive = {
				a = { fg = colors.white, bg = colors.black },
				b = { fg = colors.white, bg = colors.black },
				c = { fg = colors.black, bg = colors.black },
			},
		}

		require("lualine").setup({
			options = {
				theme = bubbles_theme,
				component_separators = "|",
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = {
					{ "mode", separator = { left = "" }, right_padding = 2 },
				},
				lualine_b = {
					"branch",
					{
						"diff",
						symbols = { added = " ", modified = " ", removed = " " },
					},
				},
				lualine_c = {
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },
						symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " },
					},
					"filename",
				},
				lualine_x = {
					{
						require("lazy.status").updates,
						cond = require("lazy.status").has_updates,
						color = { fg = "#ff9e64" },
					},
					{
						require("noice").api.statusline.mode.get,
						cond = require("noice").api.statusline.mode.has,
						color = { fg = "#ff9e64" },
					},
					{
						function()
							local harpoon = require("harpoon.mark")
							local total_marks = harpoon.get_length()
							if total_marks == 0 then
								return ""
							end
							local current_mark = "—"
							-- Use standard vim modifier ":." to get path relative to CWD
							local filename = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
							for i = 1, total_marks do
								local mark_filename = harpoon.get_marked_file_name(i)
								if mark_filename and mark_filename == filename then
									current_mark = tostring(i)
									break
								end
							end
							return "󱡁 " .. current_mark .. "/" .. total_marks
						end,
						color = { fg = "#d183e8", gui = "bold" },
					},
				},
				lualine_y = {
					{
						function()
							local msg = "No Active Lsp"
							local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
							local clients = vim.lsp.get_clients()
							if next(clients) == nil then
								return msg
							end
							for _, client in ipairs(clients) do
								local filetypes = client.config.filetypes
								if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
									return client.name
								end
							end
							return msg
						end,
						icon = " ",
						color = { fg = "#ffffff", gui = "bold" },
					},
					"filetype",
					"progress",
				},
				lualine_z = {
					{ "location", separator = { right = "" }, left_padding = 2 },
				},
			},
			inactive_sections = {
				lualine_a = { "filename" },
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = { "location" },
			},
			tabline = {},
			extensions = {},
		})
	end,
}
