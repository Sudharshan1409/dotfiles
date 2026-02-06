return {
	{
		"sindrets/diffview.nvim",
		event = "VeryLazy",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff View Open" },
			{ "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diff View Close" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
		},
		config = function()
			require("diffview").setup({})
		end,
	},
}
