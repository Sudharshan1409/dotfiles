-- luacheck: globals vim
return {
	"akinsho/toggleterm.nvim",
	config = function()
		local status_ok, toggleterm = pcall(require, "toggleterm")
		if not status_ok then
			return
		end

		toggleterm.setup({
			size = 20,
			open_mapping = [[<c-\>]],
			hide_numbers = true,
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			persist_size = true,
			direction = "float",
			close_on_exit = true,
			shell = vim.o.shell,
			float_opts = {
				border = "curved",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "Normal",
				},
			},
		})

		function _G.set_terminal_keymaps()
			local opts = { noremap = true }
			vim.api.nvim_buf_set_keymap(0, "t", "jk", [[<C-\><C-n>]], opts)
			vim.api.nvim_buf_set_keymap(0, "t", "kj", [[<C-\><C-n>]], opts)
		end

		vim.cmd([[autocmd TermOpen term://* lua set_terminal_keymaps()]])

		local terminal = require("toggleterm.terminal").Terminal
		local lazygit = terminal:new({ cmd = "lazygit", hidden = true })

		function _LAZYGIT_TOGGLE()
			lazygit:toggle()
		end

		local node = terminal:new({ cmd = "node", hidden = true })

		function _NODE_TOGGLE()
			node:toggle()
		end

		local python = terminal:new({ cmd = "python3", hidden = true })

		function _PYTHON_TOGGLE()
			python:toggle()
		end

		local ncdu = terminal:new({ cmd = "ncdu", hidden = true })

		function _NCDU_TOGGLE()
			ncdu:toggle()
		end

		-- vim.api.nvim_set_keymap("n", "<leader>gg", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>nn", "<cmd>lua _NODE_TOGGLE()<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>du", "<cmd>lua _NCDU_TOGGLE()<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>py", "<cmd>lua _PYTHON_TOGGLE()<CR>", { noremap = true, silent = true })
		----ToggleTerm
		--t = {
		--    name = "Terminal",
		--    n = { "<cmd>lua _NODE_TOGGLE()<cr>", "Node" },
		--    t = { "<cmd>lua _HTOP_TOGGLE()<cr>", "Htop" },
		--    p = { "<cmd>lua _PYTHON_TOGGLE()<cr>", "Python" },
		--    f = { "<cmd>ToggleTerm direction=float<cr>", "Float" },
		--    h = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", "Horizontal" },
		--    v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
		--}
	end,
}
