-- luacheck: globals vim
return {
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",

			"ThePrimeagen/git-worktree.nvim",
			"theprimeagen/harpoon",
		},
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")
			local Path = require("plenary.path")

			local custom_actions = {}
			require("telescope").load_extension("git_worktree")
			require("telescope").load_extension("harpoon")

			function custom_actions.fzf_multi_select(prompt_bufnr)
				local picker = action_state.get_current_picker(prompt_bufnr)
				local num_selections = #picker:get_multi_selection()

				if num_selections > 1 then
					for _, entry in ipairs(picker:get_multi_selection()) do
						vim.cmd(string.format("%s %s", ":e!", entry.value))
					end
					vim.cmd("stopinsert")
				else
					actions.file_edit(prompt_bufnr)
				end
			end

			-- Function to read .telescopeignore
			-- Function to read .telescopeignore
			local function read_telescopeignore()
				local ignore_patterns = {}
				local cwd = vim.loop.cwd()
				local path = Path:new(cwd, ".telescopeignore")

				if path:exists() and path:is_file() then
					for line in io.lines(path:absolute()) do
						-- Escape special characters for pattern matching
						line = line:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
						table.insert(ignore_patterns, "^" .. line .. "$") -- Anchor patterns to match the whole name
					end
					return ignore_patterns
				else
					return nil
				end
			end

			local function update_file_ignore_patterns()
				local ignore_patterns = read_telescopeignore()
				telescope.setup({
					defaults = {
						path_display = {
							filename_first = {
								reverse_directories = true,
							},
						},
						file_ignore_patterns = ignore_patterns or {},
						mappings = {
							i = {
								["<esc>"] = actions.close,
								["<C-j>"] = actions.move_selection_next,
								["<C-k>"] = actions.move_selection_previous,
								["<tab>"] = actions.toggle_selection + actions.move_selection_next,
								["<s-tab>"] = actions.toggle_selection + actions.move_selection_previous,
								["<cr>"] = custom_actions.fzf_multi_select,
								["<C-h>"] = actions.file_split,
								["<C-v>"] = actions.file_vsplit,
							},
							n = {
								["<esc>"] = actions.close,
								["<tab>"] = actions.toggle_selection + actions.move_selection_next,
								["<s-tab>"] = actions.toggle_selection + actions.move_selection_previous,
								["<cr>"] = custom_actions.fzf_multi_select,
								["<C-h>"] = actions.file_split,
								["<C-v>"] = actions.file_vsplit,
							},
						},
					},
				})
			end

			update_file_ignore_patterns()

			-- vim.keymap.set("n", "<leader>ff", function()
			-- 	update_file_ignore_patterns()
			-- 	builtin.find_files()
			-- end, { desc = "Find Files" })

			-- vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent Files" })
			-- vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "GREP Search" })
			-- vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
			vim.keymap.set("n", "<leader>fh", "<cmd>Telescope harpoon marks<cr>", { desc = "Harpoon Marks" })
			-- vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Find Git Files" })
			-- vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Find Keymaps" })
		end,
	},
	{
		"nvim-telescope/telescope-media-files.nvim",
		dependencies = {
			"nvim-lua/popup.nvim",
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("telescope").load_extension("media_files")
		end,
	},
}
