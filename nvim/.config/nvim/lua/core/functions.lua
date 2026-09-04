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

-- Required for creating directories and files
local fn = vim.fn

-- Function to create a file in a directory named after the current working directory
function M.create_file_in_cwd_directory()
	-- Prompt for file name
	local file_name = fn.input("Enter file name (with extension): ")
	if file_name == "" then
		print("No file name provided.")
		return
	end

	-- Get the current working directory name
	local cwd = fn.fnamemodify(fn.getcwd(), ":t")

	-- Construct the path
	local dir_path = fn.expand("~/.nvimfiles/") .. cwd
	local file_path = dir_path .. "/" .. file_name

	-- Create the directory if it doesn't exist
	if fn.isdirectory(dir_path) == 0 then
		fn.mkdir(dir_path, "p")
	end

	-- Create the file
	fn.writefile({}, file_path)
	print("Created file: " .. file_path)

	-- Open the file in a buffer for editing
	vim.cmd("edit " .. file_path)
end

-- Keymap to create a file in a directory named after the current working directory
vim.keymap.set(
	"n",
	"<leader>tf",
	':lua require("core.functions").create_file_in_cwd_directory()<CR>',
	{ desc = "Create file in CWD directory" }
)

-- Return the module table
return M
