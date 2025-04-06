-- luacheck: globals vim
local basicUtils = require("utils.basic")
return {
	"nvim-lua/plenary.nvim",
	{
		"mbbill/undotree",
		config = function()
			vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
		end,
	},
	"airblade/vim-rooter",
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end,
	},
	"ThePrimeagen/vim-with-me",
	"ThePrimeagen/vim-be-good",
	"eandrju/cellular-automaton.nvim",
	{ "mg979/vim-visual-multi", branch = "master" },
	"andymass/vim-matchup",
	"godlygeek/tabular",
	"preservim/vim-markdown",

	-- "ericbn/vim-relativize",
	-- "chase/vim-ansible-yaml",

	{
		"numToStr/Comment.nvim",
		opts = {
			-- add any options here
		},
	},
	"ryanoasis/vim-devicons",

	-- These optional plugins should be loaded directly because of a bug in Packer lazy loading
	"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
	"romgrk/barbar.nvim", -- OPTIONAL: for buffer tabline
	"christoomey/vim-tmux-navigator",
	"petertriho/nvim-scrollbar",
	"zyedidia/vim-snake",
	"sharkdp/fd",
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"mfussenegger/nvim-dap",
			"mfussenegger/nvim-dap-python", --optional
			{ "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
		},
		lazy = false,
		branch = "regexp", -- This is the regexp branch, use this for the new version
		config = function()
			require("venv-selector").setup()
		end,
		keys = {
			{ ",v", "<cmd>VenvSelect<cr>" },
		},
	},

	{
		"HiPhish/nvim-ts-rainbow2",
	},
	"alvan/vim-closetag",
	{
		"anuvyklack/pretty-fold.nvim",
		config = function()
			require("pretty-fold").setup()
		end,
	},
	{
		"Wansmer/treesj",
		keys = { "<leader>m", "<CMD>TSJToggle<CR>", desc = "Toggle treesitter highlight" },
		cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = { use_default_keybindings = false },
		config = function()
			require("treesj").setup({
				max_join_length = 5000,
			})
		end,
	},
	{
		"simrat39/symbols-outline.nvim",
		config = function()
			require("symbols-outline").setup(basicUtils.symbols_opts)
		end,
	},
	-- lazy.nvim
	{ "kosayoda/nvim-lightbulb" },
	{
		"f-person/git-blame.nvim",
		event = "VeryLazy",
		opts = {
			enabled = true,
			message_template = " <summary> 󰃶 <date>  <author>", -- Better author icon
			date_format = "%d-%m-%Y %H:%M:%S",
			virtual_text_column = 5,
			message_when_not_committed = "⚠️  Uncommitted changes!",
			highlight_group = "Comment",
			use_blame_commit_file_urls = true,
		},
	},
	{
		"VVoruganti/today.nvim",
		config = function()
			require("today").setup({
				local_root = "~/.notes",
			})
			vim.keymap.set(
				"n",
				"<leader>nt",
				":Today<CR>",
				{ noremap = true, silent = true, desc = "Open today's note" }
			)
		end,
	},
	-- Lazy.nvim
	{
		"windwp/nvim-ts-autotag",
		opts = {},
		event = "InsertEnter",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
}
