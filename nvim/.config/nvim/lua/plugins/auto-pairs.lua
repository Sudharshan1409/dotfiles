-- nvim-autopairs automatically closes brackets, quotes, and other pairs as you type.
-- It features Treesitter integration, space padding, and works seamlessly with nvim-cmp.
return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	dependencies = { "hrsh7th/nvim-cmp" },
	config = function()
		local npairs = require("nvim-autopairs")
		local Rule = require("nvim-autopairs.rule")
		local cond = require("nvim-autopairs.conds")

		npairs.setup({
			check_ts = true, -- enable treesitter integration
			ts_config = {
				lua = { "string" }, -- don't pair inside string treesitter node
				javascript = { "template_string" },
				java = false, -- don't check treesitter on java
			},
			-- Allow pairing even if followed by alphanumeric characters or punctuation
			ignored_next_char = "",
			-- Don't check for existing brackets on the same line so pairing always occurs
			enable_check_bracket_line = false,
			fast_wrap = {},
		})

		-- Auto-pad spaces inside pairs: e.g. { | } instead of {|}
		npairs.add_rules({
			Rule(" ", " ")
				:with_pair(function(opts)
					local pair = opts.line:sub(opts.col - 1, opts.col)
					return vim.tbl_contains({ "()", "[]", "{}" }, pair)
				end)
				:with_move(cond.none())
				:with_cr(cond.none())
				:with_del(function(opts)
					local col = vim.api.nvim_win_get_cursor(0)[2]
					local context = opts.line:sub(col - 1, col + 2)
					return vim.tbl_contains({ "(  )", "[  ]", "{  }" }, context)
				end),
		})

		-- Integrate with nvim-cmp
		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		local cmp = require("cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
	end,
}
