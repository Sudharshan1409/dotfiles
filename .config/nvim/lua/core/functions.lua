-- luacheck: globals vim
local M = {}

function M.search_and_replace_dynamic()
	-- Ask the user to input the number of lines
	local number_of_lines = vim.fn.input("Enter number of lines: ")

	-- Check if a valid number of lines is provided
	if tonumber(number_of_lines) then
		-- Construct the command for substitution
		local command =
			string.format(":.,+%ds/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", tonumber(number_of_lines))

		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(command, true, true, true), "n", true)
	else
		print("Invalid input. Please provide a number.")
	end
end

function M.change_function_name()
	local ts_utils = require("nvim-treesitter.ts_utils")
	local node = ts_utils.get_node_at_cursor()

	while node do
		if
			node:type() == "function_definition"
			or node:type() == "function_declaration"
			or node:type() == "method_definition"
			or node:type() == "arrow_function"
		then
			local name_node = node:child(1) -- Assuming the name is the second child
			if name_node then
				local start_row, start_col, end_row, end_col = name_node:range()
				-- Delete the function name
				vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { "" })
				-- Move the cursor to the start of the function name
				vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
				-- Enter insert mode
				vim.api.nvim_feedkeys("i", "n", true)
			end
			return
		end
		node = node:parent()
	end

	print("No function definition found under or after the cursor.")
end

-- Ensure the keymap is set correctly
vim.api.nvim_set_keymap(
	"n",
	"cfn",
	':lua require("core.functions").change_function_name()<CR>',
	{ noremap = true, silent = true, expr = false }
)

-- Return the module table
return M
