-- grug-far.nvim is a powerful search and replace plugin that provides a 
-- user-friendly interface for project-wide modifications. It enhances 
-- productivity by simplifying complex find-and-replace tasks with 
-- features like real-time previews and prefilled searches.
return {
	{
		"MagicDuck/grug-far.nvim",
		config = function()
			require("grug-far").setup({})
		end,
		cmd = "GrugFar",
		keys = {
			{
				"<leader>sr",
				function()
					require("grug-far").open()
				end,
				desc = "Search and Replace (GrugFar)",
			},
			{
				"<leader>sw",
				function()
					require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
				end,
				desc = "Search and Replace Word (GrugFar)",
			},
		},
	},
}
