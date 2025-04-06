-- luacheck: globals vim
return {
	{

		"lewis6991/gitsigns.nvim",
		"tpope/vim-fugitive",
		config = function()
			-- vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
			-- vim.keymap.set("n", "<leader>gd", vim.cmd.Gdiffsplit)
			vim.keymap.set("n", "<leader>ga", "<cmd>Git add .<cr>")
			vim.keymap.set("n", "<leader>gcm", "<cmd>Git commit<cr>")
			vim.keymap.set("n", "<leader>gp", "<cmd>lua GitPush()<cr>")
			vim.keymap.set("n", "<leader>gra", "<cmd>lua GitRemoteAdd()<cr>")
			-- vim.keymap.set("n", "<leader>gl", "<cmd>Git log --show-signature<cr>")
			local status_ok, gitsigns = pcall(require, "gitsigns")
			if not status_ok then
				return
			end

			gitsigns.setup({
				signs = {
					add = { text = "┃" },
					change = { text = "┃" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
				numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
				linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
				word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
				watch_gitdir = {
					follow_files = true,
				},
				auto_attach = true,
				attach_to_untracked = false,
				current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
				current_line_blame_opts = {
					virt_text = true,
					virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
					delay = 1000,
					ignore_whitespace = false,
					virt_text_priority = 100,
				},
				current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
				sign_priority = 6,
				update_debounce = 100,
				status_formatter = nil, -- Use default
				max_file_length = 40000, -- Disable if file is longer than this (in lines)
				preview_config = {
					-- Options passed to nvim_open_win
					border = "single",
					style = "minimal",
					relative = "cursor",
					row = 0,
					col = 1,
				},
			})
		end,
	},
	{
		"ThePrimeagen/git-worktree.nvim",
		config = function()
			local Worktree = require("git-worktree")

			-- op = Operations.Switch, Operations.Create, Operations.Delete
			-- metadata = table of useful values (structure dependent on op)
			--      Switch
			--          path = path you switched to
			--          prev_path = previous worktree path
			--      Create
			--          path = path where worktree created
			--          branch = branch name
			--          upstream = upstream remote name
			--      Delete
			--          path = path where worktree deleted

			Worktree.on_tree_change(function(op, metadata)
				if op == Worktree.Operations.Switch then
					print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
				end
			end)

			CREATE_WORKTREE = function()
				local branch = vim.fn.input("Enter Branch Name:")
				vim.cmd("Git worktree add " .. branch)
				print("Created worktree for " .. branch)
			end
		end,
	},
}
