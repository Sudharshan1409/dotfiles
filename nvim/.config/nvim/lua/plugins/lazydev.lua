-- lazydev.nvim provides a specialized development environment for Neovim 
-- and Lua development. It enhances the coding experience by providing 
-- accurate types and completion for the Neovim API. Features include 
-- luvit-meta integration and automatic library management.
return {
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
        lazy = false,
        priority = 1000, -- Ensure it loads before lspconfig
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	{ "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
}
