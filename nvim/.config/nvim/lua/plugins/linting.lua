-- nvim-lint provides asynchronous linting support for various languages. 
-- It enhances the coding experience by identifying potential errors and 
-- style issues in real-time. Features include custom linter configurations 
-- and integration with Mason for easy tool management.
-- luacheck: globals vim
return {
	"mfussenegger/nvim-lint",
	event = {
		"BufReadPre",
		"BufNewFile",
	},
	config = function()
		local lint = require("lint")
		lint.linters_by_ft = {
			-- python = { "ruff" }, -- Disabled: Using pylsp only
			sh = { "shellcheck" },
		}

		-- Configure ruff linter to use line-length 100
		local ruff = lint.linters.ruff
		-- Explicitly set path to mason binary
		ruff.cmd = vim.fn.stdpath("data") .. "/mason/bin/ruff"
		ruff.args = {
			"check",
			"--force-exclude",
			"--quiet",
			"--stdin-filename",
			function()
				return vim.api.nvim_buf_get_name(0)
			end,
			"--no-fix",
			"--output-format=json",
			"-",
			"--line-length=100",
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" }, {
			group = lint_augroup,
			callback = function()
				local ft = vim.bo.filetype
				local linters = lint.linters_by_ft[ft] or {}
				local valid_linters = {}
				for _, linter_name in ipairs(linters) do
					local linter = lint.linters[linter_name]
					local cmd = (type(linter) == "table" and linter.cmd) or linter_name
					if type(cmd) == "function" then
						cmd = cmd()
					end
					if vim.fn.executable(cmd) == 1 then
						table.insert(valid_linters, linter_name)
					end
				end
				if #valid_linters > 0 then
					lint.try_lint(valid_linters)
				end
			end,
		})

		vim.keymap.set("n", "<leader>l", function()
			lint.try_lint()
		end)
	end,
}
