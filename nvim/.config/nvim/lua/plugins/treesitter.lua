-- nvim-treesitter provides an interface to use tree-sitter library in 
-- Neovim. It is essential for advanced syntax highlighting, indentation, 
-- and code navigation. Features include fast parsing, support for 
-- numerous languages, and a powerful text objects extension.
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
		textobjects = {
			select = {
				enable = true,
				lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
				keymaps = {
					-- You can use the capture groups defined in textobjects.scm
					["aa"] = "@parameter.outer",
					["ia"] = "@parameter.inner",
					["af"] = "@function.outer",
					["if"] = "@function.inner",
					["ac"] = "@class.outer",
					["ic"] = "@class.inner",
				},
			},
			move = {
				enable = true,
				set_jumps = true, -- whether to set jumps in the jumplist
				goto_next_start = {
					["]m"] = "@function.outer",
					["]]"] = "@class.outer",
				},
				goto_next_end = {
					["]M"] = "@function.outer",
					["]["] = "@class.outer",
				},
				goto_previous_start = {
					["[m"] = "@function.outer",
					["[["] = "@class.outer",
				},
				goto_previous_end = {
					["[M"] = "@function.outer",
					["[]"] = "@class.outer",
				},
			},
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
