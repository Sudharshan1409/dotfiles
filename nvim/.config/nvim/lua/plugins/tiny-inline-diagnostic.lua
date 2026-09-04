-- tiny-inline-diagnostic.nvim provides a modern and less intrusive way to 
-- display LSP diagnostics. It enhances the UI by showing diagnostics 
-- directly in the line of code. Features include customizable diagnostic 
-- signs and integration with nvim-lspconfig.
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
