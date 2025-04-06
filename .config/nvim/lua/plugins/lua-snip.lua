-- luacheck: globals vim
return {
	"L3MON4D3/LuaSnip",
	-- follow latest release.
	version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
	-- install jsregexp (optional!).
	dependencies = {
		"rafamadriz/friendly-snippets",
		"saadparwaiz1/cmp_luasnip",
		"hrsh7th/nvim-cmp",
	},
	build = "make install_jsregexp",
	config = function()
		local ls = require("luasnip")

		-- ls.add_snippets("all", {
		--     s("ternary", {
		--         -- equivalent to "${1:cond} ? ${2:then} : ${3:else}"
		--         i(1, "cond"), t(" ? "), i(2, "then"), t(" : "), i(3, "else")
		--     }),
		-- })

		ls.config.set_config({
			enable_autosnippets = true,
			store_selection_keys = "<Tab>",
			update_events = "TextChanged,TextChangedI",
			ft_func = require("luasnip.extras.filetype_functions").from_cursor,
			-- Disable fs watchers to prevent errors
			region_check_events = "InsertEnter",
			delete_check_events = "InsertLeave",
		})

		vim.keymap.set({ "i", "s" }, "<c-j>", function()
			if ls.expand_or_jumpable() then
				ls.expand_or_jump()
			end
		end, { silent = true })

		vim.keymap.set({ "i", "s" }, "<c-k>", function()
			if ls.jumpable(-1) then
				ls.jump(-1)
			end
		end, { silent = true })

		vim.keymap.set({ "i" }, "<c-l>", function()
			if ls.choice_active() then
				ls.change_choice(1)
			end
		end)

		require("luasnip.loaders.from_vscode").lazy_load()
	end,
}
