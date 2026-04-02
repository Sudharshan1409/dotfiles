-- todo-comments.nvim is a productivity tool that highlights and searches 
-- for TODO, FIXME, and other comment tags in your code. It enhances 
-- project navigation by making it easy to track pending tasks. Features 
-- include customizable tags, colors, and Telescope integration.
return {
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = "BufReadPost",
		opts = {
			-- configuration comes here
			-- or leave it empty to use the default settings
		},
	},
}
