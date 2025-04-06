-- luacheck: globals vim
local snacksUtils = require("utils.snacks-utils")
return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	enabled = true,
	---@type snacks.Config
	opts = snacksUtils.opts,
	keys = snacksUtils.keys,
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				-- Setup some globals for debugging (lazy-loaded)
				_G.dd = function(...)
					require("snacks").debug.inspect(...)
				end
				_G.bt = function()
					require("snacks").debug.backtrace()
				end
				vim.print = _G.dd -- Override print to use snacks for `:=` command

				-- Create some toggle mappings
				require("snacks").toggle.option("spell", { name = "Spelling" }):map("<leader>us")
				require("snacks").toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
				require("snacks").toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>ul")
				require("snacks").toggle.diagnostics():map("<leader>ud")
				require("snacks").toggle
					.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
					:map("<leader>uc")
				require("snacks").toggle.treesitter():map("<leader>uT")
				require("snacks").toggle
					.option("background", { off = "light", on = "dark", name = "Dark Background" })
					:map("<leader>ub")
				require("snacks").toggle.inlay_hints():map("<leader>uh")
				require("snacks").toggle.indent():map("<leader>ug")
				require("snacks").toggle.dim():map("<leader>uD")
			end,
		})
	end,
}
