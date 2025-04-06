local function setup_treesitter()
	local parsers = {
		"javascript",
		"typescript",
		"c",
		"lua",
		"vim",
		"vimdoc",
		"query",
		"python",
		"yaml",
		"go",
		"json",
		"html",
		"css",
		"bash",
		"dockerfile",
		"rust",
		"toml",
		"regex",
		"tsx",
		"htmldjango",
		"c_sharp",
		"markdown",
		"markdown_inline",
	}

	require("nvim-treesitter.configs").setup({
		ensure_installed = parsers,
		sync_install = false,
		auto_install = true,
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = true,
		},
		indent = {
			enable = true,
		},
	})

	require("nvim-treesitter.install").compilers = { "gcc", "clang", "clan" }
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = setup_treesitter,
	},
	{ "nvim-treesitter/playground" },
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
}
