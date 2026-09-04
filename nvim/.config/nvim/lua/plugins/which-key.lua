-- which-key.nvim is a productivity tool that displays a popup with 
-- available keybindings as you start typing. It improves discoverability 
-- of keymaps and simplifies complex command sequences. Features include 
-- automatic integration with Neovim and customizable layouts.
return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
}
