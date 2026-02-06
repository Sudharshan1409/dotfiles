return {
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy",
		priority = 1000,
		enabled = false,
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		opts = { diagnostics = { virtual_text = false } },
	},
}
