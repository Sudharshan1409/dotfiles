-- before.nvim tracks your edit history and allows you to jump back and forth 
-- between recent edits. It enhances productivity by providing quick access 
-- to previously modified locations. Features include jump history, 
-- quickfix integration, and Telescope support.
-- luacheck: globals vim
return {
	"bloznelis/before.nvim",
	config = function()
		local before = require("before")
		before.setup({
			history_size = 50,
			history_wrap_enabled = true,
		})

		-- Jump to previous entry in the edit history
		vim.keymap.set("n", "<leader>ep", before.jump_to_last_edit, {})

		-- Jump to next entry in the edit history
		vim.keymap.set("n", "<leader>ea", before.jump_to_next_edit, {})

		-- Look for previous edits in quickfix list
		vim.keymap.set("n", "<leader>eq", before.show_edits_in_quickfix, {})

		-- You can provide telescope opts to the picker as show_edits_in_telescope argument:
		vim.keymap.set("n", "<leader>et", function()
			before.show_edits_in_telescope(require("telescope.themes").get_dropdown())
		end, {})
	end,
}
