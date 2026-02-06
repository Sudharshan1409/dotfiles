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
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>l", function()
			lint.try_lint()
		end)
	end,
}
