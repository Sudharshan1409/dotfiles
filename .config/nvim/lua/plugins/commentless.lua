-- commentless.nvim is a productivity tool that allows you to easily toggle 
-- comments in your code. It leverages Treesitter for context-aware 
-- commenting, ensuring that the correct comment syntax is used for 
-- different languages and nested sections.
return {
	"soemre/commentless.nvim",
	cmd = "Commentless",
	keys = {
		{
			"<leader>c",
			function()
				require("commentless").toggle()
			end,
			desc = "Toggle Comments",
		},
	},
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		-- Customize Configuration
	},
}
