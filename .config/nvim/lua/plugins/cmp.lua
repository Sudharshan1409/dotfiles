-- Autocompletion
return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-buffer", -- source for text in buffer
		"hrsh7th/cmp-path", -- source for file system path
		"L3MON4D3/LuaSnip", -- snippet engine
		"hrsh7th/cmp-nvim-lsp",
		"saadparwaiz1/cmp_luasnip", -- for autocompletion
		"rafamadriz/friendly-snippets", -- useful snippets
	},
	config = function()
		-- Here is where you configure the autocompletion settings.
		local lsp_zero = require("lsp-zero")
		lsp_zero.extend_cmp()

		-- And you can configure cmp even more, if you want to.
		local cmp = require("cmp")
		local cmp_action = lsp_zero.cmp_action()
		require("luasnip.loaders.from_vscode").lazy_load()

		cmp.setup({
			completion = {
				completeopt = "menu,menuone,preview,noselect",
			},
			sources = {
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "buffer" },
				{ name = "path" },
			},
			mapping = {
				["<C-y>"] = cmp.mapping.confirm({ select = false }),
				["<CR>"] = cmp.mapping.confirm({ select = false }),
				["<C-e>"] = cmp.mapping.abort(),
				["<Up>"] = cmp.mapping.select_prev_item({ behavior = "select" }),
				["<Down>"] = cmp.mapping.select_next_item({ behavior = "select" }),
				["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
				["<C-p>"] = cmp.mapping(function()
					if cmp.visible() then
						cmp.select_prev_item({ behavior = "insert" })
					else
						cmp.complete()
					end
				end),
				["<C-n>"] = cmp.mapping(function()
					if cmp.visible() then
						cmp.select_next_item({ behavior = "insert" })
					else
						cmp.complete()
					end
				end),
			},
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},
		})
	end,
}
